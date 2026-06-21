// Stress Test
// Test system behavior under peak load

import http from 'k6/http';
import { check, sleep } from 'k6';
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';
import { BASE_URL, TRAFFIC_URL, STRESS_THRESHOLDS } from './config.js';
import { loginRandomUser, getAuthOptions } from './auth-helper.js';
import { generateLicensePlate } from './data-generators.js';

export const options = {
  stages: [
    { duration: '2m', target: 100 },  // Ramp up to 100 VUs
    { duration: '2m', target: 100 },  // Hold at 100 VUs
    { duration: '2m', target: 200 },  // Ramp up to 200 VUs
    { duration: '2m', target: 200 },  // Hold at 200 VUs
    { duration: '2m', target: 300 },  // Ramp up to 300 VUs
    { duration: '3m', target: 300 },  // Hold at 300 VUs - STRESS!
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: STRESS_THRESHOLDS,
};

export function setup() {
  console.log('Starting stress test...');
  return { startTime: new Date().toISOString() };
}

export default function(data) {
  const token = loginRandomUser();
  if (!token) {
    sleep(1);
    return;
  }

  const authOptions = getAuthOptions(token);

  // Heavy read operations
  const operations = [
    // List violations
    () => {
      const response = http.get(`${TRAFFIC_URL}/violations?pageSize=50`, authOptions);
      check(response, { 'stress - list violations': (r) => r.status === 200 });
    },
    // Search vehicles
    () => {
      const plate = generateLicensePlate(randomIntBetween(1, 10000));
      const response = http.get(`${TRAFFIC_URL}/vehicles/search/license?licensePlate=${plate}`, authOptions);
      check(response, { 'stress - search vehicle': (r) => r.status === 200 || r.status === 404 });
    },
    // List offenses
    () => {
      const response = http.get(`${TRAFFIC_URL}/offenses?pageSize=30`, authOptions);
      check(response, { 'stress - list offenses': (r) => r.status === 200 });
    },
    // List payments
    () => {
      const response = http.get(`${TRAFFIC_URL}/payments?pageSize=20`, authOptions);
      check(response, { 'stress - list payments': (r) => r.status === 200 });
    },
  ];

  // Execute random operation
  const operation = operations[randomIntBetween(0, operations.length - 1)];
  operation();

  sleep(randomIntBetween(0.5, 2));
}

export function teardown(data) {
  const endTime = new Date();
  const startTime = new Date(data.startTime);
  const duration = (endTime - startTime) / 1000;
  console.log(`Stress test completed. Duration: ${duration.toFixed(2)}s`);
}
