package com.tutict.finalassignmentbackend.ai.agent;

import java.util.Optional;

public interface AgentDraftStore {

    void save(AgentDraft draft);

    Optional<AgentDraft> find(String draftId);

    void delete(String draftId);

    void rememberSessionDraft(String sessionKey, String draftId);

    Optional<String> lastDraftId(String sessionKey);

    /**
     * Bind {@code sessionKey} to {@code userId}. Returns false when the session
     * already belongs to a different user.
     */
    default boolean bindSession(String userId, String sessionKey) {
        return true;
    }

    default void rememberSessionDraft(String userId, String sessionKey, String draftId) {
        rememberSessionDraft(sessionKey, draftId);
    }

    default Optional<String> lastDraftId(String userId, String sessionKey) {
        return lastDraftId(sessionKey);
    }
}
