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

    @Override
    public void save(AgentDraft draft) {
        drafts.put(draft.draftId(), draft);
        if (draft.sessionKey() != null && !draft.sessionKey().isBlank()) {
            rememberSessionDraft(draft.sessionKey(), draft.draftId());
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
}
