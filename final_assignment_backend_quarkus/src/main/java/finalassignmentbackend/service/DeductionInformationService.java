package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.DeductionInformation;
import finalassignmentbackend.mapper.DeductionInformationMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.mutiny.Uni;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletionStage;
import java.util.logging.Logger;

@ApplicationScoped
public class DeductionInformationService {

    private static final Logger log = Logger.getLogger(DeductionInformationService.class.getName());

    @Inject
    DeductionInformationMapper deductionInformationMapper;

    @Inject
    @Channel("deduction-events-out")
    MutinyEmitter<DeductionInformation> deductionEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "deductionCache")
    public void createDeduction(DeductionInformation deduction) {
        try {
            sendKafkaMessage("deduction_create", deduction);
            deductionInformationMapper.insert(deduction);
        } catch (Exception e) {
            log.warning("Exception occurred while creating deduction or sending Kafka message");
            throw new RuntimeException("Failed to create deduction", e);
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

    @Transactional
    @CacheInvalidate(cacheName = "deductionCache")
    public void updateDeduction(DeductionInformation deduction) {
        try {
            sendKafkaMessage("deduction_update", deduction);
            deductionInformationMapper.updateById(deduction);
        } catch (Exception e) {
            log.warning("Exception occurred while updating deduction or sending Kafka message");
            throw new RuntimeException("Failed to update deduction", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "deductionCache")
    public void deleteDeduction(int deductionId) {
        try {
            int result = deductionInformationMapper.deleteById(deductionId);
            if (result > 0) {
                log.info(String.format("Deduction with ID %s deleted successfully", deductionId));
            } else {
                log.severe(String.format("Failed to delete deduction with ID %s", deductionId));
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting deduction");
            throw new RuntimeException("Failed to delete deduction", e);
        }
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
    public List<DeductionInformation> getDeductionsByByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("deductionTime", startTime, endTime);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, DeductionInformation deduction) {
        // 创建包含目标主题的元数据
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        // 创建包含负载和元数据的消息
        Message<DeductionInformation> message = Message.of(deduction).addMetadata(metadata);

        // 使用 MutinyEmitter 的 sendMessage 方法返回 Uni<Void>
        Uni<Void> uni = deductionEmitter.sendMessage(message);

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
