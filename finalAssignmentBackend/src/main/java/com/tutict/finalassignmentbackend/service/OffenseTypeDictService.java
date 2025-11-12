package com.tutict.finalassignmentbackend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.OffenseTypeDict;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseTypeDictDocument;
import com.tutict.finalassignmentbackend.mapper.OffenseTypeDictMapper;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.OffenseTypeDictSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@Service
public class OffenseTypeDictService {

    private static final Logger log = Logger.getLogger(OffenseTypeDictService.class.getName());
    private static final String CACHE_NAME = "offenseTypeDictCache";

    private final OffenseTypeDictMapper offenseTypeDictMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final OffenseTypeDictSearchRepository offenseTypeDictSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public OffenseTypeDictService(OffenseTypeDictMapper offenseTypeDictMapper,
                                  SysRequestHistoryMapper sysRequestHistoryMapper,
                                  OffenseTypeDictSearchRepository offenseTypeDictSearchRepository,
                                  KafkaTemplate<String, String> kafkaTemplate,
                                  ObjectMapper objectMapper) {
        this.offenseTypeDictMapper = offenseTypeDictMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.offenseTypeDictSearchRepository = offenseTypeDictSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "OffenseTypeDictService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, OffenseTypeDict dict, String action) {
        Objects.requireNonNull(dict, "OffenseTypeDict must not be null");
        if (sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey) != null) {
            throw new RuntimeException("Duplicate offense type dict request detected");
        }
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("offense_type_dict_" + action, idempotencyKey, dict);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(Optional.ofNullable(dict.getTypeId()).map(Long::valueOf).orElse(null));
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public OffenseTypeDict createDict(OffenseTypeDict dict) {
        validateDict(dict);
        offenseTypeDictMapper.insert(dict);
        syncToIndexAfterCommit(dict);
        return dict;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public OffenseTypeDict updateDict(OffenseTypeDict dict) {
        validateDict(dict);
        requirePositive(dict.getTypeId());
        int rows = offenseTypeDictMapper.updateById(dict);
        if (rows == 0) {
            throw new IllegalStateException("No OffenseTypeDict updated for id=" + dict.getTypeId());
        }
        syncToIndexAfterCommit(dict);
        return dict;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteDict(Integer typeId) {
        requirePositive(typeId);
        int rows = offenseTypeDictMapper.deleteById(typeId);
        if (rows == 0) {
            throw new IllegalStateException("No OffenseTypeDict deleted for id=" + typeId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                offenseTypeDictSearchRepository.deleteById(typeId);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#typeId", unless = "#result == null")
    public OffenseTypeDict findById(Integer typeId) {
        requirePositive(typeId);
        return offenseTypeDictSearchRepository.findById(typeId)
                .map(OffenseTypeDictDocument::toEntity)
                .orElseGet(() -> {
                    OffenseTypeDict entity = offenseTypeDictMapper.selectById(typeId);
                    if (entity != null) {
                        offenseTypeDictSearchRepository.save(OffenseTypeDictDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<OffenseTypeDict> findAll() {
        List<OffenseTypeDict> fromIndex = StreamSupport.stream(offenseTypeDictSearchRepository.findAll().spliterator(), false)
                .map(OffenseTypeDictDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<OffenseTypeDict> fromDb = offenseTypeDictMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Integer typeId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(typeId != null ? typeId.longValue() : null);
        history.setRequestParams("DONE");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark failure for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("FAILED");
        history.setRequestParams(truncate(reason));
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    private void sendKafkaMessage(String topic, String idempotencyKey, OffenseTypeDict dict) {
        try {
            String payload = objectMapper.writeValueAsString(dict);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            log.log(Level.SEVERE, "Failed to send OffenseTypeDict Kafka message", ex);
            throw new RuntimeException("Failed to send OffenseTypeDict event", ex);
        }
    }

    private void syncToIndexAfterCommit(OffenseTypeDict dict) {
        if (dict == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                OffenseTypeDictDocument doc = OffenseTypeDictDocument.fromEntity(dict);
                if (doc != null) {
                    offenseTypeDictSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<OffenseTypeDict> dicts) {
        if (dicts == null || dicts.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<OffenseTypeDictDocument> documents = dicts.stream()
                        .filter(Objects::nonNull)
                        .map(OffenseTypeDictDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    offenseTypeDictSearchRepository.saveAll(documents);
                }
            }
        });
    }

    private void validateDict(OffenseTypeDict dict) {
        Objects.requireNonNull(dict, "OffenseTypeDict must not be null");
        if (dict.getOffenseCode() == null || dict.getOffenseCode().isBlank()) {
            throw new IllegalArgumentException("Offense code must not be blank");
        }
        if (dict.getOffenseName() == null || dict.getOffenseName().isBlank()) {
            throw new IllegalArgumentException("Offense name must not be blank");
        }
        if (dict.getStatus() == null || dict.getStatus().isBlank()) {
            dict.setStatus("Active");
        }
        if (dict.getCreatedAt() == null) {
            dict.setCreatedAt(LocalDateTime.now());
        }
        if (dict.getUpdatedAt() == null) {
            dict.setUpdatedAt(LocalDateTime.now());
        }
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("Type ID" + " must be greater than zero");
        }
    }

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }
}
