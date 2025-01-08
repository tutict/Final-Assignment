package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.AppealManagement;
import finalassignmentbackend.entity.OffenseInformation;
import finalassignmentbackend.entity.RequestHistory;
import finalassignmentbackend.mapper.AppealManagementMapper;
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

import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class AppealManagementService {

    private static final Logger log = Logger.getLogger(AppealManagementService.class.getName());

    @Inject
    AppealManagementMapper appealManagementMapper;

    @Inject
    RequestHistoryMapper requestHistoryMapper;

    @Inject
    OffenseInformationMapper offenseInformationMapper;

    @Inject
    Event<AppealEvent> appealEvent;

    @Inject
    @Channel("appeal-events-out")
    MutinyEmitter<AppealManagement> appealEmitter;

    @Getter
    public static class AppealEvent {
        private final AppealManagement appealManagement;
        private final String action; // "create" or "update"

        public AppealEvent(AppealManagement appealManagement, String action) {
            this.appealManagement = appealManagement;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public void checkAndInsertIdempotency(String idempotencyKey, AppealManagement appealManagement, String action) {
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

        appealEvent.fire(new AppealManagementService.AppealEvent(appealManagement, action));

        Integer appealId = appealManagement.getAppealId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(appealId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public void createAppeal(AppealManagement appeal) {
        AppealManagement existingAppeal = appealManagementMapper.selectById(appeal.getAppealId());
        if (existingAppeal == null) {
            appealManagementMapper.insert(appeal);
        } else {
            appealManagementMapper.updateById(appeal);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public void updateAppeal(AppealManagement appeal) {
        AppealManagement existingAppeal = appealManagementMapper.selectById(appeal.getAppealId());
        if (existingAppeal == null) {
            appealManagementMapper.insert(appeal);
        } else {
            appealManagementMapper.updateById(appeal);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public void deleteAppeal(Integer appealId) {
        if (appealId == null || appealId <= 0) {
            throw new IllegalArgumentException("Invalid appeal ID");
        }
        int result = appealManagementMapper.deleteById(appealId);
        if (result > 0) {
            log.info(String.format("Appeal with ID %s deleted successfully", appealId));
        } else {
            log.severe(String.format("Failed to delete appeal with ID %s", appealId));
        }
    }

    @CacheResult(cacheName = "appealCache")
    public AppealManagement getAppealById(Integer appealId) {
        return appealManagementMapper.selectById(appealId);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealManagement> getAllAppeals() {
        return appealManagementMapper.selectList(null);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealManagement> getAppealsByProcessStatus(String processStatus) {
        if (processStatus == null || processStatus.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid process status");
        }
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processStatus);
        return appealManagementMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealManagement> getAppealsByAppealName(String appealName) {
        if (appealName == null || appealName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid appeal name");
        }
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("appeal_name", appealName);
        return appealManagementMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "appealCache")
    public OffenseInformation getOffenseByAppealId(Integer appealId) {
        AppealManagement appeal = appealManagementMapper.selectById(appealId);
        if (appeal != null) {
            return offenseInformationMapper.selectById(appeal.getOffenseId());
        } else {
            log.warning(String.format("No appeal found with ID: %s", appealId));
            return null;
        }
    }

    public void onAppealEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) AppealEvent event) {
        String topic = event.getAction().equals("create") ? "appeal_processed_create" : "appeal_processed_update";
        sendKafkaMessage(topic, event.getAppealManagement());
    }

    private void sendKafkaMessage(String topic, AppealManagement appeal) {
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<AppealManagement> message = Message.of(appeal).addMetadata(metadata);

        appealEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
