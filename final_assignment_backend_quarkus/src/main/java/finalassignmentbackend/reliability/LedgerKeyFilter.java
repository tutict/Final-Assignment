package finalassignmentbackend.reliability;

import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;

@Provider
@Priority(Priorities.AUTHENTICATION + 10)
public class LedgerKeyFilter implements ContainerRequestFilter {

    @Override
    public void filter(ContainerRequestContext requestContext) {
        String path = requestContext.getUriInfo() == null ? "" : requestContext.getUriInfo().getPath();
        if (!LedgerKeyPolicy.requiresKey(requestContext.getMethod(), path)) {
            return;
        }
        String key = requestContext.getHeaderString("Idempotency-Key");
        if (key != null && !key.isBlank()) {
            return;
        }
        requestContext.abortWith(Response.status(Response.Status.BAD_REQUEST)
                .type(MediaType.APPLICATION_JSON)
                .entity("{\"errorCode\":\"MISSING_HEADER\",\"message\":\"Missing required header: Idempotency-Key\"}")
                .build());
    }
}
