package com.tutict.finalassignmentbackend.integration;

import java.util.Map;

public class TestDataFactory {

    // -- Driver ---------------------------------------------------------------
    public static Map<String, Object> validDriver() {
        return Map.of(
            "name", "张测试",
            "licenseNumber", "TEST" + System.currentTimeMillis(),
            "phoneNumber", "13800138000",
            "birthdate", "1990-01-01",
            "firstLicenseDate", "2010-06-01",
            "issueDate", "2020-06-01",
            "expiryDate", "2030-06-01"
        );
    }

    // -- Vehicle --------------------------------------------------------------
    public static Map<String, Object> validVehicle(Long driverId) {
        return Map.of(
            "licensePlate", "京A" + System.currentTimeMillis() % 100000,
            "vehicleType", "小型汽车",
            "ownerName", "张测试",
            "driverId", driverId,
            "firstRegistrationDate", "2020-01-01",
            "registrationDate", "2020-01-01",
            "inspectionExpiryDate", "2025-01-01",
            "insuranceExpiryDate", "2025-01-01"
        );
    }

    // -- Offense --------------------------------------------------------------
    public static Map<String, Object> validOffense(Long driverId, Long vehicleId) {
        return Map.of(
            "driverId", driverId,
            "vehicleId", vehicleId,
            "offenseCode", "OSS-001",
            "offenseLocation", "北京市朝阳区建国路100号",
            "offenseTime", "2024-06-01T10:00:00",
            "offenseType", "超速行驶",
            "processStatus", "Pending",
            "notificationStatus", "Not_Sent"
        );
    }

    // -- Fine -----------------------------------------------------------------
    public static Map<String, Object> validFine(Long offenseId) {
        return Map.of(
            "offenseId", offenseId,
            "fineAmount", 200.00,
            "paymentDeadline", "2024-07-01",
            "status", "Unpaid"
        );
    }

    // -- Appeal ---------------------------------------------------------------
    public static Map<String, Object> validAppeal(Long offenseId) {
        return Map.of(
            "offenseId", offenseId,
            "appellantName", "张测试",
            "idCard", "110101199001011234",
            "contact", "13800138000",
            "appealType", "事实申诉",
            "appealReason", "该违法记录存在错误，实际车辆未在该路段行驶",
            "appealTime", "2024-06-05T09:00:00"
        );
    }

    // -- Payment --------------------------------------------------------------
    public static Map<String, Object> validPayment(Long fineId) {
        return Map.of(
            "fineId", fineId,
            "paymentAmount", 200.00,
            "paymentMethod", "微信支付",
            "payerName", "张测试",
            "paymentTime", "2024-06-10T14:00:00"
        );
    }
}
