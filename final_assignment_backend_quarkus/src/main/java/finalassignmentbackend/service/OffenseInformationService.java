package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.OffenseInformation;
import finalassignmentbackend.entity.RequestHistory;
import finalassignmentbackend.mapper.OffenseInformationMapper;
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
public class OffenseInformationService {

    private static final Logger log = Logger.getLogger(OffenseInformationService.class.getName());

    @Inject
    OffenseInformationMapper offenseInformationMapper;

    @Inject
    RequestHistoryMapper requestHistoryMapper;

    @Inject
    Event<OffenseEvent> offenseEvent;

    @Inject
    @Channel("offense-events-out")
    MutinyEmitter<OffenseInformation> offenseEmitter;

    @Getter
    public static class OffenseEvent {
        private final OffenseInformation offenseInformation;
        private final String action; // "create" or "update"

        public OffenseEvent(OffenseInformation offenseInformation, String action) {
            this.offenseInformation = offenseInformation;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseCache")
    public void checkAndInsertIdempotency(String idempotencyKey, OffenseInformation offenseInformation, String action) {
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

        offenseEvent.fire(new OffenseInformationService.OffenseEvent(offenseInformation, action));

        Integer offenseId = offenseInformation.getOffenseId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(offenseId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseCache")
    public void createOffense(OffenseInformation offenseInformation) {
        OffenseInformation existingOffense = offenseInformationMapper.selectById(offenseInformation.getOffenseId());
        if (existingOffense == null) {
            offenseInformationMapper.insert(offenseInformation);
        } else {
            offenseInformationMapper.updateById(offenseInformation);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseCache")
    public void updateOffense(OffenseInformation offenseInformation) {
        OffenseInformation existingOffense = offenseInformationMapper.selectById(offenseInformation.getOffenseId());
        if (existingOffense == null) {
            offenseInformationMapper.insert(offenseInformation);
        } else {
            offenseInformationMapper.updateById(offenseInformation);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseCache")
    public void deleteOffense(int offenseId) {
        if (offenseId <= 0) {
            throw new IllegalArgumentException("Invalid offense ID");
        }
        int result = offenseInformationMapper.deleteById(offenseId);
        if (result > 0) {
            log.info(String.format("Offense with ID %s deleted successfully", offenseId));
        } else {
            log.severe(String.format("Failed to delete offense with ID %s", offenseId));
        }
    }

    @CacheResult(cacheName = "offenseCache")
    public OffenseInformation getOffenseByOffenseId(int offenseId) {
        return offenseInformationMapper.selectById(offenseId);
    }

    @CacheResult(cacheName = "offenseCache")
    public List<OffenseInformation> getOffensesInformation() {
        return offenseInformationMapper.selectList(null);
    }

    @CacheResult(cacheName = "offenseCache")
    public List<OffenseInformation> getOffensesByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("offense_time", startTime, endTime);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "offenseCache")
    public List<OffenseInformation> getOffensesByProcessState(String processState) {
        if (processState == null || processState.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid process state");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processState);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "offenseCache")
    public List<OffenseInformation> getOffensesByDriverName(String driverName) {
        if (driverName == null || driverName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid driver name");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_name", driverName);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "offenseCache")
    public List<OffenseInformation> getOffensesByLicensePlate(String offenseLicensePlate) {
        if (offenseLicensePlate == null || offenseLicensePlate.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid license plate");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", offenseLicensePlate);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    // 不使用 @RunOnVirtualThread 这里，因为是事件观察器方法，不是入口点
    public void onOffenseEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) OffenseEvent event) {
        // 发往不同主题，避免回环
        String topic = event.getAction().equals("create") ? "offense_processed_create" : "offense_processed_update";
        sendKafkaMessage(topic, event.getOffenseInformation());
    }

    private void sendKafkaMessage(String topic, OffenseInformation offenseInformation) {
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<OffenseInformation> message = Message.of(offenseInformation).addMetadata(metadata);

        // 同步等待发送完成（此时无事务竞争问题）
        offenseEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
