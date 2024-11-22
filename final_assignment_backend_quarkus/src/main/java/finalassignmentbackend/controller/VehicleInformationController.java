package finalassignmentbackend.controller;

import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.VehicleInformation;
import finalassignmentbackend.service.VehicleInformationService;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;

@Path("/eventbus/vehicles")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
/*
 * 车辆信息控制器类，用于处理与车辆信息相关的HTTP请求。
 */
public class VehicleInformationController {

    @Inject
    VehicleInformationService vehicleInformationService;

    /**
     * 创建新的车辆信息。
     *
     * @param vehicleInformation 新创建的车辆信息对象
     * @return HTTP响应状态码201 Created
     */
    @POST
    public Response createVehicleInformation(VehicleInformation vehicleInformation) {
        vehicleInformationService.createVehicleInformation(vehicleInformation);
        return Response.status(Response.Status.CREATED).build();
    }

    /**
     * 根据ID获取车辆信息。
     *
     * @param vehicleId 车辆ID
     * @return 包含车辆信息的HTTP响应或NotFound状态
     */
    @GET
    @Path("/{vehicleId}")
    public Response getVehicleInformationById(@PathParam("vehicleId") int vehicleId) {
        VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationById(vehicleId);
        if (vehicleInformation != null) {
            return Response.ok(vehicleInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    /**
     * 根据车牌号获取车辆信息。
     *
     * @param licensePlate 车牌号
     * @return 包含车辆信息的HTTP响应或NotFound状态
     */
    @GET
    @Path("/license-plate/{licensePlate}")
    public Response getVehicleInformationByLicensePlate(@PathParam("licensePlate") String licensePlate) {
        VehicleInformation vehicleInformation = vehicleInformationService.getVehicleInformationByLicensePlate(licensePlate);
        if (vehicleInformation != null) {
            return Response.ok(vehicleInformation).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    /**
     * 获取所有车辆信息。
     *
     * @return 包含所有车辆信息列表的HTTP响应
     */
    @GET
    public Response getAllVehicleInformation() {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getAllVehicleInformation();
        return Response.ok(vehicleInformationList).build();
    }

    /**
     * 根据车辆类型获取车辆信息列表。
     *
     * @param vehicleType 车辆类型
     * @return 包含车辆信息列表的HTTP响应
     */
    @GET
    @Path("/type/{vehicleType}")
    public Response getVehicleInformationByType(@PathParam("vehicleType") String vehicleType) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByType(vehicleType);
        return Response.ok(vehicleInformationList).build();
    }

    /**
     * 根据车主名称获取车辆信息列表。
     *
     * @param ownerName 车主名称
     * @return 包含车辆信息列表的HTTP响应
     */
    @GET
    @Path("/owner/{ownerName}")
    public Response getVehicleInformationByOwnerName(@PathParam("ownerName") String ownerName) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByOwnerName(ownerName);
        return Response.ok(vehicleInformationList).build();
    }

    /**
     * 根据车辆状态获取车辆信息列表。
     *
     * @param currentStatus 车辆状态
     * @return 包含车辆信息列表的HTTP响应
     */
    @GET
    @Path("/status/{currentStatus}")
    public Response getVehicleInformationByStatus(@PathParam("currentStatus") String currentStatus) {
        List<VehicleInformation> vehicleInformationList = vehicleInformationService.getVehicleInformationByStatus(currentStatus);
        return Response.ok(vehicleInformationList).build();
    }

    /**
     * 更新车辆信息。
     *
     * @param vehicleId 车辆ID
     * @param vehicleInformation 更新后的车辆信息对象
     * @return HTTP响应状态码200 OK
     */
    @PUT
    @Path("/{vehicleId}")
    public Response updateVehicleInformation(@PathParam("vehicleId") int vehicleId, VehicleInformation vehicleInformation) {
        vehicleInformation.setVehicleId(vehicleId);
        vehicleInformationService.updateVehicleInformation(vehicleInformation);
        return Response.ok().build();
    }

    /**
     * 根据ID删除车辆信息。
     *
     * @param vehicleId 车辆ID
     * @return HTTP响应状态码204 No Content
     */
    @DELETE
    @Path("/{vehicleId}")
    public Response deleteVehicleInformation(@PathParam("vehicleId") int vehicleId) {
        vehicleInformationService.deleteVehicleInformation(vehicleId);
        return Response.noContent().build();
    }

    /**
     * 根据车牌号删除车辆信息。
     *
     * @param licensePlate 车牌号
     * @return HTTP响应状态码204 No Content
     */
    @DELETE
    @Path("/license-plate/{licensePlate}")
    public Response deleteVehicleInformationByLicensePlate(@PathParam("licensePlate") String licensePlate) {
        vehicleInformationService.deleteVehicleInformationByLicensePlate(licensePlate);
        return Response.noContent().build();
    }

    /**
     * 检查车牌号是否存在。
     *
     * @param licensePlate 车牌号
     * @return 包含检查结果的HTTP响应
     */
    @GET
    @Path("/exists/{licensePlate}")
    public Response isLicensePlateExists(@PathParam("licensePlate") String licensePlate) {
        boolean exists = vehicleInformationService.isLicensePlateExists(licensePlate);
        return Response.ok(exists).build();
    }
}
