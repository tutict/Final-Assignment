package com.tutict.finalassignmentbackend.appeal.domain.idempotency;

import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealBusinessPolicy;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.mapper.system.SysRequestHistoryMapper;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.Objects;

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
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (businessPolicy.isDuplicateRequest(history)) {
            throw new RuntimeException("Duplicate appeal request detected");
        }
        sysRequestHistoryMapper.insert(buildHistory(idempotencyKey));
    }

    public ClaimResult claimAppealCreation(String idempotencyKey, Long userId) {
        Objects.requireNonNull(idempotencyKey, "Idempotency key cannot be null");
        Objects.requireNonNull(userId, "Authenticated user ID cannot be null");
        SysRequestHistory history = buildHistory(idempotencyKey);
        history.setRequestMethod("POST");
        history.setRequestUrl("/api/appeals");
        history.setBusinessType("AppealRecord");
        history.setUserId(userId);
        if (sysRequestHistoryMapper.insertAppealCreationHistoryIfAbsent(history) == 1) {
            return ClaimResult.STARTED;
        }
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing == null || !Objects.equals(existing.getUserId(), userId)) {
            return ClaimResult.COLLISION;
        }
        if ("FAILED".equals(existing.getBusinessStatus())
                && sysRequestHistoryMapper.reopenFailedAppealCreation(idempotencyKey, userId) == 1) {
            return ClaimResult.STARTED;
        }
        return ClaimResult.DUPLICATE;
    }

    public void markAppealCreationSuccess(String idempotencyKey, Long appealId, Long userId) {
        if (sysRequestHistoryMapper.markAppealCreationSuccess(idempotencyKey, appealId, userId) != 1) {
            throw new IllegalStateException("Appeal idempotency claim was lost before success");
        }
    }

    public enum ClaimResult {
        STARTED,
        DUPLICATE,
        COLLISION
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

}
