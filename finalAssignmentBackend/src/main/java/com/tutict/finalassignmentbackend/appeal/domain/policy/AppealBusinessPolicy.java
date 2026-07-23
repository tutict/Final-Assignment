package com.tutict.finalassignmentbackend.appeal.domain.policy;

import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Objects;

@Service
public class AppealBusinessPolicy {

    private static final int FAILURE_REASON_LIMIT = 500;

    public boolean isDuplicateRequest(SysRequestHistory history) {
        return history != null;
    }

    public boolean shouldSkipProcessedRequest(SysRequestHistory history) {
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && isDoneMarker(history.getRequestParams());
    }

    public boolean belongsToRequest(SysRequestHistory history, Long userId, String fingerprint) {
        return history != null
                && Objects.equals(history.getUserId(), userId)
                && Objects.equals(extractFingerprint(history.getRequestParams()), fingerprint);
    }

    public String requestFingerprint(AppealRecord appeal) {
        StringBuilder canonical = new StringBuilder();
        append(canonical, appeal == null ? null : appeal.getOffenseId());
        append(canonical, appeal == null ? null : appeal.getDriverId());
        append(canonical, appeal == null ? null : appeal.getAppellantName());
        append(canonical, appeal == null ? null : appeal.getAppellantIdCard());
        append(canonical, appeal == null ? null : appeal.getAppellantContact());
        append(canonical, appeal == null ? null : appeal.getAppealType());
        append(canonical, appeal == null ? null : appeal.getAppealReason());
        append(canonical, appeal == null ? null : appeal.getAppealTime());
        try {
            return java.util.HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256")
                            .digest(canonical.toString().getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 is unavailable", ex);
        }
    }

    public String successMarker(String fingerprint) {
        return "DONE:" + fingerprint;
    }

    public String extractFingerprint(String requestParams) {
        if (requestParams == null || requestParams.isBlank()) {
            return null;
        }
        if (requestParams.startsWith("DONE:")) {
            return requestParams.substring("DONE:".length());
        }
        return requestParams;
    }

    public boolean isDoneMarker(String requestParams) {
        return "DONE".equalsIgnoreCase(requestParams)
                || requestParams != null && requestParams.startsWith("DONE:");
    }

    private void append(StringBuilder canonical, Object value) {
        String text = value == null ? "" : String.valueOf(value);
        canonical.append(text.length()).append(':').append(text);
    }

    public boolean canUpdateHistory(SysRequestHistory history) {
        return history != null;
    }

    public String truncateFailureReason(String reason) {
        if (reason == null) {
            return null;
        }
        return reason.length() <= FAILURE_REASON_LIMIT ? reason : reason.substring(0, FAILURE_REASON_LIMIT);
    }
}
