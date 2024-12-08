package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.OffenseInformation;
import finalassignmentbackend.mapper.OffenseInformationMapper;
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
public class OffenseInformationService {

    private static final Logger log = Logger.getLogger(OffenseInformationService.class.getName());

    @Inject
    OffenseInformationMapper offenseInformationMapper;

    @Inject
    @Channel("offense-events-out")
    MutinyEmitter<OffenseInformation> offenseEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "offenseCache")
    public void createOffense(OffenseInformation offenseInformation) {
        try {
            sendKafkaMessage("offense_create", offenseInformation);
            offenseInformationMapper.insert(offenseInformation);
        } catch (Exception e) {
            log.warning("Exception occurred while creating offense or sending Kafka message");
            throw new RuntimeException("Failed to create offense", e);
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

    @Transactional
    @CacheInvalidate(cacheName = "offenseCache")
    public void updateOffense(OffenseInformation offenseInformation) {
        try {
            sendKafkaMessage("offense_update", offenseInformation);
            offenseInformationMapper.updateById(offenseInformation);
        } catch (Exception e) {
            log.warning("Exception occurred while updating offense or sending Kafka message");
            throw new RuntimeException("Failed to update offense", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseCache")
    public void deleteOffense(int offenseId) {
        try {
            if (offenseId <= 0) {
                throw new IllegalArgumentException("Invalid offense ID");
            }
            int result = offenseInformationMapper.deleteById(offenseId);
            if (result > 0) {
                log.info(String.format("Offense with ID %s deleted successfully", offenseId));
            } else {
                log.severe(String.format("Failed to delete offense with ID %s", offenseId));
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting offense");
            throw new RuntimeException("Failed to delete offense", e);
        }
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

    private void sendKafkaMessage(String topic, OffenseInformation offenseInformation) {
        // 创建包含目标主题的元数据
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        // 创建包含负载和元数据的消息
        Message<OffenseInformation> message = Message.of(offenseInformation).addMetadata(metadata);

        // 使用 MutinyEmitter 的 sendMessage 方法返回 Uni<Void>
        Uni<Void> uni = offenseEmitter.sendMessage(message);

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
