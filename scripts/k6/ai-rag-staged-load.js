import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const BASE_URL = (__ENV.BASE_URL || 'http://127.0.0.1:8080').replace(/\/$/, '');
const ADMIN_USERNAME = __ENV.PERF_ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = __ENV.PERF_ADMIN_PASSWORD || 'Admin@123456';
const SUPER_USERNAME = __ENV.PERF_SUPER_USERNAME || 'superadmin';
const SUPER_PASSWORD = __ENV.PERF_SUPER_PASSWORD || 'SuperAdmin@123456';
const DURATION = __ENV.PERF_DURATION || '45s';
const ACTION_RATE = parseInt(__ENV.PERF_AI_ACTION_RATE || '2', 10);
const RAG_RATE = parseInt(__ENV.PERF_RAG_RATE || '2', 10);
const MODEL_RATE = parseInt(__ENV.PERF_MODEL_RATE || '1', 10);
const INCLUDE_MODEL = (__ENV.PERF_INCLUDE_MODEL || 'false').toLowerCase() === 'true';
const STRICT = (__ENV.PERF_STRICT || 'false').toLowerCase() === 'true';
const SUMMARY_JSON = __ENV.PERF_SUMMARY_JSON || 'artifacts/k6/ai-rag-staged-load-summary.json';

const aiHttpOrchestrationMs = new Trend('ai_http_orchestration_ms', true);
const ragRetrievalMs = new Trend('rag_retrieval_ms', true);
const aiModelGenerationMs = new Trend('ai_model_generation_ms', true);
const aiActionOk = new Rate('ai_action_ok');
const ragRetrievalOk = new Rate('rag_retrieval_ok');
const aiModelOk = new Rate('ai_model_ok');

const scenarios = {
  ai_http_orchestration: {
    executor: 'constant-arrival-rate',
    rate: ACTION_RATE,
    timeUnit: '1s',
    duration: DURATION,
    preAllocatedVUs: Math.max(2, ACTION_RATE * 2),
    maxVUs: Math.max(4, ACTION_RATE * 6),
    exec: 'aiHttpOrchestration',
  },
  rag_retrieval: {
    executor: 'constant-arrival-rate',
    rate: RAG_RATE,
    timeUnit: '1s',
    duration: DURATION,
    preAllocatedVUs: Math.max(2, RAG_RATE * 2),
    maxVUs: Math.max(4, RAG_RATE * 6),
    exec: 'ragRetrieval',
    startTime: '2s',
  },
};

if (INCLUDE_MODEL) {
  scenarios.ai_model_generation = {
    executor: 'constant-arrival-rate',
    rate: MODEL_RATE,
    timeUnit: '1s',
    duration: DURATION,
    preAllocatedVUs: Math.max(2, MODEL_RATE * 3),
    maxVUs: Math.max(4, MODEL_RATE * 8),
    exec: 'aiModelGeneration',
    startTime: '5s',
  };
}

const thresholds = {
  rag_retrieval_ok: ['rate>0.98'],
  rag_retrieval_ms: ['p(95)<1500'],
};

if (STRICT) {
  thresholds.http_req_failed = ['rate<0.03'];
  thresholds.checks = ['rate>0.97'];
  thresholds.ai_action_ok = ['rate>0.98'];
  thresholds.ai_http_orchestration_ms = ['p(95)<1200'];
}

export const options = {
  scenarios,
  thresholds,
  summaryTrendStats: ['min', 'avg', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

if (INCLUDE_MODEL && STRICT) {
  options.thresholds.ai_model_ok = ['rate>0.95'];
  options.thresholds.ai_model_generation_ms = ['p(95)<60000'];
}

export function setup() {
  const adminLogin = login(ADMIN_USERNAME, ADMIN_PASSWORD, 'login_admin');
  const superLogin = login(SUPER_USERNAME, SUPER_PASSWORD, 'login_super');
  assertLogin(adminLogin, ADMIN_USERNAME);
  assertLogin(superLogin, SUPER_USERNAME);
  return {
    adminToken: accessToken(adminLogin),
    superToken: accessToken(superLogin),
  };
}

export function aiHttpOrchestration(data) {
  group('AI HTTP orchestration', () => {
    const message = encodeURIComponent('帮我打开违法处理页面并说明下一步');
    const res = http.get(
      `${BASE_URL}/api/ai/chat/actions?message=${message}&webSearch=false`,
      authHeaders(data.adminToken, 'ai_actions'),
    );
    aiHttpOrchestrationMs.add(res.timings.duration);
    const success = res.status === 200 && json(res)?.success === true;
    check(res, {
      'AI actions returned an HTTP response': (r) => r.status > 0,
      'AI actions strict success': () => !STRICT || success,
    });
    aiActionOk.add(success);
  });
  sleep(0.1);
}

export function ragRetrieval(data) {
  group('RAG retrieval', () => {
    const res = http.post(
      `${BASE_URL}/api/rag/query`,
      JSON.stringify({
        query: '驾驶员如何处理交通违法申诉和罚款缴纳',
        topK: 5,
        roles: ['ADMIN'],
      }),
      authHeaders(data.adminToken, 'rag_query'),
    );
    ragRetrievalMs.add(res.timings.duration);
    const ok = check(res, {
      'RAG query status is 200': (r) => r.status === 200,
      'RAG query returns result list': (r) => Array.isArray(json(r)?.results),
    });
    ragRetrievalOk.add(ok);
  });
  sleep(0.1);
}

export function aiModelGeneration(data) {
  group('AI model generation stream', () => {
    const res = http.post(
      `${BASE_URL}/api/ai/chat/stream`,
      JSON.stringify({
        message: '请用三句话说明驾驶员申诉交通违法的办理流程',
        sessionKey: `k6-${__VU}-${__ITER}`,
        metadata: { webSearch: false, rag: false, ragEnabled: false },
      }),
      {
        ...streamHeaders(data.adminToken, 'ai_stream'),
        timeout: '90s',
      },
    );
    aiModelGenerationMs.add(res.timings.duration);
    const success = res.status === 200 && String(res.body || '').includes('data:');
    check(res, {
      'AI stream returned an HTTP response': (r) => r.status > 0,
      'AI stream strict success': () => !STRICT || success,
    });
    aiModelOk.add(success);
  });
  sleep(0.2);
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data),
    [SUMMARY_JSON]: JSON.stringify(data, null, 2),
  };
}

function login(username, password, endpoint) {
  return http.post(
    `${BASE_URL}/api/auth/login`,
    JSON.stringify({ username, password }),
    jsonHeaders(endpoint),
  );
}

function assertLogin(response, username) {
  const ok = check(response, {
    [`${username} login status is 200`]: (r) => r.status === 200,
    [`${username} login has token`]: (r) => Boolean(accessToken(r)),
  });
  if (!ok) {
    throw new Error(`Login failed for ${username}: status=${response.status} body=${response.body}`);
  }
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
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    tags: endpoint ? { endpoint } : undefined,
  };
}

function streamHeaders(token, endpoint) {
  return {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      Accept: 'text/event-stream',
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
  return [
    '',
    'AI/RAG k6 分段压测摘要',
    `base_url=${BASE_URL}`,
    `duration=${DURATION} action_rate=${ACTION_RATE}/s rag_rate=${RAG_RATE}/s include_model=${INCLUDE_MODEL} model_rate=${MODEL_RATE}/s strict=${STRICT}`,
    line(metrics, 'ai_action_ok', 'AI HTTP 编排成功率'),
    trend(metrics, 'ai_http_orchestration_ms', 'AI HTTP 编排耗时'),
    line(metrics, 'rag_retrieval_ok', 'RAG 检索成功率'),
    trend(metrics, 'rag_retrieval_ms', 'RAG 检索耗时'),
    line(metrics, 'ai_model_ok', '模型生成成功率'),
    trend(metrics, 'ai_model_generation_ms', '模型生成耗时'),
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
  if (!values) {
    return '';
  }
  return `${label}: avg=${fmt(values.avg)}ms p95=${fmt(values['p(95)'])}ms p99=${fmt(values['p(99)'])}ms`;
}

function fmt(value) {
  return typeof value === 'number' ? value.toFixed(1) : 'n/a';
}
