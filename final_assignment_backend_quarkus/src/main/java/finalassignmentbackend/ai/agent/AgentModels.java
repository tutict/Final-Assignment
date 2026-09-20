package finalassignmentbackend.ai.agent;

import java.time.Instant;
import java.util.List;
import java.util.Map;

public final class AgentModels {
    private AgentModels() {}

    public record Context(String role, String sessionKey, String username, String userKey, Long driverId, boolean confirmed) {}

    public record Draft(String draftId, String userId, String sessionKey, String toolName, String summary, String risk,
                        Map<String, Object> preview, Map<String, Object> payload, Instant expiresAt) {}

    public record Result(boolean ok, String kind, String summary, List<Map<String, Object>> items, Map<String, Object> navigate, Draft draft) {
        public static Result error(String summary) { return new Result(false, "error", summary, List.of(), null, null); }
        public static Result result(String summary, List<Map<String, Object>> items, Map<String, Object> navigate) {
            return new Result(true, "result", summary, items == null ? List.of() : items, navigate, null);
        }
        public static Result draft(Draft draft) { return new Result(true, "draft", draft.summary(), List.of(), null, draft); }
        public static Result action(String summary, Map<String, Object> navigate) { return new Result(true, "action", summary, List.of(), navigate, null); }
    }

    public static Map<String, Object> navigate(String label, String target) {
        return Map.of("type", "NAVIGATE", "label", label, "target", target, "value", "{\"source\":\"agent_tool\"}");
    }
}
