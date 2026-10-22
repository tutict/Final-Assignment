package com.tutict.finalassignmentcloud.system.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentcloud.common.transaction.AfterCommit;
import com.tutict.finalassignmentcloud.config.websocket.WsAction;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.entity.SysUser;
import com.tutict.finalassignmentcloud.entity.elastic.SysRequestHistoryDocument;
import com.tutict.finalassignmentcloud.reliability.HistoryReserve;
import com.tutict.finalassignmentcloud.reliability.IdempotencyReplayException;
import com.tutict.finalassignmentcloud.system.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentcloud.system.mapper.SysUserMapper;
import com.tutict.finalassignmentcloud.system.repository.SysRequestHistorySearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;
import com.tutict.finalassignmentcloud.reliability.LedgerFingerprint;

@Service
public class SysRequestHistoryService {

    private static final Logger log = Logger.getLogger(SysRequestHistoryService.class.getName());
    private static final String CACHE_NAME = "sysRequestHistoryCache";

    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final SysRequestHistorySearchRepository sysRequestHistorySearchRepository;
    private final SysUserMapper sysUserMapper;

    @Autowired
    public SysRequestHistoryService(SysRequestHistoryMapper sysRequestHistoryMapper,
                                    SysRequestHistorySearchRepository sysRequestHistorySearchRepository,
                                    SysUserMapper sysUserMapper) {
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.sysRequestHistorySearchRepository = sysRequestHistorySearchRepository;
        this.sysUserMapper = sysUserMapper;
    }

    @Transactional(readOnly = true)
    public Long resolveUserId(String username) {
        if (username == null || username.isBlank()) {
            return null;
        }
        SysUser user = sysUserMapper.selectOne(new QueryWrapper<SysUser>()
                .eq("username", username.trim())
                .last("LIMIT 1"));
        return user == null ? null : user.getUserId();
    }

    @Transactional(readOnly = true)
    public boolean isOwnedBy(Long id, String username) {
        if (id == null || id <= 0 || username == null || username.isBlank()) {
            return false;
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectById(id);
        if (history == null || history.getUserId() == null) {
            return false;
        }
        Long ownerId = resolveUserId(username);
        return ownerId != null && ownerId.equals(history.getUserId());
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "SysRequestHistoryService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysRequestHistory historyPayload, String action) {
        HistoryReserve.reserve(sysRequestHistoryMapper, idempotencyKey, "SYS_REQUEST_HISTORY_" + action.toUpperCase(),
                LedgerFingerprint.fingerprint(action + "|" + historyPayload.getIdempotencyKey() + "|" + historyPayload.getRequestMethod()
                        + "|" + historyPayload.getRequestUrl() + "|" + historyPayload.getBusinessType()));
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysRequestHistory createSysRequestHistory(SysRequestHistory history) {
        validateHistory(history);
        sysRequestHistoryMapper.insert(history);
        syncToIndexAfterCommit(history);
        return history;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public SysRequestHistory updateSysRequestHistory(SysRequestHistory history) {
        if (history == null) {
            throw new IllegalArgumentException("SysRequestHistory must not be null");
        }
        requirePositive(history.getId());
        SysRequestHistory existing = sysRequestHistoryMapper.selectById(history.getId());
        if (existing == null) {
            throw new IllegalStateException("SysRequestHistory not found for id=" + history.getId());
        }
        // 幂等键与创建时间描述的是“创建”这一事实，更新改写它们会让原始创建请求的重放检测失效。
        history.setIdempotencyKey(existing.getIdempotencyKey());
        history.setCreatedAt(existing.getCreatedAt());
        history.setUpdatedAt(LocalDateTime.now());
        if (isBlank(history.getBusinessType())) {
            history.setBusinessType(existing.getBusinessType());
        }
        if (isBlank(history.getBusinessStatus())) {
            history.setBusinessStatus(existing.getBusinessStatus());
        }
        int rows = sysRequestHistoryMapper.updateById(history);
        if (rows == 0) {
            throw new IllegalStateException("SysRequestHistory not found for id=" + history.getId());
        }
        SysRequestHistory merged = sysRequestHistoryMapper.selectById(history.getId());
        syncToIndexAfterCommit(merged);
        return merged;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteSysRequestHistory(Long id) {
        requirePositive(id);
        int rows = sysRequestHistoryMapper.deleteById(id);
        if (rows == 0) {
            throw new IllegalStateException("SysRequestHistory not found for id=" + id);
        }
        AfterCommit.execute(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                sysRequestHistorySearchRepository.deleteById(id);
            }
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "#id", unless = "#result == null")
    public SysRequestHistory findById(Long id) {
        requirePositive(id);
        return sysRequestHistorySearchRepository.findById(id)
                .map(SysRequestHistoryDocument::toEntity)
                .orElseGet(() -> {
                    SysRequestHistory entity = sysRequestHistoryMapper.selectById(id);
                    if (entity != null) {
                        sysRequestHistorySearchRepository.save(SysRequestHistoryDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<SysRequestHistory> findAll() {
        List<SysRequestHistory> fromIndex = StreamSupport.stream(sysRequestHistorySearchRepository.findAll().spliterator(), false)
                .map(SysRequestHistoryDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<SysRequestHistory> fromDb = sysRequestHistoryMapper.selectList(null);
        syncBatchToIndexAfterCommit(fromDb);
        return fromDb;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'status:' + #status + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRequestHistory> findByBusinessStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRequestHistory> index = mapHits(sysRequestHistorySearchRepository.searchByBusinessStatus(status, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.eq("business_status", status)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'idempotency:' + #key + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRequestHistory> searchByIdempotencyKey(String key, int page, int size) {
        if (isBlank(key)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRequestHistory> index = mapHits(sysRequestHistorySearchRepository.searchByIdempotencyKey(key, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.likeRight("idempotency_key", key)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'method:' + #requestMethod + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRequestHistory> searchByRequestMethod(String requestMethod, int page, int size) {
        if (isBlank(requestMethod)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRequestHistory> index = mapHits(sysRequestHistorySearchRepository.searchByRequestMethod(requestMethod, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.eq("request_method", requestMethod)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'urlPrefix:' + #requestUrl + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRequestHistory> searchByRequestUrlPrefix(String requestUrl, int page, int size) {
        if (isBlank(requestUrl)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRequestHistory> index = mapHits(sysRequestHistorySearchRepository.searchByRequestUrlPrefix(requestUrl, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.likeRight("request_url", requestUrl)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'businessType:' + #businessType + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRequestHistory> searchByBusinessType(String businessType, int page, int size) {
        if (isBlank(businessType)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRequestHistory> index = mapHits(sysRequestHistorySearchRepository.searchByBusinessType(businessType, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.eq("business_type", businessType)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'businessId:' + #businessId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRequestHistory> findByBusinessId(Long businessId, int page, int size) {
        if (businessId == null || businessId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRequestHistory> index = mapHits(sysRequestHistorySearchRepository.findByBusinessId(businessId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.eq("business_id", businessId)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'userId:' + #userId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRequestHistory> findByUserId(Long userId, int page, int size) {
        if (userId == null || userId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRequestHistory> index = mapHits(sysRequestHistorySearchRepository.findByUserId(userId, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'requestIp:' + #requestIp + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRequestHistory> searchByRequestIp(String requestIp, int page, int size) {
        if (isBlank(requestIp)) {
            return List.of();
        }
        validatePagination(page, size);
        List<SysRequestHistory> index = mapHits(sysRequestHistorySearchRepository.searchByRequestIp(requestIp, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.likeRight("request_ip", requestIp)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'createdRange:' + #startTime + ':' + #endTime + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<SysRequestHistory> searchByCreatedAtRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        List<SysRequestHistory> index = mapHits(sysRequestHistorySearchRepository.searchByCreatedAtRange(startTime, endTime, pageable(page, size)));
        if (!index.isEmpty()) {
            return index;
        }
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.between("created_at", start, end)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    public Optional<SysRequestHistory> findByIdempotencyKey(String key) {
        if (isBlank(key)) {
            return Optional.empty();
        }
        return Optional.ofNullable(sysRequestHistoryMapper.selectByIdempotencyKey(key));
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long historyId) {
        Long businessId = historyId;
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

    

    private void syncToIndexAfterCommit(SysRequestHistory history) {
        if (history == null) {
            return;
        }
        AfterCommit.execute(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                SysRequestHistoryDocument doc = SysRequestHistoryDocument.fromEntity(history);
                if (doc != null) {
                    sysRequestHistorySearchRepository.save(doc);
                }
            }
        });
    }

    private void syncBatchToIndexAfterCommit(List<SysRequestHistory> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        AfterCommit.execute(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                List<SysRequestHistoryDocument> documents = records.stream()
                        .filter(Objects::nonNull)
                        .map(SysRequestHistoryDocument::fromEntity)
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                if (!documents.isEmpty()) {
                    sysRequestHistorySearchRepository.saveAll(documents);
                }
            }
        });
    }

    private List<SysRequestHistory> fetchFromDatabase(QueryWrapper<SysRequestHistory> wrapper, int page, int size) {
        Page<SysRequestHistory> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysRequestHistoryMapper.selectPage(mpPage, wrapper);
        List<SysRequestHistory> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private List<SysRequestHistory> mapHits(org.springframework.data.elasticsearch.core.SearchHits<SysRequestHistoryDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return List.of();
        }
        return hits.getSearchHits().stream()
                .map(org.springframework.data.elasticsearch.core.SearchHit::getContent)
                .map(SysRequestHistoryDocument::toEntity)
                .collect(Collectors.toList());
    }

    private org.springframework.data.domain.Pageable pageable(int page, int size) {
        return org.springframework.data.domain.PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
    }

    private void validateHistory(SysRequestHistory history) {
        if (history == null) {
            throw new IllegalArgumentException("SysRequestHistory must not be null");
        }
        if (isBlank(history.getIdempotencyKey())) {
            history.setIdempotencyKey(java.util.UUID.randomUUID().toString().replace("-", ""));
        }
        if (isBlank(history.getBusinessType())) {
            history.setBusinessType("GENERAL");
        }
        if (isBlank(history.getRequestMethod())) {
            history.setRequestMethod("POST");
        }
        if (history.getRequestUrl() == null) {
            history.setRequestUrl("/api/progress");
        }
        // 共享表的时间列是秒精度，MySQL 会四舍五入纳秒；先截断可让创建响应与落库值一致。
        if (history.getCreatedAt() == null) {
            history.setCreatedAt(LocalDateTime.now().truncatedTo(ChronoUnit.SECONDS));
        }
        if (history.getUpdatedAt() == null) {
            history.setUpdatedAt(LocalDateTime.now().truncatedTo(ChronoUnit.SECONDS));
        }
        if (isBlank(history.getBusinessStatus())) {
            history.setBusinessStatus("PENDING");
        }
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private LocalDateTime parseDateTime(String value, String fieldName) {
        if (isBlank(value)) {
            return null;
        }
        try {
            return LocalDateTime.parse(value);
        } catch (DateTimeParseException ex) {
            log.log(Level.WARNING, "Failed to parse " + fieldName + ": " + value, ex);
            return null;
        }
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("History ID" + " must be greater than zero");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    }

