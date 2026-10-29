package finalassignmentbackend.reliability;

import io.agroal.api.AgroalDataSource;
import jakarta.annotation.Priority;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * 负载拒流：数据库连接池吃紧时把读请求与账务写入挡在门外。
 *
 * <p>并发数由 {@link InFlightRequest} 记账——请求作用域 Bean 在请求结束时一定销毁，
 * 名额必定归还，因此计数不会因为流式响应或被拒绝的请求而虚高。
 */
@Provider
@ApplicationScoped
@Priority(Priorities.AUTHENTICATION - 100)
public class LoadShedFilter implements ContainerRequestFilter {

    @Inject
    InFlightCounter counter;

    @Inject
    InFlightRequest inFlightRequest;

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
        inFlightRequest.hold();
        String path = requestContext.getUriInfo() == null ? "" : requestContext.getUriInfo().getPath();
        String method = requestContext.getMethod();
        int max = dataSource.getConfiguration().connectionPoolConfiguration().maxSize();
        int now = counter.value();
        var pool = dataSource.getMetrics();
        double utilization = max <= 0 ? 0d : (double) pool.activeCount() / max;
        int awaiting = (int) Math.min(Integer.MAX_VALUE, pool.awaitingCount());
        int idle = (int) Math.min(Integer.MAX_VALUE, pool.availableCount());
        if (!LoadShedPolicy.shed(method, path, utilization, awaiting, idle)
                && !LoadShedPolicy.shedWhenBusy(method, path, now, max)) {
            return;
        }
        metrics.loadShed();
        requestContext.abortWith(Response.status(Response.Status.SERVICE_UNAVAILABLE)
                .header("Retry-After", "1")
                .type(MediaType.APPLICATION_JSON)
                .entity("{\"errorCode\":\"LOAD_SHED\",\"message\":\"Overloaded\"}")
                .build());
    }
}
