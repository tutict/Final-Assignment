package com.tutict.finalassignmentbackend.controller.view;

import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import com.tutict.finalassignmentbackend.service.view.OffenseDetailsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/eventbus/offense-details")
public class OffenseDetailsController {

    private final OffenseDetailsService offenseDetailsService;

    @Autowired
    public OffenseDetailsController(OffenseDetailsService offenseDetailsService) {
        this.offenseDetailsService = offenseDetailsService;
    }

    // 获取所有违规详情记录
    @GetMapping
    public List<OffenseDetails> getAllOffenseDetails() {
        return offenseDetailsService.getAllOffenseDetails();
    }

    // 根据 ID 获取违规详情
    @GetMapping("/{id}")
    public OffenseDetails getOffenseDetailsById(@PathVariable Integer id) {
        return offenseDetailsService.getOffenseDetailsById(id);
    }

    // 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题
    @GetMapping("/send-to-kafka/{id}")
    public String sendOffenseDetailsToKafka(@PathVariable Integer id) {
        OffenseDetails offenseDetails = offenseDetailsService.getOffenseDetailsById(id);
        if (offenseDetails != null) {
            offenseDetailsService.sendOffenseDetailsToKafka(offenseDetails);
            return "OffenseDetails sent to Kafka topic successfully!";
        } else {
            return "OffenseDetails not found for id: " + id;
        }
    }
}
