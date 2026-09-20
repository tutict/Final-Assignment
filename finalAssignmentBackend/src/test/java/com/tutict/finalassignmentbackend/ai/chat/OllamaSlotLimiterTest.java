package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.ai.provider.AiToken;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Sinks;

import java.time.Duration;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class OllamaSlotLimiterTest {

    @Test
    void thirdCallerReceivesQueuePositionThenTokens() throws Exception {
        OllamaSlotLimiter limiter = new OllamaSlotLimiter(2, 8, Duration.ofSeconds(5));
        Sinks.Empty<Void> firstRelease = Sinks.empty();
        Sinks.Empty<Void> secondRelease = Sinks.empty();

        Flux<AiToken> first = limiter.protect(firstRelease.asMono().thenMany(Flux.just(new AiToken("a", true, null))));
        Flux<AiToken> second = limiter.protect(secondRelease.asMono().thenMany(Flux.just(new AiToken("b", true, null))));

        CountDownLatch firstStarted = new CountDownLatch(1);
        CountDownLatch secondStarted = new CountDownLatch(1);
        first.subscribe(token -> firstStarted.countDown());
        second.subscribe(token -> secondStarted.countDown());
        assertThat(firstStarted.await(1, TimeUnit.SECONDS)).isFalse();
        assertThat(limiter.usedCount()).isEqualTo(2);

        List<AiToken> thirdTokens = new CopyOnWriteArrayList<>();
        CountDownLatch thirdDone = new CountDownLatch(1);
        limiter.protect(Flux.just(new AiToken("c", true, null)))
                .doOnComplete(thirdDone::countDown)
                .subscribe(thirdTokens::add);

        Thread.sleep(150);
        assertThat(thirdTokens).anyMatch(token -> token.metadata().containsKey("queue"));
        assertThat(thirdTokens.stream().noneMatch(token -> "c".equals(token.text()))).isTrue();

        firstRelease.tryEmitEmpty();
        secondRelease.tryEmitEmpty();
        assertThat(thirdDone.await(2, TimeUnit.SECONDS)).isTrue();
        assertThat(thirdTokens).anyMatch(token -> "c".equals(token.text()));
        assertThat(limiter.usedCount()).isEqualTo(0);
    }

    @Test
    void waitTimeoutEmitsQueueExceptionWithoutWork() {
        OllamaSlotLimiter limiter = new OllamaSlotLimiter(1, 4, Duration.ofMillis(200));
        Sinks.Empty<Void> hold = Sinks.empty();
        AtomicInteger work = new AtomicInteger();
        limiter.protect(hold.asMono().thenMany(Flux.just(new AiToken("held", true, null)))).subscribe();

        assertThatThrownBy(() -> limiter.protect(Flux.from(Mono.fromCallable(() -> {
            work.incrementAndGet();
            return new AiToken("late", true, null);
        }))).blockLast(Duration.ofSeconds(2)))
                .isInstanceOf(AiQueueException.class)
                .hasMessageContaining("超时");
        assertThat(work.get()).isZero();
        hold.tryEmitEmpty();
    }

    @Test
    void blockingCallSharesTheSameSlots() {
        OllamaSlotLimiter limiter = new OllamaSlotLimiter(1, 1, Duration.ofMillis(150));
        Sinks.Empty<Void> hold = Sinks.empty();
        limiter.protect(hold.asMono().thenMany(Flux.just(new AiToken("held", true, null)))).subscribe();

        assertThatThrownBy(() -> limiter.call(() -> "nope"))
                .isInstanceOf(AiQueueException.class);
        hold.tryEmitEmpty();
    }
}
