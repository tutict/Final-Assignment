package com.tutict.finalassignmentbackend.controller.view;

import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import com.tutict.finalassignmentbackend.mapper.view.OffenseDetailsMapper;
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

    private final OffenseDetailsMapper offenseDetailsMapper;
    private final OffenseDetailsService offenseDetailsService;

    @Autowired
    public OffenseDetailsController(OffenseDetailsMapper offenseDetailsMapper, OffenseDetailsService offenseDetailsService) {
        this.offenseDetailsMapper = offenseDetailsMapper;
        this.offenseDetailsService = offenseDetailsService;
    }

    @GetMapping
    public List<OffenseDetails> getAllOffenseDetails() {
        return offenseDetailsMapper.selectList(null);
    }

    @GetMapping("/{id}")
    public OffenseDetails getOffenseDetailsById(@PathVariable Integer id) {
        return offenseDetailsMapper.selectById(id);
    }

    // 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题
    @GetMapping("/send-to-kafka/{id}")
    public String sendOffenseDetailsToKafka(@PathVariable Integer id) {
        OffenseDetails offenseDetails = offenseDetailsMapper.selectById(id);
        if (offenseDetails != null) {
            offenseDetailsService.sendOffenseDetailsToKafka(offenseDetails);
            return "OffenseDetails sent to Kafka topic successfully!";
        } else {
            return "OffenseDetails not found for id: " + id;
        }
    }
}
