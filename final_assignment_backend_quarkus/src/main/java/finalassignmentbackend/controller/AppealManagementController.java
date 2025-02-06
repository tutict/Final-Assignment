package finalassignmentbackend.controller;

import finalassignmentbackend.entity.AppealManagement;
import finalassignmentbackend.entity.OffenseInformation;
import finalassignmentbackend.service.AppealManagementService;
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
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;

// 控制器类，处理与申诉管理相关的HTTP请求
@Path("/api/appeals")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Appeal Management", description = "Appeal Management Controller for managing appeals")
public class AppealManagementController {

    // 申诉管理服务的接口实例，用于处理申诉的业务逻辑
    @Inject
    AppealManagementService appealManagementService;

    // 创建新的申诉
    // [POST] 请求，创建并存储新的申诉信息
    @POST
    @RunOnVirtualThread
    public Response
    createAppeal(AppealManagement appeal, String idempotencyKey) {
        appealManagementService.checkAndInsertIdempotency(idempotencyKey, appeal, "create");
        return Response.status(Response.Status.CREATED).build();
    }

    // 根据ID获取申诉
    // [GET] 请求，通过申诉ID检索申诉信息
    @GET
    @Path("/{appealId}")
    @RunOnVirtualThread
    public Response getAppealById(@PathParam("appealId") Integer appealId) {
        AppealManagement appeal = appealManagementService.getAppealById(appealId);
        if (appeal != null) {
            return Response.ok(appeal).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    // 获取所有申诉
    // [GET] 请求，检索并返回所有申诉的列表
    @GET
    @RunOnVirtualThread
    public Response getAllAppeals() {
        List<AppealManagement> appeals = appealManagementService.getAllAppeals();
        return Response.ok(appeals).build();
    }

    // 更新申诉信息
    // [PUT] 请求，根据ID检索并更新现有申诉的信息
    @PUT
    @Path("/{appealId}")
    @RunOnVirtualThread
    public Response updateAppeal(@PathParam("appealId") Integer appealId, AppealManagement updatedAppeal, String idempotencyKey) {
        AppealManagement existingAppeal = appealManagementService.getAppealById(appealId);
        if (existingAppeal != null) {
            // 更新现有申诉的属性
            existingAppeal.setOffenseId(updatedAppeal.getOffenseId());
            existingAppeal.setAppellantName(updatedAppeal.getAppellantName());
            existingAppeal.setIdCardNumber(updatedAppeal.getIdCardNumber());
            existingAppeal.setContactNumber(updatedAppeal.getContactNumber());
            existingAppeal.setAppealReason(updatedAppeal.getAppealReason());
            existingAppeal.setAppealTime(updatedAppeal.getAppealTime());
            existingAppeal.setProcessStatus(updatedAppeal.getProcessStatus());
            existingAppeal.setProcessResult(updatedAppeal.getProcessResult());

            // 更新申诉
            appealManagementService.checkAndInsertIdempotency(idempotencyKey, existingAppeal, "update");
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    // 删除申诉
    // [DELETE] 请求，根据ID删除申诉信息
    @DELETE
    @Path("/{appealId}")
    @RunOnVirtualThread
    public Response deleteAppeal(@PathParam("appealId") Integer appealId) {
        appealManagementService.deleteAppeal(appealId);
        return Response.noContent().build();
    }

    // 根据处理状态获取申诉
    // [GET] 请求，通过处理状态检索申诉列表
    @GET
    @Path("/status/{processStatus}")
    @RunOnVirtualThread
    public Response getAppealsByProcessStatus(@PathParam("processStatus") String processStatus) {
        List<AppealManagement> appeals = appealManagementService.getAppealsByProcessStatus(processStatus);
        return Response.ok(appeals).build();
    }

    // 根据申诉人姓名获取申诉
    // [GET] 请求，通过申诉人姓名检索申诉列表
    @GET
    @Path("/name/{appealName}")
    @RunOnVirtualThread
    public Response getAppealsByAppealName(@PathParam("appealName") String appealName) {
        List<AppealManagement> appeals = appealManagementService.getAppealsByAppealName(appealName);
        return Response.ok(appeals).build();
    }

    // 根据申诉ID获取违规信息
    // [GET] 请求，通过申诉ID检索关联的违规信息
    @GET
    @Path("/{appealId}/offense")
    @RunOnVirtualThread
    public Response getOffenseByAppealId(@PathParam("appealId") Integer appealId) {
        OffenseInformation offense = appealManagementService.getOffenseByAppealId(appealId);
        if (offense != null) {
            return Response.ok(offense).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }
}
