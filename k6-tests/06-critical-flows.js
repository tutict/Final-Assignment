// Critical Flow Test - Complete Violation Processing
// Test end-to-end business workflows

import http from 'k6/http';
import { check, sleep } from 'k6';
import { TRAFFIC_URL, THRESHOLDS } from './config.js';
import { login, getAuthOptions } from './auth-helper.js';
import {
  createDriverTestData,
  createVehicleTestData,
  createOffenseTestData,
  createFineTestData,
  createPaymentTestData,
} from './data-generators.js';

export const options = {
  vus: 10,
  iterations: 20,
  thresholds: THRESHOLDS,
};

let authToken;

export function setup() {
  console.log('Setting up critical flow test...');
  authToken = login('testuser1', 'Test123456!');
  return { token: authToken };
}

export default function(data) {
  const token = data.token;
  const authOptions = getAuthOptions(token);

  console.log('Starting complete violation processing flow...');

  // Step 1: Create driver
  const driverData = createDriverTestData();
  let response = http.post(`${TRAFFIC_URL}/drivers`, JSON.stringify(driverData), authOptions);

  const driverCreated = check(response, {
    'flow - create driver success': (r) => r.status === 200 || r.status === 201,
  });

  if (!driverCreated) {
    console.error(`Failed to create driver: ${response.status} ${response.body}`);
    return;
  }

  const driver = response.json();
  const driverId = driver.driverId || driver.id;

  console.log(`Created driver: ${driverId}`);
  sleep(0.5);

  // Step 2: Create vehicle
  const vehicleData = createVehicleTestData(null, driverData.name, driverData.idCardNumber);
  response = http.post(`${TRAFFIC_URL}/vehicles`, JSON.stringify(vehicleData), authOptions);

  const vehicleCreated = check(response, {
    'flow - create vehicle success': (r) => r.status === 200 || r.status === 201,
  });

  if (!vehicleCreated) {
    console.error(`Failed to create vehicle: ${response.status} ${response.body}`);
    return;
  }

  const vehicle = response.json();
  const vehicleId = vehicle.vehicleId || vehicle.id;

  console.log(`Created vehicle: ${vehicleId}`);
  sleep(0.5);

  // Step 3: Create offense record
  const offenseData = createOffenseTestData(driverId, vehicleId);
  response = http.post(`${TRAFFIC_URL}/offenses`, JSON.stringify(offenseData), authOptions);

  const offenseCreated = check(response, {
    'flow - create offense success': (r) => r.status === 200 || r.status === 201,
  });

  if (!offenseCreated) {
    console.error(`Failed to create offense: ${response.status} ${response.body}`);
    return;
  }

  const offense = response.json();
  const offenseId = offense.offenseId || offense.id;

  console.log(`Created offense: ${offenseId}`);
  sleep(0.5);

  // Step 4: Create fine record
  const fineData = createFineTestData(offenseId, driverId);
  response = http.post(`${TRAFFIC_URL}/fines`, JSON.stringify(fineData), authOptions);

  const fineCreated = check(response, {
    'flow - create fine success': (r) => r.status === 200 || r.status === 201,
  });

  if (!fineCreated) {
    console.error(`Failed to create fine: ${response.status} ${response.body}`);
    return;
  }

  const fine = response.json();
  const fineId = fine.fineId || fine.id;
  const fineAmount = fine.fineAmount || fineData.fineAmount;

  console.log(`Created fine: ${fineId}, amount: ${fineAmount}`);
  sleep(0.5);

  // Step 5: Create payment record
  const paymentData = createPaymentTestData(fineId, driverId, fineAmount);
  response = http.post(`${TRAFFIC_URL}/payments`, JSON.stringify(paymentData), authOptions);

  const paymentCreated = check(response, {
    'flow - create payment success': (r) => r.status === 200 || r.status === 201,
  });

  if (!paymentCreated) {
    console.error(`Failed to create payment: ${response.status} ${response.body}`);
    return;
  }

  const payment = response.json();
  const paymentId = payment.paymentId || payment.id;

  console.log(`Created payment: ${paymentId}`);
  sleep(0.5);

  // Step 6: Query violation with all details
  response = http.get(`${TRAFFIC_URL}/violations/${offenseId}`, authOptions);

  check(response, {
    'flow - query violation details success': (r) => r.status === 200,
    'flow - violation has complete data': (r) => {
      try {
        const data = r.json();
        return data.offense && data.driver && data.vehicle;
      } catch (e) {
        return false;
      }
    },
  });

  console.log(`✅ Complete violation processing flow finished successfully`);
  sleep(1);
}

export function teardown(data) {
  console.log('Critical flow test completed');
}
