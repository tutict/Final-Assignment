package finalassignmentbackend.ai.chat;

import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.ext.Provider;

import java.util.Locale;

/**
 * Keeps reverse proxies from buffering the SSE chat stream. Without this the browser receives
 * the whole answer at once after the model finishes, which defeats token-by-token streaming.
 */
@Provider
public class SseHeadersFilter implements ContainerResponseFilter {

    @Override
    public void filter(ContainerRequestContext requestContext, ContainerResponseContext responseContext) {
        String contentType = responseContext.getMediaType() == null
                ? ""
                : responseContext.getMediaType().toString().toLowerCase(Locale.ROOT);
        if (contentType.startsWith("text/event-stream")) {
            responseContext.getHeaders().putSingle("X-Accel-Buffering", "no");
            responseContext.getHeaders().putSingle(HttpHeaders.CACHE_CONTROL, "no-cache");
        }
    }
}
