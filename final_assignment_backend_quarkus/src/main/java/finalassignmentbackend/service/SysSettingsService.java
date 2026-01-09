package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.entity.SysSettings;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;
import finalassignmentbackend.mapper.SysSettingsMapper;
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
public class SysSettingsService {

    private static final Logger log = Logger.getLogger(SysSettingsService.class.getName());

    @Inject
    SysSettingsMapper sysSettingsMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "sysSettingsCache")
    @WsAction(service = "SysSettingsService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysSettings settings, String action) {
        Objects.requireNonNull(settings, "SysSettings must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate sys settings request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(settings.getSettingId() != null ? settings.getSettingId().longValue() : null);
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysSettingsCache")
    public SysSettings createSysSettings(SysSettings settings) {
        validateSettings(settings);
        sysSettingsMapper.insert(settings);
        return settings;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysSettingsCache")
    public SysSettings updateSysSettings(SysSettings settings) {
        validateSettingsId(settings);
        int rows = sysSettingsMapper.updateById(settings);
        if (rows == 0) {
            throw new IllegalStateException("Settings not found: " + settings.getSettingId());
        }
        return settings;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysSettingsCache")
    public void deleteSysSettings(Integer settingId) {
        requirePositive(settingId);
        int rows = sysSettingsMapper.deleteById(settingId);
        if (rows == 0) {
            throw new IllegalStateException("Settings not found: " + settingId);
        }
    }

    @CacheResult(cacheName = "sysSettingsCache")
    public SysSettings findById(Integer settingId) {
        requirePositive(settingId);
        return sysSettingsMapper.selectById(settingId);
    }

    @CacheResult(cacheName = "sysSettingsCache")
    public List<SysSettings> findAll() {
        return sysSettingsMapper.selectList(null);
    }

    @CacheResult(cacheName = "sysSettingsCache")
    public SysSettings findByKey(String settingKey) {
        if (isBlank(settingKey)) {
            return null;
        }
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.eq("setting_key", settingKey);
        return sysSettingsMapper.selectOne(wrapper);
    }

    @CacheResult(cacheName = "sysSettingsCache")
    public List<SysSettings> findByCategory(String category, int page, int size) {
        if (isBlank(category)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.eq("category", category)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysSettingsCache")
    public List<SysSettings> searchBySettingKeyPrefix(String settingKey, int page, int size) {
        if (isBlank(settingKey)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.likeRight("setting_key", settingKey)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysSettingsCache")
    public List<SysSettings> searchBySettingKeyFuzzy(String settingKey, int page, int size) {
        if (isBlank(settingKey)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.like("setting_key", settingKey)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysSettingsCache")
    public List<SysSettings> searchBySettingType(String settingType, int page, int size) {
        if (isBlank(settingType)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.eq("setting_type", settingType)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysSettingsCache")
    public List<SysSettings> searchByIsEditable(boolean isEditable, int page, int size) {
        validatePagination(page, size);
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.eq("is_editable", isEditable ? 1 : 0)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysSettingsCache")
    public List<SysSettings> searchByIsEncrypted(boolean isEncrypted, int page, int size) {
        validatePagination(page, size);
        QueryWrapper<SysSettings> wrapper = new QueryWrapper<>();
        wrapper.eq("is_encrypted", isEncrypted ? 1 : 0)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
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
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
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

    private List<SysSettings> fetchFromDatabase(QueryWrapper<SysSettings> wrapper, int page, int size) {
        Page<SysSettings> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysSettingsMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
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

    private void validateSettingsId(SysSettings settings) {
        validateSettings(settings);
        requirePositive(settings.getSettingId());
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("Setting ID must be greater than zero");
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
