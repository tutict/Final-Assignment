package finalassignmentbackend.reliability;

import io.agroal.api.AgroalDataSource;
import jakarta.annotation.Priority;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import java.util.concurrent.atomic.AtomicInteger;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@Provider
@ApplicationScoped
@Priority(Priorities.AUTHENTICATION - 100)
public class LoadShedFilter implements ContainerRequestFilter, ContainerResponseFilter {

    static final String IN_FLIGHT = "reliability.inflight";

    private final AtomicInteger inFlight = new AtomicInteger();

    @Inject
    ReliabilityMetrics metrics;

    @Inject
    AgroalDataSource dataSource;

    @Inject
    @ConfigProperty(name = "reliability.load-shed", defaultValue = "true")
    boolean loadShedEnabled;

    @Override
    public void filter(ContainerRequestContext requestContext) {
        if (!loadShedEnabled || dataSource == null || metrics == null) {
            return;
        }
        String path = requestContext.getUriInfo() == null ? "" : requestContext.getUriInfo().getPath();
        String method = requestContext.getMethod();
        int max = dataSource.getConfiguration().connectionPoolConfiguration().maxSize();
        int now = inFlight.incrementAndGet();
        requestContext.setProperty(IN_FLIGHT, Boolean.TRUE);
        var pool = dataSource.getMetrics();
        double utilization = max <= 0 ? 0d : (double) pool.activeCount() / max;
        int awaiting = (int) Math.min(Integer.MAX_VALUE, pool.awaitingCount());
        int idle = (int) Math.min(Integer.MAX_VALUE, pool.availableCount());
        if (!LoadShedPolicy.shed(method, path, utilization, awaiting, idle)
                && !LoadShedPolicy.shedWhenBusy(method, path, now, max)) {
            return;
        }
        release(requestContext);
        metrics.loadShed();
        requestContext.abortWith(Response.status(Response.Status.SERVICE_UNAVAILABLE)
                .header("Retry-After", "1")
                .type(MediaType.APPLICATION_JSON)
                .entity("{\"errorCode\":\"LOAD_SHED\",\"message\":\"Overloaded\"}")
                .build());
    }

    @Override
    public void filter(ContainerRequestContext requestContext, ContainerResponseContext responseContext) {
        release(requestContext);
    }

    private void release(ContainerRequestContext requestContext) {
        if (requestContext.getProperty(IN_FLIGHT) == null) {
            return;
        }
        requestContext.removeProperty(IN_FLIGHT);
        inFlight.decrementAndGet();
    }
}
