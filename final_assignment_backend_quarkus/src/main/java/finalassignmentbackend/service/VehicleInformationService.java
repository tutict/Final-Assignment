package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.VehicleInformationMapper;
import finalassignmentbackend.entity.VehicleInformation;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.jboss.logging.Logger;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

import java.util.List;

@ApplicationScoped
public class VehicleInformationService {

    private static final Logger log = Logger.getLogger(VehicleInformationService.class);

    @Inject
    VehicleInformationMapper vehicleInformationMapper;

    @Inject
    @Channel("vehicle-events-out")
    Emitter<VehicleInformation> vehicleEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "vehicleCache")
    public void createVehicleInformation(VehicleInformation vehicleInformation) {
        try {
            sendKafkaMessage("vehicle_create", vehicleInformation);
            vehicleInformationMapper.insert(vehicleInformation);
        } catch (Exception e) {
            log.error("Exception occurred while creating vehicle information or sending Kafka message", e);
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
    public void updateVehicleInformation(VehicleInformation vehicleInformation) {
        try {
            sendKafkaMessage("vehicle_update", vehicleInformation);
            vehicleInformationMapper.updateById(vehicleInformation);
        } catch (Exception e) {
            log.error("Exception occurred while updating vehicle information or sending Kafka message", e);
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
            log.error("Exception occurred while deleting vehicle information", e);
            throw new RuntimeException("Failed to delete vehicle information", e);
        }
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
        if (currentStatus == null || currentStatus.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid current status");
        }
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("current_status", currentStatus);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    @Transactional
    @CacheInvalidate(cacheName = "vehicleCache")
    public void deleteVehicleInformationByLicensePlate(String licensePlate) {
        if (licensePlate == null || licensePlate.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid license plate number");
        }
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        vehicleInformationMapper.delete(queryWrapper);
    }

    private void sendKafkaMessage(String topic, VehicleInformation vehicleInformation) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build();
        KafkaRecord<String, VehicleInformation> record = (KafkaRecord<String, VehicleInformation>) KafkaRecord.of(vehicleInformation.getVehicleId().toString(), vehicleInformation).addMetadata(metadata);
        vehicleEmitter.send(record);
        log.info("Message sent to Kafka topic {} successfully");
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }
}
