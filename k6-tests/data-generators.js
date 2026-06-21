// Test Data Generators
// Generate realistic test data with proper foreign key relationships

import { randomIntBetween, randomString } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';

// Counter for generating unique IDs
let counter = 0;

/**
 * Get current timestamp in yyyyMMddHHmmss format
 */
export function getTimestamp() {
  const now = new Date();
  return now.getFullYear().toString() +
    (now.getMonth() + 1).toString().padStart(2, '0') +
    now.getDate().toString().padStart(2, '0') +
    now.getHours().toString().padStart(2, '0') +
    now.getMinutes().toString().padStart(2, '0') +
    now.getSeconds().toString().padStart(2, '0');
}

/**
 * Generate unique Chinese ID card number (18 digits)
 * Format: 110101yyyyMMdd####X
 */
export function generateIdCard(baseCounter) {
  const seq = (baseCounter || ++counter).toString().padStart(4, '0');
  const idCard = `110101199001${seq}`;
  // Simple checksum (not real algorithm, just for testing)
  const checksum = (parseInt(idCard) % 10).toString();
  return idCard + checksum;
}

/**
 * Generate unique license plate number
 * Format: 京A12345
 */
export function generateLicensePlate(baseCounter) {
  const provinces = ['京', '津', '沪', '渝', '冀', '豫', '云', '辽', '黑', '湘'];
  const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K'];

  const province = provinces[randomIntBetween(0, provinces.length - 1)];
  const letter = letters[randomIntBetween(0, letters.length - 1)];
  const number = (baseCounter || ++counter).toString().padStart(5, '0');

  return `${province}${letter}${number}`;
}

/**
 * Generate unique driver license number
 */
export function generateDriverLicense(baseCounter) {
  const seq = (baseCounter || ++counter).toString().padStart(12, '0');
  return `110101${seq}`;
}

/**
 * Generate unique offense number
 * Format: OF2024060100001
 */
export function generateOffenseNumber() {
  const timestamp = getTimestamp().substring(0, 8); // yyyyMMdd
  const seq = (++counter).toString().padStart(5, '0');
  return `OF${timestamp}${seq}`;
}

/**
 * Generate unique fine number
 */
export function generateFineNumber() {
  const timestamp = getTimestamp().substring(0, 8);
  const seq = (++counter).toString().padStart(4, '0');
  return `FN${timestamp}${seq}`;
}

/**
 * Generate unique payment number
 */
export function generatePaymentNumber() {
  const timestamp = getTimestamp();
  const seq = (++counter).toString().padStart(5, '0');
  return `PAY${timestamp}${seq}`;
}

/**
 * Generate unique appeal number
 */
export function generateAppealNumber() {
  const timestamp = getTimestamp().substring(0, 8);
  const seq = (++counter).toString().padStart(4, '0');
  return `AP${timestamp}${seq}`;
}

/**
 * Generate realistic Chinese name
 */
export function generateChineseName() {
  const surnames = ['张', '李', '王', '刘', '陈', '杨', '黄', '赵', '吴', '周'];
  const names = ['伟', '芳', '娜', '秀英', '敏', '静', '丽', '强', '磊', '军', '洋', '勇', '艳', '杰', '涛'];

  const surname = surnames[randomIntBetween(0, surnames.length - 1)];
  const name1 = names[randomIntBetween(0, names.length - 1)];
  const name2 = randomIntBetween(0, 1) === 1 ? names[randomIntBetween(0, names.length - 1)] : '';

  return surname + name1 + name2;
}

/**
 * Generate phone number
 */
export function generatePhoneNumber() {
  const prefixes = ['130', '131', '132', '133', '134', '135', '136', '137', '138', '139',
                    '150', '151', '152', '153', '155', '156', '157', '158', '159',
                    '180', '181', '182', '183', '184', '185', '186', '187', '188', '189'];
  const prefix = prefixes[randomIntBetween(0, prefixes.length - 1)];
  const suffix = randomIntBetween(10000000, 99999999).toString();
  return prefix + suffix;
}

/**
 * Generate address
 */
export function generateAddress() {
  const cities = ['北京市朝阳区', '上海市浦东新区', '广州市天河区', '深圳市南山区', '杭州市西湖区'];
  const streets = ['建国路', '中山路', '人民大道', '解放路', '和平街'];

  const city = cities[randomIntBetween(0, cities.length - 1)];
  const street = streets[randomIntBetween(0, streets.length - 1)];
  const number = randomIntBetween(1, 999);

  return `${city}${street}${number}号`;
}

/**
 * Get random date in the past N days
 */
export function getDateDaysAgo(daysAgo) {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return date.toISOString().split('T')[0];
}

/**
 * Get random datetime in the past N days
 */
export function getDateTimeDaysAgo(daysAgo) {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return date.toISOString().replace('Z', '');
}

/**
 * Create driver test data
 */
export function createDriverTestData(baseCounter) {
  const name = generateChineseName();
  const idCard = generateIdCard(baseCounter);
  const phone = generatePhoneNumber();
  const address = generateAddress();
  const driverLicense = generateDriverLicense(baseCounter);

  return {
    name: name,
    idCardNumber: idCard,
    gender: randomIntBetween(0, 1) === 1 ? 'Male' : 'Female',
    birthdate: getDateDaysAgo(randomIntBetween(8000, 15000)), // 22-41 years old
    contactNumber: phone,
    email: `${randomString(8)}@test.com`,
    address: address,
    driverLicenseNumber: driverLicense,
    licenseType: ['C1', 'C2', 'B1', 'B2'][randomIntBetween(0, 3)],
    firstLicenseDate: getDateDaysAgo(randomIntBetween(1000, 5000)),
    issueDate: getDateDaysAgo(randomIntBetween(100, 1000)),
    expiryDate: getDateDaysAgo(-randomIntBetween(1000, 2000)), // Future date
    issuingAuthority: '北京市公安局交通管理局',
    currentPoints: randomIntBetween(0, 12),
    status: ['Active', 'Suspended'][randomIntBetween(0, 1)],
  };
}

/**
 * Create vehicle test data
 */
export function createVehicleTestData(baseCounter, ownerName, ownerIdCard) {
  const licensePlate = generateLicensePlate(baseCounter);

  return {
    licensePlate: licensePlate,
    plateColor: ['Blue', 'Yellow', 'Green'][randomIntBetween(0, 2)],
    vehicleType: '小型汽车',
    brand: ['丰田', '本田', '大众', '奥迪', '宝马', '奔驰'][randomIntBetween(0, 5)],
    model: ['凯美瑞', '雅阁', '帕萨特', 'A4', '3系', 'C级'][randomIntBetween(0, 5)],
    vehicleColor: ['白色', '黑色', '银色', '红色', '蓝色'][randomIntBetween(0, 4)],
    engineNumber: `ENG${randomString(12, '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ')}`,
    frameNumber: `VIN${randomString(14, '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ')}`,
    ownerName: ownerName || generateChineseName(),
    ownerIdCard: ownerIdCard || generateIdCard(baseCounter),
    ownerContact: generatePhoneNumber(),
    ownerAddress: generateAddress(),
    firstRegistrationDate: getDateDaysAgo(randomIntBetween(100, 2000)),
    registrationDate: getDateDaysAgo(randomIntBetween(100, 2000)),
    issuingAuthority: '北京市公安局车辆管理所',
    status: 'Active',
    inspectionExpiryDate: getDateDaysAgo(-randomIntBetween(30, 365)),
    insuranceExpiryDate: getDateDaysAgo(-randomIntBetween(30, 365)),
  };
}

/**
 * Create offense test data
 */
export function createOffenseTestData(driverId, vehicleId) {
  const offenseNumber = generateOffenseNumber();
  const offenseCodes = ['1001', '1002', '1003', '1004', '1005', '1006', '1007', '1008'];
  const offenseCode = offenseCodes[randomIntBetween(0, offenseCodes.length - 1)];

  return {
    offenseCode: offenseCode,
    offenseNumber: offenseNumber,
    offenseTime: getDateTimeDaysAgo(randomIntBetween(1, 180)),
    offenseLocation: generateAddress(),
    offenseProvince: ['北京市', '上海市', '广东省'][randomIntBetween(0, 2)],
    offenseCity: ['朝阳区', '浦东新区', '天河区'][randomIntBetween(0, 2)],
    driverId: driverId,
    vehicleId: vehicleId,
    offenseDescription: '超速行驶，超过限速20%',
    evidenceType: 'Photo',
    evidenceUrls: '["https://example.com/evidence1.jpg"]',
    enforcementAgency: '市公安局交通管理局',
    enforcementOfficer: '警官' + randomIntBetween(1000, 9999),
    enforcementDevice: `CAM-${randomString(6, '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ')}`,
    processStatus: ['Unprocessed', 'Processing', 'Processed'][randomIntBetween(0, 2)],
    notificationStatus: 'Not_Sent',
    fineAmount: [100, 200, 500, 1000, 2000][randomIntBetween(0, 4)],
    deductedPoints: [0, 1, 2, 3, 6, 12][randomIntBetween(0, 5)],
    detentionDays: 0,
  };
}

/**
 * Create fine test data
 */
export function createFineTestData(offenseId, driverId) {
  const fineNumber = generateFineNumber();
  const fineAmount = [100, 200, 500, 1000, 2000][randomIntBetween(0, 4)];

  return {
    offenseId: offenseId,
    driverId: driverId,
    fineNumber: fineNumber,
    fineAmount: fineAmount,
    lateFee: 0,
    totalAmount: fineAmount,
    fineDate: getDateDaysAgo(randomIntBetween(1, 90)),
    paymentDeadline: getDateDaysAgo(-randomIntBetween(10, 60)),
    issuingAuthority: '市公安局交通管理局',
    handler: '警官' + randomIntBetween(1000, 9999),
    approver: '队长' + randomIntBetween(100, 999),
    paymentStatus: ['Unpaid', 'Paid'][randomIntBetween(0, 1)],
    paidAmount: 0,
    unpaidAmount: fineAmount,
  };
}

/**
 * Create payment test data
 */
export function createPaymentTestData(fineId, driverId, paymentAmount) {
  const paymentNumber = generatePaymentNumber();

  return {
    fineId: fineId,
    driverId: driverId,
    paymentNumber: paymentNumber,
    paymentAmount: paymentAmount,
    paymentMethod: ['Cash', 'BankCard', 'Alipay', 'WeChat'][randomIntBetween(0, 3)],
    paymentTime: new Date().toISOString().replace('Z', ''),
    paymentChannel: '支付宝移动端',
    payerName: generateChineseName(),
    payerIdCard: generateIdCard(),
    payerContact: generatePhoneNumber(),
    transactionId: getTimestamp() + randomIntBetween(10000, 99999).toString(),
    receiptNumber: `RCP${getTimestamp()}${randomIntBetween(1000, 9999)}`,
    paymentStatus: 'Success',
    refundAmount: 0,
  };
}

/**
 * Create appeal test data
 */
export function createAppealTestData(offenseId, driverId) {
  const appealNumber = generateAppealNumber();
  const name = generateChineseName();
  const idCard = generateIdCard();

  return {
    offenseId: offenseId,
    driverId: driverId,
    appealNumber: appealNumber,
    appellantName: name,
    appellantIdCard: idCard,
    appellantContact: generatePhoneNumber(),
    appellantEmail: `${randomString(8)}@test.com`,
    appellantAddress: generateAddress(),
    appealType: ['Information_Error', 'Equipment_Error', 'Judgment_Error'][randomIntBetween(0, 2)],
    appealReason: '该违法记录存在错误，请求撤销',
    appealTime: new Date().toISOString().replace('Z', ''),
    evidenceDescription: '相关证据说明',
    evidenceUrls: '["https://example.com/evidence.jpg"]',
    acceptanceStatus: 'Pending',
    processStatus: 'Unprocessed',
  };
}
