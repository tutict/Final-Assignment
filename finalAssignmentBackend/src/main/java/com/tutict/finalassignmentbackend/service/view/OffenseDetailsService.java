package com.tutict.finalassignmentbackend.service.view;

import com.tutict.finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.concurrent.CompletableFuture;

// 服务类，用于处理违规详情的相关操作
@Service
public class OffenseDetailsService {

    // 日志记录器，用于记录应用的运行信息
    private static final Logger log = LoggerFactory.getLogger(OffenseDetailsService.class);

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
    @Transactional(readOnly = true)
    public List<OffenseDetails> getAllOffenseDetails() {
        return offenseDetailsMapper.selectList(null);
    }

    // 根据 ID 获取违规详情
    // 参数 id: 违规记录的唯一标识
    // 返回指定 ID 的违规详情对象，若不存在则返回 null
    @Transactional(readOnly = true)
    public OffenseDetails getOffenseDetailsById(Integer id) {
        return offenseDetailsMapper.selectById(id);
    }

    // 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题
    // 参数 offenseDetails: 需要发送的违规详情对象
    // 通过 Kafka 模板将违规详情对象发送到指定的主题
    public void sendOffenseDetailsToKafka(OffenseDetails offenseDetails) {
        try {
            CompletableFuture<SendResult<String, OffenseDetails>> future = kafkaTemplate.send("offense_details_topic", offenseDetails);
            future.thenAccept(sendResult -> log.info("Message sent to Kafka successfully: {}", sendResult.toString()))
                    .exceptionally(ex -> {
                        log.error("Failed to send message to Kafka", ex);
                        throw new RuntimeException("Kafka message send failure", ex);
                    });
        } catch (Exception e) {
            log.error("Exception occurred while sending message to Kafka", e);
            throw new RuntimeException("Failed to send message to Kafka", e);
        }
    }

    // 保存违规详情到数据库
    // 参数 offenseDetails: 需要保存的违规详情对象
    // 将 offenseDetails 保存到数据库中
    @Transactional
    public void saveOffenseDetails(OffenseDetails offenseDetails) {
        try {
            offenseDetailsMapper.insert(offenseDetails);
            log.info("Offense details saved to database successfully");
            // 同步发送 Kafka 消息
            sendOffenseDetailsToKafka(offenseDetails);
        } catch (Exception e) {
            log.error("Exception occurred while saving offense details or sending Kafka message", e);
            throw new RuntimeException("Failed to save offense details", e);
        }
    }
}
