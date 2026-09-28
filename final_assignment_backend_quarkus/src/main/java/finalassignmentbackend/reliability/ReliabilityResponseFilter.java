package finalassignmentbackend.reliability;

import jakarta.inject.Inject;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.ext.Provider;

@Provider
public class ReliabilityResponseFilter implements ContainerResponseFilter {

    @Inject
    ReliabilityMetrics metrics;

    @Override
    public void filter(ContainerRequestContext requestContext, ContainerResponseContext responseContext) {
        if (metrics != null && responseContext != null) {
            metrics.noteStatus(responseContext.getStatus());
        }
    }
}
