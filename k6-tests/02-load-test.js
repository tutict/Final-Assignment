// Load Test
// Test system under normal operational load

import http from 'k6/http';
import { check, sleep } from 'k6';
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';
import { BASE_URL, TRAFFIC_URL, THRESHOLDS } from './config.js';
import { loginRandomUser, getAuthOptions } from './auth-helper.js';
import { generateLicensePlate } from './data-generators.js';

export const options = {
  stages: [
    { duration: '1m', target: 50 },   // Ramp up to 50 VUs
    { duration: '3m', target: 50 },   // Hold at 50 VUs
    { duration: '1m', target: 100 },  // Ramp up to 100 VUs
    { duration: '3m', target: 100 },  // Hold at 100 VUs
    { duration: '1m', target: 0 },    // Ramp down to 0
  ],
  thresholds: THRESHOLDS,
};

export function setup() {
  console.log('Starting load test...');
  return { startTime: new Date().toISOString() };
}

export default function(data) {
  // Login once per VU
  const token = loginRandomUser();
  if (!token) {
    console.error('Failed to login');
    return;
  }

  const authOptions = getAuthOptions(token);
  const action = randomIntBetween(1, 100);

  // 30% - Search violations
  if (action <= 30) {
    const response = http.get(`${TRAFFIC_URL}/violations`, authOptions);
    check(response, {
      'search violations success': (r) => r.status === 200,
      'search violations has data': (r) => {
        try {
          const body = r.json();
          return Array.isArray(body) || body.data !== undefined;
        } catch (e) {
          return false;
        }
      },
    });
  }
  // 20% - Get violation details
  else if (action <= 50) {
    // First get a list
    let response = http.get(`${TRAFFIC_URL}/offenses?pageSize=10`, authOptions);
    if (response.status === 200) {
      try {
        const offenses = response.json();
        if (Array.isArray(offenses) && offenses.length > 0) {
          const offenseId = offenses[0].offenseId || offenses[0].id;
          if (offenseId) {
            response = http.get(`${TRAFFIC_URL}/violations/${offenseId}`, authOptions);
            check(response, {
              'get violation details success': (r) => r.status === 200,
            });
          }
        }
      } catch (e) {
        // Silently handle parsing errors
      }
    }
  }
  // 25% - Search license plates
  else if (action <= 75) {
    const licensePlate = generateLicensePlate(randomIntBetween(1, 1000));
    const response = http.get(`${TRAFFIC_URL}/vehicles/search/license?licensePlate=${licensePlate}`, authOptions);
    check(response, {
      'search license plate executed': (r) => r.status === 200 || r.status === 404,
    });
  }
  // 10% - Query payments
  else if (action <= 85) {
    const response = http.get(`${TRAFFIC_URL}/payments?pageSize=20`, authOptions);
    check(response, {
      'query payments success': (r) => r.status === 200,
    });
  }
  // 15% - Query user profile
  else {
    const response = http.get(`${BASE_URL}/api/auth/me`, authOptions);
    check(response, {
      'query profile success': (r) => r.status === 200,
    });
  }

  // Think time - random between 1-3 seconds
  sleep(randomIntBetween(1, 3));
}

export function teardown(data) {
  const endTime = new Date();
  const startTime = new Date(data.startTime);
  const duration = (endTime - startTime) / 1000;
  console.log(`Load test completed. Duration: ${duration.toFixed(2)}s`);
}
