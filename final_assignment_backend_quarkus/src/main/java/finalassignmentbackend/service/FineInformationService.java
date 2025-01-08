package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.FineInformation;
import finalassignmentbackend.entity.RequestHistory;
import finalassignmentbackend.mapper.FineInformationMapper;
import finalassignmentbackend.mapper.RequestHistoryMapper;
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
public class FineInformationService {

    private static final Logger log = Logger.getLogger(FineInformationService.class.getName());

    @Inject
    FineInformationMapper fineInformationMapper;

    @Inject
    RequestHistoryMapper requestHistoryMapper;

    @Inject
    Event<FineEvent> fineEvent;

    @Inject
    @Channel("fine-events-out")
    MutinyEmitter<FineInformation> fineEmitter;

    @Getter
    public static class FineEvent {
        private final FineInformation fineInformation;
        private final String action; // "create" or "update"

        public FineEvent(FineInformation fineInformation, String action) {
            this.fineInformation = fineInformation;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "fineCache")
    public void checkAndInsertIdempotency(String idempotencyKey, FineInformation fineInformation, String action) {
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

        fineEvent.fire(new FineInformationService.FineEvent(fineInformation, action));

        Integer fireId = fineInformation.getFineId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(fireId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheInvalidate(cacheName = "fineCache")
    public void createFine(FineInformation fineInformation) {
        FineInformation existingFine = fineInformationMapper.selectById(fineInformation.getFineId());
        if (existingFine == null) {
            fineInformationMapper.insert(fineInformation);
        } else {
            fineInformationMapper.updateById(fineInformation);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "fineCache")
    public void updateFine(FineInformation fineInformation) {
        FineInformation existingFine = fineInformationMapper.selectById(fineInformation.getFineId());
        if (existingFine == null) {
            fineInformationMapper.insert(fineInformation);
        } else {
            fineInformationMapper.updateById(fineInformation);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "fineCache")
    public void deleteFine(int fineId) {
        if (fineId <= 0) {
            throw new IllegalArgumentException("Invalid fine ID");
        }
        int result = fineInformationMapper.deleteById(fineId);
        if (result > 0) {
            log.info(String.format("Fine with ID %s deleted successfully", fineId));
        } else {
            log.severe(String.format("Failed to delete fine with ID %s", fineId));
        }
    }

    @CacheResult(cacheName = "fineCache")
    public FineInformation getFineById(int fineId) {
        if (fineId <= 0) {
            throw new IllegalArgumentException("Invalid fine ID");
        }
        return fineInformationMapper.selectById(fineId);
    }

    @CacheResult(cacheName = "fineCache")
    public List<FineInformation> getAllFines() {
        return fineInformationMapper.selectList(null);
    }

    @CacheResult(cacheName = "fineCache")
    public List<FineInformation> getFinesByPayee(String payee) {
        if (payee == null || payee.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid payee");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("payee", payee);
        return fineInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "fineCache")
    public List<FineInformation> getFinesByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("fineTime", startTime, endTime);
        return fineInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "fineCache")
    public FineInformation getFineByReceiptNumber(String receiptNumber) {
        if (receiptNumber == null || receiptNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid receipt number");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("receiptNumber", receiptNumber);
        return fineInformationMapper.selectOne(queryWrapper);
    }

    public void onFineEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) FineEvent event) {
        String topic = event.getAction().equals("create") ? "fine_processed_create" : "fine_processed_update";
        sendKafkaMessage(topic, event.getFineInformation());
    }

    private void sendKafkaMessage(String topic, FineInformation fineInformation) {
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<FineInformation> message = Message.of(fineInformation).addMetadata(metadata);

        fineEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
