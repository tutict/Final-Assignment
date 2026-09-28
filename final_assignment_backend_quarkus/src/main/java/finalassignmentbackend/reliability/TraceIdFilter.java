package finalassignmentbackend.reliability;

import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.ext.Provider;

@Provider
@Priority(Priorities.AUTHENTICATION - 200)
public class TraceIdFilter implements ContainerRequestFilter, ContainerResponseFilter {

    static final String PROPERTY = "reliability.traceId";

    @Override
    public void filter(ContainerRequestContext requestContext) {
        String traceId = TraceIds.resolve(requestContext.getHeaderString(TraceIds.HEADER));
        requestContext.getHeaders().putSingle(TraceIds.HEADER, traceId);
        requestContext.setProperty(PROPERTY, traceId);
    }

    @Override
    public void filter(ContainerRequestContext requestContext, ContainerResponseContext responseContext) {
        Object stored = requestContext.getProperty(PROPERTY);
        String traceId = stored instanceof String value && !value.isBlank() ? value : TraceIds.resolve(null);
        responseContext.getHeaders().putSingle(TraceIds.HEADER, traceId);
    }
}
