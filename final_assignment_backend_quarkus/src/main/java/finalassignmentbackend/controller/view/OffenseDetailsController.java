package finalassignmentbackend.controller.view;

import finalassignmentbackend.entity.view.OffenseDetails;
import finalassignmentbackend.service.view.OffenseDetailsService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;

@Path("/eventbus/offense-details")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class OffenseDetailsController {

    @Inject
    OffenseDetailsService offenseDetailsService;

    /**
     * 获取所有违规详情记录
     *
     * @return 包含所有违规详情的列表
     */
    @GET
    @RunOnVirtualThread
    public Response getAllOffenseDetails() {
        List<OffenseDetails> offenseDetailsList = offenseDetailsService.getAllOffenseDetails();
        return Response.ok(offenseDetailsList).build();
    }

    /**
     * 根据 ID 获取违规详情
     *
     * @param id 违规详情的ID
     * @return 包含违规详情的响应或NotFound状态
     */
    @GET
    @Path("/{id}")
    @RunOnVirtualThread
    public Response getOffenseDetailsById(@PathParam("id") Integer id) {
        OffenseDetails offenseDetails = offenseDetailsService.getOffenseDetailsById(id);
        if (offenseDetails != null) {
            return Response.ok(offenseDetails).build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }

    /**
     * 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题
     *
     * @param id 违规详情的ID
     * @return 成功或失败的消息
     */
    @POST
    @Path("/send-to-kafka/{id}")
    @RunOnVirtualThread
    public Response updateOffenseDetailsToKafka(@PathParam("id") Integer id) {
        OffenseDetails offenseDetails = offenseDetailsService.getOffenseDetailsById(id);
        if (offenseDetails != null) {
            offenseDetailsService.saveOffenseDetails(offenseDetails);
            return Response.ok("OffenseDetails sent to Kafka topic successfully!").build();
        } else {
            return Response.status(Response.Status.NOT_FOUND).entity("OffenseDetails not found for id: " + id).build();
        }
    }
}
