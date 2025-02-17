package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.VehicleInformationMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.logging.Logger;

@Service
public class VehicleInformationService {

    private static final Logger log = Logger.getLogger(VehicleInformationService.class.getName());

    private final VehicleInformationMapper vehicleInformationMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, VehicleInformation> kafkaTemplate;

    @Autowired
    public VehicleInformationService(VehicleInformationMapper vehicleInformationMapper,
                                     RequestHistoryMapper requestHistoryMapper,
                                     KafkaTemplate<String, VehicleInformation> kafkaTemplate) {
        this.vehicleInformationMapper = vehicleInformationMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    public void checkAndInsertIdempotency(String idempotencyKey, VehicleInformation vehicleInformation, String action) {
        // Query request_history
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        // Insert a "PROCESSING" status if not found
        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
        } catch (Exception e) {
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        // Notify Kafka or local events to create the vehicle information
        sendKafkaMessage(vehicleInformation, action);

        Integer vehicleId = vehicleInformation.getVehicleId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(vehicleId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    public void createVehicleInformation(VehicleInformation vehicleInformation) {
        try {
            vehicleInformationMapper.insert(vehicleInformation);
            Integer vehicleId = vehicleInformation.getVehicleId();
            log.info(String.format("Vehicle created successfully, vehicleId=%d", vehicleId));
        } catch (Exception e) {
            log.warning("Exception occurred while creating vehicle information: " + e.getMessage());
            throw new RuntimeException("Failed to create vehicle information", e);
        }
    }

    @Cacheable(cacheNames = "vehicleCache")
    public VehicleInformation getVehicleInformationById(Integer vehicleId) {
        if (vehicleId == null || vehicleId == 0 || vehicleId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid vehicle ID" + vehicleId);
        }
        return vehicleInformationMapper.selectById(vehicleId);
    }

    @Cacheable(cacheNames = "vehicleCache")
    public VehicleInformation getVehicleInformationByLicensePlate(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        return vehicleInformationMapper.selectByLicensePlate(licensePlate);
    }

    @Cacheable(cacheNames = "vehicleCache")
    public List<VehicleInformation> getAllVehicleInformation() {
        return vehicleInformationMapper.selectList(null);
    }

    @Cacheable(cacheNames = "vehicleCache")
    public List<VehicleInformation> getVehicleInformationByType(String vehicleType) {
        validateInput(vehicleType, "Invalid vehicle type");
        return vehicleInformationMapper.selectByType(vehicleType);
    }

    @Cacheable(cacheNames = "vehicleCache")
    public List<VehicleInformation> getVehicleInformationByOwnerName(String ownerName) {
        validateInput(ownerName, "Invalid owner name");
        return vehicleInformationMapper.selectByOwnerName(ownerName);
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    public void updateVehicleInformation(VehicleInformation vehicleInformation) {
        try {
            vehicleInformationMapper.updateById(vehicleInformation);
        } catch (Exception e) {
            log.warning("Exception occurred while updating vehicle information: " + e.getMessage());
            throw new RuntimeException("Failed to update vehicle information", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    public void deleteVehicleInformation(int vehicleId) {
        try {
            vehicleInformationMapper.deleteById(vehicleId);
            log.info(String.format("Vehicle with ID %d deleted successfully", vehicleId));
        } catch (Exception e) {
            log.warning("Exception occurred while deleting vehicle information: " + e.getMessage());
            throw new RuntimeException("Failed to delete vehicle information", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    public void deleteVehicleInformationByLicensePlate(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        vehicleInformationMapper.deleteByLicensePlate(licensePlate);
    }

    @Cacheable(cacheNames = "vehicleCache")
    public boolean isLicensePlateExists(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        return vehicleInformationMapper.selectCountByLicensePlate(licensePlate) > 0;
    }

    @Cacheable(cacheNames = "vehicleCache")
    public List<VehicleInformation> getVehicleInformationByStatus(String currentStatus) {
        validateInput(currentStatus, "Invalid current status");
        return vehicleInformationMapper.selectByStatus(currentStatus);
    }

    public void sendKafkaMessage(VehicleInformation vehicleInformation, String action) {
        String topic = action.equals("create") ? "vehicle_create" : "vehicle_update";
        kafkaTemplate.send(topic, vehicleInformation);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }
}