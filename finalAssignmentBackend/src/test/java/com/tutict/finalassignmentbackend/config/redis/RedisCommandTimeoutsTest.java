package com.tutict.finalassignmentbackend.config.redis;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.Duration;
import org.junit.jupiter.api.Test;

class RedisCommandTimeoutsTest {

    @Test
    void cacheIsSlowerThanBlacklist() {
        assertEquals(Duration.ofMillis(300), RedisCommandTimeouts.CACHE);
        assertEquals(Duration.ofMillis(200), RedisCommandTimeouts.BLACKLIST);
    }
}
