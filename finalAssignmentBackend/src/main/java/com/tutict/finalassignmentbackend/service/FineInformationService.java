package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.FineInformationDocument;
import com.tutict.finalassignmentbackend.mapper.FineInformationMapper;
import com.tutict.finalassignmentbackend.entity.FineInformation;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.FineInformationSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class FineInformationService {

    private static final Logger log = Logger.getLogger(FineInformationService.class.getName());

    private final FineInformationMapper fineInformationMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final FineInformationSearchRepository fineInformationSearchRepository;
    private final KafkaTemplate<String, FineInformation> kafkaTemplate;

    @Autowired
    public FineInformationService(FineInformationMapper fineInformationMapper,
                                  RequestHistoryMapper requestHistoryMapper,
                                  FineInformationSearchRepository fineInformationSearchRepository,
                                  KafkaTemplate<String, FineInformation> kafkaTemplate) {
        this.fineInformationMapper = fineInformationMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.fineInformationSearchRepository = fineInformationSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "fineCache", allEntries = true)
    @WsAction(service = "FineInformationService", action = "checkAndInsertIdempotency")
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

        sendKafkaMessage("fine_" + action, fineInformation);

        Integer fineId = fineInformation.getFineId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(fineId != null ? fineId.longValue() : null);
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
    @WsAction(service = "FineInformationService", action = "deleteFine")
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
    @WsAction(service = "FineInformationService", action = "getFineById")
    public FineInformation getFineById(Integer fineId) {
        if (fineId == null || fineId <= 0 || fineId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid fine ID" + fineId);
        }
        return fineInformationMapper.selectById(fineId);
    }

    @Cacheable(cacheNames = "fineCache")
    @WsAction(service = "FineInformationService", action = "getAllFines")
    public List<FineInformation> getAllFines() {
        return fineInformationMapper.selectList(null);
    }

    @Cacheable(cacheNames = "fineCache")
    @WsAction(service = "FineInformationService", action = "getFinesByPayee")
    public List<FineInformation> getFinesByPayee(String payee) {
        if (payee == null || payee.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid payee");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("payee", payee);
        return fineInformationMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "fineCache")
    @WsAction(service = "FineInformationService", action = "getFinesByTimeRange")
    public List<FineInformation> getFinesByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("fineTime", startTime, endTime);
        return fineInformationMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "fineCache")
    @WsAction(service = "FineInformationService", action = "getFineByReceiptNumber")
    public FineInformation getFineByReceiptNumber(String receiptNumber) {
        if (receiptNumber == null || receiptNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid receipt number");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("receiptNumber", receiptNumber);
        return fineInformationMapper.selectOne(queryWrapper);
    }

    @Cacheable(cacheNames = "fineCache", unless = "#result == null")
    public List<FineInformation> searchByPayee(String payee, int maxSuggestions) {
        Set<FineInformation> suggestions = new HashSet<>();

        log.log(Level.INFO, "Executing payee search for payee: {0}, maxSuggestions: {1}",
                new Object[]{payee, maxSuggestions});

        // 1. Prefix matching
        SearchHits<FineInformationDocument> suggestHits = null;
        try {
            suggestHits = fineInformationSearchRepository.searchByPayeePrefix(payee);
            log.log(Level.INFO, "Payee search returned {0} hits",
                    new Object[]{suggestHits != null ? suggestHits.getTotalHits() : 0});
        } catch (Exception e) {
            log.log(Level.WARNING, "Error executing payee search query: {0}", new Object[]{e.getMessage()});
        }

        if (suggestHits != null && suggestHits.hasSearchHits()) {
            for (SearchHit<FineInformationDocument> hit : suggestHits) {
                FineInformationDocument doc = hit.getContent();
                if (doc.getPayee() != null) {
                    suggestions.add(doc.toEntity());
                    log.log(Level.INFO, "Found fine with ID: {0}, payee: {1}",
                            new Object[]{doc.getFineId(), doc.getPayee()});
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
            log.log(Level.INFO, "Found {0} payee suggestions: {1}",
                    new Object[]{suggestions.size(), suggestions});
        } else {
            log.log(Level.INFO, "No payee suggestions found for prefix: {0}", new Object[]{payee});
        }

        // 2. If results are insufficient, execute fuzzy query
        if (suggestions.size() < maxSuggestions) {
            log.log(Level.INFO, "Executing fuzzy query for payee: {0}", new Object[]{payee});
            SearchHits<FineInformationDocument> fuzzyHits = null;
            try {
                fuzzyHits = fineInformationSearchRepository.searchByPayeeFuzzy(payee);
                log.log(Level.INFO, "Fuzzy query returned {0} hits",
                        new Object[]{fuzzyHits != null ? fuzzyHits.getTotalHits() : 0});
            } catch (Exception e) {
                log.log(Level.WARNING, "Error executing fuzzy query for payee: {0}", new Object[]{e.getMessage()});
            }

            if (fuzzyHits != null && fuzzyHits.hasSearchHits()) {
                for (SearchHit<FineInformationDocument> hit : fuzzyHits) {
                    FineInformationDocument doc = hit.getContent();
                    if (doc.getPayee() != null) {
                        suggestions.add(doc.toEntity());
                        log.log(Level.INFO, "Found fine with ID: {0}, payee: {1}",
                                new Object[]{doc.getFineId(), doc.getPayee()});
                    }
                    if (suggestions.size() >= maxSuggestions) {
                        break;
                    }
                }
                log.log(Level.INFO, "After fuzzy search, total payee suggestions: {0}",
                        new Object[]{suggestions.size()});
            } else {
                log.log(Level.INFO, "Fuzzy search returned no results for payee: {0}", new Object[]{payee});
            }
        }

        List<FineInformation> resultList = new ArrayList<>(suggestions);
        return resultList.size() <= maxSuggestions ? resultList : resultList.subList(0, maxSuggestions);
    }

    @Cacheable(cacheNames = "fineCache", unless = "#result == null")
    public List<FineInformation> searchByFineTimeRange(String startTime, String endTime, int maxSuggestions) {
        Set<FineInformation> suggestions = new HashSet<>();

        log.log(Level.INFO, "Executing fineTime range search for startTime: {0}, endTime: {1}, maxSuggestions: {2}",
                new Object[]{startTime, endTime, maxSuggestions});

        // Range query (no fuzzy equivalent needed for time range)
        SearchHits<FineInformationDocument> suggestHits = null;
        try {
            suggestHits = fineInformationSearchRepository.searchByFineTimeRange(startTime, endTime);
            log.log(Level.INFO, "FineTime range search returned {0} hits",
                    new Object[]{suggestHits != null ? suggestHits.getTotalHits() : 0});
        } catch (Exception e) {
            log.log(Level.WARNING, "Error executing fineTime range search query: {0}", new Object[]{e.getMessage()});
        }

        if (suggestHits != null && suggestHits.hasSearchHits()) {
            for (SearchHit<FineInformationDocument> hit : suggestHits) {
                FineInformationDocument doc = hit.getContent();
                if (doc.getFineTime() != null) {
                    suggestions.add(doc.toEntity());
                    log.log(Level.INFO, "Found fine with ID: {0}, fineTime: {1}",
                            new Object[]{doc.getFineId(), doc.getFineTime()});
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
            log.log(Level.INFO, "Found {0} fineTime range suggestions: {1}",
                    new Object[]{suggestions.size(), suggestions});
        } else {
            log.log(Level.INFO, "No fineTime range suggestions found for range: {0} to {1}",
                    new Object[]{startTime, endTime});
        }

        List<FineInformation> resultList = new ArrayList<>(suggestions);
        return resultList.size() <= maxSuggestions ? resultList : resultList.subList(0, maxSuggestions);
    }

    private void sendKafkaMessage(String topic, FineInformation fineInformation) {
        kafkaTemplate.send(topic, fineInformation);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}