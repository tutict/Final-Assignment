package finalassignmentbackend.service.view;

import finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import finalassignmentbackend.entity.view.OffenseDetails;
import io.smallrye.mutiny.Uni;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.List;
import java.util.concurrent.CompletionStage;
import java.util.logging.Logger;

@ApplicationScoped
public class OffenseDetailsService {

    private static final Logger log = Logger.getLogger(OffenseDetailsService.class.getName());

    @Inject
    OffenseDetailsMapper offenseDetailsMapper;

    @Inject
    @Channel("offense-details-out")
    MutinyEmitter<OffenseDetails> offenseDetailsEmitter;

    // 获取所有违规详情记录
    @Transactional
    public List<OffenseDetails> getAllOffenseDetails() {
        return offenseDetailsMapper.selectList(null);
    }

    // 根据 ID 获取违规详情
    @Transactional
    public OffenseDetails getOffenseDetailsById(Integer id) {
        return offenseDetailsMapper.selectById(id);
    }

    // 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题
    public void sendOffenseDetailsToKafka(OffenseDetails offenseDetails) {
        try {
            var metadata = OutgoingKafkaRecordMetadata.<String>builder()
                    .withTopic("offense_details_topic")
                    .build();

            Message<OffenseDetails> message = Message.of(offenseDetails).addMetadata(metadata);

            // 使用 MutinyEmitter 发送消息
            Uni<Void> uni = offenseDetailsEmitter.sendMessage(message);

            // 将 Uni<Void> 转换为 CompletionStage<Void> 并处理结果
            CompletionStage<Void> sendStage = uni.subscribe().asCompletionStage();
            sendStage.whenComplete((ignored, throwable) -> {
                if (throwable != null) {
                    log.severe(String.format("Failed to send message to Kafka topic %s: %s", "offense_details_topic", throwable.getMessage()));
                } else {
                    log.info("Message sent to Kafka topic offense_details_topic successfully");
                }
            });
        } catch (Exception e) {
            log.warning("Exception occurred while sending message to Kafka");
            throw new RuntimeException("Failed to send message to Kafka", e);
        }
    }

    // 保存违规详情到数据库
    @Transactional
    public void saveOffenseDetails(OffenseDetails offenseDetails) {
        try {
            offenseDetailsMapper.insert(offenseDetails);
            log.info("Offense details saved to database successfully");
            // 同步发送 Kafka 消息
            sendOffenseDetailsToKafka(offenseDetails);
        } catch (Exception e) {
            log.warning("Exception occurred while saving offense details or sending Kafka message");
            throw new RuntimeException("Failed to save offense details", e);
        }
    }
}
