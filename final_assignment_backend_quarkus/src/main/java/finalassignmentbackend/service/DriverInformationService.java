package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.DriverInformation;
import finalassignmentbackend.mapper.DriverInformationMapper;
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

import java.util.List;
import java.util.concurrent.CompletionStage;
import java.util.logging.Logger;

@ApplicationScoped
public class DriverInformationService {

    private static final Logger log = Logger.getLogger(DriverInformationService.class.getName());

    @Inject
    DriverInformationMapper driverInformationMapper;

    @Inject
    @Channel("driver-events-out")
    MutinyEmitter<DriverInformation> driverEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    public void createDriver(DriverInformation driverInformation) {
        try {
            sendKafkaMessage("driver_create", driverInformation);
            driverInformationMapper.insert(driverInformation);
        } catch (Exception e) {
            log.warning("Exception occurred while creating driver or sending Kafka message");
            throw new RuntimeException("Failed to create driver", e);
        }
    }

    @CacheResult(cacheName = "driverCache")
    public DriverInformation getDriverById(int driverId) {
        return driverInformationMapper.selectById(driverId);
    }

    @CacheResult(cacheName = "driverCache")
    public List<DriverInformation> getAllDrivers() {
        return driverInformationMapper.selectList(null);
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    public void updateDriver(DriverInformation driverInformation) {
        try {
            sendKafkaMessage("driver_update", driverInformation);
            driverInformationMapper.updateById(driverInformation);
        } catch (Exception e) {
            log.warning("Exception occurred while updating driver or sending Kafka message");
            throw new RuntimeException("Failed to update driver", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    public void deleteDriver(int driverId) {
        try {
            int result = driverInformationMapper.deleteById(driverId);
            if (result > 0) {
                log.info(String.format("Driver with ID %s deleted successfully", driverId));
            } else {
                log.severe(String.format("Failed to delete driver with ID %s", driverId));
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting driver");
            throw new RuntimeException("Failed to delete driver", e);
        }
    }

    @CacheResult(cacheName = "driverCache")
    public List<DriverInformation> getDriversByIdCardNumber(String idCardNumber) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("id_card_number", idCardNumber);
        return driverInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "driverCache")
    public DriverInformation getDriverByDriverLicenseNumber(String driverLicenseNumber) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_license_number", driverLicenseNumber);
        return driverInformationMapper.selectOne(queryWrapper);
    }

    @CacheResult(cacheName = "driverCache")
    public List<DriverInformation> getDriversByName(String name) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("name", name);
        return driverInformationMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, DriverInformation driverInformation) {
        // 创建包含目标主题的元数据
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        // 创建包含负载和元数据的消息
        Message<DriverInformation> message = Message.of(driverInformation).addMetadata(metadata);

        // 使用 MutinyEmitter 的 sendMessage 方法返回 Uni<Void>
        Uni<Void> uni = driverEmitter.sendMessage(message);

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
