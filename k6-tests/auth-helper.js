// Authentication Helper
// Handle JWT token management for authenticated requests

import http from 'k6/http';
import { check } from 'k6';
import { AUTH_URL, HTTP_OPTIONS, TEST_USERS } from './config.js';
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';

// Token cache (shared across VUs via __ENV if needed)
let tokenCache = {};

/**
 * Login and get JWT token
 */
export function login(username, password) {
  const payload = JSON.stringify({
    username: username,
    password: password,
  });

  const response = http.post(`${AUTH_URL}/login`, payload, HTTP_OPTIONS);

  const success = check(response, {
    'login status is 200': (r) => r.status === 200,
    'login response has token': (r) => r.json('token') !== undefined,
  });

  if (success) {
    const token = response.json('token');
    tokenCache[username] = token;
    return token;
  }

  console.error(`Login failed for ${username}: ${response.status} ${response.body}`);
  return null;
}

/**
 * Get a random test user and login
 */
export function loginRandomUser() {
  const user = TEST_USERS[randomIntBetween(0, TEST_USERS.length - 1)];

  // Check if we already have a cached token
  if (tokenCache[user.username]) {
    return tokenCache[user.username];
  }

  return login(user.username, user.password);
}

/**
 * Get authorization header with Bearer token
 */
export function getAuthHeader(token) {
  if (!token) {
    token = loginRandomUser();
  }

  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

/**
 * Get authenticated HTTP options
 */
export function getAuthOptions(token) {
  return {
    headers: getAuthHeader(token),
    timeout: '30s',
  };
}

/**
 * Check if token is expired (simple check based on response)
 */
export function isTokenExpired(response) {
  return response.status === 401 || response.status === 403;
}

/**
 * Refresh token if needed
 */
export function refreshTokenIfNeeded(username, response) {
  if (isTokenExpired(response)) {
    console.log(`Token expired for ${username}, refreshing...`);
    const user = TEST_USERS.find(u => u.username === username);
    if (user) {
      return login(user.username, user.password);
    }
  }
  return tokenCache[username];
}

/**
 * Clear token cache
 */
export function clearTokenCache() {
  tokenCache = {};
}
