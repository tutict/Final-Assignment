package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.quarkus.runtime.annotations.RegisterForReflection;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
@RegisterForReflection
public class SysRequestHistoryService {

    private static final Logger log = Logger.getLogger(SysRequestHistoryService.class.getName());

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "sysRequestHistoryCache")
    @WsAction(service = "SysRequestHistoryService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysRequestHistory historyPayload, String action) {
        Objects.requireNonNull(historyPayload, "SysRequestHistory must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            throw new RuntimeException("Duplicate sys request history request detected");
        }
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(historyPayload.getId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysRequestHistoryCache")
    public SysRequestHistory createSysRequestHistory(SysRequestHistory history) {
        validateHistory(history);
        sysRequestHistoryMapper.insert(history);
        return history;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysRequestHistoryCache")
    public SysRequestHistory updateSysRequestHistory(SysRequestHistory history) {
        validateHistory(history);
        requirePositive(history.getId());
        int rows = sysRequestHistoryMapper.updateById(history);
        if (rows == 0) {
            throw new IllegalStateException("SysRequestHistory not found for id=" + history.getId());
        }
        return history;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysRequestHistoryCache")
    public void deleteSysRequestHistory(Long id) {
        requirePositive(id);
        int rows = sysRequestHistoryMapper.deleteById(id);
        if (rows == 0) {
            throw new IllegalStateException("SysRequestHistory not found for id=" + id);
        }
    }

    @CacheResult(cacheName = "sysRequestHistoryCache")
    public SysRequestHistory findById(Long id) {
        requirePositive(id);
        return sysRequestHistoryMapper.selectById(id);
    }

    @CacheResult(cacheName = "sysRequestHistoryCache")
    public List<SysRequestHistory> findAll() {
        return sysRequestHistoryMapper.selectList(null);
    }

    @CacheResult(cacheName = "sysRequestHistoryCache")
    public List<SysRequestHistory> findByBusinessStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.eq("business_status", status)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRequestHistoryCache")
    public List<SysRequestHistory> searchByIdempotencyKey(String key, int page, int size) {
        if (isBlank(key)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.likeRight("idempotency_key", key)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRequestHistoryCache")
    public List<SysRequestHistory> searchByRequestMethod(String requestMethod, int page, int size) {
        if (isBlank(requestMethod)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.eq("request_method", requestMethod)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRequestHistoryCache")
    public List<SysRequestHistory> searchByRequestUrlPrefix(String requestUrl, int page, int size) {
        if (isBlank(requestUrl)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.likeRight("request_url", requestUrl)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRequestHistoryCache")
    public List<SysRequestHistory> searchByBusinessType(String businessType, int page, int size) {
        if (isBlank(businessType)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.eq("business_type", businessType)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRequestHistoryCache")
    public List<SysRequestHistory> findByBusinessId(Long businessId, int page, int size) {
        if (businessId == null || businessId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.eq("business_id", businessId)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRequestHistoryCache")
    public List<SysRequestHistory> findByUserId(Long userId, int page, int size) {
        if (userId == null || userId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRequestHistoryCache")
    public List<SysRequestHistory> searchByRequestIp(String requestIp, int page, int size) {
        if (isBlank(requestIp)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRequestHistory> wrapper = new QueryWrapper<>();
        wrapper.likeRight("request_ip", requestIp)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRequestHistoryCache")
    public List<SysRequestHistory> searchByCreatedAtRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
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
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(historyId);
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

    private void validateHistory(SysRequestHistory history) {
        if (history == null) {
            throw new IllegalArgumentException("SysRequestHistory must not be null");
        }
        if (isBlank(history.getIdempotencyKey())) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        if (history.getCreatedAt() == null) {
            history.setCreatedAt(LocalDateTime.now());
        }
        if (history.getUpdatedAt() == null) {
            history.setUpdatedAt(LocalDateTime.now());
        }
        if (isBlank(history.getBusinessStatus())) {
            history.setBusinessStatus("PENDING");
        }
    }

    private List<SysRequestHistory> fetchFromDatabase(QueryWrapper<SysRequestHistory> wrapper, int page, int size) {
        Page<SysRequestHistory> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysRequestHistoryMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
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
            throw new IllegalArgumentException("History ID must be greater than zero");
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
