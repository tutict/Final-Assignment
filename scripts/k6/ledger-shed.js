import http from "k6/http";
import { check } from "k6";
import { Counter } from "k6/metrics";
import { authHeaders, login, accessToken } from "./lib.js";

const shed503 = new Counter("shed_503");

export const options = {
  scenarios: {
    shed: {
      executor: "constant-vus",
      vus: Number(__ENV.SHED_VUS || 40),
      duration: __ENV.SHED_DURATION || "15s",
    },
  },
  thresholds: {
    checks: ["rate>0.99"],
    shed_503: ["count>0"],
  },
};

const BASE = __ENV.BASE_URL || "http://127.0.0.1:9080";

export function setup() {
  const response = login(BASE, __ENV.ADMIN_USER || "admin", __ENV.ADMIN_PASSWORD || "Admin@123456", "shed_login");
  return { token: accessToken(response) };
}

function retryAfter(response) {
  return response.headers["Retry-After"] || response.headers["retry-after"] || "";
}

function noteShed(response) {
  if (response.status === 503 && retryAfter(response) === "1") {
    shed503.add(1);
    return true;
  }
  return false;
}

export default function (data) {
  const read = http.get(`${BASE}/api/auth/me`, authHeaders(data.token, "shed_me"));
  if (read.status === 503) {
    check(read, {
      "shed has Retry-After": (r) => noteShed(r),
    });
  } else {
    check(read, {
      "read is not an unexpected 5xx": (r) => r.status > 0 && r.status < 500,
    });
  }

  const stamp = `${__VU}-${__ITER}-${Date.now()}`;
  const key = `shed-${stamp}`;
  const headers = authHeaders(data.token, "shed_pay").headers;
  headers["Idempotency-Key"] = key;
  const body = JSON.stringify({
    fineId: Number(__ENV.FINE_ID || 1),
    paymentAmount: 1,
    paymentMethod: "WeChat",
    payerName: "shed",
    paymentNumber: `PS${stamp}`.slice(0, 64),
    transactionId: `TS${stamp}`.slice(0, 64),
  });
  const first = http.post(`${BASE}/api/payments`, body, { headers });
  const second = http.post(`${BASE}/api/payments`, body, { headers });
  noteShed(first);
  noteShed(second);
  check(first, {
    "first payment is accepted, shed, or a client conflict": (r) =>
      r.status === 201 || r.status === 208 || r.status === 400 || r.status === 409 || (r.status === 503 && retryAfter(r) === "1"),
  });
  check(second, {
    "replay does not create another payment": (r) => !(first.status === 201 && r.status === 201),
    "shed payment carries Retry-After": (r) => r.status !== 503 || retryAfter(r) === "1",
  });
}
