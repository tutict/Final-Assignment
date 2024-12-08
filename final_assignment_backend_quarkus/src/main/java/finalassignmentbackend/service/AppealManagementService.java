package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.AppealManagementMapper;
import finalassignmentbackend.mapper.OffenseInformationMapper;
import finalassignmentbackend.entity.AppealManagement;
import finalassignmentbackend.entity.OffenseInformation;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.mutiny.Uni;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Channel;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.List;
import java.util.concurrent.CompletionStage;
import java.util.logging.Logger;

@ApplicationScoped
public class AppealManagementService {

    private static final Logger log = Logger.getLogger(AppealManagementService.class.getName());

    @Inject
    AppealManagementMapper appealManagementMapper;

    @Inject
    OffenseInformationMapper offenseInformationMapper;

    @Inject
    @Channel("appeal-events-out")
    MutinyEmitter<AppealManagement> appealEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public void createAppeal(AppealManagement appeal) {
        try {
            appealManagementMapper.insert(appeal);
            sendKafkaMessage("appeal_create", appeal);
        } catch (Exception e) {
            log.warning("Exception occurred while creating appeal or sending Kafka message");
            throw new RuntimeException("Failed to create appeal", e);
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

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public void updateAppeal(AppealManagement appeal) {
        try {
            appealManagementMapper.updateById(appeal);
            sendKafkaMessage("appeal_updated", appeal);
        } catch (Exception e) {
            log.warning("Exception occurred while updating appeal or sending Kafka message");
            throw new RuntimeException("Failed to update appeal", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public void deleteAppeal(Integer appealId) {
        try {
            AppealManagement appeal = appealManagementMapper.selectById(appealId);
            if (appeal == null) {
                log.warning(String.format("Appeal with ID %s not found, cannot delete", appealId));
                return;
            }
            int result = appealManagementMapper.deleteById(appealId);
            if (result > 0) {
                log.info(String.format("Appeal with ID %s deleted successfully", appealId));
            } else {
                log.severe(String.format("Failed to delete appeal with ID %s", appealId));
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting appeal");
            throw new RuntimeException("Failed to delete appeal", e);
        }
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealManagement> getAppealsByProcessStatus(String processStatus) {
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processStatus);
        return appealManagementMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealManagement> getAppealsByAppealName(String appealName) {
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

    private void sendKafkaMessage(String topic, AppealManagement appeal) {
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<AppealManagement> message = Message.of(appeal).addMetadata(metadata);

        // 使用 MutinyEmitter 的 sendMessage 方法返回 Uni<Void>
        Uni<Void> uni = appealEmitter.sendMessage(message);

        // 将 Uni<Void> 转换为 CompletionStage<Void>
        CompletionStage<Void> sendStage = uni.subscribe().asCompletionStage();

        sendStage.whenComplete((ignored, throwable) -> {
            if (throwable != null) {
                log.severe(String.format("Failed to send message to Kafka topic %s: %s", topic, throwable.getMessage()));
            } else {
                log.info(String.format("Message sent to Kafka topic %s successfully", topic));
            }
        });
    }
}
