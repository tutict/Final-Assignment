// Smoke Test
// Verify all critical endpoints are accessible and responding correctly

import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL, AUTH_URL, USER_URL, TRAFFIC_URL, AUDIT_URL, SYSTEM_URL, SMOKE_THRESHOLDS } from './config.js';
import { login, getAuthOptions } from './auth-helper.js';

export const options = {
  vus: 5,
  duration: '30s',
  thresholds: SMOKE_THRESHOLDS,
};

let authToken;

export function setup() {
  // Login once before tests
  console.log('Setting up smoke test...');
  authToken = login('testuser1', 'Test123456!');

  if (!authToken) {
    console.error('Failed to login during setup');
  }

  return { token: authToken };
}

export default function(data) {
  const token = data.token;
  const authOptions = getAuthOptions(token);

  // Test Gateway health
  let response = http.get(`${BASE_URL}/actuator/health`);
  check(response, {
    'gateway health check': (r) => r.status === 200 || r.status === 404,
  });

  sleep(0.5);

  // Test Auth endpoints
  response = http.get(`${AUTH_URL}/me`, authOptions);
  check(response, {
    'auth - get current user': (r) => r.status === 200,
  });

  sleep(0.5);

  // Test User endpoints
  response = http.get(`${USER_URL}`, authOptions);
  check(response, {
    'user - list users': (r) => r.status === 200,
  });

  sleep(0.5);

  // Test Traffic endpoints - Violations
  response = http.get(`${TRAFFIC_URL}/violations`, authOptions);
  check(response, {
    'traffic - list violations': (r) => r.status === 200,
  });

  sleep(0.5);

  // Test Traffic endpoints - Vehicles
  response = http.get(`${TRAFFIC_URL}/vehicles`, authOptions);
  check(response, {
    'traffic - list vehicles': (r) => r.status === 200,
  });

  sleep(0.5);

  // Test Traffic endpoints - Drivers
  response = http.get(`${TRAFFIC_URL}/drivers`, authOptions);
  check(response, {
    'traffic - list drivers': (r) => r.status === 200,
  });

  sleep(0.5);

  // Test Traffic endpoints - Offenses
  response = http.get(`${TRAFFIC_URL}/offenses`, authOptions);
  check(response, {
    'traffic - list offenses': (r) => r.status === 200,
  });

  sleep(0.5);

  // Test Traffic endpoints - Payments
  response = http.get(`${TRAFFIC_URL}/payments`, authOptions);
  check(response, {
    'traffic - list payments': (r) => r.status === 200,
  });

  sleep(0.5);

  // Test Audit endpoints - Login logs
  response = http.get(`${AUDIT_URL}/login`, authOptions);
  check(response, {
    'audit - list login logs': (r) => r.status === 200,
  });

  sleep(0.5);

  // Test Audit endpoints - Operation logs
  response = http.get(`${AUDIT_URL}/operation`, authOptions);
  check(response, {
    'audit - list operation logs': (r) => r.status === 200,
  });

  sleep(0.5);

  // Test System endpoints - Settings
  response = http.get(`${SYSTEM_URL}/settings`, authOptions);
  check(response, {
    'system - list settings': (r) => r.status === 200,
  });

  sleep(1);
}

export function teardown(data) {
  console.log('Smoke test completed');
}
