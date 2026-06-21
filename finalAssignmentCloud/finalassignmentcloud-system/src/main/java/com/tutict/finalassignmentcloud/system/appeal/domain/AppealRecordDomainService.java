package com.tutict.finalassignmentcloud.system.appeal.domain;

import com.tutict.finalassignmentcloud.entity.appeal.AppealRecord;
import org.springframework.stereotype.Service;

@Service
public class AppealRecordDomainService {

    public void validateAppeal(AppealRecord appealRecord) {
        if (appealRecord == null) {
            throw new IllegalArgumentException("Appeal record cannot be null");
        }
        if (appealRecord.getOffenseId() == null) {
            throw new IllegalArgumentException("Offense ID is required");
        }
    }

    public void validateAppealId(AppealRecord appealRecord) {
        validateAppeal(appealRecord);
        validateAppealId(appealRecord.getAppealId());
    }

    public void validateAppealId(Long appealId) {
        if (appealId == null || appealId <= 0) {
            throw new IllegalArgumentException("Invalid appeal ID: " + appealId);
        }
    }
}
