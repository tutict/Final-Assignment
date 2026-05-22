package com.tutict.finalassignmentbackend.dto.response;

import com.tutict.finalassignmentbackend.entity.AppealRecord;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class AppealResponse {

    private Long appealId;
    private Long offenseId;
    private Long driverId;
    private String appealNumber;
    private String appellantName;
    private String idCard;
    private String contact;
    private String appealType;
    private String appealReason;
    private LocalDateTime appealTime;
    private String acceptanceStatus;
    private String processStatus;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static AppealResponse from(AppealRecord record) {
        if (record == null) {
            return null;
        }
        return AppealResponse.builder()
                .appealId(record.getAppealId())
                .offenseId(record.getOffenseId())
                .driverId(record.getDriverId())
                .appealNumber(record.getAppealNumber())
                .appellantName(record.getAppellantName())
                .idCard(record.getAppellantIdCard())
                .contact(record.getAppellantContact())
                .appealType(record.getAppealType())
                .appealReason(record.getAppealReason())
                .appealTime(record.getAppealTime())
                .acceptanceStatus(record.getAcceptanceStatus())
                .processStatus(record.getProcessStatus())
                .createdAt(record.getCreatedAt())
                .updatedAt(record.getUpdatedAt())
                .build();
    }
}
