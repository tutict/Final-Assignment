package com.tutict.finalassignmentcloud.ai.agent;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

@Component
@ConditionalOnProperty(name = "ai.agent.draft.store", havingValue = "redis")
@ConditionalOnBean(StringRedisTemplate.class)
public class RedisAgentDraftStore implements AgentDraftStore {

    private static final String DRAFT_PREFIX = "ai:agent:draft:";
    private static final String SESSION_PREFIX = "ai:agent:session:";
    private static final String SESSION_OWNER_PREFIX = "ai:agent:session-owner:";
    private static final Duration SESSION_TTL = Duration.ofMinutes(10);

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;

    public RedisAgentDraftStore(StringRedisTemplate redis, ObjectMapper objectMapper) {
        this.redis = redis;
        this.objectMapper = objectMapper;
    }

    @Override
    public void save(AgentDraft draft) {
        try {
            Duration ttl = ttlOf(draft);
            redis.opsForValue().set(DRAFT_PREFIX + draft.draftId(), objectMapper.writeValueAsString(draft), ttl);
            if (draft.sessionKey() != null && !draft.sessionKey().isBlank()) {
                bindSession(draft.userId(), draft.sessionKey());
                redis.opsForValue().set(sessionKey(draft.userId(), draft.sessionKey()), draft.draftId(), ttl);
            }
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to persist agent draft", ex);
        }
    }

    @Override
    public Optional<AgentDraft> find(String draftId) {
        if (draftId == null || draftId.isBlank()) {
            return Optional.empty();
        }
        String json = redis.opsForValue().get(DRAFT_PREFIX + draftId);
        if (json == null || json.isBlank()) {
            return Optional.empty();
        }
        try {
            AgentDraft draft = objectMapper.readValue(json, AgentDraft.class);
            if (draft.expiresAt() != null && draft.expiresAt().isBefore(Instant.now())) {
                delete(draftId);
                return Optional.empty();
            }
            return Optional.of(draft);
        } catch (Exception ex) {
            return Optional.empty();
        }
    }

    @Override
    public void delete(String draftId) {
        if (draftId != null) {
            redis.delete(DRAFT_PREFIX + draftId);
        }
    }

    @Override
    public void rememberSessionDraft(String sessionKey, String draftId) {
        rememberSessionDraft(null, sessionKey, draftId);
    }

    @Override
    public Optional<String> lastDraftId(String sessionKey) {
        return lastDraftId(null, sessionKey);
    }

    @Override
    public boolean bindSession(String userId, String sessionKey) {
        if (sessionKey == null || sessionKey.isBlank()) {
            return true;
        }
        String boundUser = normalizeUser(userId);
        String ownerKey = SESSION_OWNER_PREFIX + sessionKey;
        String existing = redis.opsForValue().get(ownerKey);
        if (existing != null && !existing.isBlank() && !existing.equals(boundUser)) {
            return false;
        }
        redis.opsForValue().set(ownerKey, boundUser, SESSION_TTL);
        redis.opsForValue().setIfAbsent(sessionKey(boundUser, sessionKey), "", SESSION_TTL);
        return true;
    }

    @Override
    public void rememberSessionDraft(String userId, String sessionKey, String draftId) {
        if (sessionKey == null || sessionKey.isBlank() || draftId == null) {
            return;
        }
        bindSession(userId, sessionKey);
        redis.opsForValue().set(sessionKey(userId, sessionKey), draftId, SESSION_TTL);
    }

    @Override
    public Optional<String> lastDraftId(String userId, String sessionKey) {
        if (sessionKey == null || sessionKey.isBlank()) {
            return Optional.empty();
        }
        String value = redis.opsForValue().get(sessionKey(userId, sessionKey));
        if (value == null || value.isBlank()) {
            return Optional.empty();
        }
        return Optional.of(value);
    }

    private static String sessionKey(String userId, String sessionKey) {
        return SESSION_PREFIX + normalizeUser(userId) + ":" + sessionKey;
    }

    private static String normalizeUser(String userId) {
        return userId == null || userId.isBlank() ? "anonymous" : userId;
    }

    private static Duration ttlOf(AgentDraft draft) {
        if (draft.expiresAt() == null) {
            return SESSION_TTL;
        }
        Duration ttl = Duration.between(Instant.now(), draft.expiresAt());
        return ttl.isNegative() || ttl.isZero() ? Duration.ofSeconds(1) : ttl;
    }
}
