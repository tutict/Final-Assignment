package com.tutict.finalassignmentcloud.system.appeal.domain;

import com.tutict.finalassignmentcloud.entity.appeal.AppealRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Appeal Record Domain Service
 * Handles domain validation and business rules
 */
@Service
public class AppealRecordDomainService {

    private static final Logger log = LoggerFactory.getLogger(AppealRecordDomainService.class);

    public void validateAppeal(AppealRecord appealRecord) {
        log.debug("Validating appeal record: appealId={}",
                 appealRecord != null ? appealRecord.getAppealId() : null);

        if (appealRecord == null) {
            log.error("Appeal validation failed: appeal record is null");
            throw new IllegalArgumentException("Appeal record cannot be null");
        }
        if (appealRecord.getOffenseId() == null) {
            log.error("Appeal validation failed: appealId={}, missing offenseId",
                     appealRecord.getAppealId());
            throw new IllegalArgumentException("Offense ID is required");
        }

        log.info("Appeal validated successfully: appealId={}, offenseId={}",
                appealRecord.getAppealId(), appealRecord.getOffenseId());
    }

    public void validateAppealId(AppealRecord appealRecord) {
        validateAppeal(appealRecord);
        validateAppealId(appealRecord.getAppealId());
    }

    public void validateAppealId(Long appealId) {
        log.debug("Validating appeal ID: {}", appealId);

        if (appealId == null || appealId <= 0) {
            log.error("Appeal ID validation failed: invalid appealId={}", appealId);
            throw new IllegalArgumentException("Invalid appeal ID: " + appealId);
        }

        log.debug("Appeal ID validated: {}", appealId);
    }
}
