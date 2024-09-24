package finalassignmentbackend.controller;


import finalassignmentbackend.entity.AppealManagement;
import finalassignmentbackend.entity.OffenseInformation;
import finalassignmentbackend.service.AppealManagementService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;

@Path("/eventbus/appeals")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AppealManagementController {

    @Inject
    AppealManagementService appealManagementService;

    @POST
    public Response createAppeal(AppealManagement appeal) {
        appealManagementService.createAppeal(appeal);
        return Response.status(Response.Status.CREATED).build();
    }

    @GET
    @Path("/{appealId}")
    public Response getAppealById(@PathParam("appealId") Long appealId) {
        AppealManagement appeal = appealManagementService.getAppealById(appealId);
        if (appeal != null) {
            return Response.ok(appeal).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @GET
    public Response getAllAppeals() {
        List<AppealManagement> appeals = appealManagementService.getAllAppeals();
        return Response.ok(appeals).build();
    }

    @PUT
    @Path("/{appealId}")
    public Response updateAppeal(@PathParam("appealId") Long appealId, AppealManagement updatedAppeal) {
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
            appealManagementService.updateAppeal(existingAppeal);
            return Response.ok().build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    @DELETE
    @Path("/{appealId}")
    public Response deleteAppeal(@PathParam("appealId") Long appealId) {
        appealManagementService.deleteAppeal(appealId);
        return Response.noContent().build();
    }

    @GET
    @Path("/status/{processStatus}")
    public Response getAppealsByProcessStatus(@PathParam("processStatus") String processStatus) {
        List<AppealManagement> appeals = appealManagementService.getAppealsByProcessStatus(processStatus);
        return Response.ok(appeals).build();
    }

    @GET
    @Path("/name/{appealName}")
    public Response getAppealsByAppealName(@PathParam("appealName") String appealName) {
        List<AppealManagement> appeals = appealManagementService.getAppealsByAppealName(appealName);
        return Response.ok(appeals).build();
    }

    @GET
    @Path("/{appealId}/offense")
    public Response getOffenseByAppealId(@PathParam("appealId") Long appealId) {
        OffenseInformation offense = appealManagementService.getOffenseByAppealId(appealId);
        if (offense != null) {
            return Response.ok(offense).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }
}