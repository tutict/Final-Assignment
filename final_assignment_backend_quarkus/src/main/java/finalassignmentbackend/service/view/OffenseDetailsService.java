package finalassignmentbackend.service.view;

import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import finalassignmentbackend.entity.view.OffenseDetails;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.jboss.logging.Logger;

import java.util.List;

@ApplicationScoped
public class OffenseDetailsService {

    private static final Logger log = Logger.getLogger(OffenseDetailsService.class);

    @Inject
    OffenseDetailsMapper offenseDetailsMapper;

    @Inject
    @Channel("offense-details-out")
    Emitter<OffenseDetails> offenseDetailsEmitter;

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
            var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic("offense_details_topic").build();
            KafkaRecord<String, OffenseDetails> record = (KafkaRecord<String, OffenseDetails>) KafkaRecord.of(offenseDetails.getOffenseId().toString(), offenseDetails).addMetadata(metadata);
            offenseDetailsEmitter.send(record);
            log.info("Message sent to Kafka successfully");
        } catch (Exception e) {
            log.error("Exception occurred while sending message to Kafka", e);
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
            log.error("Exception occurred while saving offense details or sending Kafka message", e);
            throw new RuntimeException("Failed to save offense details", e);
        }
    }
}
