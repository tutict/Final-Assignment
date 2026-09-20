package finalassignmentbackend.ai.agent;

import jakarta.enterprise.context.ApplicationScoped;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@ApplicationScoped
public class InMemoryDraftStore {
    private final ConcurrentHashMap<String, AgentModels.Draft> drafts = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, String> sessionOwners = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, String> sessionDrafts = new ConcurrentHashMap<>();

    public void save(AgentModels.Draft draft) {
        drafts.put(draft.draftId(), draft);
        if (draft.sessionKey() != null) {
            sessionOwners.putIfAbsent(draft.sessionKey(), draft.userId());
            sessionDrafts.put(draft.userId() + ":" + draft.sessionKey(), draft.draftId());
        }
    }

    public Optional<AgentModels.Draft> find(String draftId) {
        AgentModels.Draft draft = drafts.get(draftId);
        if (draft == null) return Optional.empty();
        if (draft.expiresAt() != null && draft.expiresAt().isBefore(Instant.now())) {
            drafts.remove(draftId);
            return Optional.empty();
        }
        return Optional.of(draft);
    }

    public void delete(String draftId) { drafts.remove(draftId); }

    public boolean bindSession(String userId, String sessionKey) {
        if (sessionKey == null || sessionKey.isBlank()) return true;
        String bound = userId == null || userId.isBlank() ? "anonymous" : userId;
        String existing = sessionOwners.putIfAbsent(sessionKey, bound);
        return existing == null || existing.equals(bound);
    }

    public Optional<String> lastDraftId(String userId, String sessionKey) {
        if (sessionKey == null) return Optional.empty();
        String value = sessionDrafts.get((userId == null ? "anonymous" : userId) + ":" + sessionKey);
        return value == null || value.isBlank() ? Optional.empty() : Optional.of(value);
    }
}
