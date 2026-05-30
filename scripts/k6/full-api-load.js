import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const BASE_URL = (__ENV.BASE_URL || 'http://127.0.0.1:8080').replace(/\/$/, '');
const RUN_ID = `${Date.now()}-${Math.random().toString(16).slice(2)}`;

const USERNAME = __ENV.PERF_USERNAME || `perf-user-${RUN_ID}@test.com`;
const PASSWORD = __ENV.PERF_PASSWORD || 'pass12345';
const ADMIN_USERNAME = __ENV.PERF_ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = __ENV.PERF_ADMIN_PASSWORD || 'Admin@123456';
const SUPER_USERNAME = __ENV.PERF_SUPER_USERNAME || 'superadmin';
const SUPER_PASSWORD = __ENV.PERF_SUPER_PASSWORD || 'SuperAdmin@123456';
const REGISTER_USER = (__ENV.PERF_REGISTER_USER || 'true').toLowerCase() !== 'false';
const INCLUDE_AI = (__ENV.PERF_INCLUDE_AI || 'false').toLowerCase() === 'true';
const SUMMARY_JSON = __ENV.PERF_SUMMARY_JSON || 'artifacts/k6/full-api-load-summary.json';

const duration = __ENV.PERF_DURATION || '45s';
const userVus = parseInt(__ENV.PERF_USER_VUS || '12', 10);
const adminVus = parseInt(__ENV.PERF_ADMIN_VUS || '10', 10);
const superVus = parseInt(__ENV.PERF_SUPER_VUS || '4', 10);
const loginRate = parseInt(__ENV.PERF_LOGIN_RATE || '2', 10);

const healthOk = new Rate('health_ok');
const registerOk = new Rate('register_ok');
const loginOk = new Rate('login_ok');
const userReadOk = new Rate('user_read_ok');
const adminReadOk = new Rate('admin_read_ok');
const superReadOk = new Rate('super_read_ok');
const aiActionOk = new Rate('ai_action_ok');

export const options = {
  scenarios: {
    health_probe: {
      executor: 'constant-vus',
      vus: 2,
      duration,
      exec: 'healthProbe',
    },
    driver_read_journey: {
      executor: 'ramping-vus',
      stages: [
        { duration: '10s', target: userVus },
        { duration, target: userVus },
        { duration: '10s', target: 0 },
      ],
      exec: 'driverReadJourney',
    },
    admin_business_read: {
      executor: 'ramping-vus',
      stages: [
        { duration: '10s', target: adminVus },
        { duration, target: adminVus },
        { duration: '10s', target: 0 },
      ],
      exec: 'adminBusinessRead',
      startTime: '2s',
    },
    super_admin_read: {
      executor: 'constant-vus',
      vus: superVus,
      duration,
      exec: 'superAdminRead',
      startTime: '5s',
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
    http_req_failed: ['rate<0.02'],
    http_req_duration: ['p(95)<1500', 'p(99)<5000'],
    checks: ['rate>0.98'],
    health_ok: ['rate>0.99'],
    login_ok: ['rate>0.99'],
    user_read_ok: ['rate>0.98'],
    admin_read_ok: ['rate>0.98'],
    super_read_ok: ['rate>0.98'],
  },
  summaryTrendStats: ['min', 'avg', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

export function setup() {
  if (REGISTER_USER) {
    const registerRes = http.post(
      `${BASE_URL}/api/auth/register`,
      JSON.stringify({
        username: USERNAME,
        password: PASSWORD,
        role: 'USER',
        idempotencyKey: `perf-register-${RUN_ID}`,
      }),
      jsonHeaders('register'),
    );
    registerOk.add(check(registerRes, {
      'register status is created or conflict': (r) => r.status === 201 || r.status === 409,
    }));
  }

  const userLogin = loginRequest(USERNAME, PASSWORD, 'login_user');
  const adminLogin = loginRequest(ADMIN_USERNAME, ADMIN_PASSWORD, 'login_admin');
  const superLogin = loginRequest(SUPER_USERNAME, SUPER_PASSWORD, 'login_super');

  assertLogin(userLogin, USERNAME);
  assertLogin(adminLogin, ADMIN_USERNAME);
  assertLogin(superLogin, SUPER_USERNAME);

  return {
    username: USERNAME,
    userToken: accessToken(userLogin),
    userDriverId: json(userLogin)?.driverId,
    adminToken: accessToken(adminLogin),
    superToken: accessToken(superLogin),
  };
}

export function healthProbe() {
  group('health', () => {
    getAndCheck('/actuator/health/liveness', null, healthOk, 'health_liveness');
    getAndCheck('/actuator/health/readiness', null, healthOk, 'health_readiness');
  });
  sleep(0.2);
}

export function driverReadJourney(data) {
  group('driver reads', () => {
    getAndCheck('/api/auth/me', data.userToken, userReadOk, 'user_me');

    if (data.userDriverId) {
      getAndCheck(`/api/drivers/${data.userDriverId}`, data.userToken, userReadOk, 'driver_profile');
      getAndCheck(`/api/vehicles/drivers/${data.userDriverId}/records?page=1&size=10`, data.userToken, userReadOk, 'driver_vehicle_records');
      getAndCheck(`/api/offenses/driver/${data.userDriverId}?page=1&size=10`, data.userToken, userReadOk, 'driver_offenses');
      getAndCheck(`/api/fines/driver/${data.userDriverId}?page=1&size=10`, data.userToken, userReadOk, 'driver_fines');
      getAndCheck(`/api/payments/driver/${data.userDriverId}?page=1&size=10`, data.userToken, userReadOk, 'driver_payments');
      getAndCheck(`/api/deductions/driver/${data.userDriverId}?page=1&size=10`, data.userToken, userReadOk, 'driver_deductions');
    }

    getAndCheck('/api/appeals/my?page=1&size=10', data.userToken, userReadOk, 'driver_appeals');
  });
  sleep(0.2 + Math.random() * 0.4);
}

export function adminBusinessRead(data) {
  group('admin business reads', () => {
    const endpoints = [
      ['/api/auth/me', 'admin_me'],
      ['/api/users?page=1&size=10', 'admin_users'],
      ['/api/drivers?page=1&size=10', 'admin_drivers'],
      ['/api/vehicles?page=1&size=10', 'admin_vehicles'],
      ['/api/offenses?page=1&size=10', 'admin_offenses'],
      ['/api/fines?page=1&size=10', 'admin_fines'],
      ['/api/payments?page=1&size=10', 'admin_payments'],
      ['/api/deductions', 'admin_deductions'],
      ['/api/appeals?page=1&size=10', 'admin_appeals'],
      ['/api/offense-types?page=1&size=10', 'admin_offense_types'],
      ['/api/permissions?page=1&size=10', 'admin_permissions'],
      ['/api/roles?page=1&size=10', 'admin_roles'],
      ['/api/system/settings?page=1&size=10', 'admin_settings'],
    ];
    const selected = endpoints[(__VU + __ITER) % endpoints.length];
    getAndCheck(selected[0], data.adminToken, adminReadOk, selected[1]);
  });
  sleep(0.15 + Math.random() * 0.35);
}

export function superAdminRead(data) {
  group('super admin reads', () => {
    const endpoints = [
      ['/api/system/logs/overview', 'super_logs_overview'],
      ['/api/logs/login?page=1&size=10', 'super_login_logs'],
      ['/api/logs/operation?page=1&size=10', 'super_operation_logs'],
      ['/api/rag/admin/overview', 'super_rag_overview'],
      ['/api/rag/admin/documents?page=1&size=10', 'super_rag_documents'],
    ];
    const selected = endpoints[(__VU + __ITER) % endpoints.length];
    getAndCheck(selected[0], data.superToken, superReadOk, selected[1]);

    if (INCLUDE_AI) {
      const res = http.get(
        `${BASE_URL}/api/ai/chat/actions?message=${encodeURIComponent('帮我查看违法处理入口')}&webSearch=false`,
        authHeaders(data.adminToken, 'ai_actions'),
      );
      const ok = res.status === 200;
      aiActionOk.add(ok);
      check(res, { 'ai action status is 200': () => ok });
    }
  });
  sleep(0.3 + Math.random() * 0.4);
}

export function loginBaseline() {
  const res = loginRequest(ADMIN_USERNAME, ADMIN_PASSWORD, 'login_baseline');
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

function getAndCheck(path, token, rate, endpoint) {
  const res = http.get(`${BASE_URL}${path}`, token ? authHeaders(token, endpoint) : jsonHeaders(endpoint));
  const ok = res.status >= 200 && res.status < 300;
  rate.add(ok);
  check(res, { [`${endpoint} status is 2xx`]: () => ok });
  return res;
}

function assertLogin(response, username) {
  const ok = check(response, {
    [`${username} login status is 200`]: (r) => r.status === 200,
    [`${username} login returns access token`]: (r) => Boolean(accessToken(r)),
  });
  if (!ok) {
    throw new Error(`Login failed for ${username}: status=${response.status} body=${response.body}`);
  }
}

function loginRequest(username, password, endpoint) {
  return http.post(
    `${BASE_URL}/api/auth/login`,
    JSON.stringify({ username, password }),
    jsonHeaders(endpoint),
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
  const requests = metrics.http_reqs?.values?.count ?? 0;
  const lines = [
    '',
    'k6 full API load summary',
    `base_url=${BASE_URL}`,
    `duration=${duration} user_vus=${userVus} admin_vus=${adminVus} super_vus=${superVus} login_rate=${loginRate}/s include_ai=${INCLUDE_AI}`,
    `requests=${requests}`,
    `http_req_failed_rate=${format(failedMetric.rate)}`,
    `checks_rate=${format(checksMetric.rate)}`,
    `http_req_duration_avg=${format(durationMetric.avg)}ms`,
    `http_req_duration_p95=${format(durationMetric['p(95)'])}ms`,
    `http_req_duration_p99=${format(durationMetric['p(99)'])}ms`,
  ];

  for (const metric of ['health_ok', 'register_ok', 'login_ok', 'user_read_ok', 'admin_read_ok', 'super_read_ok', 'ai_action_ok']) {
    const values = metrics[metric]?.values;
    if (values) {
      lines.push(`${metric}_rate=${format(values.rate)}`);
    }
  }

  lines.push(`summary_json=${SUMMARY_JSON}`, '');
  return lines.join('\n');
}

function format(value) {
  return typeof value === 'number' ? value.toFixed(3) : 'n/a';
}
