package com.tutict.finalassignmentcloud.config.redis;

import java.time.Duration;

public final class RedisCommandTimeouts {

    public static final Duration CACHE = Duration.ofMillis(300);
    public static final Duration BLACKLIST = Duration.ofMillis(200);

    private RedisCommandTimeouts() {
    }
}
