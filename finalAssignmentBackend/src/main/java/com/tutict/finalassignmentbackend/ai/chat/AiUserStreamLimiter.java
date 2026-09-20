package com.tutict.finalassignmentbackend.ai.chat;

import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Sinks;

import java.util.ArrayDeque;
import java.util.concurrent.ConcurrentHashMap;

/**
 * One in-flight AI stream per user. A second request waits; anything more is rejected with 429.
 */
@Component
public class AiUserStreamLimiter {

    public static final String REJECT_MESSAGE = "请等待当前回答结束";

    public enum Decision {
        ACCEPT,
        QUEUE,
        REJECT
    }

    private final ConcurrentHashMap<String, UserState> users = new ConcurrentHashMap<>();

    public Lease tryAdmit(String userId) {
        String key = userId == null || userId.isBlank() ? "anonymous" : userId;
        UserState state = users.computeIfAbsent(key, ignored -> new UserState());
        synchronized (state) {
            if (state.running == 0) {
                state.running = 1;
                return new Lease(key, Decision.ACCEPT, null);
            }
            if (state.waiting == 0) {
                state.waiting = 1;
                Waiter waiter = new Waiter();
                state.waiters.addLast(waiter);
                return new Lease(key, Decision.QUEUE, waiter);
            }
            return null;
        }
    }

    public final class Lease {
        private final String userId;
        private final Decision decision;
        private final Waiter waiter;
        private volatile boolean released;

        private Lease(String userId, Decision decision, Waiter waiter) {
            this.userId = userId;
            this.decision = decision;
            this.waiter = waiter;
        }

        public Decision decision() {
            return decision;
        }

        public Mono<Void> awaitTurn() {
            if (decision != Decision.QUEUE || waiter == null) {
                return Mono.empty();
            }
            return waiter.granted.asMono().then();
        }

        public void release() {
            if (released) {
                return;
            }
            released = true;
            UserState state = users.computeIfAbsent(userId, ignored -> new UserState());
            Waiter next = null;
            synchronized (state) {
                if (decision == Decision.QUEUE && waiter != null && state.waiters.remove(waiter)) {
                    state.waiting = Math.max(0, state.waiting - 1);
                    waiter.granted.tryEmitError(new AiQueueException("当前回答已取消"));
                    return;
                }
                next = state.waiters.pollFirst();
                if (next != null) {
                    state.waiting = Math.max(0, state.waiting - 1);
                } else {
                    state.running = 0;
                }
            }
            if (next != null) {
                next.granted.tryEmitValue(Boolean.TRUE);
            }
        }
    }

    private static final class UserState {
        private int running;
        private int waiting;
        private final ArrayDeque<Waiter> waiters = new ArrayDeque<>();
    }

    private static final class Waiter {
        private final Sinks.One<Boolean> granted = Sinks.one();
    }
}
