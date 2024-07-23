package finalassignmentbackend.controller.view;


import finalassignmentbackend.entity.view.OffenseDetails;
import finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import finalassignmentbackend.service.view.OffenseDetailsService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;

import java.util.List;

@Path("/eventbus/offense-details")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class OffenseDetailsController {

    @Inject
    OffenseDetailsMapper offenseDetailsMapper;

    @Inject
    OffenseDetailsService offenseDetailsService;

    @GET
    public List<OffenseDetails> getAllOffenseDetails() {
        return offenseDetailsMapper.selectList(null);
    }

    @GET
    @Path("/{id}")
    public OffenseDetails getOffenseDetailsById(@PathParam("id") Integer id) {
        return offenseDetailsMapper.selectById(id);
    }

    // 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题
    @GET
    @Path("/send-to-kafka/{id}")
    public String sendOffenseDetailsToKafka(@PathParam("id") Integer id) {
        OffenseDetails offenseDetails = offenseDetailsMapper.selectById(id);
        if (offenseDetails != null) {
            offenseDetailsService.sendOffenseDetailsToKafka(offenseDetails);
            return "OffenseDetails sent to Kafka topic successfully!";
        } else {
            return "OffenseDetails not found for id: " + id;
        }
    }
}
