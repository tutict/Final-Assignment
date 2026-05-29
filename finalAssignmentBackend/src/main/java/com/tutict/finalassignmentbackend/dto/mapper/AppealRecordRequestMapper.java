package com.tutict.finalassignmentbackend.dto.mapper;

import com.tutict.finalassignmentbackend.dto.request.AppealCreateRequest;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;

import java.util.Locale;

public final class AppealRecordRequestMapper {

    private AppealRecordRequestMapper() {
    }

    public static AppealRecord toEntity(AppealCreateRequest request) {
        if (request == null) {
            return null;
        }
        AppealRecord record = new AppealRecord();
        record.setOffenseId(request.getOffenseId());
        record.setDriverId(request.getDriverId());
        record.setAppellantName(request.getAppellantName());
        record.setAppellantIdCard(request.getIdCard());
        record.setAppellantContact(request.getContact());
        record.setAppealType(normalizeAppealType(request.getAppealType()));
        record.setAppealReason(request.getAppealReason());
        record.setAppealTime(request.getAppealTime());
        return record;
    }

    private static String normalizeAppealType(String value) {
        if (value == null || value.isBlank()) {
            return "Other";
        }
        String normalized = value.trim();
        return switch (normalized.toLowerCase(Locale.ROOT)) {
            case "information_error", "information", "info", "信息错误", "信息有误", "资料错误", "档案错误" ->
                    "Information_Error";
            case "equipment_error", "equipment", "device", "设备错误", "设备故障", "抓拍设备错误" ->
                    "Equipment_Error";
            case "judgment_error", "judgment", "fact", "事实申诉", "事实错误", "判定错误", "认定错误", "处罚错误" ->
                    "Judgment_Error";
            case "force_majeure", "force", "不可抗力", "特殊情况" -> "Force_Majeure";
            case "other", "其他" -> "Other";
            default -> "Other";
        };
    }
}
