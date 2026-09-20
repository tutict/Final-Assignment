package com.tutict.finalassignmentbackend.ai.agent;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Component
@ConditionalOnProperty(name = "ai.agent.draft.store", havingValue = "memory", matchIfMissing = true)
public class InMemoryAgentDraftStore implements AgentDraftStore {

    private final ConcurrentHashMap<String, AgentDraft> drafts = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, String> sessionDrafts = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, String> sessionOwners = new ConcurrentHashMap<>();

    @Override
    public void save(AgentDraft draft) {
        drafts.put(draft.draftId(), draft);
        if (draft.sessionKey() != null && !draft.sessionKey().isBlank()) {
            rememberSessionDraft(draft.userId(), draft.sessionKey(), draft.draftId());
        }
    }

    @Override
    public Optional<AgentDraft> find(String draftId) {
        if (draftId == null || draftId.isBlank()) {
            return Optional.empty();
        }
        AgentDraft draft = drafts.get(draftId);
        if (draft == null) {
            return Optional.empty();
        }
        if (draft.expiresAt() != null && draft.expiresAt().isBefore(Instant.now())) {
            drafts.remove(draftId);
            return Optional.empty();
        }
        return Optional.of(draft);
    }

    @Override
    public void delete(String draftId) {
        if (draftId != null) {
            drafts.remove(draftId);
        }
    }

    @Override
    public void rememberSessionDraft(String sessionKey, String draftId) {
        if (sessionKey != null && !sessionKey.isBlank() && draftId != null) {
            sessionDrafts.put(sessionKey, draftId);
        }
    }

    @Override
    public Optional<String> lastDraftId(String sessionKey) {
        if (sessionKey == null || sessionKey.isBlank()) {
            return Optional.empty();
        }
        return Optional.ofNullable(sessionDrafts.get(sessionKey));
    }

    @Override
    public boolean bindSession(String userId, String sessionKey) {
        if (sessionKey == null || sessionKey.isBlank()) {
            return true;
        }
        String ownerKey = ownerKey(sessionKey);
        String boundUser = userId == null || userId.isBlank() ? "anonymous" : userId;
        String existing = sessionOwners.putIfAbsent(ownerKey, boundUser);
        return existing == null || existing.equals(boundUser);
    }

    @Override
    public void rememberSessionDraft(String userId, String sessionKey, String draftId) {
        if (sessionKey == null || sessionKey.isBlank() || draftId == null) {
            return;
        }
        bindSession(userId, sessionKey);
        sessionDrafts.put(sessionKey, draftId);
        sessionDrafts.put(userSessionKey(userId, sessionKey), draftId);
    }

    @Override
    public Optional<String> lastDraftId(String userId, String sessionKey) {
        if (sessionKey == null || sessionKey.isBlank()) {
            return Optional.empty();
        }
        if (userId == null || userId.isBlank()) {
            return lastDraftId(sessionKey);
        }
        return Optional.ofNullable(sessionDrafts.get(userSessionKey(userId, sessionKey)))
                .filter(value -> !value.isBlank());
    }

    private static String userSessionKey(String userId, String sessionKey) {
        String boundUser = userId == null || userId.isBlank() ? "anonymous" : userId;
        return boundUser + ":" + sessionKey;
    }

    private static String ownerKey(String sessionKey) {
        return "owner:" + sessionKey;
    }
}
