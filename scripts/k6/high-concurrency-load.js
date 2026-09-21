import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';
import {
  accessToken,
  assertLogin,
  authHeaders,
  backendName,
  firstDocumentId,
  healthPaths,
  jsonHeaders,
  jsonBody,
  login,
  ragResults,
  resolveBaseUrl,
  sseHas,
  streamHeaders,
} from './lib.js';

http.setResponseCallback(http.expectedStatuses({ min: 200, max: 399 }, 403, 404, 409));

const BASE_URL = resolveBaseUrl();
const BACKEND = backendName();
const DRIVER_USERNAME = __ENV.PERF_USERNAME || 'ce@ce.com';
const DRIVER_PASSWORD = __ENV.PERF_PASSWORD || '123456';
const ADMIN_USERNAME = __ENV.PERF_ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = __ENV.PERF_ADMIN_PASSWORD || 'Admin@123456';
const SUPER_USERNAME = __ENV.PERF_SUPER_USERNAME || 'superadmin';
const SUPER_PASSWORD = __ENV.PERF_SUPER_PASSWORD || 'SuperAdmin@123456';
const RAMP = __ENV.PERF_RAMP || '30s';
const HOLD = __ENV.PERF_HOLD || '2m';
const DOWN = __ENV.PERF_DOWN || '20s';
const DRIVER_VUS = parseInt(__ENV.PERF_USER_VUS || '160', 10);
const ADMIN_VUS = parseInt(__ENV.PERF_ADMIN_VUS || '120', 10);
const SUPER_VUS = parseInt(__ENV.PERF_SUPER_VUS || '40', 10);
const RAG_RATE = parseInt(__ENV.PERF_RAG_RATE || '25', 10);
const AGENT_RATE = parseInt(__ENV.PERF_AGENT_RATE || '6', 10);
const INCLUDE_AGENT = (__ENV.PERF_INCLUDE_AGENT || 'true').toLowerCase() !== 'false';
const RAG_QUERY = __ENV.PERF_RAG_QUERY || '驾驶员交通违法申诉材料、罚款缴纳、事故快处和车辆登记办理指南';
const AGENT_QUERY_MESSAGE = __ENV.PERF_AGENT_QUERY_MESSAGE || '查询我的违法记录';
const SUMMARY_JSON = __ENV.PERF_SUMMARY_JSON || `artifacts/k6/high-concurrency-${BACKEND}-summary.json`;

const healthOk = new Rate('health_ok');
const driverReadOk = new Rate('driver_read_ok');
const adminReadOk = new Rate('admin_read_ok');
const ragAdminOk = new Rate('rag_admin_ok');
const ragQueryOk = new Rate('rag_query_ok');
const agentOk = new Rate('agent_loop_ok');
const driverReadMs = new Trend('driver_read_ms', true);
const adminReadMs = new Trend('admin_read_ms', true);
const ragAdminMs = new Trend('rag_admin_ms', true);
const ragQueryMs = new Trend('rag_query_ms', true);
const agentMs = new Trend('agent_loop_ms', true);
const requests = new Counter('scenario_requests');

function ramp(target) {
  return [
    { duration: RAMP, target: Math.max(1, Math.floor(target * 0.4)) },
    { duration: RAMP, target },
    { duration: HOLD, target },
    { duration: DOWN, target: 0 },
  ];
}

const scenarios = {
  health_probe: {
    executor: 'constant-vus',
    vus: 4,
    duration: HOLD,
    exec: 'healthProbe',
  },
  driver_read: {
    executor: 'ramping-vus',
    stages: ramp(DRIVER_VUS),
    exec: 'driverRead',
  },
  admin_read: {
    executor: 'ramping-vus',
    stages: ramp(ADMIN_VUS),
    exec: 'adminRead',
    startTime: '5s',
  },
  rag_admin: {
    executor: 'ramping-vus',
    stages: ramp(SUPER_VUS),
    exec: 'ragAdmin',
    startTime: '8s',
  },
  rag_query: {
    executor: 'constant-arrival-rate',
    rate: RAG_RATE,
    timeUnit: '1s',
    duration: HOLD,
    preAllocatedVUs: Math.max(20, RAG_RATE * 2),
    maxVUs: Math.max(40, RAG_RATE * 6),
    exec: 'ragQuery',
    startTime: '10s',
  },
};

if (INCLUDE_AGENT) {
  scenarios.agent_loop = {
    executor: 'constant-arrival-rate',
    rate: AGENT_RATE,
    timeUnit: '1s',
    duration: HOLD,
    preAllocatedVUs: Math.max(8, AGENT_RATE * 3),
    maxVUs: Math.max(16, AGENT_RATE * 8),
    exec: 'agentLoop',
    startTime: '12s',
  };
}

export const options = {
  noConnectionReuse: false,
  scenarios,
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<3000', 'p(99)<8000'],
    checks: ['rate>0.90'],
    health_ok: ['rate>0.98'],
    driver_read_ok: ['rate>0.95'],
    admin_read_ok: ['rate>0.95'],
    rag_admin_ok: ['rate>0.95'],
    rag_query_ok: ['rate>0.95'],
  },
  summaryTrendStats: ['min', 'avg', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

if (INCLUDE_AGENT) {
  options.thresholds.agent_loop_ok = ['rate>0.85'];
}

export function setup() {
  const driverLogin = login(BASE_URL, DRIVER_USERNAME, DRIVER_PASSWORD, 'login_driver');
  const adminLogin = login(BASE_URL, ADMIN_USERNAME, ADMIN_PASSWORD, 'login_admin');
  const superLogin = login(BASE_URL, SUPER_USERNAME, SUPER_PASSWORD, 'login_super');
  assertLogin(driverLogin, DRIVER_USERNAME);
  assertLogin(adminLogin, ADMIN_USERNAME);
  assertLogin(superLogin, SUPER_USERNAME);
  const superToken = accessToken(superLogin);
  const list = http.get(`${BASE_URL}/api/rag/admin/documents?limit=20`, authHeaders(superToken, 'rag_admin_list_setup'));
  return {
    driverToken: accessToken(driverLogin),
    adminToken: accessToken(adminLogin),
    superToken,
    driverId: jsonBody(driverLogin)?.driverId || rawDriverId(driverLogin),
    documentId: firstDocumentId(list),
  };
}

function rawDriverId(response) {
  try {
    const body = response.json();
    return body.driverId || body.data?.driverId;
  } catch (_) {
    return null;
  }
}

export function healthProbe() {
  group('health', () => {
    for (const path of healthPaths()) {
      const res = http.get(`${BASE_URL}${path}`, jsonHeaders('health'));
      if (res.status >= 200 && res.status < 300) {
        healthOk.add(true);
        check(res, { 'health 2xx': () => true });
        return;
      }
    }
    healthOk.add(false);
    check({ status: 0 }, { 'health 2xx': () => false });
  });
  sleep(0.2);
}

export function driverRead(data) {
  group('driver high concurrency reads', () => {
    const paths = ['/api/auth/me'];
    if (data.driverId) {
      paths.push(
        `/api/drivers/${data.driverId}`,
        `/api/offenses/driver/${data.driverId}?page=1&size=10`,
        `/api/fines/driver/${data.driverId}?page=1&size=10`,
        `/api/payments/driver/${data.driverId}?page=1&size=10`,
      );
    }
    paths.push('/api/appeals/my?page=1&size=10');
    const path = paths[(__VU + __ITER) % paths.length];
    const res = http.get(`${BASE_URL}${path}`, authHeaders(data.driverToken, 'driver_read'));
    driverReadMs.add(res.timings.duration);
    const ok = res.status >= 200 && res.status < 300;
    driverReadOk.add(ok);
    requests.add(1);
    check(res, { 'driver read 2xx': () => ok });
  });
  sleep(0.05 + Math.random() * 0.15);
}

export function adminRead(data) {
  group('admin high concurrency reads', () => {
    const paths = [
      '/api/users?page=1&size=10',
      '/api/drivers?page=1&size=10',
      '/api/vehicles?page=1&size=10',
      '/api/offenses?page=1&size=10',
      '/api/fines?page=1&size=10',
      '/api/payments?page=1&size=10',
      '/api/appeals?page=1&size=10',
      '/api/roles?page=1&size=10',
    ];
    const path = paths[(__VU + __ITER) % paths.length];
    const res = http.get(`${BASE_URL}${path}`, authHeaders(data.adminToken, 'admin_read'));
    adminReadMs.add(res.timings.duration);
    const ok = res.status >= 200 && res.status < 300;
    adminReadOk.add(ok);
    requests.add(1);
    check(res, { 'admin read 2xx': () => ok });
  });
  sleep(0.04 + Math.random() * 0.12);
}

export function ragAdmin(data) {
  group('RAG admin high concurrency', () => {
    const choice = (__VU + __ITER) % 4;
    let res;
    if (choice === 0) {
      res = http.get(`${BASE_URL}/api/rag/admin/overview`, authHeaders(data.superToken, 'rag_admin_overview'));
    } else if (choice === 1) {
      res = http.get(`${BASE_URL}/api/rag/admin/documents?limit=20`, authHeaders(data.superToken, 'rag_admin_list'));
    } else if (choice === 2 && data.documentId) {
      res = http.get(`${BASE_URL}/api/rag/admin/documents/${data.documentId}`, authHeaders(data.superToken, 'rag_admin_detail'));
    } else {
      res = http.post(
        `${BASE_URL}/api/rag/admin/preview`,
        JSON.stringify({ query: RAG_QUERY, asRole: 'ADMIN', topK: 8 }),
        authHeaders(data.superToken, 'rag_admin_preview'),
      );
    }
    ragAdminMs.add(res.timings.duration);
    const ok = res.status >= 200 && res.status < 300;
    ragAdminOk.add(ok);
    requests.add(1);
    check(res, { 'rag admin 2xx': () => ok });
  });
  sleep(0.05 + Math.random() * 0.1);
}

export function ragQuery(data) {
  group('RAG query high concurrency', () => {
    const res = http.post(
      `${BASE_URL}/api/rag/query`,
      JSON.stringify({ query: RAG_QUERY, topK: 5, roles: ['ADMIN'] }),
      authHeaders(data.adminToken, 'rag_query'),
    );
    ragQueryMs.add(res.timings.duration);
    const results = ragResults(res);
    const ok = res.status === 200 && Array.isArray(results);
    ragQueryOk.add(ok);
    requests.add(1);
    check(res, { 'rag query 200 with list': () => ok });
  });
  sleep(0.02);
}

export function agentLoop(data) {
  group('assistant loop high concurrency', () => {
    const res = http.post(
      `${BASE_URL}/api/ai/chat/stream`,
      JSON.stringify({
        message: AGENT_QUERY_MESSAGE,
        sessionKey: `k6-hc-${BACKEND}-${__VU}-${__ITER}`,
        metadata: { webSearch: false },
      }),
      { ...streamHeaders(data.driverToken, 'ai_agent_query'), timeout: '45s' },
    );
    agentMs.add(res.timings.duration);
    const ok = res.status === 200 && (
      String(res.body || '').includes('data:') ||
      sseHas(res.body, 'tool') ||
      sseHas(res.body, 'result') ||
      sseHas(res.body, 'token') ||
      sseHas(res.body, 'done')
    );
    agentOk.add(ok);
    requests.add(1);
    check(res, { 'agent stream 200/sse': () => ok });
  });
  sleep(0.05);
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data),
    [SUMMARY_JSON]: JSON.stringify(data, null, 2),
  };
}

function textSummary(data) {
  const m = data.metrics || {};
  return [
    '',
    `Cloud/Go/Quarkus 高并发压测摘要`,
    `backend=${BACKEND} base_url=${BASE_URL}`,
    `driver_vus=${DRIVER_VUS} admin_vus=${ADMIN_VUS} super_vus=${SUPER_VUS} rag_rate=${RAG_RATE}/s agent_rate=${AGENT_RATE}/s hold=${HOLD} agent=${INCLUDE_AGENT}`,
    line(m, 'health_ok', '健康检查成功率'),
    line(m, 'driver_read_ok', '驾驶员读成功率'),
    trend(m, 'driver_read_ms', '驾驶员读耗时'),
    line(m, 'admin_read_ok', '管理员读成功率'),
    trend(m, 'admin_read_ms', '管理员读耗时'),
    line(m, 'rag_admin_ok', 'RAG 管理成功率'),
    trend(m, 'rag_admin_ms', 'RAG 管理耗时'),
    line(m, 'rag_query_ok', 'RAG 检索成功率'),
    trend(m, 'rag_query_ms', 'RAG 检索耗时'),
    line(m, 'agent_loop_ok', '帮办循环成功率'),
    trend(m, 'agent_loop_ms', '帮办循环耗时'),
    trend(m, 'http_req_duration', 'HTTP 总耗时'),
    line(m, 'http_req_failed', 'HTTP 失败率'),
    `summary_json=${SUMMARY_JSON}`,
    '',
  ].filter(Boolean).join('\n');
}

function line(metrics, name, label) {
  const rate = metrics[name]?.values?.rate;
  return typeof rate === 'number' ? `${label}=${rate.toFixed(3)}` : '';
}

function trend(metrics, name, label) {
  const values = metrics[name]?.values;
  if (!values) return '';
  return `${label}: avg=${fmt(values.avg)}ms p95=${fmt(values['p(95)'])}ms p99=${fmt(values['p(99)'])}ms`;
}

function fmt(value) {
  return typeof value === 'number' ? value.toFixed(1) : 'n/a';
}
