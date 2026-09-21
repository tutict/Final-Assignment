// RAG admin + retrieval + assistant loop
// Works against Spring / Cloud / Go / Quarkus via BASE_URL or BACKEND.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { RAG_URL, THRESHOLDS, ROLE_USERS, BASE_URL } from './config.js';
import { login, getAuthOptions } from './auth-helper.js';

export const options = {
  vus: 5,
  iterations: 20,
  thresholds: THRESHOLDS,
};

http.setResponseCallback(http.expectedStatuses({ min: 200, max: 399 }, 403, 409));

function unwrap(payload) {
  if (!payload || typeof payload !== 'object') return payload;
  if (Object.prototype.hasOwnProperty.call(payload, 'data') &&
      (payload.success === true || payload.success === false || payload.errorCode)) {
    return payload.data;
  }
  return payload;
}

function body(res) {
  try { return unwrap(res.json()); } catch (_) { return null; }
}

function sseHas(text, type) {
  return String(text || '').toLowerCase().includes(`"type":"${type}"`) ||
    String(text || '').includes(`event: ${type}`);
}

export function setup() {
  console.log(`Setting up RAG module test against ${BASE_URL}`);
  const driverToken = login(ROLE_USERS.driver.username, ROLE_USERS.driver.password);
  const adminToken = login(ROLE_USERS.admin.username, ROLE_USERS.admin.password);
  const superToken = login(ROLE_USERS.superAdmin.username, ROLE_USERS.superAdmin.password);
  return { driverToken, adminToken, superToken };
}

export default function (data) {
  const superOpts = getAuthOptions(data.superToken);
  const adminOpts = getAuthOptions(data.adminToken);
  const driverOpts = getAuthOptions(data.driverToken);

  const queryPayload = JSON.stringify({
    query: '交通违章处理流程',
    topK: 10,
    roles: ['USER'],
  });
  let response = http.post(`${RAG_URL}/query`, queryPayload, driverOpts);
  const queryBody = body(response);
  const results = Array.isArray(queryBody) ? queryBody : (queryBody && queryBody.results) || [];
  check(response, {
    'rag - query executed': (r) => r.status === 200 || r.status === 409,
    'rag - query payload unwraps': () => response.status !== 200 || Array.isArray(results),
  });
  sleep(0.5);

  response = http.get(`${RAG_URL}/admin/overview`, superOpts);
  check(response, {
    'rag - SUPER_ADMIN overview 200': (r) => r.status === 200,
  });
  sleep(0.3);

  response = http.get(`${RAG_URL}/admin/overview`, adminOpts);
  check(response, {
    'rag - ADMIN overview 200': (r) => r.status === 200,
  });
  sleep(0.3);

  response = http.get(`${RAG_URL}/admin/overview`, driverOpts);
  check(response, {
    'rag - USER overview 403': (r) => r.status === 403,
  });
  sleep(0.3);

  response = http.get(`${RAG_URL}/admin/documents?limit=20`, superOpts);
  const docs = body(response);
  const list = Array.isArray(docs) ? docs : (docs && (docs.items || docs.records || docs.content)) || [];
  check(response, {
    'rag - SUPER_ADMIN list 200': (r) => r.status === 200,
  });

  const documentId = list[0] && (list[0].id || list[0].documentId);
  if (documentId) {
    response = http.get(`${RAG_URL}/admin/documents/${documentId}`, superOpts);
    check(response, {
      'rag - SUPER_ADMIN detail 200': (r) => r.status === 200,
    });
  }

  response = http.post(`${RAG_URL}/admin/preview`, JSON.stringify({
    query: '违法申诉',
    asRole: 'USER',
    topK: 8,
  }), superOpts);
  const preview = body(response);
  check(response, {
    'rag - SUPER_ADMIN preview 200': (r) => r.status === 200,
    'rag - preview is array': () => Array.isArray(preview) || Array.isArray(preview && preview.results),
  });
  sleep(0.5);

  response = http.post(`${BASE_URL}/api/ai/chat/stream`, JSON.stringify({
    message: '查询我的违法记录',
    sessionKey: `k6-rag-${__VU}-${__ITER}`,
    metadata: { webSearch: false },
  }), {
    headers: {
      Authorization: `Bearer ${data.driverToken}`,
      'Content-Type': 'application/json',
      Accept: 'text/event-stream',
    },
    timeout: '60s',
  });
  check(response, {
    'agent - driver query stream 200': (r) => r.status === 200,
    'agent - stream has SSE': (r) => String(r.body || '').includes('data:'),
    'agent - emits tool/result/token/done': (r) =>
      sseHas(r.body, 'tool') || sseHas(r.body, 'result') || sseHas(r.body, 'token') || sseHas(r.body, 'done'),
  });
  sleep(1);
}

export function teardown() {
  console.log('RAG module test completed');
}
