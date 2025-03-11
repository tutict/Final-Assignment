package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.entity.elastic.DriverInformationDocument;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.mapper.DriverInformationMapper;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.UserManagementMapper;
import com.tutict.finalassignmentbackend.repository.DriverInformationSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@Service
public class DriverInformationService {

    private static final Logger log = Logger.getLogger(DriverInformationService.class.getName());

    private final DriverInformationMapper driverInformationMapper;
    private final UserManagementMapper userManagementMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, DriverInformation> kafkaTemplate;
    private final DriverInformationSearchRepository driverInformationSearchRepository;

    @Autowired
    public DriverInformationService(
            DriverInformationMapper driverInformationMapper,
            UserManagementMapper userManagementMapper,
            RequestHistoryMapper requestHistoryMapper,
            KafkaTemplate<String, DriverInformation> kafkaTemplate,
            DriverInformationSearchRepository driverInformationSearchRepository) {
        this.driverInformationMapper = driverInformationMapper;
        this.userManagementMapper = userManagementMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.driverInformationSearchRepository = driverInformationSearchRepository;
    }

    @Transactional
    @CacheEvict(cacheNames = "driverCache", allEntries = true)
    @WsAction(service = "DriverInformationService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, DriverInformation driverInformation, String action) {
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

        sendKafkaMessage("driver_" + action, driverInformation);

        if ("create".equals(action)) {
            createDriver(driverInformation);
        } else if ("update".equals(action)) {
            updateDriver(driverInformation);
        }

        Integer driverId = driverInformation.getDriverId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(driverId != null ? driverId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "driverCache", allEntries = true)
    public void createDriver(DriverInformation driverInformation) {
        if (driverInformation == null) {
            throw new IllegalArgumentException("Driver information cannot be null");
        }

        DriverInformation existingDriver = driverInformationMapper.selectById(driverInformation.getDriverId());
        if (existingDriver == null) {
            driverInformationMapper.insert(driverInformation);
            log.info(String.format("Driver created with ID %s", driverInformation.getDriverId()));
        } else {
            driverInformationMapper.updateById(driverInformation);
            log.info(String.format("Driver updated with ID %s", driverInformation.getDriverId()));
        }

        DriverInformationDocument document = DriverInformationDocument.fromEntity(driverInformation);
        if (document != null) {
            driverInformationSearchRepository.save(document);
            log.info(String.format("Driver synced to Elasticsearch with ID %s", driverInformation.getDriverId()));
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "driverCache", allEntries = true)
    @WsAction(service = "DriverInformationService", action = "updateDriver")
    public void updateDriver(DriverInformation driverInformation) {
        if (driverInformation == null || driverInformation.getDriverId() == null) {
            throw new IllegalArgumentException("Driver information or ID cannot be null");
        }

        DriverInformation existingDriver = driverInformationMapper.selectById(driverInformation.getDriverId());
        if (existingDriver == null) {
            throw new IllegalStateException("Driver does not exist with ID: " + driverInformation.getDriverId());
        }

        driverInformationMapper.updateById(driverInformation);
        log.info(String.format("Driver updated with ID %s", driverInformation.getDriverId()));

        // Update UserManagement.modifiedTime
        UserManagement user = userManagementMapper.selectById(driverInformation.getDriverId());
        if (user != null) {
            user.setModifiedTime(LocalDateTime.now());
            userManagementMapper.updateById(user);
            log.info(String.format("UserManagement modifiedTime updated for userId %s", driverInformation.getDriverId()));
        } else {
            log.warning("No UserManagement found for driverId: " + driverInformation.getDriverId());
        }

        DriverInformationDocument document = DriverInformationDocument.fromEntity(driverInformation);
        if (document != null) {
            driverInformationSearchRepository.save(document);
            log.info(String.format("Driver synced to Elasticsearch with ID %s", driverInformation.getDriverId()));
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "driverCache", allEntries = true)
    @WsAction(service = "DriverInformationService", action = "deleteDriver")
    public void deleteDriver(int driverId) {
        if (driverId <= 0) {
            throw new IllegalArgumentException("Invalid driver ID");
        }

        int result = driverInformationMapper.deleteById(driverId);
        if (result > 0) {
            log.info(String.format("Driver with ID %s deleted successfully from database", driverId));
            driverInformationSearchRepository.deleteById(driverId);
            log.info(String.format("Driver with ID %s deleted from Elasticsearch", driverId));
        } else {
            log.severe(String.format("Failed to delete driver with ID %s from database", driverId));
            throw new IllegalStateException("Driver not found with ID: " + driverId);
        }
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriverById")
    public DriverInformation getDriverById(Integer driverId) {
        if (driverId == null || driverId <= 0 || driverId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid driver ID " + driverId);
        }

        DriverInformationDocument document = driverInformationSearchRepository.findById(driverId).orElse(null);
        if (document != null) {
            log.info(String.format("Driver with ID %s retrieved from Elasticsearch", driverId));
            return document.toEntity();
        }

        DriverInformation driver = driverInformationMapper.selectById(driverId);
        if (driver != null) {
            log.info(String.format("Driver with ID %s retrieved from database", driverId));
            driverInformationSearchRepository.save(DriverInformationDocument.fromEntity(driver));
        }
        return driver;
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getAllDrivers")
    public List<DriverInformation> getAllDrivers() {
        Iterable<DriverInformationDocument> documents = driverInformationSearchRepository.findAll();
        List<DriverInformation> driversFromEs = StreamSupport.stream(documents.spliterator(), false)
                .map(DriverInformationDocument::toEntity)
                .collect(Collectors.toList());

        if (!driversFromEs.isEmpty()) {
            log.info("Drivers retrieved from Elasticsearch");
            return driversFromEs;
        }

        List<DriverInformation> drivers = driverInformationMapper.selectList(null);
        if (!drivers.isEmpty()) {
            log.info("Drivers retrieved from database, syncing to Elasticsearch");
            drivers.forEach(driver -> driverInformationSearchRepository.save(DriverInformationDocument.fromEntity(driver)));
        }
        return drivers;
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriversByIdCardNumber")
    public List<DriverInformation> getDriversByIdCardNumber(String idCardNumber) {
        if (idCardNumber == null || idCardNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid ID card number");
        }

        List<DriverInformationDocument> documents = driverInformationSearchRepository.findByIdCardNumber(idCardNumber);
        if (!documents.isEmpty()) {
            log.info(String.format("Drivers with ID card number %s retrieved from Elasticsearch", idCardNumber));
            return documents.stream().map(DriverInformationDocument::toEntity).collect(Collectors.toList());
        }

        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("id_card_number", idCardNumber);
        List<DriverInformation> drivers = driverInformationMapper.selectList(queryWrapper);
        if (!drivers.isEmpty()) {
            log.info(String.format("Drivers with ID card number %s retrieved from database, syncing to Elasticsearch", idCardNumber));
            drivers.forEach(driver -> driverInformationSearchRepository.save(DriverInformationDocument.fromEntity(driver)));
        }
        return drivers;
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriverByDriverLicenseNumber")
    public DriverInformation getDriverByDriverLicenseNumber(String driverLicenseNumber) {
        if (driverLicenseNumber == null || driverLicenseNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid driver license number");
        }

        DriverInformationDocument document = driverInformationSearchRepository.findByDriverLicenseNumber(driverLicenseNumber);
        if (document != null) {
            log.info(String.format("Driver with license number %s retrieved from Elasticsearch", driverLicenseNumber));
            return document.toEntity();
        }

        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_license_number", driverLicenseNumber);
        DriverInformation driver = driverInformationMapper.selectOne(queryWrapper);
        if (driver != null) {
            log.info(String.format("Driver with license number %s retrieved from database, syncing to Elasticsearch", driverLicenseNumber));
            driverInformationSearchRepository.save(DriverInformationDocument.fromEntity(driver));
        }
        return driver;
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriversByName")
    public List<DriverInformation> getDriversByName(String name) {
        if (name == null || name.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid name");
        }

        List<DriverInformationDocument> documents = driverInformationSearchRepository.findByName(name);
        if (!documents.isEmpty()) {
            log.info(String.format("Drivers with name %s retrieved from Elasticsearch", name));
            return documents.stream().map(DriverInformationDocument::toEntity).collect(Collectors.toList());
        }

        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("name", name);
        List<DriverInformation> drivers = driverInformationMapper.selectList(queryWrapper);
        if (!drivers.isEmpty()) {
            log.info(String.format("Drivers with name %s retrieved from database, syncing to Elasticsearch", name));
            drivers.forEach(driver -> driverInformationSearchRepository.save(DriverInformationDocument.fromEntity(driver)));
        }
        return drivers;
    }

    private void sendKafkaMessage(String topic, DriverInformation driverInformation) {
        kafkaTemplate.send(topic, driverInformation);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}