package com.tutict.finalassignmentbackend.observability;

import org.slf4j.MDC;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

public final class TraceContext {

    public static final String TRACE_ID_HEADER = "X-Trace-Id";
    public static final String TRACE_ID_MDC_KEY = "traceId";

    private TraceContext() {
    }

    public static String currentTraceId() {
        return MDC.get(TRACE_ID_MDC_KEY);
    }

    public static String getOrCreateTraceId() {
        String traceId = currentTraceId();
        return hasText(traceId) ? traceId : newTraceId();
    }

    public static void put(String traceId) {
        MDC.put(TRACE_ID_MDC_KEY, hasText(traceId) ? traceId : newTraceId());
    }

    public static void clear() {
        MDC.remove(TRACE_ID_MDC_KEY);
    }

    public static String newTraceId() {
        return UUID.randomUUID().toString().replace("-", "").substring(0, 16);
    }

    public static byte[] encode(String traceId) {
        return traceId.getBytes(StandardCharsets.UTF_8);
    }

    public static String decode(byte[] value) {
        return value == null ? null : new String(value, StandardCharsets.UTF_8);
    }

    public static boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
