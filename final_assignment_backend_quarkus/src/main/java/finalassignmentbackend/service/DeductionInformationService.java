package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.DeductionInformation;
import finalassignmentbackend.mapper.DeductionInformationMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Event;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.event.TransactionPhase;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import lombok.Getter;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class DeductionInformationService {

    private static final Logger log = Logger.getLogger(DeductionInformationService.class.getName());

    @Inject
    DeductionInformationMapper deductionInformationMapper;

    @Inject
    Event<DeductionEvent> deductionEvent;

    @Inject
    @Channel("deduction-events-out")
    MutinyEmitter<DeductionInformation> deductionEmitter;

    @Getter
    public static class DeductionEvent {
        private final DeductionInformation deductionInformation;
        private final String action; // "create" or "update"

        public DeductionEvent(DeductionInformation deductionInformation, String action) {
            this.deductionInformation = deductionInformation;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "deductionCache")
    public void createDeduction(DeductionInformation deduction) {
        DeductionInformation existingDeduction = deductionInformationMapper.selectById(deduction.getDeductionId());
        if (existingDeduction == null) {
            deductionInformationMapper.insert(deduction);
        } else {
            deductionInformationMapper.updateById(deduction);
        }
        deductionEvent.fire(new DeductionEvent(deduction, "create"));
    }

    @Transactional
    @CacheInvalidate(cacheName = "deductionCache")
    public void updateDeduction(DeductionInformation deduction) {
        DeductionInformation existingDeduction = deductionInformationMapper.selectById(deduction.getDeductionId());
        if (existingDeduction == null) {
            deductionInformationMapper.insert(deduction);
        } else {
            deductionInformationMapper.updateById(deduction);
        }
        deductionEvent.fire(new DeductionEvent(deduction, "update"));
    }

    @Transactional
    @CacheInvalidate(cacheName = "deductionCache")
    public void deleteDeduction(int deductionId) {
        if (deductionId <= 0) {
            throw new IllegalArgumentException("Invalid deduction ID");
        }
        int result = deductionInformationMapper.deleteById(deductionId);
        if (result > 0) {
            log.info(String.format("Deduction with ID %s deleted successfully", deductionId));
        } else {
            log.severe(String.format("Failed to delete deduction with ID %s", deductionId));
        }
    }

    @CacheResult(cacheName = "deductionCache")
    public DeductionInformation getDeductionById(int deductionId) {
        if (deductionId <= 0) {
            throw new IllegalArgumentException("Invalid deduction ID");
        }
        return deductionInformationMapper.selectById(deductionId);
    }

    @CacheResult(cacheName = "deductionCache")
    public List<DeductionInformation> getAllDeductions() {
        return deductionInformationMapper.selectList(null);
    }

    @CacheResult(cacheName = "deductionCache")
    public List<DeductionInformation> getDeductionsByHandler(String handler) {
        if (handler == null || handler.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid handler");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("handler", handler);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "deductionCache")
    public List<DeductionInformation> getDeductionsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("deduction_time", startTime, endTime);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    public void onDeductionEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) DeductionEvent event) {
        String topic = event.getAction().equals("create") ? "deduction_processed_create" : "deduction_processed_update";
        sendKafkaMessage(topic, event.getDeductionInformation());
    }

    private void sendKafkaMessage(String topic, DeductionInformation deduction) {
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<DeductionInformation> message = Message.of(deduction).addMetadata(metadata);

        deductionEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
