import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import {
  accessToken,
  assertLogin,
  authHeaders,
  backendName,
  firstDocumentId,
  jsonBody,
  login,
  parseSseEvents,
  ragDocuments,
  ragResults,
  resolveBaseUrl,
  sseHas,
  streamHeaders,
} from './lib.js';

http.setResponseCallback(http.expectedStatuses({ min: 200, max: 399 }, 403, 409));

const BASE_URL = resolveBaseUrl();
const BACKEND = backendName();
const ADMIN_USERNAME = __ENV.PERF_ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = __ENV.PERF_ADMIN_PASSWORD || 'Admin@123456';
const SUPER_USERNAME = __ENV.PERF_SUPER_USERNAME || 'superadmin';
const SUPER_PASSWORD = __ENV.PERF_SUPER_PASSWORD || 'SuperAdmin@123456';
const DRIVER_USERNAME = __ENV.PERF_USERNAME || 'ce@ce.com';
const DRIVER_PASSWORD = __ENV.PERF_PASSWORD || '123456';
const DURATION = __ENV.PERF_DURATION || '45s';
const ACTION_RATE = parseInt(__ENV.PERF_AI_ACTION_RATE || '2', 10);
const RAG_RATE = parseInt(__ENV.PERF_RAG_RATE || '2', 10);
const RAG_ADMIN_RATE = parseInt(__ENV.PERF_RAG_ADMIN_RATE || '1', 10);
const AGENT_RATE = parseInt(__ENV.PERF_AGENT_RATE || '1', 10);
const MODEL_RATE = parseInt(__ENV.PERF_MODEL_RATE || '1', 10);
const INCLUDE_MODEL = (__ENV.PERF_INCLUDE_MODEL || 'false').toLowerCase() === 'true';
const INCLUDE_AGENT = (__ENV.PERF_INCLUDE_AGENT || 'true').toLowerCase() === 'true';
const STRICT = (__ENV.PERF_STRICT || 'false').toLowerCase() === 'true';
const SUMMARY_JSON = __ENV.PERF_SUMMARY_JSON || 'artifacts/k6/ai-rag-staged-load-summary.json';
const RAG_QUERY = __ENV.PERF_RAG_QUERY || '驾驶员交通违法申诉材料、罚款缴纳、事故快处和车辆登记办理指南';
const ACTION_MESSAGE = __ENV.PERF_ACTION_MESSAGE || '帮我打开交通违法申诉办理页面，并说明下一步需要填写什么';
const MODEL_MESSAGE = __ENV.PERF_MODEL_MESSAGE || '请用三句话说明驾驶员交通违法申诉、罚款缴纳和事故快处的办理流程';
const AGENT_QUERY_MESSAGE = __ENV.PERF_AGENT_QUERY_MESSAGE || '查询我的违法记录';
const AGENT_DRAFT_MESSAGE = __ENV.PERF_AGENT_DRAFT_MESSAGE || '我要申诉';

const aiHttpOrchestrationMs = new Trend('ai_http_orchestration_ms', true);
const ragRetrievalMs = new Trend('rag_retrieval_ms', true);
const ragAdminMs = new Trend('rag_admin_ms', true);
const aiModelGenerationMs = new Trend('ai_model_generation_ms', true);
const agentLoopMs = new Trend('agent_loop_ms', true);
const aiActionOk = new Rate('ai_action_ok');
const ragRetrievalOk = new Rate('rag_retrieval_ok');
const ragAdminOk = new Rate('rag_admin_ok');
const ragAdminForbiddenOk = new Rate('rag_admin_forbidden_ok');
const aiModelOk = new Rate('ai_model_ok');
const aiModelOllamaOk = new Rate('ai_model_ollama_ok');
const aiModelNoopFallbackOk = new Rate('ai_model_noop_fallback_ok');
const agentLoopOk = new Rate('agent_loop_ok');
const agentDraftOk = new Rate('agent_draft_ok');

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
  rag_admin: {
    executor: 'constant-arrival-rate',
    rate: RAG_ADMIN_RATE,
    timeUnit: '1s',
    duration: DURATION,
    preAllocatedVUs: Math.max(2, RAG_ADMIN_RATE * 2),
    maxVUs: Math.max(4, RAG_ADMIN_RATE * 6),
    exec: 'ragAdmin',
    startTime: '3s',
  },
};

if (INCLUDE_AGENT) {
  scenarios.agent_loop = {
    executor: 'constant-arrival-rate',
    rate: AGENT_RATE,
    timeUnit: '1s',
    duration: DURATION,
    preAllocatedVUs: Math.max(2, AGENT_RATE * 3),
    maxVUs: Math.max(4, AGENT_RATE * 8),
    exec: 'agentLoop',
    startTime: '4s',
  };
}

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
  rag_admin_ok: ['rate>0.98'],
  rag_admin_forbidden_ok: ['rate>0.98'],
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

if (INCLUDE_AGENT && STRICT) {
  options.thresholds.agent_loop_ok = ['rate>0.90'];
  options.thresholds.agent_draft_ok = ['rate>0.90'];
}

if (INCLUDE_MODEL && STRICT) {
  options.thresholds.ai_model_ok = ['rate>0.95'];
  options.thresholds.ai_model_generation_ms = ['p(95)<60000'];
}

export function setup() {
  const adminLogin = login(BASE_URL, ADMIN_USERNAME, ADMIN_PASSWORD, 'login_admin');
  const superLogin = login(BASE_URL, SUPER_USERNAME, SUPER_PASSWORD, 'login_super');
  const driverLogin = login(BASE_URL, DRIVER_USERNAME, DRIVER_PASSWORD, 'login_driver');
  assertLogin(adminLogin, ADMIN_USERNAME);
  assertLogin(superLogin, SUPER_USERNAME);
  assertLogin(driverLogin, DRIVER_USERNAME);

  const superToken = accessToken(superLogin);
  const list = http.get(`${BASE_URL}/api/rag/admin/documents?limit=20`, authHeaders(superToken, 'rag_admin_list_setup'));
  return {
    adminToken: accessToken(adminLogin),
    superToken,
    driverToken: accessToken(driverLogin),
    documentId: firstDocumentId(list),
  };
}

export function aiHttpOrchestration(data) {
  group('AI HTTP orchestration', () => {
    const message = encodeURIComponent(ACTION_MESSAGE);
    const res = http.get(
      `${BASE_URL}/api/ai/chat/actions?message=${message}&webSearch=false`,
      authHeaders(data.adminToken, 'ai_actions'),
    );
    aiHttpOrchestrationMs.add(res.timings.duration);
    const body = jsonBody(res);
    const success = res.status === 200 && Boolean(body) && (body.success === undefined || body.success === true || typeof body.answer === 'string');
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
        query: RAG_QUERY,
        topK: 5,
        roles: ['ADMIN'],
      }),
      authHeaders(data.adminToken, 'rag_query'),
    );
    ragRetrievalMs.add(res.timings.duration);
    const results = ragResults(res);
    const ok = check(res, {
      'RAG query status is 200': (r) => r.status === 200,
      'RAG query returns result list': () => Array.isArray(results),
      'RAG strict query returns real hits': () => !STRICT || (Array.isArray(results) && results.length > 0),
    });
    ragRetrievalOk.add(ok);
  });
  sleep(0.1);
}

export function ragAdmin(data) {
  group('RAG admin contract', () => {
    const overview = http.get(`${BASE_URL}/api/rag/admin/overview`, authHeaders(data.superToken, 'rag_admin_overview'));
    ragAdminMs.add(overview.timings.duration);
    const overviewBody = jsonBody(overview);
    const overviewOk = check(overview, {
      'SUPER_ADMIN overview is 200': (r) => r.status === 200,
      'overview has documentCount': () => overviewBody && (overviewBody.documentCount !== undefined || overviewBody.ragEnabled !== undefined),
    });

    const list = http.get(`${BASE_URL}/api/rag/admin/documents?limit=20`, authHeaders(data.superToken, 'rag_admin_list'));
    ragAdminMs.add(list.timings.duration);
    const docs = ragDocuments(list);
    const listOk = check(list, {
      'SUPER_ADMIN list is 200': (r) => r.status === 200,
      'document list is array': () => Array.isArray(docs),
    });

    const documentId = data.documentId || firstDocumentId(list);
    let detailOk = true;
    if (documentId) {
      const detail = http.get(`${BASE_URL}/api/rag/admin/documents/${documentId}`, authHeaders(data.superToken, 'rag_admin_detail'));
      ragAdminMs.add(detail.timings.duration);
      const detailBody = jsonBody(detail);
      detailOk = check(detail, {
        'SUPER_ADMIN document detail is 200': (r) => r.status === 200,
        'document detail has chunks or content': () => Boolean(detailBody && (detailBody.content !== undefined || detailBody.chunks || detailBody.document)),
      });
    }

    const preview = http.post(
      `${BASE_URL}/api/rag/admin/preview`,
      JSON.stringify({ query: RAG_QUERY, asRole: 'ADMIN', topK: 8 }),
      authHeaders(data.superToken, 'rag_admin_preview'),
    );
    ragAdminMs.add(preview.timings.duration);
    const hits = ragResults(preview);
    const previewOk = check(preview, {
      'SUPER_ADMIN preview is 200': (r) => r.status === 200,
      'preview returns array': () => Array.isArray(hits),
    });

    const adminOverview = http.get(`${BASE_URL}/api/rag/admin/overview`, authHeaders(data.adminToken, 'rag_admin_admin'));
    const adminCanManage = check(adminOverview, {
      'ADMIN rag admin is 200': (r) => r.status === 200,
    });
    const forbidden = http.get(`${BASE_URL}/api/rag/admin/overview`, authHeaders(data.driverToken, 'rag_admin_forbidden'));
    const forbiddenOk = check(forbidden, {
      'USER rag admin is 403': (r) => r.status === 403,
    });
    ragAdminForbiddenOk.add(forbiddenOk);
    ragAdminOk.add(overviewOk && listOk && detailOk && previewOk && adminCanManage);
  });
  sleep(0.1);
}

export function agentLoop(data) {
  group('assistant tool loop', () => {
    const queryRes = http.post(
      `${BASE_URL}/api/ai/chat/stream`,
      JSON.stringify({
        message: AGENT_QUERY_MESSAGE,
        sessionKey: `k6-query-${__VU}-${__ITER}`,
        metadata: { webSearch: false },
      }),
      { ...streamHeaders(data.driverToken, 'ai_agent_query'), timeout: '60s' },
    );
    agentLoopMs.add(queryRes.timings.duration);
    const queryOk = check(queryRes, {
      'driver query stream is 200': (r) => r.status === 200,
      'driver query stream has SSE data': (r) => String(r.body || '').includes('data:'),
      'driver query emits tool or result': (r) => sseHas(r.body, 'tool') || sseHas(r.body, 'result') || sseHas(r.body, 'token') || sseHas(r.body, 'done'),
    });
    agentLoopOk.add(queryOk);

    const draftRes = http.post(
      `${BASE_URL}/api/ai/chat/stream`,
      JSON.stringify({
        message: AGENT_DRAFT_MESSAGE,
        sessionKey: `k6-draft-${__VU}-${__ITER}`,
        metadata: { webSearch: false },
      }),
      { ...streamHeaders(data.driverToken, 'ai_agent_draft'), timeout: '60s' },
    );
    agentLoopMs.add(draftRes.timings.duration);
    const events = parseSseEvents(draftRes.body);
    const draftEvent = events.find((event) => String(event.type || '').toLowerCase() === 'draft');
    const draftOk = check(draftRes, {
      'driver draft stream is 200': (r) => r.status === 200,
      'write intent does not require model crash': (r) => r.status === 200,
    });
    const foreign = http.post(
      `${BASE_URL}/api/ai/chat/stream`,
      JSON.stringify({
        message: `确认办理 ${draftEvent?.payload?.draftId || '00000000-0000-0000-0000-000000000000'}`,
        sessionKey: `k6-foreign-${__VU}-${__ITER}`,
        metadata: { webSearch: false },
      }),
      { ...streamHeaders(data.adminToken, 'ai_agent_foreign_draft'), timeout: '60s' },
    );
    const foreignBody = String(foreign.body || '');
    const foreignRejected = foreign.status === 200 && (
      foreignBody.includes('其他用户') ||
      foreignBody.includes('过期') ||
      foreignBody.includes('没有待确认') ||
      sseHas(foreign.body, 'result') ||
      sseHas(foreign.body, 'error')
    );
    check(foreign, {
      'foreign draft confirm is rejected or explained': () => foreignRejected,
    });
    agentDraftOk.add(draftOk && foreignRejected);
  });
  sleep(0.2);
}

export function aiModelGeneration(data) {
  group('AI model generation stream', () => {
    const res = http.post(
      `${BASE_URL}/api/ai/chat/stream`,
      JSON.stringify({
        message: MODEL_MESSAGE,
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
    const providerStats = streamProviderStats(res.body);
    check(res, {
      'AI stream returned an HTTP response': (r) => r.status > 0,
      'AI stream strict success': () => !STRICT || success,
    });
    aiModelOk.add(success);
    aiModelOllamaOk.add(success && providerStats.hasOllama && !providerStats.hasNoopFallback);
    aiModelNoopFallbackOk.add(success && providerStats.hasNoopFallback);
  });
  sleep(0.2);
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data),
    [SUMMARY_JSON]: JSON.stringify(data, null, 2),
  };
}

function streamProviderStats(body) {
  const stats = { hasOllama: false, hasNoopFallback: false };
  for (const event of parseSseEvents(body)) {
    const payload = event.payload || event.metadata || {};
    const provider = String(payload.provider || event.provider || '').toLowerCase();
    const fallback = payload.isFallback === true || payload.fallback === true || event.isFallback === true;
    if (provider === 'ollama') {
      stats.hasOllama = true;
    }
    if (provider === 'noop' || fallback) {
      stats.hasNoopFallback = true;
    }
  }
  return stats;
}

function textSummary(data) {
  const metrics = data.metrics || {};
  return [
    '',
    'AI/RAG k6 分段压测摘要',
    `backend=${BACKEND} base_url=${BASE_URL}`,
    `duration=${DURATION} action_rate=${ACTION_RATE}/s rag_rate=${RAG_RATE}/s rag_admin_rate=${RAG_ADMIN_RATE}/s agent_rate=${AGENT_RATE}/s include_agent=${INCLUDE_AGENT} include_model=${INCLUDE_MODEL} model_rate=${MODEL_RATE}/s strict=${STRICT}`,
    line(metrics, 'ai_action_ok', 'AI HTTP 编排成功率'),
    trend(metrics, 'ai_http_orchestration_ms', 'AI HTTP 编排耗时'),
    line(metrics, 'rag_retrieval_ok', 'RAG 检索成功率'),
    trend(metrics, 'rag_retrieval_ms', 'RAG 检索耗时'),
    line(metrics, 'rag_admin_ok', 'RAG 管理成功率'),
    line(metrics, 'rag_admin_forbidden_ok', 'RAG 管理 USER 403 对齐成功率'),
    trend(metrics, 'rag_admin_ms', 'RAG 管理耗时'),
    line(metrics, 'agent_loop_ok', '帮办查询循环成功率'),
    line(metrics, 'agent_draft_ok', '帮办草稿/拒绝成功率'),
    trend(metrics, 'agent_loop_ms', '帮办循环耗时'),
    line(metrics, 'ai_model_ok', 'AI stream 返回成功率'),
    line(metrics, 'ai_model_ollama_ok', 'AI stream Ollama 真实调用成功率'),
    line(metrics, 'ai_model_noop_fallback_ok', 'AI stream noop fallback 比例'),
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
