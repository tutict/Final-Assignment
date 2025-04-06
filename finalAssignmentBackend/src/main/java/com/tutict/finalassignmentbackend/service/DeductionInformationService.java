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
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

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
        // Input validation
        validateInput(deduction);
        if (deduction.getDeductionId() != null && deduction.getDeductionId() <= 0) {
            throw new IllegalArgumentException("Invalid deduction ID: must be positive if provided");
        }

        try {
            log.log(Level.INFO, "Processing deduction: {}", deduction);

            DeductionInformation existingDeduction = deductionInformationMapper.selectById(deduction.getDeductionId());

            Integer deductionId;
            if (existingDeduction == null) {
                // Insert new deduction
                log.info("No existing deduction found, inserting new record");
                deductionInformationMapper.insert(deduction);
                deductionId = deduction.getDeductionId();
                if (deductionId == null) {
                    throw new RuntimeException("Failed to generate deductionId after insert");
                }
                log.log(Level.INFO, "Database insert successful, deductionId={}", deductionId);
            } else {
                // Update existing deduction
                log.log(Level.INFO, "Existing deduction found, updating record with deductionId={}", existingDeduction.getDeductionId());
                deductionInformationMapper.updateById(deduction);
                deductionId = deduction.getDeductionId();
                log.log(Level.INFO, "Database update successful, deductionId={}", deductionId);
            }

            // Register ES indexing after commit
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    DeductionInformationDocument doc = DeductionInformationDocument.fromEntity(deduction);
                    deductionInformationSearchRepository.save(doc);
                    log.log(Level.INFO, "Post-commit: Elasticsearch indexed, deductionId={}", deductionId);
                }
            });

        } catch (Exception e) {
            log.log(Level.WARNING, "Failed to process deduction: {0} {1}", new Object[]{deduction, e});
            throw new RuntimeException("Failed to create or update deduction", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "deductionCache", allEntries = true)
    public void updateDeduction(DeductionInformation deduction) {

        validateInput(deduction);
        if (deduction.getDeductionId() == null || deduction.getDeductionId() <= 0) {
            throw new IllegalArgumentException("Deduction ID cannot be null or invalid");
        }

        try {
            log.log(Level.INFO, "Updating deduction: {0}", deduction);
            int rowsAffected = deductionInformationMapper.updateById(deduction);
            if (rowsAffected == 0) {
                log.log(Level.WARNING, "No deduction found to update for ID: {0}", deduction.getDeductionId());
                throw new RuntimeException("Deduction not found");
            }
            log.log(Level.INFO, "Database update successful, deductionId={0}", deduction.getDeductionId());

            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    DeductionInformationDocument document = DeductionInformationDocument.fromEntity(deduction);
                    if (document != null) {
                        deductionInformationSearchRepository.save(document);
                        log.log(Level.INFO, "Post-commit: Elasticsearch indexed, deductionId={0}", deduction.getDeductionId());
                    } else {
                        log.log(Level.WARNING, "Failed to create DeductionInformationDocument for deductionId={0}", deduction.getDeductionId());
                    }
                }
            });

        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to update deduction: " + e.getMessage(), e);
            throw new RuntimeException("Failed to update deduction information", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "deductionCache", allEntries = true)
    @WsAction(service = "DeductionInformationService", action = "deleteDeduction")
    public void deleteDeduction(int deductionId) {

        if (deductionId <= 0) {
            throw new IllegalArgumentException("Invalid deduction ID: " + deductionId);
        }

        try {
            log.log(Level.INFO, "Deleting deduction with ID: {0}", deductionId);
            int rowsAffected = deductionInformationMapper.deleteById(deductionId);
            if (rowsAffected == 0) {
                log.log(Level.WARNING, "No deduction found to delete for ID: {0}", deductionId);
                throw new RuntimeException("Deduction not found");
            }
            log.log(Level.INFO, "Database deletion successful, deductionId={0}", deductionId);

            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    deductionInformationSearchRepository.deleteById(deductionId);
                    log.log(Level.INFO, "Post-commit: Elasticsearch record deleted, deductionId={0}", deductionId);
                }
            });

        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to delete deduction: " + e.getMessage(), e);
            throw new RuntimeException("Failed to delete deduction information", e);
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
        if (deductionInformation == null || topic == null) {
            log.warning("Invalid input for sending Kafka message");
            return;
        }
        try {
            kafkaTemplate.send(topic, deductionInformation);
            log.info(String.format("Message sent to Kafka topic %s successfully", topic));
        } catch (Exception e) {
            log.log(Level.WARNING, "Error sending Kafka message: {0}", new Object[]{e.getMessage()});
        }
    }

    private void validateInput(DeductionInformation deduction) {
        if (deduction == null) {
            throw new IllegalArgumentException("Deduction information cannot be null");
        }
    }
}