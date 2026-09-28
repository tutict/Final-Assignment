package com.tutict.finalassignmentbackend.reliability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.mapper.system.SysRequestHistoryMapper;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;

class LedgerHistoryReserveTest {

    @Test
    void concurrentReserveHasOneWinner() throws Exception {
        RacingMapper racing = new RacingMapper();
        SysRequestHistoryMapper mapper = racing.proxy();
        LedgerHistoryReserve reserve = new LedgerHistoryReserve(mapper, new ReliabilityMetrics(new SimpleMeterRegistry()));
        ExecutorService pool = Executors.newFixedThreadPool(8);
        List<Future<Throwable>> futures = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            futures.add(pool.submit(() -> {
                try {
                    reserve.reserve("same", "PAYMENT_STATUS", "POST", "/api/workflow/payments/1/events/PAY", "sha256:pay");
                    return null;
                } catch (RuntimeException ex) {
                    return ex;
                }
            }));
        }
        pool.shutdown();
        assertTrue(pool.awaitTermination(5, TimeUnit.SECONDS));
        int winners = 0;
        int absorbed = 0;
        for (Future<Throwable> future : futures) {
            Throwable error = future.get();
            if (error == null) {
                winners++;
            } else if (error instanceof IdempotencyReplayException || error instanceof IdempotencyInProgressException) {
                absorbed++;
            } else {
                throw new AssertionError(error);
            }
        }
        assertEquals(1, winners);
        assertEquals(7, absorbed);
        assertEquals(1, racing.inserts.get());
        assertEquals("PROCESSING", racing.saved.getBusinessStatus());
    }

    private static final class RacingMapper implements InvocationHandler {
        private final Object lock = new Object();
        private final AtomicInteger inserts = new AtomicInteger();
        private SysRequestHistory saved;

        private SysRequestHistoryMapper proxy() {
            return (SysRequestHistoryMapper) Proxy.newProxyInstance(
                    SysRequestHistoryMapper.class.getClassLoader(),
                    new Class<?>[] {SysRequestHistoryMapper.class},
                    this);
        }

        @Override
        public Object invoke(Object proxy, Method method, Object[] args) {
            return switch (method.getName()) {
                case "selectByIdempotencyKey" -> {
                    synchronized (lock) {
                        yield copy(saved);
                    }
                }
                case "insert" -> {
                    synchronized (lock) {
                        if (!inserts.compareAndSet(0, 1)) {
                            throw new DataIntegrityViolationException("duplicate");
                        }
                        saved = copy((SysRequestHistory) args[0]);
                        yield 1;
                    }
                }
                case "updateById" -> {
                    synchronized (lock) {
                        saved = copy((SysRequestHistory) args[0]);
                        yield 1;
                    }
                }
                case "toString" -> "racing-mapper";
                case "hashCode" -> System.identityHashCode(proxy);
                case "equals" -> proxy == args[0];
                default -> throw new UnsupportedOperationException(method.getName());
            };
        }
    }

    private static SysRequestHistory copy(SysRequestHistory source) {
        if (source == null) {
            return null;
        }
        SysRequestHistory copy = new SysRequestHistory();
        copy.setId(source.getId());
        copy.setIdempotencyKey(source.getIdempotencyKey());
        copy.setRequestMethod(source.getRequestMethod());
        copy.setRequestUrl(source.getRequestUrl());
        copy.setRequestParams(source.getRequestParams());
        copy.setBusinessType(source.getBusinessType());
        copy.setBusinessId(source.getBusinessId());
        copy.setBusinessStatus(source.getBusinessStatus());
        copy.setUserId(source.getUserId());
        copy.setRequestIp(source.getRequestIp());
        copy.setCreatedAt(source.getCreatedAt());
        copy.setUpdatedAt(source.getUpdatedAt());
        return copy;
    }
}