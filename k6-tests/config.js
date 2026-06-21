// k6 Test Configuration
// Centralized configuration for all test scenarios

export const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
export const AUTH_URL = `${BASE_URL}/api/auth`;
export const USER_URL = `${BASE_URL}/api/users`;
export const TRAFFIC_URL = `${BASE_URL}/api`;
export const AUDIT_URL = `${BASE_URL}/api/logs`;
export const SYSTEM_URL = `${BASE_URL}/api/system`;

// Test user credentials (create these users before running tests)
export const TEST_USERS = [
  { username: 'testuser1', password: 'Test123456!' },
  { username: 'testuser2', password: 'Test123456!' },
  { username: 'testuser3', password: 'Test123456!' },
  { username: 'testuser4', password: 'Test123456!' },
  { username: 'testuser5', password: 'Test123456!' },
];

// Performance thresholds
export const THRESHOLDS = {
  // 95% of requests should be below 500ms
  http_req_duration: ['p(95)<500', 'p(99)<1000'],
  // Error rate should be less than 1%
  http_req_failed: ['rate<0.01'],
  // Throughput should be at least 100 req/s
  http_reqs: ['rate>100'],
  // 95% of checks should pass
  checks: ['rate>0.95'],
};

// Stricter thresholds for smoke tests
export const SMOKE_THRESHOLDS = {
  http_req_duration: ['p(95)<500'],
  http_req_failed: ['rate<0.001'],
  checks: ['rate>0.99'],
};

// Relaxed thresholds for stress tests
export const STRESS_THRESHOLDS = {
  http_req_duration: ['p(95)<1000', 'p(99)<2000'],
  http_req_failed: ['rate<0.05'],
  http_reqs: ['rate>50'],
  checks: ['rate>0.90'],
};

// HTTP request options
export const HTTP_OPTIONS = {
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  timeout: '30s',
};

// Test data configuration
export const DATA_CONFIG = {
  numDrivers: 100,
  numVehicles: 100,
  numOffenses: 200,
};
