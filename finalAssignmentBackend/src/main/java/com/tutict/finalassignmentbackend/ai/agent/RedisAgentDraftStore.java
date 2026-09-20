package com.tutict.finalassignmentbackend.ai.agent;

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
                redis.opsForValue().set(SESSION_PREFIX + draft.sessionKey(), draft.draftId(), ttl);
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
        if (sessionKey == null || sessionKey.isBlank() || draftId == null) {
            return;
        }
        redis.opsForValue().set(SESSION_PREFIX + sessionKey, draftId, Duration.ofMinutes(10));
    }

    @Override
    public Optional<String> lastDraftId(String sessionKey) {
        if (sessionKey == null || sessionKey.isBlank()) {
            return Optional.empty();
        }
        return Optional.ofNullable(redis.opsForValue().get(SESSION_PREFIX + sessionKey));
    }

    private static Duration ttlOf(AgentDraft draft) {
        if (draft.expiresAt() == null) {
            return Duration.ofMinutes(10);
        }
        Duration ttl = Duration.between(Instant.now(), draft.expiresAt());
        return ttl.isNegative() || ttl.isZero() ? Duration.ofSeconds(1) : ttl;
    }
}
