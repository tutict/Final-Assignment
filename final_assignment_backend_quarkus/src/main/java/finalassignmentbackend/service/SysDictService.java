package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.SysDict;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.SysDictMapper;
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
public class SysDictService {

    private static final Logger log = Logger.getLogger(SysDictService.class.getName());

    @Inject
    SysDictMapper sysDictMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "sysDictCache")
    @WsAction(service = "SysDictService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysDict dict, String action) {
        Objects.requireNonNull(dict, "SysDict must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate sys dict request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(dict.getDictId() != null ? dict.getDictId().longValue() : null);
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysDictCache")
    public SysDict createSysDict(SysDict dict) {
        validateDict(dict);
        sysDictMapper.insert(dict);
        return dict;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysDictCache")
    public SysDict updateSysDict(SysDict dict) {
        validateDictId(dict);
        int rows = sysDictMapper.updateById(dict);
        if (rows == 0) {
            throw new IllegalStateException("SysDict not found: " + dict.getDictId());
        }
        return dict;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysDictCache")
    public void deleteSysDict(Integer dictId) {
        requirePositive(dictId);
        int rows = sysDictMapper.deleteById(dictId);
        if (rows == 0) {
            throw new IllegalStateException("SysDict not found: " + dictId);
        }
    }

    @CacheResult(cacheName = "sysDictCache")
    public SysDict findById(Integer dictId) {
        requirePositive(dictId);
        return sysDictMapper.selectById(dictId);
    }

    @CacheResult(cacheName = "sysDictCache")
    public List<SysDict> findAll() {
        return sysDictMapper.selectList(null);
    }

    @CacheResult(cacheName = "sysDictCache")
    public List<SysDict> searchByDictType(String dictType, int page, int size) {
        if (isBlank(dictType)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.eq("dict_type", dictType);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysDictCache")
    public List<SysDict> searchByDictCodePrefix(String dictCode, int page, int size) {
        if (isBlank(dictCode)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.likeRight("dict_code", dictCode);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysDictCache")
    public List<SysDict> searchByDictLabelPrefix(String dictLabel, int page, int size) {
        if (isBlank(dictLabel)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.likeRight("dict_label", dictLabel);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysDictCache")
    public List<SysDict> searchByDictLabelFuzzy(String dictLabel, int page, int size) {
        if (isBlank(dictLabel)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.like("dict_label", dictLabel);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysDictCache")
    public List<SysDict> findByParentId(Integer parentId, int page, int size) {
        if (parentId == null) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.eq("parent_id", parentId);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysDictCache")
    public List<SysDict> searchByIsDefault(boolean isDefault, int page, int size) {
        validatePagination(page, size);
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.eq("is_default", isDefault ? 1 : 0);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysDictCache")
    public List<SysDict> searchByStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysDict> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status);
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Integer dictId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(dictId != null ? dictId.longValue() : null);
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

    private List<SysDict> fetchFromDatabase(QueryWrapper<SysDict> wrapper, int page, int size) {
        Page<SysDict> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysDictMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void validateDict(SysDict dict) {
        if (dict == null) {
            throw new IllegalArgumentException("SysDict must not be null");
        }
        if (isBlank(dict.getDictType())) {
            throw new IllegalArgumentException("Dict type must not be blank");
        }
        if (isBlank(dict.getDictLabel())) {
            throw new IllegalArgumentException("Dict label must not be blank");
        }
    }

    private void validateDictId(SysDict dict) {
        validateDict(dict);
        requirePositive(dict.getDictId());
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("Dict ID must be greater than zero");
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
