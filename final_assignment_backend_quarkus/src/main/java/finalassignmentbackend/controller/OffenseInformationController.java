package finalassignmentbackend.controller;

import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.OffenseInformation;
import finalassignmentbackend.service.OffenseInformationService;
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

@Path("/eventbus/offenses")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class OffenseInformationController {

    @Inject
    OffenseInformationService offenseInformationService;

    /**
     * 创建新的违法行为信息。
     *
     * @param offenseInformation 新创建的违法行为信息对象
     * @return HTTP响应状态码201 Created
     */
    @POST
    public Response createOffense(OffenseInformation offenseInformation) {
        offenseInformationService.createOffense(offenseInformation);
        return Response.status(Response.Status.CREATED).build();
    }

    /**
     * 根据违法行为ID获取违法行为信息。
     *
     * @param offenseId 违法行为ID
     * @return 包含违法行为信息的HTTP响应或NotFound状态
     */
    @GET
    @Path("/{offenseId}")
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
     *
     * @return 包含所有违法行为信息列表的HTTP响应
     */
    @GET
    public Response getOffensesInformation() {
        List<OffenseInformation> offensesInformation = offenseInformationService.getOffensesInformation();
        return Response.ok(offensesInformation).build();
    }

    /**
     * 更新指定违法行为的信息。
     *
     * @param offenseId 违法行为ID
     * @param updatedOffenseInformation 更新后的违法行为信息对象
     * @return HTTP响应状态码200 OK或404 Not Found
     */
    @PUT
    @Path("/{offenseId}")
    public Response updateOffense(@PathParam("offenseId") int offenseId, OffenseInformation updatedOffenseInformation) {
        OffenseInformation existingOffenseInformation = offenseInformationService.getOffenseByOffenseId(offenseId);
        if (existingOffenseInformation != null) {
            updatedOffenseInformation.setOffenseId(offenseId);
            offenseInformationService.updateOffense(updatedOffenseInformation);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    /**
     * 删除指定违法行为的信息。
     *
     * @param offenseId 违法行为ID
     * @return HTTP响应状态码204 No Content
     */
    @DELETE
    @Path("/{offenseId}")
    public Response deleteOffense(@PathParam("offenseId") int offenseId) {
        offenseInformationService.deleteOffense(offenseId);
        return Response.noContent().build();
    }

    /**
     * 根据时间范围获取违法行为信息。
     *
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 包含在指定时间范围内的违法行为信息列表的HTTP响应
     */
    @GET
    @Path("/timeRange")
    public Response getOffensesByTimeRange(@QueryParam("startTime") Date startTime,
                                           @QueryParam("endTime") Date endTime) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByTimeRange(startTime, endTime);
        return Response.ok(offenses).build();
    }

    /**
     * 根据处理状态获取违法行为信息。
     *
     * @param processState 处理状态
     * @return 包含指定处理状态的违法行为信息列表的HTTP响应
     */
    @GET
    @Path("/processState/{processState}")
    public Response getOffensesByProcessState(@PathParam("processState") String processState) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByProcessState(processState);
        return Response.ok(offenses).build();
    }

    /**
     * 根据司机姓名获取违法行为信息。
     *
     * @param driverName 司机姓名
     * @return 包含指定司机姓名的违法行为信息列表的HTTP响应
     */
    @GET
    @Path("/driverName/{driverName}")
    public Response getOffensesByDriverName(@PathParam("driverName") String driverName) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByDriverName(driverName);
        return Response.ok(offenses).build();
    }

    /**
     * 根据车牌号获取违法行为信息。
     *
     * @param licensePlate 车牌号
     * @return 包含指定车牌号的违法行为信息列表的HTTP响应
     */
    @GET
    @Path("/licensePlate/{licensePlate}")
    public Response getOffensesByLicensePlate(@PathParam("licensePlate") String licensePlate) {
        List<OffenseInformation> offenses = offenseInformationService.getOffensesByLicensePlate(licensePlate);
        return Response.ok(offenses).build();
    }
}
