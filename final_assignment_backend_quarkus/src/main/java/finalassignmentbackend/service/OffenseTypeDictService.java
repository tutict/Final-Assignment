package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.OffenseTypeDict;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.OffenseTypeDictMapper;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.quarkus.runtime.annotations.RegisterForReflection;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
@RegisterForReflection
public class OffenseTypeDictService {

    private static final Logger log = Logger.getLogger(OffenseTypeDictService.class.getName());

    @Inject
    OffenseTypeDictMapper offenseTypeDictMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "offenseTypeDictCache")
    @WsAction(service = "OffenseTypeDictService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, OffenseTypeDict dict, String action) {
        Objects.requireNonNull(dict, "OffenseTypeDict must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate offense type dict request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(dict.getTypeId() != null ? dict.getTypeId().longValue() : null);
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseTypeDictCache")
    public OffenseTypeDict createDict(OffenseTypeDict dict) {
        validateDict(dict);
        offenseTypeDictMapper.insert(dict);
        return dict;
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseTypeDictCache")
    public OffenseTypeDict updateDict(OffenseTypeDict dict) {
        validateDict(dict);
        requirePositive(dict.getTypeId());
        int rows = offenseTypeDictMapper.updateById(dict);
        if (rows == 0) {
            throw new IllegalStateException("No OffenseTypeDict updated for id=" + dict.getTypeId());
        }
        return dict;
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseTypeDictCache")
    public void deleteDict(Integer typeId) {
        requirePositive(typeId);
        int rows = offenseTypeDictMapper.deleteById(typeId);
        if (rows == 0) {
            throw new IllegalStateException("No OffenseTypeDict deleted for id=" + typeId);
        }
    }

    @CacheResult(cacheName = "offenseTypeDictCache")
    public OffenseTypeDict findById(Integer typeId) {
        requirePositive(typeId);
        return offenseTypeDictMapper.selectById(typeId);
    }

    @CacheResult(cacheName = "offenseTypeDictCache")
    public List<OffenseTypeDict> findAll() {
        return offenseTypeDictMapper.selectList(null);
    }

    @CacheResult(cacheName = "offenseTypeDictCache")
    public List<OffenseTypeDict> searchByOffenseCodePrefix(String offenseCode, int page, int size) {
        if (isBlank(offenseCode)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseTypeDict> wrapper = new QueryWrapper<>();
        wrapper.likeRight("offense_code", offenseCode);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseTypeDictCache")
    public List<OffenseTypeDict> searchByOffenseCodeFuzzy(String offenseCode, int page, int size) {
        if (isBlank(offenseCode)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseTypeDict> wrapper = new QueryWrapper<>();
        wrapper.like("offense_code", offenseCode);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseTypeDictCache")
    public List<OffenseTypeDict> searchByOffenseNamePrefix(String offenseName, int page, int size) {
        if (isBlank(offenseName)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseTypeDict> wrapper = new QueryWrapper<>();
        wrapper.likeRight("offense_name", offenseName);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseTypeDictCache")
    public List<OffenseTypeDict> searchByOffenseNameFuzzy(String offenseName, int page, int size) {
        if (isBlank(offenseName)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseTypeDict> wrapper = new QueryWrapper<>();
        wrapper.like("offense_name", offenseName);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseTypeDictCache")
    public List<OffenseTypeDict> searchByCategory(String category, int page, int size) {
        if (isBlank(category)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseTypeDict> wrapper = new QueryWrapper<>();
        wrapper.eq("category", category);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseTypeDictCache")
    public List<OffenseTypeDict> searchBySeverityLevel(String severityLevel, int page, int size) {
        if (isBlank(severityLevel)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseTypeDict> wrapper = new QueryWrapper<>();
        wrapper.eq("severity_level", severityLevel);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseTypeDictCache")
    public List<OffenseTypeDict> searchByStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<OffenseTypeDict> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseTypeDictCache")
    public List<OffenseTypeDict> searchByStandardFineAmountRange(double minAmount, double maxAmount, int page, int size) {
        validatePagination(page, size);
        if (minAmount > maxAmount) {
            return List.of();
        }
        QueryWrapper<OffenseTypeDict> wrapper = new QueryWrapper<>();
        wrapper.between("standard_fine_amount", minAmount, maxAmount);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "offenseTypeDictCache")
    public List<OffenseTypeDict> searchByDeductedPointsRange(int minPoints, int maxPoints, int page, int size) {
        validatePagination(page, size);
        if (minPoints > maxPoints) {
            return List.of();
        }
        QueryWrapper<OffenseTypeDict> wrapper = new QueryWrapper<>();
        wrapper.between("deducted_points", minPoints, maxPoints);
        return fetchFromDatabase(wrapper, page, size);
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

    private SysRequestHistory buildHistory(String key) {
        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(key);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        history.setUpdatedAt(LocalDateTime.now());
        return history;
    }

    private List<OffenseTypeDict> fetchFromDatabase(QueryWrapper<OffenseTypeDict> wrapper, int page, int size) {
        Page<OffenseTypeDict> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        offenseTypeDictMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validateDict(OffenseTypeDict dict) {
        if (dict == null) {
            throw new IllegalArgumentException("OffenseTypeDict must not be null");
        }
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

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("Type ID must be greater than zero");
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
