package finalassignmentbackend.reliability;

import java.util.UUID;

public final class TraceIds {

    public static final String HEADER = "X-Trace-Id";

    private TraceIds() {
    }

    public static String resolve(String incoming) {
        if (incoming != null && !incoming.isBlank()) {
            return incoming.trim();
        }
        return UUID.randomUUID().toString().replace("-", "").substring(0, 16);
    }
}
