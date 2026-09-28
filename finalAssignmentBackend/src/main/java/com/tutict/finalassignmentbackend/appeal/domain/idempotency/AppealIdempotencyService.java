package com.tutict.finalassignmentbackend.appeal.domain.idempotency;

import com.tutict.finalassignmentbackend.appeal.domain.policy.AppealBusinessPolicy;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.mapper.system.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.reliability.IdempotencyConflictException;
import com.tutict.finalassignmentbackend.reliability.IdempotencyInProgressException;
import com.tutict.finalassignmentbackend.reliability.IdempotencyReplayException;
import com.tutict.finalassignmentbackend.reliability.LedgerBodyFingerprint;
import com.tutict.finalassignmentbackend.reliability.LedgerIdempotencyDecider;
import org.springframework.dao.DataIntegrityViolationException;
import java.time.Duration;
import org.springframework.stereotype.Service;

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
        checkAndInsert(idempotencyKey, LedgerBodyFingerprint.sha256(""));
    }

    public void checkAndInsert(String idempotencyKey, String fingerprint) {
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            throw new IllegalArgumentException("Idempotency-Key must not be blank");
        }
        String storedFingerprint = fingerprint == null || fingerprint.isBlank()
                ? LedgerBodyFingerprint.sha256("")
                : fingerprint;
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            apply(history, storedFingerprint);
            return;
        }
        SysRequestHistory created = buildHistory(idempotencyKey);
        created.setRequestParams(storedFingerprint);
        created.setBusinessType("APPEAL");
        created.setRequestMethod("POST");
        created.setRequestUrl("/api/appeals");
        try {
            sysRequestHistoryMapper.insert(created);
        } catch (DataIntegrityViolationException ex) {
            SysRequestHistory winner = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
            if (winner == null) {
                throw new IdempotencyReplayException("Duplicate appeal request detected");
            }
            apply(winner, storedFingerprint);
        }
    }

    private void apply(SysRequestHistory history, String fingerprint) {
        java.time.LocalDateTime stamp = history.getUpdatedAt() != null ? history.getUpdatedAt() : history.getCreatedAt();
        Duration age = stamp == null ? Duration.ZERO : Duration.between(stamp, java.time.LocalDateTime.now());
        LedgerIdempotencyDecider.Outcome outcome = LedgerIdempotencyDecider.decide(
                true, history.getBusinessStatus(), history.getRequestParams(), fingerprint, age);
        switch (outcome) {
            case REPLAY -> throw new IdempotencyReplayException("Duplicate appeal request detected");
            case CONFLICT -> throw new IdempotencyConflictException("Idempotency-Key was reused with a different payload");
            case IN_PROGRESS -> throw new IdempotencyInProgressException("Idempotency-Key is already in progress");
            case INSERT, RETRY -> {
                history.setRequestParams(fingerprint);
                history.setBusinessStatus("PROCESSING");
                history.setUpdatedAt(java.time.LocalDateTime.now());
                sysRequestHistoryMapper.updateById(history);
            }
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
        if (history.getRequestParams() == null || !history.getRequestParams().startsWith("sha256:")) {
            history.setRequestParams("DONE");
        }
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (!businessPolicy.canUpdateHistory(history)) {
            log.log(Level.WARNING, "Cannot mark failure for missing idempotency key {0}", idempotencyKey);
            return;
        }
        if ("SUCCESS".equalsIgnoreCase(history.getBusinessStatus())) {
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
