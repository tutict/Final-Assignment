package finalassignmentbackend.reliability;

import io.smallrye.mutiny.Multi;

import java.time.Duration;

public final class AiStreamGuard {

    public static final String FALLBACK = "{\"isFallback\":true,\"reason\":\"model_unavailable\"}";

    private AiStreamGuard() {
    }

    public static Multi<String> bound(Multi<String> upstream, Duration firstItem, Runnable onFallback) {
        Multi<String> source = upstream == null ? Multi.createFrom().empty() : upstream;
        return source.ifNoItem()
                .after(firstItem == null ? Duration.ofSeconds(1) : firstItem)
                .fail()
                .onFailure()
                .recoverWithMulti(ignored -> {
                    if (onFallback != null) {
                        onFallback.run();
                    }
                    return Multi.createFrom().item(FALLBACK);
                });
    }
}
