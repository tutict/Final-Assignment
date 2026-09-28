package com.tutict.finalassignmentcloud.reliability;

import java.time.Duration;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.core.SearchHitsImpl;
import org.springframework.data.elasticsearch.core.TotalHitsRelation;

@Aspect
public class ElasticsearchUnavailableGuard {

    static final long CIRCUIT_OPEN_MILLIS = 15_000L;
    private volatile long openUntilMillis;

    @Around("execution(* org.springframework.data.elasticsearch.repository.ElasticsearchRepository+.*(..))")
    public Object guard(ProceedingJoinPoint joinPoint) throws Throwable {
        if (System.currentTimeMillis() < openUntilMillis) {
            return fallback(joinPoint);
        }
        try {
            return joinPoint.proceed();
        } catch (RuntimeException ex) {
            if (!unavailable(ex)) {
                throw ex;
            }
            openUntilMillis = System.currentTimeMillis() + CIRCUIT_OPEN_MILLIS;
            return fallback(joinPoint);
        }
    }

    private static Object fallback(ProceedingJoinPoint joinPoint) {
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        String name = signature.getName();
        Object[] args = joinPoint.getArgs();
        if ((name.startsWith("save") || name.startsWith("index")) && args.length > 0) {
            return args[0];
        }
        Class<?> type = signature.getReturnType();
        if (type == void.class || type == Void.class) {
            return null;
        }
        if (Optional.class.isAssignableFrom(type)) {
            return Optional.empty();
        }
        if (SearchHits.class.isAssignableFrom(type)) {
            return new SearchHitsImpl<>(
                    0L,
                    TotalHitsRelation.OFF,
                    Float.NaN,
                    Duration.ZERO,
                    null,
                    null,
                    List.of(),
                    null,
                    null,
                    null);
        }
        if (Page.class.isAssignableFrom(type)) {
            return new PageImpl<>(List.of());
        }
        if (Collection.class.isAssignableFrom(type) || Iterable.class.isAssignableFrom(type)) {
            return List.of();
        }
        if (type == boolean.class || type == Boolean.class) {
            return false;
        }
        if (type == int.class || type == Integer.class) {
            return 0;
        }
        if (type == long.class || type == Long.class) {
            return 0L;
        }
        return null;
    }

    static boolean unavailable(Throwable error) {
        Throwable current = error;
        while (current != null) {
            if (current instanceof java.net.SocketTimeoutException || current instanceof java.net.ConnectException) {
                return true;
            }
            String type = current.getClass().getName();
            String message = current.getMessage() == null ? "" : current.getMessage();
            if (type.contains("UncategorizedElasticsearchException")
                    || type.contains("DataAccessResourceFailureException")
                    || type.contains("ResourceAccessException")
                    || type.startsWith("co.elastic.clients.")
                    || type.startsWith("org.elasticsearch.")
                    || type.startsWith("org.springframework.data.elasticsearch.")
                    || type.contains("ConnectException")
                    || message.contains("Connection refused")
                    || message.contains("Read timed out")
                    || message.contains(":9200")) {
                return true;
            }
            current = current.getCause();
        }
        return false;
    }
}
