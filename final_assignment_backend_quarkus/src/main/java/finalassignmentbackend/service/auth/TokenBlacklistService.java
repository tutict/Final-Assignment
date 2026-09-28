package finalassignmentbackend.service.auth;
import io.quarkus.redis.client.RedisClientName;
import io.quarkus.redis.datasource.RedisDataSource;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import finalassignmentbackend.reliability.BlacklistAccessPolicy;
import java.util.HexFormat;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * access token 黑名单（登出即撤销）。以 token 的 SHA-256 为 key 存入 Redis，TTL 等于该 token 的剩余寿命，
 * 到期自动清理。对齐 Spring service/auth/TokenBlacklistService（Spring 用 RedisTemplate，这里用 Quarkus Redis）。
 */
@ApplicationScoped
public class TokenBlacklistService {

    private static final Logger LOG = Logger.getLogger(TokenBlacklistService.class.getName());
    private static final String BLACKLIST_PREFIX = "blacklist:";
    private static final String REVOKED_MARKER = "revoked";

    @Inject
    @RedisClientName("blacklist")
    RedisDataSource redisDataSource;

    @ConfigProperty(name = "app.security.token-blacklist.fail-open", defaultValue = "false")
    boolean failOpenWhenUnavailable;
    private final ConcurrentHashMap<String, Long> localRevocations = new ConcurrentHashMap<>();

    private io.quarkus.redis.datasource.value.ValueCommands<String, String> valueCommands;
    private io.quarkus.redis.datasource.keys.KeyCommands<String> keyCommands;

    @PostConstruct
    void init() {
        this.valueCommands = redisDataSource.value(String.class);
        this.keyCommands = redisDataSource.key();
    }

    public void blacklist(String token, long ttlMillis) {
        if (isBlank(token) || ttlMillis <= 0) {
            return;
        }
        long ttlSeconds = Math.max(1, ttlMillis / 1000);
        localRevocations.put(sha256(token), System.currentTimeMillis() + ttlMillis);
        try {
            valueCommands.setex(key(token), ttlSeconds, REVOKED_MARKER);
        } catch (RuntimeException ex) {
            if (failOpenWhenUnavailable) {
                LOG.log(Level.WARNING, "Failed to blacklist access token because Redis is unavailable", ex);
                return;
            }
            throw ex;
        }
    }

    public boolean isBlacklisted(String token) {
        return inspect(token) == BlacklistAccessPolicy.Verdict.REVOKED;
    }

    public BlacklistAccessPolicy.Verdict inspect(String token) {
        if (isBlank(token)) {
            return BlacklistAccessPolicy.Verdict.CLEAR;
        }
        Long until = localRevocations.get(sha256(token));
        if (until != null && until >= System.currentTimeMillis()) {
            return BlacklistAccessPolicy.Verdict.REVOKED;
        }
        try {
            if (keyCommands.exists(key(token))) {
                localRevocations.put(sha256(token), System.currentTimeMillis() + 30 * 60 * 1000L);
                return BlacklistAccessPolicy.Verdict.REVOKED;
            }
            return BlacklistAccessPolicy.Verdict.CLEAR;
        } catch (RuntimeException ex) {
            LOG.log(Level.SEVERE, "Failed to check access token blacklist", ex);
            return BlacklistAccessPolicy.Verdict.UNAVAILABLE;
        }
    }

    public boolean redisReachable() {
        try {
            keyCommands.exists("reliability:redis-ping");
            return true;
        } catch (RuntimeException ex) {
            return false;
        }
    }

    private String key(String token) {
        return BLACKLIST_PREFIX + sha256(token);
    }

    private String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 algorithm is unavailable", ex);
        }
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    // 保留以对齐 Spring 语义（未直接使用）
    @SuppressWarnings("unused")
    private static Duration toDuration(long ttlMillis) {
        return Duration.ofMillis(ttlMillis);
    }
}
