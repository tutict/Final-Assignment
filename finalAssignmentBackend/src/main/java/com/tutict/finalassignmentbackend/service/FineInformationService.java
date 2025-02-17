package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.FineInformationMapper;
import com.tutict.finalassignmentbackend.entity.FineInformation;
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

@Service
public class FineInformationService {

    private static final Logger log = Logger.getLogger(FineInformationService.class.getName());

    private final FineInformationMapper fineInformationMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, FineInformation> kafkaTemplate;

    @Autowired
    public FineInformationService(FineInformationMapper fineInformationMapper,
                                  RequestHistoryMapper requestHistoryMapper,
                                  KafkaTemplate<String, FineInformation> kafkaTemplate) {
        this.fineInformationMapper = fineInformationMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "fineCache", allEntries = true)
    public void checkAndInsertIdempotency(String idempotencyKey, FineInformation fineInformation, String action) {
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

        sendKafkaMessage(fineInformation);

        Integer fineId = fineInformation.getFineId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(fineId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "fineCache", allEntries = true)
    public void createFine(FineInformation fineInformation) {
        FineInformation existingFine = fineInformationMapper.selectById(fineInformation.getFineId());
        if (existingFine == null) {
            fineInformationMapper.insert(fineInformation);
        } else {
            fineInformationMapper.updateById(fineInformation);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "fineCache", allEntries = true)
    public void updateFine(FineInformation fineInformation) {
        FineInformation existingFine = fineInformationMapper.selectById(fineInformation.getFineId());
        if (existingFine == null) {
            fineInformationMapper.insert(fineInformation);
        } else {
            fineInformationMapper.updateById(fineInformation);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "fineCache", allEntries = true)
    public void deleteFine(int fineId) {
        if (fineId <= 0) {
            throw new IllegalArgumentException("Invalid fine ID");
        }
        int result = fineInformationMapper.deleteById(fineId);
        if (result > 0) {
            log.info(String.format("Fine with ID %s deleted successfully", fineId));
        } else {
            log.severe(String.format("Failed to delete fine with ID %s", fineId));
        }
    }

    @Cacheable(cacheNames = "fineCache")
    public FineInformation getFineById(Integer fineId) {
        if (fineId == null || fineId <= 0 || fineId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid fine ID" + fineId);
        }
        return fineInformationMapper.selectById(fineId);
    }

    @Cacheable(cacheNames = "fineCache")
    public List<FineInformation> getAllFines() {
        return fineInformationMapper.selectList(null);
    }

    @Cacheable(cacheNames = "fineCache")
    public List<FineInformation> getFinesByPayee(String payee) {
        if (payee == null || payee.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid payee");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("payee", payee);
        return fineInformationMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "fineCache")
    public List<FineInformation> getFinesByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("fineTime", startTime, endTime);
        return fineInformationMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "fineCache")
    public FineInformation getFineByReceiptNumber(String receiptNumber) {
        if (receiptNumber == null || receiptNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid receipt number");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("receiptNumber", receiptNumber);
        return fineInformationMapper.selectOne(queryWrapper);
    }

    private void sendKafkaMessage(FineInformation fineInformation) {
        kafkaTemplate.send("fine_processed_topic", fineInformation);
        log.info(String.format("Message sent to Kafka topic %s successfully", "fine_processed_topic"));
    }
}