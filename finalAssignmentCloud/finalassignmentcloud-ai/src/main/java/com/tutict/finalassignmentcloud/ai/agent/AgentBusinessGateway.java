package com.tutict.finalassignmentcloud.ai.agent;

import com.tutict.finalassignmentcloud.ai.client.AuditClient;
import com.tutict.finalassignmentcloud.ai.client.TrafficClient;
import com.tutict.finalassignmentcloud.ai.client.UserProfileClient;
import com.tutict.finalassignmentcloud.ai.client.rag.RagAdminClient;
import com.tutict.finalassignmentcloud.ai.client.rag.RagClient;
import com.tutict.finalassignmentcloud.ai.client.rag.RagQueryRequest;
import com.tutict.finalassignmentcloud.ai.client.rag.RagRetrievalResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

@Component
public class AgentBusinessGateway {

    private static final Logger logger = LoggerFactory.getLogger(AgentBusinessGateway.class);

    private final TrafficClient trafficClient;
    private final UserProfileClient userProfileClient;
    private final AuditClient auditClient;
    private final RagAdminClient ragAdminClient;
    private final RagClient ragClient;

    public AgentBusinessGateway(
            TrafficClient trafficClient,
            UserProfileClient userProfileClient,
            AuditClient auditClient,
            RagAdminClient ragAdminClient,
            RagClient ragClient
    ) {
        this.trafficClient = trafficClient;
        this.userProfileClient = userProfileClient;
        this.auditClient = auditClient;
        this.ragAdminClient = ragAdminClient;
        this.ragClient = ragClient;
    }

    public List<Map<String, Object>> offenses(Long driverId) {
        return driverId == null ? list(trafficClient::offenses) : list(() -> trafficClient.offensesByDriver(driverId));
    }

    public Map<String, Object> createOffense(Map<String, Object> body) {
        return map(() -> trafficClient.createOffense(body));
    }

    public List<Map<String, Object>> fines(Long driverId) {
        return driverId == null ? list(trafficClient::fines) : list(() -> trafficClient.finesByDriver(driverId));
    }

    public Map<String, Object> fine(Long fineId) {
        return map(() -> trafficClient.fine(fineId));
    }

    public Map<String, Object> createFine(Map<String, Object> body) {
        return map(() -> trafficClient.createFine(body));
    }

    public List<Map<String, Object>> appeals(Long driverId) {
        return driverId == null ? list(trafficClient::appeals) : list(() -> trafficClient.appealsByDriver(driverId));
    }

    public Map<String, Object> createAppeal(Map<String, Object> body) {
        return map(() -> trafficClient.createAppeal(body));
    }

    public Map<String, Object> reviewAppeal(Long appealId, Map<String, Object> body) {
        return map(() -> trafficClient.reviewAppeal(appealId, body));
    }

    public List<Map<String, Object>> vehicles(Long driverId) {
        return driverId == null ? list(trafficClient::vehicles) : list(() -> trafficClient.vehiclesByDriver(driverId));
    }

    public Map<String, Object> bindVehicle(Long vehicleId, Map<String, Object> body) {
        return map(() -> trafficClient.bindVehicle(vehicleId, body));
    }

    public List<Map<String, Object>> drivers() {
        return list(trafficClient::drivers);
    }

    public Map<String, Object> driver(Long driverId) {
        return map(() -> trafficClient.driver(driverId));
    }

    public Map<String, Object> updateDriver(Long driverId, Map<String, Object> body) {
        return map(() -> trafficClient.updateDriver(driverId, body));
    }

    public List<Map<String, Object>> progress() {
        return list(trafficClient::progress);
    }

    public Map<String, Object> createDeduction(Map<String, Object> body) {
        return map(() -> trafficClient.createDeduction(body));
    }

    public Map<String, Object> createPayment(Map<String, Object> body) {
        return map(() -> trafficClient.createPayment(body));
    }

    public List<Map<String, Object>> users() {
        return list(userProfileClient::users);
    }

    public List<Map<String, Object>> operations(String username) {
        return username == null || username.isBlank()
                ? list(auditClient::operations)
                : list(() -> auditClient.operationsByUsername(username));
    }

    public List<Map<String, Object>> logins(String username) {
        return username == null || username.isBlank()
                ? list(auditClient::logins)
                : list(() -> auditClient.loginsByUsername(username));
    }

    public Map<String, Object> ragOverview() {
        return unwrap(call(ragAdminClient::overview));
    }

    public Map<String, Object> ingestRag(Map<String, Object> body) {
        return unwrap(call(() -> ragAdminClient.createManual(body)));
    }

    public List<RagRetrievalResult> searchKnowledge(String query, String userId, List<String> roles) {
        try {
            RagClient.RagQueryApiResponse response = ragClient.query(new RagQueryRequest(query, 5, userId, roles, null));
            if (response == null || !response.success() || response.data() == null) {
                return List.of();
            }
            return response.data().getOrDefault("results", List.of());
        } catch (RuntimeException error) {
            logger.warn("RAG query failed: {}", error.getMessage());
            throw new AgentBusinessException(error.getMessage() == null ? "知识库检索失败" : error.getMessage());
        }
    }

    private List<Map<String, Object>> list(Supplier<List<Map<String, Object>>> supplier) {
        List<Map<String, Object>> value = call(supplier);
        return value == null ? List.of() : value;
    }

    private Map<String, Object> map(Supplier<Map<String, Object>> supplier) {
        Map<String, Object> value = call(supplier);
        return value == null ? Map.of() : value;
    }

    private <T> T call(Supplier<T> supplier) {
        try {
            return supplier.get();
        } catch (RuntimeException error) {
            logger.warn("Agent Feign call failed: {}", error.toString());
            throw new AgentBusinessException(error.getMessage() == null ? "业务服务暂时不可用" : error.getMessage());
        }
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> unwrap(Map<String, Object> payload) {
        if (payload == null) {
            return Map.of();
        }
        Object data = payload.get("data");
        if (data instanceof Map<?, ?> map) {
            Map<String, Object> copy = new LinkedHashMap<>();
            map.forEach((k, v) -> copy.put(String.valueOf(k), v));
            return copy;
        }
        return payload;
    }

    public static List<Map<String, Object>> summarize(List<Map<String, Object>> records, String... keys) {
        List<Map<String, Object>> items = new ArrayList<>();
        if (records == null) {
            return items;
        }
        for (Map<String, Object> record : records) {
            Map<String, Object> item = new LinkedHashMap<>();
            for (String key : keys) {
                if (record.containsKey(key)) {
                    item.put(key, record.get(key));
                }
            }
            if (item.isEmpty()) {
                item.putAll(record);
            }
            items.add(item);
        }
        return items;
    }

    public static Long longValue(Map<String, Object> source, String... keys) {
        if (source == null) {
            return null;
        }
        for (String key : keys) {
            Object value = source.get(key);
            if (value instanceof Number number) {
                return number.longValue();
            }
            if (value != null && !value.toString().isBlank()) {
                try {
                    return Long.parseLong(value.toString());
                } catch (NumberFormatException ignored) {
                    return null;
                }
            }
        }
        return null;
    }
}
