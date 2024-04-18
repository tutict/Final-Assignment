package com.tutict.finalassignmentbackend.service.view;

import com.tutict.finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class OffenseDetailsService {

    private final OffenseDetailsMapper offenseDetailsMapper;
    private final KafkaTemplate<String, OffenseDetails> kafkaTemplate;

    @Autowired
    public OffenseDetailsService(OffenseDetailsMapper offenseDetailsMapper, KafkaTemplate<String, OffenseDetails> kafkaTemplate) {
        this.offenseDetailsMapper = offenseDetailsMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    public List<OffenseDetails> getAllOffenseDetails() {
        return offenseDetailsMapper.selectList(null);
    }

    public OffenseDetails getOffenseDetailsById(Integer id) {
        return offenseDetailsMapper.selectById(id);
    }

    // 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题
    public void sendOffenseDetailsToKafka(OffenseDetails offenseDetails) {
        kafkaTemplate.send("offense_details_topic", offenseDetails);
    }
}
