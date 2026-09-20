package com.tutict.finalassignmentbackend.ai.agent;

import java.util.Optional;

public interface AgentDraftStore {

    void save(AgentDraft draft);

    Optional<AgentDraft> find(String draftId);

    void delete(String draftId);

    void rememberSessionDraft(String sessionKey, String draftId);

    Optional<String> lastDraftId(String sessionKey);
}
