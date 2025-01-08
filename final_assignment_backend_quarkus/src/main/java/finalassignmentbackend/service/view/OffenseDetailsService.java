package finalassignmentbackend.service.view;

import finalassignmentbackend.entity.RequestHistory;
import finalassignmentbackend.mapper.RequestHistoryMapper;
import finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import finalassignmentbackend.entity.view.OffenseDetails;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Event;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.event.TransactionPhase;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import lombok.Getter;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;

import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class OffenseDetailsService {

    private static final Logger log = Logger.getLogger(OffenseDetailsService.class.getName());

    @Inject
    OffenseDetailsMapper offenseDetailsMapper;

    @Inject
    RequestHistoryMapper requestHistoryMapper;

    @Inject
    Event<OffenseDetailsEvent> offenseDetailsEvent;

    @Inject
    @Channel("offense-details-out")
    MutinyEmitter<OffenseDetails> offenseDetailsEmitter;

    @Getter
    public static class OffenseDetailsEvent {
        private final OffenseDetails offenseDetails;
        private final String action; // "create"

        public OffenseDetailsEvent(OffenseDetails offenseDetails, String action) {
            this.offenseDetails = offenseDetails;
            this.action = action;
        }
    }

    @Transactional
    public void checkAndInsertIdempotency(String idempotencyKey, OffenseDetails offenseDetails, String action) {
        // 查询 request_history
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            // 已有此 key -> 重复请求
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        // 不存在 -> 插入一条 PROCESSING
        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
        } catch (Exception e) {
            // 若并发下同 key 导致唯一索引冲突
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        offenseDetailsEvent.fire(new OffenseDetailsService.OffenseDetailsEvent(offenseDetails, action));

        Integer offenseDetailsId = offenseDetails.getOffenseId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(offenseDetailsId);
        requestHistoryMapper.updateById(newRequest);
    }

    // 获取所有违规详情记录
    public List<OffenseDetails> getAllOffenseDetails() {
        return offenseDetailsMapper.selectList(null);
    }

    // 根据 ID 获取违规详情
    public OffenseDetails getOffenseDetailsById(Integer id) {
        return offenseDetailsMapper.selectById(id);
    }

    // 保存违规详情到数据库
    @Transactional
    public void saveOffenseDetails(OffenseDetails offenseDetails) {
        try {
            offenseDetailsMapper.insert(offenseDetails);
            log.info("Offense details saved to database successfully");
            // 发布事件
        } catch (Exception e) {
            log.warning("Exception occurred while saving offense details or firing event");
            throw new RuntimeException("Failed to save offense details", e);
        }
    }

    // 监听事件并发送 Kafka 消息
    public void onOffenseDetailsEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) OffenseDetailsEvent event) {
        if ("create".equals(event.getAction())) {
            sendKafkaMessage(event.getOffenseDetails());
        }
    }

    // 发送 Kafka 消息
    private void sendKafkaMessage(OffenseDetails offenseDetails) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic("offense_details_topic")
                .build();

        Message<OffenseDetails> message = Message.of(offenseDetails).addMetadata(metadata);

        offenseDetailsEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", "offense_details_topic"));
    }
}
