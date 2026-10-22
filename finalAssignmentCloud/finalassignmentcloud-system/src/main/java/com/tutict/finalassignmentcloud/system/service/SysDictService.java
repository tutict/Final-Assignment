package com.tutict.finalassignmentcloud.system.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentcloud.common.transaction.AfterCommit;
import com.tutict.finalassignmentcloud.config.websocket.WsAction;
import com.tutict.finalassignmentcloud.entity.SysDict;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.entity.elastic.SysDictDocument;
import com.tutict.finalassignmentcloud.reliability.HistoryReserve;
import com.tutict.finalassignmentcloud.reliability.IdempotencyReplayException;
import com.tutict.finalassignmentcloud.system.mapper.SysDictMapper;
import com.tutict.finalassignmentcloud.system.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentcloud.system.repository.SysDictSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;
import com.tutict.finalassignmentcloud.reliability.LedgerFingerprint;

@Service
public class SysDictService {

    private static final Logger log = Logger.getLogger(SysDictService.class.getName());
    private static final String CACHE_NAME = "sysDictCache";

    private final SysDictMapper sysDictMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final SysDictSearchRepository sysDictSearchRepository;

    @Autowired
    public SysDictService(SysDictMapper sysDictMapper,
                          SysRequestHistoryMapper sysRequestHistoryMapper,
                          SysDictSearchRepository sysDictSearchRepository) {
        this.sysDictMapper = sysDictMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.sysDictSearchRepository = sysDictSearchRepository;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "SysDictService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysDict sysDict, String action) {
        HistoryReserve.reserve(sysRequestHistoryMapper, idempotencyKey, "SYS_DICT_" + action.toUpperCase(),
                LedgerFingerprint.fingerprint(action + "|" + sysDict.getDictType() + "|" + sysDict.getDictCode()
                        + "|" + sysDict.getDictValue()));
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysDict createSysDict(SysDict sysDict) {
        validateSysDict(sysDict);
        sysDictMapper.insert(sysDict);
        syncToIndexAfterCommit(sysDict);
        return sysDict;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysDict updateSysDict(SysDict sysDict) {
        validateSysDict(sysDict);
        requirePositive(sysDict.getDictId());
        int rows = sysDictMapper.updateById(sysDict);
        if (rows == 0) {
            throw new IllegalStateException("No SysDict updated for id=" + sysDict.getDictId());
        }
        syncToIndexAfterCommit(sysDict);
        return sysDict;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteSysDict(Integer dictId) {
        requirePositive(dictId);
        int rows = sysDictMapper.deleteById(dictId);
        if (rows == 0) {
            throw new IllegalStateException("No SysDict deleted for id=" + dictId);
        }
        AfterCommit.execute(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                sysDictSearchRepository.deleteById(dictId);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#dictId", unless = "#result == null")
    public SysDict findById(Integer dictId) {
        requirePositive(dictId);
        return sysDictSearchRepository.findById(dictId)
                .map(SysDictDocument::toEntity)
                .orElseGet(() -> {
                    SysDict entity = sysDictMapper.selectById(dictId);
                    if (entity != null) {
                        sysDictSearchRepository.save(SysDictDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<SysDict> findAll() {
        List<SysDict> fromIndex = StreamSupport.stream(sysDictSearchRepository.findAll().spliterator(), false)
                .map(SysDictDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<SysDict> fromDb = sysDictMapper.selectList(null);
        fromDb.stream()
                .map(SysDictDocument::fromEntity)
                .filter(Objects::nonNull)
                .forEach(sysDictSearchRepository::save);
        return fromDb;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'type:' + #dictType + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysDict> searchByDictType(String dictType, int page, int size) {
        if (isBlank(dictType)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysDict> index = mapHits(sysDictSearchRepository.searchByDictType(dictType, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.eq("dict_type", dictType)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'codePrefix:' + #dictCode + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysDict> searchByDictCodePrefix(String dictCode, int page, int size) {
        if (isBlank(dictCode)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysDict> index = mapHits(sysDictSearchRepository.searchByDictCodePrefix(dictCode, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.likeRight("dict_code", dictCode)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'labelPrefix:' + #dictLabel + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysDict> searchByDictLabelPrefix(String dictLabel, int page, int size) {
        if (isBlank(dictLabel)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysDict> index = mapHits(sysDictSearchRepository.searchByDictLabelPrefix(dictLabel, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.likeRight("dict_label", dictLabel)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'labelFuzzy:' + #dictLabel + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysDict> searchByDictLabelFuzzy(String dictLabel, int page, int size) {
        if (isBlank(dictLabel)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysDict> index = mapHits(sysDictSearchRepository.searchByDictLabelFuzzy(dictLabel, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.like("dict_label", dictLabel)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'parent:' + #parentId + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysDict> findByParentId(Integer parentId, int page, int size) {
        validatePagination(page, size);
        List<SysDict> index = mapHits(sysDictSearchRepository.findByParentId(parentId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.eq("parent_id", parentId)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'default:' + #isDefault + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysDict> searchByIsDefault(boolean isDefault, int page, int size) {
        validatePagination(page, size);
        List<SysDict> index = mapHits(sysDictSearchRepository.searchByIsDefault(isDefault, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.eq("is_default", isDefault)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'status:' + #status + ':' + #page + ':' + #size",
            unless = "#result == null || #result.isEmpty()")
    public List<SysDict> searchByStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysDict> index = mapHits(sysDictSearchRepository.searchByStatus(status, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Integer dictId) {
        Long businessId = dictId != null ? dictId.longValue() : null;
        if (!HistoryReserve.markSuccess(sysRequestHistoryMapper, idempotencyKey, businessId)) {
            log.log(Level.WARNING, "Idempotency key {0} is not pending, success marking skipped", idempotencyKey);
        }
    }

    public void markHistoryFailure(String idempotencyKey, String reason) {
        log.log(Level.FINE, "Marking idempotency key {0} as failed: {1}", new Object[]{idempotencyKey, reason});
        if (!HistoryReserve.markFailure(sysRequestHistoryMapper, idempotencyKey)) {
            log.log(Level.WARNING, "Idempotency key {0} is not pending, failure marking skipped", idempotencyKey);
        }
    }

    

    private void syncToIndexAfterCommit(SysDict sysDict) {
        if (sysDict == null) {
            return;
        }
        AfterCommit.execute(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                SysDictDocument doc = SysDictDocument.fromEntity(sysDict);
                if (doc != null) {
                    sysDictSearchRepository.save(doc);
                }
            }
        });
    }

    private void validateSysDict(SysDict sysDict) {
        Objects.requireNonNull(sysDict, "SysDict must not be null");
        if (sysDict.getDictType() == null || sysDict.getDictType().isBlank()) {
            throw new IllegalArgumentException("Dictionary type must not be blank");
        }
        if (sysDict.getDictCode() == null || sysDict.getDictCode().isBlank()) {
            throw new IllegalArgumentException("Dictionary code must not be blank");
        }
    }

    private List<SysDict> fetchFromDatabase(QueryWrapper<SysDict> wrapper, int page, int size) {
        Page<SysDict> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysDictMapper.selectPage(mpPage, wrapper);
        List<SysDict> records = mpPage.getRecords();
        records.stream()
                .map(SysDictDocument::fromEntity)
                .filter(Objects::nonNull)
                .forEach(sysDictSearchRepository::save);
        return records;
    }

    private List<SysDict> mapHits(org.springframework.data.elasticsearch.core.SearchHits<SysDictDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(org.springframework.data.elasticsearch.core.SearchHit::getContent)
                .map(SysDictDocument::toEntity)
                .collect(Collectors.toList());
    }

    private org.springframework.data.domain.Pageable pageable(int page, int size) {
        return org.springframework.data.domain.PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("Dictionary ID" + " must be greater than zero");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    }

