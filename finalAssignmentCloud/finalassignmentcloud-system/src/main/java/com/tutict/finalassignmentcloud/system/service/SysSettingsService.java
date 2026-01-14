package com.tutict.finalassignmentcloud.system.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.config.websocket.WsAction;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.entity.SysSettings;
import com.tutict.finalassignmentcloud.entity.elastic.SysSettingsDocument;
import com.tutict.finalassignmentcloud.system.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentcloud.system.mapper.SysSettingsMapper;
import com.tutict.finalassignmentcloud.system.repository.SysSettingsSearchRepository;
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
public class SysSettingsService {

    private static final Logger LOG = Logger.getLogger(SysSettingsService.class.getName());
    private static final String CACHE_NAME = "sysSettingsCache";

    private final SysSettingsMapper sysSettingsMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final SysSettingsSearchRepository sysSettingsSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public SysSettingsService(SysSettingsMapper sysSettingsMapper,
                              SysRequestHistoryMapper sysRequestHistoryMapper,
                              SysSettingsSearchRepository sysSettingsSearchRepository,
                              KafkaTemplate<String, String> kafkaTemplate,
                              ObjectMapper objectMapper) {
        this.sysSettingsMapper = sysSettingsMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.sysSettingsSearchRepository = sysSettingsSearchRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "SysSettingsService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysSettings settings, String action) {
        Objects.requireNonNull(settings, "SysSettings must not be null");
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            LOG.warning(() -> String.format("Duplicate sys settings request detected (key=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate sys settings request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("sys_settings_" + action, idempotencyKey, settings);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(Optional.ofNullable(settings.getSettingId()).map(Integer::longValue).orElse(null));
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysSettings createSysSettings(SysSettings settings) {
        validateSettings(settings);
        sysSettingsMapper.insert(settings);
        syncToIndexAfterCommit(settings);
        return settings;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysSettings updateSysSettings(SysSettings settings) {
        validateSettings(settings);
        requirePositive(settings.getSettingId());
        int rows = sysSettingsMapper.updateById(settings);
        if (rows == 0) {
            throw new IllegalStateException("SysSettings not found for id=" + settings.getSettingId());
        }
        syncToIndexAfterCommit(settings);
        return settings;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteSysSettings(Integer settingId) {
        requirePositive(settingId);
        int rows = sysSettingsMapper.deleteById(settingId);
        if (rows == 0) {
            throw new IllegalStateException("SysSettings not found for id=" + settingId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                sysSettingsSearchRepository.deleteById(settingId);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#settingId", unless = "#result == null")
    public SysSettings findById(Integer settingId) {
        requirePositive(settingId);
        return sysSettingsSearchRepository.findById(settingId)
                .map(SysSettingsDocument::toEntity)
                .orElseGet(() -> {
                    SysSettings entity = sysSettingsMapper.selectById(settingId);
                    if (entity != null) {
                        sysSettingsSearchRepository.save(SysSettingsDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'key:' + #settingKey", unless = "#result == null")
    public SysSettings findByKey(String settingKey) {
        if (isBlank(settingKey)) {
            return null;
        }
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.eq("setting_key", settingKey);
        SysSettings entity = sysSettingsMapper.selectOne(wrapper);
        if (entity != null) {
            sysSettingsSearchRepository.save(SysSettingsDocument.fromEntity(entity));
        }
        return entity;
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'category:' + #category + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysSettings> findByCategory(String category, int page, int size) {
        if (isBlank(category)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysSettings> index = mapHits(sysSettingsSearchRepository.searchByCategory(category, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.eq("category", category)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'keyPrefix:' + #settingKey + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysSettings> searchBySettingKeyPrefix(String settingKey, int page, int size) {
        if (isBlank(settingKey)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysSettings> index = mapHits(sysSettingsSearchRepository.searchBySettingKeyPrefix(settingKey, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.likeRight("setting_key", settingKey)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'keyFuzzy:' + #settingKey + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysSettings> searchBySettingKeyFuzzy(String settingKey, int page, int size) {
        if (isBlank(settingKey)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysSettings> index = mapHits(sysSettingsSearchRepository.searchBySettingKeyFuzzy(settingKey, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.like("setting_key", settingKey)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'type:' + #settingType + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysSettings> searchBySettingType(String settingType, int page, int size) {
        if (isBlank(settingType)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysSettings> index = mapHits(sysSettingsSearchRepository.searchBySettingType(settingType, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.eq("setting_type", settingType)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'editable:' + #isEditable + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysSettings> searchByIsEditable(boolean isEditable, int page, int size) {
        validatePagination(page, size);
        List<SysSettings> index = mapHits(sysSettingsSearchRepository.searchByIsEditable(isEditable, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.eq("is_editable", isEditable)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'encrypted:' + #isEncrypted + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysSettings> searchByIsEncrypted(boolean isEncrypted, int page, int size) {
        validatePagination(page, size);
        List<SysSettings> index = mapHits(sysSettingsSearchRepository.searchByIsEncrypted(isEncrypted, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.eq("is_encrypted", isEncrypted)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<SysSettings> findAll() {
        List<SysSettings> fromIndex = StreamSupport.stream(sysSettingsSearchRepository.findAll().spliterator(), false)
                .map(SysSettingsDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<SysSettings> fromDb = sysSettingsMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Integer settingId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            LOG.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(settingId != null ? settingId.longValue() : null);
        history.setRequestParams("DONE");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            LOG.log(Level.WARNING, "Cannot mark failure for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("FAILED");
        history.setRequestParams(truncate(reason));
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    private void sendKafkaMessage(String topic, String idempotencyKey, SysSettings settings) {
        try {
            String payload = objectMapper.writeValueAsString(settings);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception ex) {
            LOG.log(Level.SEVERE, "Failed to send SysSettings Kafka message", ex);
            throw new RuntimeException("Failed to send SysSettings event", ex);
        }
    }

    private void syncToIndexAfterCommit(SysSettings settings) {
        if (settings == null) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                SysSettingsDocument doc = SysSettingsDocument.fromEntity(settings);
                if (doc != null) {
                    sysSettingsSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<SysSettings> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<SysSettingsDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(SysSettingsDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    sysSettingsSearchRepository.saveAll(documents);
                }
            }
        });
    }

    private List<SysSettings> fetchFromDatabase(QueryWrapper<SysSettings> wrapper, int page, int size) {
        Page<SysSettings> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysSettingsMapper.selectPage(mpPage, wrapper);
        List<SysSettings> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private List<SysSettings> mapHits(org.springframework.data.elasticsearch.core.SearchHits<SysSettingsDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(org.springframework.data.elasticsearch.core.SearchHit::getContent)
                .map(SysSettingsDocument::toEntity)
                .collect(Collectors.toList());
    }

    private org.springframework.data.domain.Pageable pageable(int page, int size) {
        return org.springframework.data.domain.PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
    }

    private void validateSettings(SysSettings settings) {
        if (settings == null) {
            throw new IllegalArgumentException("SysSettings must not be null");
        }
        if (isBlank(settings.getSettingKey())) {
            throw new IllegalArgumentException("Setting key must not be blank");
        }
        if (settings.getSettingValue() == null) {
            throw new IllegalArgumentException("Setting value must not be null");
        }
        if (settings.getCreatedAt() == null) {
            settings.setCreatedAt(LocalDateTime.now());
        }
        if (settings.getUpdatedAt() == null) {
            settings.setUpdatedAt(LocalDateTime.now());
        }
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("Setting ID" + " must be greater than zero");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }
}

