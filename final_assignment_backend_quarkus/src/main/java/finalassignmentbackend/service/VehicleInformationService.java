package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.VehicleInformation;
import finalassignmentbackend.mapper.VehicleInformationMapper;
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
public class VehicleInformationService {

    private static final Logger log = Logger.getLogger(VehicleInformationService.class.getName());

    @Inject
    VehicleInformationMapper vehicleInformationMapper;

    @Inject
    Event<VehicleEvent> vehicleEvent;

    @Inject
    @Channel("vehicle-events-out")
    MutinyEmitter<VehicleInformation> vehicleEmitter;

    @Getter
    public static class VehicleEvent {
        private final VehicleInformation vehicleInformation;
        private final String action; // "create" or "update"

        public VehicleEvent(VehicleInformation vehicleInformation, String action) {
            this.vehicleInformation = vehicleInformation;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "vehicleCache")
    public void createVehicleInformation(VehicleInformation vehicleInformation) {
        try {
            vehicleInformationMapper.insert(vehicleInformation);
            vehicleEvent.fire(new VehicleEvent(vehicleInformation, "create"));
        } catch (Exception e) {
            log.warning("Exception occurred while creating vehicle information or firing event");
            throw new RuntimeException("Failed to create vehicle information", e);
        }
    }

    @CacheResult(cacheName = "vehicleCache")
    public VehicleInformation getVehicleInformationById(int vehicleId) {
        return vehicleInformationMapper.selectById(vehicleId);
    }

    @CacheResult(cacheName = "vehicleCache")
    public VehicleInformation getVehicleInformationByLicensePlate(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        return vehicleInformationMapper.selectOne(queryWrapper);
    }

    @CacheResult(cacheName = "vehicleCache")
    public List<VehicleInformation> getAllVehicleInformation() {
        return vehicleInformationMapper.selectList(null);
    }

    @CacheResult(cacheName = "vehicleCache")
    public List<VehicleInformation> getVehicleInformationByType(String vehicleType) {
        validateInput(vehicleType, "Invalid vehicle type");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("vehicle_type", vehicleType);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "vehicleCache")
    public List<VehicleInformation> getVehicleInformationByOwnerName(String ownerName) {
        validateInput(ownerName, "Invalid owner name");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("owner_name", ownerName);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    @Transactional
    @CacheInvalidate(cacheName = "vehicleCache")
    public VehicleInformation updateVehicleInformation(VehicleInformation vehicleInformation) {
        try {
            vehicleInformationMapper.updateById(vehicleInformation);
            vehicleEvent.fire(new VehicleEvent(vehicleInformation, "update"));
            return vehicleInformation;
        } catch (Exception e) {
            log.warning("Exception occurred while updating vehicle information or firing event");
            throw new RuntimeException("Failed to update vehicle information", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "vehicleCache")
    public void deleteVehicleInformation(int vehicleId) {
        try {
            VehicleInformation vehicleToDelete = vehicleInformationMapper.selectById(vehicleId);
            if (vehicleToDelete != null) {
                vehicleInformationMapper.deleteById(vehicleId);
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting vehicle information");
            throw new RuntimeException("Failed to delete vehicle information", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "vehicleCache")
    public void deleteVehicleInformationByLicensePlate(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        vehicleInformationMapper.delete(queryWrapper);
    }

    @CacheResult(cacheName = "vehicleCache")
    public boolean isLicensePlateExists(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        return vehicleInformationMapper.selectCount(queryWrapper) > 0;
    }

    @CacheResult(cacheName = "vehicleCache")
    public List<VehicleInformation> getVehicleInformationByStatus(String currentStatus) {
        validateInput(currentStatus, "Invalid current status");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("current_status", currentStatus);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    public void onVehicleEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) VehicleEvent event) {
        String topic = event.getAction().equals("create") ? "vehicle_create" : "vehicle_update";
        sendKafkaMessage(topic, event.getVehicleInformation());
    }

    private void sendKafkaMessage(String topic, VehicleInformation vehicleInformation) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<VehicleInformation> message = Message.of(vehicleInformation).addMetadata(metadata);

        vehicleEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }
}
