package finalassignmentbackend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import finalassignmentbackend.entity.OffenseRecord;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Offense 领域的 Kafka 生产者。将治理后的命令回灌到 Quarkus 监听器消费的
 * {@code offense_create} / {@code offense_update} 主题，形成
 * HTTP 请求 → Kafka 命令 → 监听器治理落库 的闭环（对齐 Spring 的 service 层 Kafka 发布）。
 *
 * <p>出站通道需在配置中声明（application.properties）：
 * <pre>
 * mp.messaging.outgoing.offense-create-out.connector=smallrye-kafka
 * mp.messaging.outgoing.offense-create-out.topic=offense_create
 * mp.messaging.outgoing.offense-update-out.connector=smallrye-kafka
 * mp.messaging.outgoing.offense-update-out.topic=offense_update
 * </pre>
 */
@ApplicationScoped
public class OffenseKafkaProducer {

    private static final Logger log = Logger.getLogger(OffenseKafkaProducer.class.getName());

    @Inject
    @Channel("offense-create-out")
    Emitter<String> createEmitter;

    @Inject
    @Channel("offense-update-out")
    Emitter<String> updateEmitter;

    @Inject
    ObjectMapper objectMapper;

    public void sendCreate(String key, OffenseRecord record) {
        send(createEmitter, "offense_create", key, record);
    }

    public void sendUpdate(String key, OffenseRecord record) {
        send(updateEmitter, "offense_update", key, record);
    }

    private void send(Emitter<String> emitter, String topic, String key, OffenseRecord record) {
        try {
            String payload = objectMapper.writeValueAsString(record);
            Message<String> message = Message.of(payload);
            if (key != null && !key.isBlank()) {
                message = message.addMetadata(OutgoingKafkaRecordMetadata.<String>builder()
                        .withKey(key)
                        .build());
            }
            emitter.send(message);
            log.log(Level.FINE, "Published OffenseRecord event to {0}", topic);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to publish OffenseRecord Kafka message to " + topic, ex);
            throw new RuntimeException("Failed to send OffenseRecord event", ex);
        }
    }
}
