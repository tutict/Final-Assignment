package finalassignmentbackend.reliability;

import io.agroal.api.AgroalDataSource;
import jakarta.annotation.security.PermitAll;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Map;

@Path("/")
public class ActuatorAliasResource {

    @Inject
    AgroalDataSource dataSource;

    @Inject
    ReliabilityMetrics metrics;

    @Inject
    LedgerReconciliation ledgerReconciliation;

    @GET
    @Path("actuator/health")
    @PermitAll
    @Produces(MediaType.APPLICATION_JSON)
    public Response health() {
        return database();
    }

    @GET
    @Path("actuator/health/readiness")
    @PermitAll
    @Produces(MediaType.APPLICATION_JSON)
    public Response readiness() {
        return database();
    }

    @GET
    @Path("api/actuator/health")
    @PermitAll
    @Produces(MediaType.APPLICATION_JSON)
    public Response apiHealth() {
        return database();
    }

    private Response database() {
        try (Connection connection = dataSource.getConnection()) {
            if (connection.isValid(1)) {
                return Response.ok(Map.of("status", "UP")).build();
            }
        } catch (Exception ignored) {
            return Response.status(Response.Status.SERVICE_UNAVAILABLE).entity(Map.of("status", "DOWN")).build();
        }
        return Response.status(Response.Status.SERVICE_UNAVAILABLE).entity(Map.of("status", "DOWN")).build();
    }


    @POST
    @Path("actuator/ledgerReconcile")
    @RolesAllowed({"ADMIN", "SUPER_ADMIN"})
    @Produces(MediaType.APPLICATION_JSON)
    public Response ledgerReconcile() {
        return Response.ok(Map.of("updated", ledgerReconciliation.reconcileStaleProcessing())).build();
    }
    @GET
    @Path("q/metrics")
    @RolesAllowed({"ADMIN", "SUPER_ADMIN"})
    @Produces("text/plain")
    public String quarkusMetrics() {
        return prometheus();
    }
    @GET
    @Path("actuator/prometheus")
    @RolesAllowed({"ADMIN", "SUPER_ADMIN"})
    @Produces("text/plain")
    public String prometheus() {
        return metrics.prometheus(backupSuccessEpoch(), poolAwaiting(), poolBlockingMillis());
    }

    private long backupSuccessEpoch() {
        try (Connection connection = dataSource.getConnection();
             PreparedStatement statement = connection.prepareStatement(
                     "SELECT UNIX_TIMESTAMP(MAX(backup_time)) FROM sys_backup_restore WHERE status = 'Success' AND deleted_at IS NULL");
             ResultSet result = statement.executeQuery()) {
            if (result.next() && result.getObject(1) != null) {
                return result.getLong(1);
            }
        } catch (Exception ignored) {
            return 0L;
        }
        return 0L;
    }

    private long poolAwaiting() {
        try {
            return dataSource.getMetrics().awaitingCount();
        } catch (RuntimeException ignored) {
            return 0L;
        }
    }

    private long poolBlockingMillis() {
        try {
            return dataSource.getMetrics().blockingTimeTotal().toMillis();
        } catch (RuntimeException ignored) {
            return 0L;
        }
    }
}