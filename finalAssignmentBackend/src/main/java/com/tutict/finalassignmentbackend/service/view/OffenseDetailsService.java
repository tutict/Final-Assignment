package com.tutict.finalassignmentbackend.service.view;

import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.logging.Logger;

// 服务类，用于处理违规详情的相关操作
@Service
public class OffenseDetailsService {

    private static final Logger log = Logger.getLogger(OffenseDetailsService.class.getName());

    private final OffenseDetailsMapper offenseDetailsMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, OffenseDetails> kafkaTemplate;

    @Autowired
    public OffenseDetailsService(OffenseDetailsMapper offenseDetailsMapper,
                                 RequestHistoryMapper requestHistoryMapper,
                                 KafkaTemplate<String, OffenseDetails> kafkaTemplate) {
        this.offenseDetailsMapper = offenseDetailsMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "offenseDetailsCache", allEntries = true)
    public void checkAndInsertIdempotency(String idempotencyKey, OffenseDetails offenseDetails) {
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

        sendKafkaMessage(offenseDetails);

        Integer offenseDetailsId = offenseDetails.getOffenseId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(offenseDetailsId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Cacheable(cacheNames = "offenseDetailsCache")
    public List<OffenseDetails> getAllOffenseDetails() {
        return offenseDetailsMapper.selectList(null);
    }

    @Cacheable(cacheNames = "offenseDetailsCache")
    public OffenseDetails getOffenseDetailsById(Integer id) {
        if (id == null || id <= 0 || id >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid offense ID" + id);
        }
        return offenseDetailsMapper.selectById(id);
    }

    @Transactional
    public void saveOffenseDetails(OffenseDetails offenseDetails) {
        try {
            offenseDetailsMapper.insert(offenseDetails);
            log.info("Offense details saved to database successfully");
        } catch (Exception e) {
            log.warning("Exception occurred while saving offense details");
            throw new RuntimeException("Failed to save offense details", e);
        }
    }

    private void sendKafkaMessage(OffenseDetails offenseDetails) {
        kafkaTemplate.send("offense_details_topic", offenseDetails);
        log.info(String.format("Message sent to Kafka topic %s successfully", "offense_details_topic"));
    }
}