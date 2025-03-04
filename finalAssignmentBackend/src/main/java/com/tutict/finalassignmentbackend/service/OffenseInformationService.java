package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.OffenseInformationMapper;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;

// 定义一个服务类，用于处理违规信息的相关操作
@Service
public class OffenseInformationService {

    private static final Logger log = Logger.getLogger(OffenseInformationService.class.getName());

    private final OffenseInformationMapper offenseInformationMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, OffenseInformation> kafkaTemplate;

    @Autowired
    public OffenseInformationService(OffenseInformationMapper offenseInformationMapper,
                                     RequestHistoryMapper requestHistoryMapper,
                                     KafkaTemplate<String, OffenseInformation> kafkaTemplate) {
        this.offenseInformationMapper = offenseInformationMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "offenseCache", allEntries = true)
    @WsAction(service = "OffenseInformationService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, OffenseInformation offenseInformation, String action) {
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

        sendKafkaMessage("offense_"+action, offenseInformation);

        Integer offenseId = offenseInformation.getOffenseId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(offenseId != null ? offenseId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "offenseCache", allEntries = true)
    public void createOffense(OffenseInformation offenseInformation) {
        OffenseInformation existingOffense = offenseInformationMapper.selectById(offenseInformation.getOffenseId());
        if (existingOffense == null) {
            offenseInformationMapper.insert(offenseInformation);
        } else {
            offenseInformationMapper.updateById(offenseInformation);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "offenseCache", allEntries = true)
    public void updateOffense(OffenseInformation offenseInformation) {
        OffenseInformation existingOffense = offenseInformationMapper.selectById(offenseInformation.getOffenseId());
        if (existingOffense == null) {
            offenseInformationMapper.insert(offenseInformation);
        } else {
            offenseInformationMapper.updateById(offenseInformation);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "offenseCache", allEntries = true)
    @WsAction(service = "OffenseInformationService", action = "deleteOffense")
    public void deleteOffense(int offenseId) {
        if (offenseId <= 0) {
            throw new IllegalArgumentException("Invalid offense ID");
        }
        int result = offenseInformationMapper.deleteById(offenseId);
        if (result > 0) {
            log.info(String.format("Offense with ID %s deleted successfully", offenseId));
        } else {
            log.severe(String.format("Failed to delete offense with ID %s", offenseId));
        }
    }

    @Cacheable(cacheNames = "offenseCache")
    @WsAction(service = "OffenseInformationService", action = "getOffenseByOffenseId")
    public OffenseInformation getOffenseByOffenseId(Integer offenseId) {
        if (offenseId == null || offenseId <= 0 || offenseId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid offense ID" + offenseId);
        }
        return offenseInformationMapper.selectById(offenseId);
    }

    @Cacheable(cacheNames = "offenseCache")
    @WsAction(service = "OffenseInformationService", action = "getOffensesInformation")
    public List<OffenseInformation> getOffensesInformation() {
        return offenseInformationMapper.selectList(null);
    }

    @Cacheable(cacheNames = "offenseCache")
    @WsAction(service = "OffenseInformationService", action = "getOffensesByTimeRange")
    public List<OffenseInformation> getOffensesByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("offense_time", startTime, endTime);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "offenseCache")
    @WsAction(service = "OffenseInformationService", action = "getOffensesByProcessState")
    public List<OffenseInformation> getOffensesByProcessState(String processState) {
        if (processState == null || processState.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid process state");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processState);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "offenseCache")
    @WsAction(service = "OffenseInformationService", action = "getOffensesByDriverName")
    public List<OffenseInformation> getOffensesByDriverName(String driverName) {
        if (driverName == null || driverName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid driver name");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_name", driverName);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "offenseCache")
    @WsAction(service = "OffenseInformationService", action = "getOffensesByLicensePlate")
    public List<OffenseInformation> getOffensesByLicensePlate(String offenseLicensePlate) {
        if (offenseLicensePlate == null || offenseLicensePlate.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid license plate");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", offenseLicensePlate);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, OffenseInformation offenseInformation) {
        kafkaTemplate.send(topic, offenseInformation);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}