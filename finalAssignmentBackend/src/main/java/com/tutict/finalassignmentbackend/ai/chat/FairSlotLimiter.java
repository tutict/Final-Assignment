package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.ai.provider.AiToken;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Sinks;

import java.time.Duration;
import java.util.ArrayDeque;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Supplier;

/**
 * FIFO slot limiter. Excess callers wait; chat streams emit queue tokens with position.
 */
public final class FairSlotLimiter {

    public static final String TIMEOUT_MESSAGE = "排队等待超时，请稍后再试";
    public static final String FULL_MESSAGE = "当前排队人数过多，请稍后再试";

    private final int slots;
    private final int maxQueue;
    private final Duration waitTimeout;
    private final Object lock = new Object();
    private int used;
    private final ArrayDeque<Waiter> waiters = new ArrayDeque<>();

    public FairSlotLimiter(int slots, int maxQueue, Duration waitTimeout) {
        this.slots = Math.max(1, slots);
        this.maxQueue = Math.max(1, maxQueue);
        this.waitTimeout = waitTimeout == null || waitTimeout.isZero() || waitTimeout.isNegative()
                ? Duration.ofSeconds(90)
                : waitTimeout;
    }

    public Flux<AiToken> protect(Flux<AiToken> work) {
        return Flux.defer(() -> {
            Waiter waiter = enqueue();
            if (waiter == null) {
                return Flux.error(new AiQueueException(FULL_MESSAGE));
            }
            Mono<Void> grantedMono = waiter.granted.asMono()
                    .then()
                    .timeout(waitTimeout)
                    .doOnError(error -> waiter.cancel())
                    .onErrorMap(error -> error instanceof AiQueueException
                            ? error
                            : new AiQueueException(TIMEOUT_MESSAGE))
                    .cache();
            Flux<AiToken> waiting = waiter.positions
                    .asFlux()
                    .map(FairSlotLimiter::queueToken)
                    .takeUntilOther(grantedMono.onErrorResume(error -> Mono.empty()));
            Flux<AiToken> granted = grantedMono
                    .thenMany(Flux.defer(() -> work))
                    .doFinally(signal -> waiter.release());
            return waiting.concatWith(granted);
        });
    }

    public <T> T call(Supplier<T> work) {
        Waiter waiter = enqueue();
        if (waiter == null) {
            throw new AiQueueException(FULL_MESSAGE);
        }
        try {
            waiter.granted.asMono().then()
                    .timeout(waitTimeout)
                    .block();
        } catch (RuntimeException error) {
            waiter.cancel();
            waiter.release();
            throw error instanceof AiQueueException
                    ? error
                    : new AiQueueException(TIMEOUT_MESSAGE);
        }
        try {
            return work.get();
        } finally {
            waiter.release();
        }
    }

    int queuedCount() {
        synchronized (lock) {
            return waiters.size();
        }
    }

    int usedCount() {
        synchronized (lock) {
            return used;
        }
    }

    private Waiter enqueue() {
        synchronized (lock) {
            if (used < slots) {
                used++;
                Waiter waiter = new Waiter();
                waiter.heldPermit = true;
                waiter.markGranted();
                return waiter;
            }
            if (waiters.size() >= maxQueue) {
                return null;
            }
            Waiter waiter = new Waiter();
            waiters.addLast(waiter);
            reindexLocked();
            return waiter;
        }
    }

    private void reindexLocked() {
        int index = 1;
        for (Waiter waiter : waiters) {
            waiter.updatePosition(index++);
        }
    }

    private static AiToken queueToken(int position) {
        return new AiToken("", false, Map.of("queue", Map.of("position", position)));
    }

    final class Waiter {
        private final Sinks.One<Boolean> granted = Sinks.one();
        private final Sinks.Many<Integer> positions = Sinks.many().replay().latest();
        private final AtomicBoolean released = new AtomicBoolean(false);
        private volatile boolean heldPermit;
        private volatile int position;

        private void markGranted() {
            granted.tryEmitValue(Boolean.TRUE);
        }

        private void updatePosition(int next) {
            this.position = next;
            positions.tryEmitNext(next);
        }

        private void cancel() {
            synchronized (lock) {
                if (waiters.remove(this)) {
                    reindexLocked();
                }
            }
            granted.tryEmitError(new AiQueueException(TIMEOUT_MESSAGE));
        }

        private void release() {
            if (!released.compareAndSet(false, true)) {
                return;
            }
            Waiter next = null;
            synchronized (lock) {
                if (waiters.remove(this)) {
                    reindexLocked();
                    return;
                }
                if (!heldPermit) {
                    return;
                }
                next = waiters.pollFirst();
                if (next == null) {
                    used = Math.max(0, used - 1);
                } else {
                    next.heldPermit = true;
                    reindexLocked();
                }
            }
            if (next != null) {
                next.markGranted();
            }
        }
    }
}
