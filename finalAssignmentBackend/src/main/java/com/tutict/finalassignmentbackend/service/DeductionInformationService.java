package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.DeductionInformationDocument;
import com.tutict.finalassignmentbackend.mapper.DeductionInformationMapper;
import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.DeductionInformationSearchRepository;
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
public class DeductionInformationService {

    private static final Logger log = Logger.getLogger(DeductionInformationService.class.getName());

    private final DeductionInformationMapper deductionInformationMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final DeductionInformationSearchRepository deductionInformationSearchRepository;
    private final KafkaTemplate<String, DeductionInformation> kafkaTemplate;

    @Autowired
    public DeductionInformationService(DeductionInformationMapper deductionInformationMapper,
                                       RequestHistoryMapper requestHistoryMapper,
                                       DeductionInformationSearchRepository deductionInformationSearchRepository,
                                       KafkaTemplate<String, DeductionInformation> kafkaTemplate) {
        this.deductionInformationMapper = deductionInformationMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.deductionInformationSearchRepository = deductionInformationSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "deductionCache", allEntries = true)
    @WsAction(service = "DeductionService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, DeductionInformation deductionInformation, String action) {
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

        sendKafkaMessage("deduction_" + action, deductionInformation);

        Integer deductionId = deductionInformation.getDeductionId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(deductionId != null ? deductionId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "deductionCache", allEntries = true)
    public void createDeduction(DeductionInformation deduction) {
        DeductionInformation existingDeduction = deductionInformationMapper.selectById(deduction.getDeductionId());
        if (existingDeduction == null) {
            deductionInformationMapper.insert(deduction);
        } else {
            deductionInformationMapper.updateById(deduction);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "deductionCache", allEntries = true)
    public void updateDeduction(DeductionInformation deduction) {
        DeductionInformation existingDeduction = deductionInformationMapper.selectById(deduction.getDeductionId());
        if (existingDeduction == null) {
            deductionInformationMapper.insert(deduction);
        } else {
            deductionInformationMapper.updateById(deduction);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "deductionCache", allEntries = true)
    @WsAction(service = "DeductionInformationService", action = "deleteDeduction")
    public void deleteDeduction(int deductionId) {
        if (deductionId <= 0) {
            throw new IllegalArgumentException("Invalid deduction ID");
        }
        int result = deductionInformationMapper.deleteById(deductionId);
        if (result > 0) {
            log.info(String.format("Deduction with ID %s deleted successfully", deductionId));
        } else {
            log.severe(String.format("Failed to delete deduction with ID %s", deductionId));
        }
    }

    @Cacheable(cacheNames = "deductionCache")
    @WsAction(service = "DeductionInformationService", action = "getDeductionById")
    public DeductionInformation getDeductionById(Integer deductionId) {
        if (deductionId == null || deductionId <= 0 || deductionId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid deduction ID " + deductionId);
        }
        return deductionInformationMapper.selectById(deductionId);
    }

    @Cacheable(cacheNames = "deductionCache")
    @WsAction(service = "DeductionInformationService", action = "getAllDeductions")
    public List<DeductionInformation> getAllDeductions() {
        return deductionInformationMapper.selectList(null);
    }

    @Cacheable(cacheNames = "deductionCache")
    @WsAction(service = "DeductionInformationService", action = "getDeductionsByHandler")
    public List<DeductionInformation> getDeductionsByHandler(String handler) {
        if (handler == null || handler.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid handler");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("handler", handler);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "deductionCache")
    @WsAction(service = "DeductionInformationService", action = "getDeductionsByTimeRange")
    public List<DeductionInformation> getDeductionsByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("deduction_time", startTime, endTime);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "deductionCache", unless = "#result == null")
    public List<DeductionInformation> searchByDeductionTimeRange(String startTime, String endTime, int maxSuggestions) {
        Set<DeductionInformation> suggestions = new HashSet<>();

        log.log(Level.INFO, "Executing deductionTime range search for startTime: {0}, endTime: {1}, maxSuggestions: {2}",
                new Object[]{startTime, endTime, maxSuggestions});

        // Range query (no fuzzy equivalent needed for time range)
        SearchHits<DeductionInformationDocument> suggestHits = null;
        try {
            suggestHits = deductionInformationSearchRepository.searchByDeductionTimeRange(startTime, endTime);
            log.log(Level.INFO, "DeductionTime range search returned {0} hits",
                    new Object[]{suggestHits != null ? suggestHits.getTotalHits() : 0});
        } catch (Exception e) {
            log.log(Level.WARNING, "Error executing deductionTime range search query: {0}", new Object[]{e.getMessage()});
        }

        if (suggestHits != null && suggestHits.hasSearchHits()) {
            for (SearchHit<DeductionInformationDocument> hit : suggestHits) {
                DeductionInformationDocument doc = hit.getContent();
                if (doc.getDeductionTime() != null) {
                    suggestions.add(doc.toEntity());
                    log.log(Level.INFO, "Found deduction with ID: {0}, deductionTime: {1}",
                            new Object[]{doc.getDeductionId(), doc.getDeductionTime()});
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
            log.log(Level.INFO, "Found {0} deductionTime range suggestions: {1}",
                    new Object[]{suggestions.size(), suggestions});
        } else {
            log.log(Level.INFO, "No deductionTime range suggestions found for range: {0} to {1}",
                    new Object[]{startTime, endTime});
        }

        List<DeductionInformation> resultList = new ArrayList<>(suggestions);
        return resultList.size() <= maxSuggestions ? resultList : resultList.subList(0, maxSuggestions);
    }


    @Cacheable(cacheNames = "deductionCache", unless = "#result == null")
    public List<DeductionInformation> searchByHandler(String handler, int maxSuggestions) {
        Set<DeductionInformation> suggestions = new HashSet<>();

        log.log(Level.INFO, "Executing handler search for handler: {0}, maxSuggestions: {1}",
                new Object[]{handler, maxSuggestions});

        // 1. Prefix matching
        SearchHits<DeductionInformationDocument> suggestHits = null;
        try {
            suggestHits = deductionInformationSearchRepository.searchByHandlerPrefix(handler);
            log.log(Level.INFO, "Handler search returned {0} hits",
                    new Object[]{suggestHits != null ? suggestHits.getTotalHits() : 0});
        } catch (Exception e) {
            log.log(Level.WARNING, "Error executing handler search query: {0}", new Object[]{e.getMessage()});
        }

        if (suggestHits != null && suggestHits.hasSearchHits()) {
            for (SearchHit<DeductionInformationDocument> hit : suggestHits) {
                DeductionInformationDocument doc = hit.getContent();
                if (doc.getHandler() != null) {
                    suggestions.add(doc.toEntity());
                    log.log(Level.INFO, "Found deduction with ID: {0}, handler: {1}",
                            new Object[]{doc.getDeductionId(), doc.getHandler()});
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
            log.log(Level.INFO, "Found {0} handler suggestions: {1}",
                    new Object[]{suggestions.size(), suggestions});
        } else {
            log.log(Level.INFO, "No handler suggestions found for prefix: {0}", new Object[]{handler});
        }

        // 2. If results are insufficient, execute fuzzy query
        if (suggestions.size() < maxSuggestions) {
            log.log(Level.INFO, "Executing fuzzy query for handler: {0}", new Object[]{handler});
            SearchHits<DeductionInformationDocument> fuzzyHits = null;
            try {
                fuzzyHits = deductionInformationSearchRepository.searchByHandlerFuzzy(handler);
                log.log(Level.INFO, "Fuzzy query returned {0} hits",
                        new Object[]{fuzzyHits != null ? fuzzyHits.getTotalHits() : 0});
            } catch (Exception e) {
                log.log(Level.WARNING, "Error executing fuzzy query for handler: {0}", new Object[]{e.getMessage()});
            }

            if (fuzzyHits != null && fuzzyHits.hasSearchHits()) {
                for (SearchHit<DeductionInformationDocument> hit : fuzzyHits) {
                    DeductionInformationDocument doc = hit.getContent();
                    if (doc.getHandler() != null) {
                        suggestions.add(doc.toEntity());
                        log.log(Level.INFO, "Found deduction with ID: {0}, handler: {1}",
                                new Object[]{doc.getDeductionId(), doc.getHandler()});
                    }
                    if (suggestions.size() >= maxSuggestions) {
                        break;
                    }
                }
                log.log(Level.INFO, "After fuzzy search, total handler suggestions: {0}",
                        new Object[]{suggestions.size()});
            } else {
                log.log(Level.INFO, "Fuzzy search returned no results for handler: {0}", new Object[]{handler});
            }
        }

        List<DeductionInformation> resultList = new ArrayList<>(suggestions);
        return resultList.size() <= maxSuggestions ? resultList : resultList.subList(0, maxSuggestions);
    }

    private void sendKafkaMessage(String topic, DeductionInformation deductionInformation) {
        kafkaTemplate.send(topic, deductionInformation);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}