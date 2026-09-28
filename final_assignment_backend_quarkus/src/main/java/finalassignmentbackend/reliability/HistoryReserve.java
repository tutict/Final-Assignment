package finalassignmentbackend.reliability;

import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.LocalDateTime;

public final class HistoryReserve {

    private HistoryReserve() {
    }

    public static void reserve(SysRequestHistoryMapper mapper, String key, String businessType, String fingerprint) {
        if (key == null || key.isBlank()) {
            throw new IllegalArgumentException("Idempotency-Key must not be blank");
        }
        SysRequestHistory history = mapper.selectByIdempotencyKey(key);
        if (history == null) {
            SysRequestHistory created = new SysRequestHistory();
            created.setIdempotencyKey(key);
            created.setBusinessStatus("PROCESSING");
            created.setBusinessType(businessType);
            created.setRequestParams(fingerprint);
            created.setCreatedAt(LocalDateTime.now());
            created.setUpdatedAt(LocalDateTime.now());
            mapper.insert(created);
            return;
        }
        LocalDateTime stamp = history.getUpdatedAt() != null ? history.getUpdatedAt() : history.getCreatedAt();
        Duration age = stamp == null ? Duration.ZERO : Duration.between(stamp, LocalDateTime.now());
        switch (LedgerIdempotencyDecider.decide(true, history.getBusinessStatus(), history.getRequestParams(), fingerprint, age)) {
            case REPLAY -> throw new IdempotencyReplayException();
            case CONFLICT -> throw new IdempotencyConflictException();
            case IN_PROGRESS -> throw new IdempotencyInProgressException();
            case RETRY -> {
                history.setBusinessStatus("PROCESSING");
                history.setBusinessType(businessType);
                history.setRequestParams(fingerprint);
                history.setUpdatedAt(LocalDateTime.now());
                mapper.updateById(history);
            }
            default -> throw new IllegalStateException("Unexpected idempotency outcome");
        }
    }

    public static String sha256(String canonical) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256").digest(canonical.getBytes(StandardCharsets.UTF_8));
            return "sha256:" + java.util.HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
