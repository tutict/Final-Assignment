import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const BASE_URL = (__ENV.BASE_URL || 'http://127.0.0.1:8080').replace(/\/$/, '');
const PASSWORD = __ENV.PERF_PASSWORD || 'pass12345';
const USERNAME = __ENV.PERF_USERNAME || `k6-${Date.now()}@test.com`;
const REGISTER_USER = (__ENV.PERF_REGISTER_USER || 'true').toLowerCase() !== 'false';
const SUMMARY_JSON = __ENV.PERF_SUMMARY_JSON || 'artifacts/k6/auth-read-load-summary.json';

const readVus = parseInt(__ENV.PERF_READ_VUS || '20', 10);
const loginRate = parseInt(__ENV.PERF_LOGIN_RATE || '2', 10);
const duration = __ENV.PERF_DURATION || '45s';

const healthOk = new Rate('health_ok');
const profileOk = new Rate('profile_ok');
const loginOk = new Rate('login_ok');

export const options = {
  scenarios: {
    auth_read: {
      executor: 'ramping-vus',
      stages: [
        { duration: '10s', target: readVus },
        { duration, target: readVus },
        { duration: '10s', target: 0 },
      ],
      exec: 'authRead',
    },
    login_baseline: {
      executor: 'constant-arrival-rate',
      rate: loginRate,
      timeUnit: '1s',
      duration,
      preAllocatedVUs: Math.max(2, loginRate * 2),
      maxVUs: Math.max(6, loginRate * 6),
      exec: 'loginBaseline',
      startTime: '5s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1000', 'p(99)<2000'],
    checks: ['rate>0.99'],
    health_ok: ['rate>0.99'],
    profile_ok: ['rate>0.99'],
    login_ok: ['rate>0.99'],
  },
  summaryTrendStats: ['min', 'avg', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

export function setup() {
  if (REGISTER_USER) {
    const registerPayload = JSON.stringify({
      username: USERNAME,
      password: PASSWORD,
      role: 'USER',
      idempotencyKey: `${USERNAME}-${Date.now()}`,
    });
    const registerRes = http.post(`${BASE_URL}/api/auth/register`, registerPayload, jsonHeaders());
    check(registerRes, {
      'setup register created or already exists': (res) => res.status === 201 || res.status === 409,
    });
  }

  const login = loginRequest(USERNAME);
  check(login, {
    'setup login status is 200': (res) => res.status === 200,
    'setup login has access token': (res) => Boolean(accessToken(res)),
  });
  const token = accessToken(login);
  if (!token) {
    throw new Error(`Login failed for ${USERNAME}: status=${login.status} body=${login.body}`);
  }

  return {
    username: USERNAME,
    token,
  };
}

export function authRead(data) {
  group('health', () => {
    const res = http.get(`${BASE_URL}/actuator/health`, {
      tags: { endpoint: 'health' },
    });
    const ok = check(res, {
      'health status is 200': (r) => r.status === 200,
      'health is UP': (r) => String(r.body).includes('"UP"'),
    });
    healthOk.add(ok);
  });

  group('auth profile', () => {
    const res = http.get(`${BASE_URL}/api/auth/me`, authHeaders(data.token, 'auth_me'));
    const ok = check(res, {
      'profile status is 200': (r) => r.status === 200,
      'profile success envelope': (r) => json(r)?.success === true,
      'profile username matches': (r) => json(r)?.data?.username === data.username,
    });
    profileOk.add(ok);
  });

  sleep(0.2 + Math.random() * 0.4);
}

export function loginBaseline(data) {
  const res = loginRequest(data.username);
  const ok = check(res, {
    'login status is 200': (r) => r.status === 200,
    'login returns access token': (r) => Boolean(accessToken(r)),
  });
  loginOk.add(ok);
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data),
    [SUMMARY_JSON]: JSON.stringify(data, null, 2),
  };
}

function loginRequest(username) {
  return http.post(
    `${BASE_URL}/api/auth/login`,
    JSON.stringify({ username, password: PASSWORD }),
    jsonHeaders('auth_login'),
  );
}

function jsonHeaders(endpoint) {
  return {
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    tags: endpoint ? { endpoint } : undefined,
  };
}

function authHeaders(token, endpoint) {
  return {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/json',
    },
    tags: endpoint ? { endpoint } : undefined,
  };
}

function accessToken(response) {
  return json(response)?.accessToken || json(response)?.jwtToken || json(response)?.data?.accessToken;
}

function json(response) {
  try {
    return response.json();
  } catch (_) {
    return null;
  }
}

function textSummary(data) {
  const metrics = data.metrics || {};
  const durationMetric = metrics.http_req_duration?.values || {};
  const failedMetric = metrics.http_req_failed?.values || {};
  const checksMetric = metrics.checks?.values || {};
  const healthMetric = metrics.health_ok?.values || {};
  const profileMetric = metrics.profile_ok?.values || {};
  const loginMetric = metrics.login_ok?.values || {};
  const requests = metrics.http_reqs?.values?.count ?? 0;
  return [
    '',
    'k6 auth/read load summary',
    `base_url=${BASE_URL}`,
    `read_vus=${readVus} login_rate=${loginRate}/s duration=${duration}`,
    `requests=${requests}`,
    `http_req_failed_rate=${format(failedMetric.rate)}`,
    `checks_rate=${format(checksMetric.rate)}`,
    `health_ok_rate=${format(healthMetric.rate)}`,
    `profile_ok_rate=${format(profileMetric.rate)}`,
    `login_ok_rate=${format(loginMetric.rate)}`,
    `http_req_duration_avg=${format(durationMetric.avg)}ms`,
    `http_req_duration_p95=${format(durationMetric['p(95)'])}ms`,
    `http_req_duration_p99=${format(durationMetric['p(99)'])}ms`,
    `summary_json=${SUMMARY_JSON}`,
    '',
  ].join('\n');
}

function format(value) {
  return typeof value === 'number' ? value.toFixed(3) : 'n/a';
}
