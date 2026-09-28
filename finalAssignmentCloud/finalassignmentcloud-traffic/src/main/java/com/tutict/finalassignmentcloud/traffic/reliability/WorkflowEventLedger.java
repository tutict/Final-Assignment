package com.tutict.finalassignmentcloud.traffic.reliability;

import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.traffic.mapper.SysRequestHistoryMapper;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class WorkflowEventLedger {

    private static final Logger LOG = Logger.getLogger(WorkflowEventLedger.class.getName());

    interface Store {
        SysRequestHistory find(String key);
        void insert(SysRequestHistory row);
        void update(SysRequestHistory row);
    }

    private final Store store;

    @Autowired
    public WorkflowEventLedger(SysRequestHistoryMapper mapper) {
        this(new Store() {
            @Override
            public SysRequestHistory find(String key) {
                return mapper.selectByIdempotencyKey(key);
            }

            @Override
            public void insert(SysRequestHistory row) {
                mapper.insert(row);
            }

            @Override
            public void update(SysRequestHistory row) {
                mapper.updateById(row);
            }
        });
    }

    WorkflowEventLedger(Store store) {
        this.store = store;
    }

    public static String fingerprint(long businessId, String event) {
        String canonical = businessId + "|" + normalize(event);
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256").digest(canonical.getBytes(StandardCharsets.UTF_8));
            return "sha256:" + HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException(ex);
        }
    }

    public void reserve(String idempotencyKey, String businessType, String url, long businessId, String event) {
        String key = idempotencyKey == null ? "" : idempotencyKey.trim();
        if (key.isEmpty()) {
            throw new IllegalArgumentException("Idempotency-Key must not be blank");
        }
        String fingerprint = fingerprint(businessId, event);
        SysRequestHistory existing = store.find(key);
        if (existing == null) {
            SysRequestHistory created = processing(key, businessType, url, fingerprint, businessId);
            try {
                store.insert(created);
                return;
            } catch (RuntimeException ex) {
                existing = store.find(key);
                if (existing == null) {
                    throw ex;
                }
            }
        }
        applyExisting(existing, businessType, url, fingerprint, businessId);
    }

    public void markSuccess(String idempotencyKey, long businessId) {
        SysRequestHistory history = store.find(trim(idempotencyKey));
        if (history == null) {
            LOG.log(Level.WARNING, "Cannot mark workflow success for missing key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(businessId);
        if (history.getRequestParams() == null || !history.getRequestParams().startsWith("sha256:")) {
            history.setRequestParams("DONE");
        }
        history.setUpdatedAt(LocalDateTime.now());
        store.update(history);
    }

    public void markFailed(String idempotencyKey, String reason) {
        SysRequestHistory history = store.find(trim(idempotencyKey));
        if (history == null) {
            LOG.log(Level.WARNING, "Cannot mark workflow failure for missing key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("FAILED");
        history.setRequestParams(truncate(reason));
        history.setUpdatedAt(LocalDateTime.now());
        store.update(history);
    }

    private void applyExisting(SysRequestHistory existing, String businessType, String url, String fingerprint, long businessId) {
        LocalDateTime stamp = existing.getUpdatedAt() != null ? existing.getUpdatedAt() : existing.getCreatedAt();
        Duration age = stamp == null ? Duration.ZERO : Duration.between(stamp, LocalDateTime.now());
        LedgerIdempotencyDecider.Outcome outcome = LedgerIdempotencyDecider.decide(
                true, existing.getBusinessStatus(), existing.getRequestParams(), fingerprint, age);
        switch (outcome) {
            case REPLAY -> throw new IdempotencyReplayException();
            case CONFLICT -> throw new IdempotencyConflictException();
            case IN_PROGRESS -> throw new IdempotencyInProgressException();
            case RETRY -> {
                existing.setRequestMethod("POST");
                existing.setRequestUrl(url);
                existing.setRequestParams(fingerprint);
                existing.setBusinessType(businessType);
                existing.setBusinessId(businessId);
                existing.setBusinessStatus("PROCESSING");
                existing.setUpdatedAt(LocalDateTime.now());
                store.update(existing);
            }
            default -> throw new IllegalStateException("Unexpected idempotency outcome");
        }
    }

    private static SysRequestHistory processing(String key, String businessType, String url, String fingerprint, long businessId) {
        SysRequestHistory created = new SysRequestHistory();
        created.setIdempotencyKey(key);
        created.setRequestMethod("POST");
        created.setRequestUrl(url);
        created.setRequestParams(fingerprint);
        created.setBusinessType(businessType);
        created.setBusinessId(businessId);
        created.setBusinessStatus("PROCESSING");
        LocalDateTime now = LocalDateTime.now();
        created.setCreatedAt(now);
        created.setUpdatedAt(now);
        return created;
    }

    private static String normalize(String event) {
        return event == null ? "" : event.trim().toUpperCase();
    }

    private static String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private static String truncate(String value) {
        if (value == null || value.isBlank()) {
            return "FAILED";
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }
}
