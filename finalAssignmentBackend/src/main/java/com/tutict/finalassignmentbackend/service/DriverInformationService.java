package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.DriverInformationMapper;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.logging.Logger;

@Service
public class DriverInformationService {

    private static final Logger log = Logger.getLogger(DriverInformationService.class.getName());

    private final DriverInformationMapper driverInformationMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, DriverInformation> kafkaTemplate;

    @Autowired
    public DriverInformationService(DriverInformationMapper driverInformationMapper,
                                    RequestHistoryMapper requestHistoryMapper,
                                    KafkaTemplate<String, DriverInformation> kafkaTemplate) {
        this.driverInformationMapper = driverInformationMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "driverCache", allEntries = true)
    @WsAction(service = "DriverInformationService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, DriverInformation driverInformation, String action) {
        // 查询 request_history
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        // 不存在 -> 插入一条 PROCESSING
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

        Integer driverId = driverInformation.getDriverId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(driverId != null ? driverId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "driverCache", allEntries = true)
    public void createDriver(DriverInformation driverInformation) {
        DriverInformation existingDriver = driverInformationMapper.selectById(driverInformation.getDriverId());
        if (existingDriver == null) {
            driverInformationMapper.insert(driverInformation);
        } else {
            driverInformationMapper.updateById(driverInformation);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "driverCache", allEntries = true)
    public void updateDriver(DriverInformation driverInformation) {
        DriverInformation existingDriver = driverInformationMapper.selectById(driverInformation.getDriverId());
        if (existingDriver == null) {
            driverInformationMapper.insert(driverInformation);
        } else {
            driverInformationMapper.updateById(driverInformation);
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
            log.info(String.format("Driver with ID %s deleted successfully", driverId));
        } else {
            log.severe(String.format("Failed to delete driver with ID %s", driverId));
        }
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriverById")
    public DriverInformation getDriverById(Integer driverId) {
        if (driverId == null || driverId <= 0 || driverId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid driver ID " + driverId);
        }
        return driverInformationMapper.selectById(driverId);
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getAllDrivers")
    public List<DriverInformation> getAllDrivers() {
        return driverInformationMapper.selectList(null);
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriversByIdCardNumber")
    public List<DriverInformation> getDriversByIdCardNumber(String idCardNumber) {
        if (idCardNumber == null || idCardNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid ID card number");
        }
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("id_card_number", idCardNumber);
        return driverInformationMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriverByDriverLicenseNumber")
    public DriverInformation getDriverByDriverLicenseNumber(String driverLicenseNumber) {
        if (driverLicenseNumber == null || driverLicenseNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid driver license number");
        }
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_license_number", driverLicenseNumber);
        return driverInformationMapper.selectOne(queryWrapper);
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriversByName")
    public List<DriverInformation> getDriversByName(String name) {
        if (name == null || name.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid name");
        }
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("name", name);
        return driverInformationMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, DriverInformation driverInformation) {
        kafkaTemplate.send(topic, driverInformation);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}