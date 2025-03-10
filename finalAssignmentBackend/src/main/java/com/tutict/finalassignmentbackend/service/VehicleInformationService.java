package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.VehicleInformationMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.repository.VehicleInformationSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class VehicleInformationService {

    private static final Logger log = Logger.getLogger(VehicleInformationService.class.getName());

    private final VehicleInformationMapper vehicleInformationMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, VehicleInformation> kafkaTemplate;
    private final VehicleInformationSearchRepository vehicleInformationSearchRepository;

    @Autowired
    public VehicleInformationService(VehicleInformationMapper vehicleInformationMapper,
                                     RequestHistoryMapper requestHistoryMapper,
                                     KafkaTemplate<String, VehicleInformation> kafkaTemplate,
                                     VehicleInformationSearchRepository vehicleInformationSearchRepository) {
        this.vehicleInformationMapper = vehicleInformationMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.vehicleInformationSearchRepository = vehicleInformationSearchRepository;
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    @WsAction(service = "VehicleInformationService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, VehicleInformation vehicleInformation, String action) {
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
        } catch (Exception e) {
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        sendKafkaMessage(vehicleInformation, action);

        Integer vehicleId = vehicleInformation.getVehicleId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(vehicleId != null ? vehicleId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    public void createVehicleInformation(VehicleInformation vehicleInformation) {
        try {
            vehicleInformationMapper.insert(vehicleInformation);
            //  vehicleInformationSearchRepository.save(VehicleInformationDocument.fromEntity(vehicleInformation));
            Integer vehicleId = vehicleInformation.getVehicleId();
            log.info(String.format("Vehicle created successfully, vehicleId=%d", vehicleId));
        } catch (Exception e) {
            log.warning("Exception occurred while creating vehicle information: " + e.getMessage());
            throw new RuntimeException("Failed to create vehicle information", e);
        }
    }

    @Cacheable(cacheNames = "vehicleCache", unless = "#result == null")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationById")
    public VehicleInformation getVehicleInformationById(Integer vehicleId) {
        if (vehicleId == null || vehicleId == 0 || vehicleId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid vehicle ID: " + vehicleId);
        }
        return vehicleInformationMapper.selectById(vehicleId); // Returns null if not found
    }

    @Cacheable(cacheNames = "vehicleCache", unless = "#result == null")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByLicensePlate")
    public VehicleInformation getVehicleInformationByLicensePlate(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        // Use selectList instead of selectOne to handle multiple results
        List<VehicleInformation> results = vehicleInformationMapper.selectList(queryWrapper);
        if (results.isEmpty()) {
            return null; // No vehicle found
        } else if (results.size() > 1) {
            // Log warning and return the first result (or throw a custom exception)
            log.log(Level.WARNING, "Multiple vehicles found for license plate: " + licensePlate + ". Returning first result.");
            return results.getFirst();
        }
        return results.getFirst();
    }

    @Cacheable(cacheNames = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getAllVehicleInformation")
    public List<VehicleInformation> getAllVehicleInformation() {
        List<VehicleInformation> result = vehicleInformationMapper.selectList(null);
        return result != null ? result : Collections.emptyList(); // Never returns null
    }

    @Cacheable(cacheNames = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByType")
    public List<VehicleInformation> getVehicleInformationByType(String vehicleType) {
        validateInput(vehicleType, "Invalid vehicle type");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("vehicle_type", vehicleType);
        List<VehicleInformation> result = vehicleInformationMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList(); // Never returns null
    }

    @Cacheable(cacheNames = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByOwnerName")
    public List<VehicleInformation> getVehicleInformationByOwnerName(String ownerName) {
        validateInput(ownerName, "Invalid owner name");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("owner_name", ownerName);
        List<VehicleInformation> result = vehicleInformationMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList(); // Never returns null
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    public void updateVehicleInformation(VehicleInformation vehicleInformation) {
        try {
            vehicleInformationMapper.updateById(vehicleInformation);
            vehicleInformationSearchRepository.save(VehicleInformationDocument.fromEntity(vehicleInformation));
        } catch (Exception e) {
            log.warning("Exception occurred while updating vehicle information: " + e.getMessage());
            throw new RuntimeException("Failed to update vehicle information", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    @WsAction(service = "VehicleInformationService", action = "deleteVehicleInformation")
    public void deleteVehicleInformation(int vehicleId) {
        try {
            vehicleInformationMapper.deleteById(vehicleId);
            log.info(String.format("Vehicle with ID %d deleted successfully", vehicleId));
        } catch (Exception e) {
            log.warning("Exception occurred while deleting vehicle information: " + e.getMessage());
            throw new RuntimeException("Failed to delete vehicle information", e);
        }

        try {
            vehicleInformationSearchRepository.deleteById(vehicleId);
            log.info(String.format("车辆信息从 Elasticsearch 删除成功，ID %d", vehicleId));
        } catch (Exception e) {
            log.warning(String.format("从 Elasticsearch 删除车辆信息失败，ID %d: %s", vehicleId, e.getMessage()));
            // 可选择忽略失败或记录到队列以供后续处理
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    @WsAction(service = "VehicleInformationService", action = "deleteVehicleInformationByLicensePlate")
    public void deleteVehicleInformationByLicensePlate(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        vehicleInformationMapper.delete(queryWrapper);
    }

    @Cacheable(cacheNames = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "isLicensePlateExists")
    public boolean isLicensePlateExists(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        return vehicleInformationMapper.selectCount(queryWrapper) > 0;
    }

    // 使用 Elasticsearch 的搜索方法
    public List<VehicleInformation> searchVehicles(String query, int page, int size) {
        try {
            Page<VehicleInformationDocument> results = vehicleInformationSearchRepository.findByLicensePlateContainingOrVehicleTypeContainingOrOwnerNameContainingOrCurrentStatusContaining(
                    query, query, query, query, PageRequest.of(page - 1, size));
            return results.getContent().stream()
                    .map(VehicleInformationDocument::toEntity)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.severe("搜索车辆失败: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    @Cacheable(cacheNames = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByStatus")
    public List<VehicleInformation> getVehicleInformationByStatus(String currentStatus) {
        validateInput(currentStatus, "Invalid current status");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("current_status", currentStatus);
        List<VehicleInformation> result = vehicleInformationMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList(); // Never returns null
    }

    public void sendKafkaMessage(VehicleInformation vehicleInformation, String action) {
        String topic = "vehicle_" + action.toLowerCase();
        kafkaTemplate.send(topic, vehicleInformation);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }
}