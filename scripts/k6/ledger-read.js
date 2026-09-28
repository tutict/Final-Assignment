import http from "k6/http";
import { check, sleep } from "k6";
import { authHeaders, login, accessToken } from "./lib.js";

export const options = {
  scenarios: {
    ledger: {
      executor: "constant-vus",
      vus: 16,
      duration: __ENV.PERF_DURATION || "5m",
    },
  },
  thresholds: {
    checks: ["rate>0.99"],
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<200", "p(99)<500"],
  },
};

const BASE = __ENV.BASE_URL || "http://127.0.0.1:9080";
const PATHS = [
  "/api/payments?page=1&size=10",
  "/api/fines?page=1&size=10",
  "/api/deductions?page=1&size=10",
  "/api/appeals?page=1&size=10",
  "/api/offenses?page=1&size=10",
];

export function setup() {
  const response = login(BASE, __ENV.ADMIN_USER || "admin", __ENV.ADMIN_PASSWORD || "Admin@123456", "ledger_read_login");
  return { token: accessToken(response) };
}

export default function (data) {
  const path = PATHS[__ITER % PATHS.length];
  const response = http.get(`${BASE}${path}`, authHeaders(data.token, "ledger_read"));
  check(response, {
    "ledger read is 200": (r) => r.status === 200,
  });
  sleep(0.05);
}
