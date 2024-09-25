package com.tutict.finalassignmentbackend.service.view;

import com.tutict.finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

// 服务类，用于处理违规详情的相关操作
@Service
public class OffenseDetailsService {

    // 映射器，用于执行违规详情的数据访问操作
    private final OffenseDetailsMapper offenseDetailsMapper;
    // Kafka 模板，用于发送违规详情对象到 Kafka 主题
    private final KafkaTemplate<String, OffenseDetails> kafkaTemplate;

    // 构造函数，通过依赖注入初始化映射器和 Kafka 模板
    @Autowired
    public OffenseDetailsService(OffenseDetailsMapper offenseDetailsMapper, KafkaTemplate<String, OffenseDetails> kafkaTemplate) {
        this.offenseDetailsMapper = offenseDetailsMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 获取所有违规详情记录
    // 无参数
    // 返回一个包含所有违规详情的列表
    public List<OffenseDetails> getAllOffenseDetails() {
        return offenseDetailsMapper.selectList(null);
    }

    // 根据 ID 获取违规详情
    // 参数 id: 违规记录的唯一标识
    // 返回指定 ID 的违规详情对象，若不存在则返回 null
    public OffenseDetails getOffenseDetailsById(Integer id) {
        return offenseDetailsMapper.selectById(id);
    }

    // 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题
    // 参数 offenseDetails: 需要发送的违规详情对象
    // 通过 Kafka 模板将违规详情对象发送到指定的主题
    public void sendOffenseDetailsToKafka(OffenseDetails offenseDetails) {
        kafkaTemplate.send("offense_details_topic", offenseDetails);
    }

    // 保存违规详情到数据库
    // 参数 offenseDetails: 需要保存的违规详情对象
    // 将 offenseDetails 保存到数据库中
    public void saveOffenseDetails(OffenseDetails offenseDetails) {
        offenseDetailsMapper.insert(offenseDetails);
    }
}
