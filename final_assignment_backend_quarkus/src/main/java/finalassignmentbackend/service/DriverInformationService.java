package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.DriverInformation;
import finalassignmentbackend.mapper.DriverInformationMapper;
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
public class DriverInformationService {

    private static final Logger log = Logger.getLogger(DriverInformationService.class.getName());

    @Inject
    DriverInformationMapper driverInformationMapper;

    @Inject
    Event<DriverEvent> driverEvent;

    @Inject
    @Channel("driver-events-out")
    MutinyEmitter<DriverInformation> driverEmitter;

    @Getter
    public static class DriverEvent {
        private final DriverInformation driverInformation;
        private final String action; // "create" or "update"

        public DriverEvent(DriverInformation driverInformation, String action) {
            this.driverInformation = driverInformation;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    public void createDriver(DriverInformation driverInformation) {
        DriverInformation existingDriver = driverInformationMapper.selectById(driverInformation.getDriverId());
        if (existingDriver == null) {
            driverInformationMapper.insert(driverInformation);
        } else {
            driverInformationMapper.updateById(driverInformation);
        }
        driverEvent.fire(new DriverEvent(driverInformation, "create"));
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    public void updateDriver(DriverInformation driverInformation) {
        DriverInformation existingDriver = driverInformationMapper.selectById(driverInformation.getDriverId());
        if (existingDriver == null) {
            driverInformationMapper.insert(driverInformation);
        } else {
            driverInformationMapper.updateById(driverInformation);
        }
        driverEvent.fire(new DriverEvent(driverInformation, "update"));
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    public void deleteDriver(int driverId) {
        if (driverId <= 0) {
            throw new IllegalArgumentException("Invalid driver ID");
        }
        int result = driverInformationMapper.deleteById(driverId);
        if (result > 0) {
            log.info(String.format("Driver with ID %s deleted successfully", driverId));
        } else {
            log.severe(String.format("Failed to delete driver with ID %s", driverId));
        }
    }

    @CacheResult(cacheName = "driverCache")
    public DriverInformation getDriverById(int driverId) {
        if (driverId <= 0) {
            throw new IllegalArgumentException("Invalid driver ID");
        }
        return driverInformationMapper.selectById(driverId);
    }

    @CacheResult(cacheName = "driverCache")
    public List<DriverInformation> getAllDrivers() {
        return driverInformationMapper.selectList(null);
    }

    @CacheResult(cacheName = "driverCache")
    public List<DriverInformation> getDriversByIdCardNumber(String idCardNumber) {
        if (idCardNumber == null || idCardNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid ID card number");
        }
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("id_card_number", idCardNumber);
        return driverInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "driverCache")
    public DriverInformation getDriverByDriverLicenseNumber(String driverLicenseNumber) {
        if (driverLicenseNumber == null || driverLicenseNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid driver license number");
        }
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_license_number", driverLicenseNumber);
        return driverInformationMapper.selectOne(queryWrapper);
    }

    @CacheResult(cacheName = "driverCache")
    public List<DriverInformation> getDriversByName(String name) {
        if (name == null || name.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid name");
        }
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("name", name);
        return driverInformationMapper.selectList(queryWrapper);
    }

    public void onDriverEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) DriverEvent event) {
        String topic = event.getAction().equals("create") ? "driver_processed_create" : "driver_processed_update";
        sendKafkaMessage(topic, event.getDriverInformation());
    }

    private void sendKafkaMessage(String topic, DriverInformation driverInformation) {
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<DriverInformation> message = Message.of(driverInformation).addMetadata(metadata);

        driverEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
