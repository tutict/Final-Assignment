package com.tutict.finalassignmentbackend.reliability;

import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.mapper.system.SysRequestHistoryMapper;
import java.time.Duration;
import java.time.LocalDateTime;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

@Service
public class LedgerHistoryReserve {

    private final SysRequestHistoryMapper historyMapper;
    private final ReliabilityMetrics metrics;

    public LedgerHistoryReserve(SysRequestHistoryMapper historyMapper, ReliabilityMetrics metrics) {
        this.historyMapper = historyMapper;
        this.metrics = metrics;
    }

    public void reserve(String idempotencyKey, String businessType, String method, String url, String fingerprint) {
        reserve(idempotencyKey, businessType, method, url, fingerprint, null);
    }

    public void reserve(String idempotencyKey, String businessType, String method, String url, String fingerprint, Long businessId) {
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            throw new IllegalArgumentException("Idempotency-Key must not be blank");
        }
        String storedFingerprint = fingerprint == null || fingerprint.isBlank()
                ? LedgerBodyFingerprint.sha256("")
                : fingerprint;
        SysRequestHistory existing = historyMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            apply(existing, storedFingerprint, businessType, method, url, businessId);
            return;
        }
        SysRequestHistory history = newHistory(idempotencyKey, businessType, method, url, storedFingerprint, businessId);
        try {
            historyMapper.insert(history);
        } catch (DataIntegrityViolationException ex) {
            SysRequestHistory winner = historyMapper.selectByIdempotencyKey(idempotencyKey);
            if (winner == null) {
                throw new IdempotencyReplayException("Duplicate ledger request detected");
            }
            apply(winner, storedFingerprint, businessType, method, url, businessId);
        }
    }

    public void markSuccess(String idempotencyKey, Long businessId) {
        SysRequestHistory history = historyMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            return;
        }
        history.setBusinessStatus("SUCCESS");
        if (businessId != null) {
            history.setBusinessId(businessId);
        }
        if (history.getRequestParams() == null || !history.getRequestParams().startsWith("sha256:")) {
            history.setRequestParams("DONE");
        }
        history.setUpdatedAt(java.time.LocalDateTime.now());
        historyMapper.updateById(history);
    }

    public void markFailed(String idempotencyKey, String reason) {
        SysRequestHistory history = historyMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null || "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())) {
            return;
        }
        history.setBusinessStatus("FAILED");
        String value = reason == null || reason.isBlank() ? "FAILED" : reason;
        history.setRequestParams(value.length() <= 500 ? value : value.substring(0, 500));
        history.setUpdatedAt(java.time.LocalDateTime.now());
        historyMapper.updateById(history);
    }

    private void apply(SysRequestHistory existing, String fingerprint, String businessType, String method, String url, Long businessId) {
        LocalDateTime stamp = existing.getUpdatedAt() != null ? existing.getUpdatedAt() : existing.getCreatedAt();
        Duration age = stamp == null ? Duration.ZERO : Duration.between(stamp, LocalDateTime.now());
        LedgerIdempotencyDecider.Outcome outcome = LedgerIdempotencyDecider.decide(
                true, existing.getBusinessStatus(), existing.getRequestParams(), fingerprint, age);
        switch (outcome) {
            case REPLAY -> throw new IdempotencyReplayException("Duplicate ledger request detected");
            case CONFLICT -> {
                metrics.idempotencyConflict();
                throw new IdempotencyConflictException("Idempotency-Key was reused with a different payload");
            }
            case IN_PROGRESS -> throw new IdempotencyInProgressException("Idempotency-Key is already in progress");
            case INSERT, RETRY -> {
                existing.setBusinessType(businessType);
                existing.setRequestMethod(method);
                existing.setRequestUrl(url);
                existing.setRequestParams(fingerprint);
                if (businessId != null) {
                    existing.setBusinessId(businessId);
                }
                existing.setBusinessStatus("PROCESSING");
                existing.setUpdatedAt(LocalDateTime.now());
                historyMapper.updateById(existing);
            }
        }
    }

    private static SysRequestHistory newHistory(String key, String businessType, String method, String url, String fingerprint, Long businessId) {
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(key);
        history.setBusinessType(businessType);
        history.setBusinessId(businessId);
        history.setRequestMethod(method);
        history.setRequestUrl(url);
        history.setRequestParams(fingerprint);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        return history;
    }
}
