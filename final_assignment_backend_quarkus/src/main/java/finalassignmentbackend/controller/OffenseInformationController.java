package finalassignmentbackend.controller;

import finalassignmentbackend.entity.OffenseInformation;
import finalassignmentbackend.service.OffenseInformationService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.Date;
import java.util.List;

@Path("/api/offenses")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class OffenseInformationController {

    @Inject
    OffenseInformationService offenseInformationService;

    /**
     * 创建新的违法行为信息。
     */
    @POST
    @RunOnVirtualThread
    public Response createOffense(OffenseInformation offenseInformation, String idempotencyKey) {
        offenseInformationService.checkAndInsertIdempotency(idempotencyKey, offenseInformation, "create");
        return Response.status(Response.Status.CREATED).build();
    }

    /**
     * 根据违法行为ID获取违法行为信息。
     */
    @GET
    @Path("/{offenseId}")
    @RunOnVirtualThread
    public Response getOffenseByOffenseId(@PathParam("offenseId") int offenseId) {
        OffenseInformation offenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
        if (offenseInformation != null) {
            return Response.ok(offenseInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    /**
     * 获取所有违法行为的信息。
     */
    @GET
    @RunOnVirtualThread
    public Response getOffensesInformation() {
        List<OffenseInformation> offensesInformation = offenseInformationService.getOffensesInformation();
        return Response.ok(offensesInformation).build();
    }

    /**
     * 更新指定违法行为的信息。
     */
    @PUT
    @Path("/{offenseId}")
    @RunOnVirtualThread
    public Response updateOffense(@PathParam("offenseId") int offenseId, OffenseInformation updatedOffenseInformation, String idempotencyKey) {
        OffenseInformation existingOffenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
        if (existingOffenseInformation != null) {
            updatedOffenseInformation.setOffenseId(offenseId);
            offenseInformationService.checkAndInsertIdempotency(idempotencyKey, updatedOffenseInformation, "update");
            return Response.ok(Response.Status.OK).entity(updatedOffenseInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    /**
     * 删除指定违法行为的信息。
     */
    @DELETE
    @Path("/{offenseId}")
    @RunOnVirtualThread
    public Response deleteOffense(@PathParam("offenseId") int offenseId) {
        offenseInformationService.deleteOffense(offenseId);
        return Response.noContent().build();
    }

    /**
     * 根据时间范围获取违法行为信息。
     */
    @GET
    @Path("/timeRange")
    @RunOnVirtualThread
    public Response getOffensesByTimeRange(@QueryParam("startTime") Date startTime,
                                           @QueryParam("endTime") Date endTime) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByTimeRange(startTime, endTime);
        return Response.ok(offenses).build();
    }

    /**
     * 根据处理状态获取违法行为信息。
     */
    @GET
    @Path("/processState/{processState}")
    @RunOnVirtualThread
    public Response getOffensesByProcessState(@PathParam("processState") String processState) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByProcessState(processState);
        return Response.ok(offenses).build();
    }

    /**
     * 根据司机姓名获取违法行为信息。
     */
    @GET
    @Path("/driverName/{driverName}")
    @RunOnVirtualThread
    public Response getOffensesByDriverName(@PathParam("driverName") String driverName) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByDriverName(driverName);
        return Response.ok(offenses).build();
    }

    /**
     * 根据车牌号获取违法行为信息。
     */
    @GET
    @Path("/licensePlate/{licensePlate}")
    @RunOnVirtualThread
    public Response getOffensesByLicensePlate(@PathParam("licensePlate") String licensePlate) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByLicensePlate(licensePlate);
        return Response.ok(offenses).build();
    }
}
