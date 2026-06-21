// RAG Module Test
// Test RAG retrieval and document management

import http from 'k6/http';
import { check, sleep } from 'k6';
import { RAG_URL, THRESHOLDS } from './config.js';
import { login, getAuthOptions } from './auth-helper.js';

export const options = {
  vus: 5,
  iterations: 20,
  thresholds: THRESHOLDS,
};

let authToken;

export function setup() {
  console.log('Setting up RAG module test...');
  authToken = login('testuser1', 'Test123456!');
  return { token: authToken };
}

export default function(data) {
  const token = data.token;
  const authOptions = getAuthOptions(token);

  // Test 1: RAG Query
  const queryPayload = JSON.stringify({
    query: '交通违章处理流程',
    topK: 10,
    roles: [],
    userId: null,
    department: null
  });

  let response = http.post(`${RAG_URL}/query`, queryPayload, authOptions);

  check(response, {
    'rag - query executed': (r) => r.status === 200 || r.status === 409, // 409 if RAG disabled
    'rag - response is valid': (r) => {
      if (r.status === 200) {
        try {
          const body = r.json();
          return body.success !== undefined;
        } catch (e) {
          return false;
        }
      }
      return true; // Skip validation if disabled
    },
  });

  sleep(1);

  // Test 2: RAG Query with different parameters
  const query2Payload = JSON.stringify({
    query: '罚款支付方式',
    topK: 5,
    roles: ['USER'],
    userId: 'test-user',
    department: null
  });

  response = http.post(`${RAG_URL}/query`, query2Payload, authOptions);

  check(response, {
    'rag - query with roles': (r) => r.status === 200 || r.status === 409,
  });

  sleep(1);

  // Test 3: Empty query handling
  const emptyQueryPayload = JSON.stringify({
    query: '',
    topK: 10,
  });

  response = http.post(`${RAG_URL}/query`, emptyQueryPayload, authOptions);

  check(response, {
    'rag - empty query handling': (r) => r.status >= 200 && r.status < 500,
  });

  sleep(1);
}

export function teardown(data) {
  console.log('RAG module test completed');
}
