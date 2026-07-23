package com.tutict.finalassignmentbackend.appeal.domain.idempotency;

import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealBusinessPolicy;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.mapper.system.SysRequestHistoryMapper;
import org.springframework.stereotype.Service;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class AppealIdempotencyService {

    private static final Logger log = Logger.getLogger(AppealIdempotencyService.class.getName());

    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final AppealBusinessPolicy businessPolicy;

    public AppealIdempotencyService(
            SysRequestHistoryMapper sysRequestHistoryMapper,
            AppealBusinessPolicy businessPolicy
    ) {
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.businessPolicy = businessPolicy;
    }

    public void checkAndInsert(String idempotencyKey) {
        reserve(idempotencyKey);
    }

    /**
     * Reserves a key using the database unique constraint as the concurrency
     * boundary. The caller must invoke this in the same transaction as the
     * appeal insert so a failed create releases the reservation on rollback.
     */
    public void reserve(String idempotencyKey) {
        if (!StringUtils.hasText(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency-Key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (businessPolicy.isDuplicateRequest(history)) {
            throw duplicate();
        }
        try {
            sysRequestHistoryMapper.insert(buildHistory(idempotencyKey));
        } catch (DataIntegrityViolationException ex) {
            throw duplicate(ex);
        }
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return businessPolicy.shouldSkipProcessedRequest(history);
    }

    public void markPendingSuccess(String idempotencyKey, Long appealId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (!businessPolicy.canUpdateHistory(history)) {
            log.log(Level.WARNING, "Cannot mark pending success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(appealId);
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    public void markHistorySuccess(String idempotencyKey, Long appealId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (!businessPolicy.canUpdateHistory(history)) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(appealId);
        history.setRequestParams("DONE");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (!businessPolicy.canUpdateHistory(history)) {
            log.log(Level.WARNING, "Cannot mark failure for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("FAILED");
        history.setRequestParams(businessPolicy.truncateFailureReason(reason));
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    private SysRequestHistory buildHistory(String key) {
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(key);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        return history;
    }

    private AppealDuplicateRequestException duplicate() {
        return new AppealDuplicateRequestException("Duplicate appeal request detected");
    }

    private AppealDuplicateRequestException duplicate(Throwable cause) {
        return new AppealDuplicateRequestException("Duplicate appeal request detected", cause);
    }

}
