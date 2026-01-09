package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.SysPermission;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.SysPermissionMapper;
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
public class SysPermissionService {

    private static final Logger log = Logger.getLogger(SysPermissionService.class.getName());

    @Inject
    SysPermissionMapper sysPermissionMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "sysPermissionCache")
    @WsAction(service = "SysPermissionService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysPermission permission, String action) {
        Objects.requireNonNull(permission, "SysPermission must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate permission request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(permission.getPermissionId() != null ? permission.getPermissionId().longValue() : null);
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysPermissionCache")
    public SysPermission createSysPermission(SysPermission permission) {
        validatePermission(permission);
        sysPermissionMapper.insert(permission);
        return permission;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysPermissionCache")
    public SysPermission updateSysPermission(SysPermission permission) {
        validatePermissionId(permission);
        int rows = sysPermissionMapper.updateById(permission);
        if (rows == 0) {
            throw new IllegalStateException("Permission not found: " + permission.getPermissionId());
        }
        return permission;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysPermissionCache")
    public void deleteSysPermission(Integer permissionId) {
        requirePositive(permissionId);
        int rows = sysPermissionMapper.deleteById(permissionId);
        if (rows == 0) {
            throw new IllegalStateException("Permission not found: " + permissionId);
        }
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public SysPermission findById(Integer permissionId) {
        requirePositive(permissionId);
        return sysPermissionMapper.selectById(permissionId);
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public List<SysPermission> findAll() {
        return sysPermissionMapper.selectList(null);
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public List<SysPermission> findByParentId(Integer parentId, int page, int size) {
        if (parentId == null || parentId < 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysPermission> wrapper = new QueryWrapper<>();
        wrapper.eq("parent_id", parentId)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public List<SysPermission> searchByPermissionCodePrefix(String permissionCode, int page, int size) {
        if (isBlank(permissionCode)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysPermission> wrapper = new QueryWrapper<>();
        wrapper.likeRight("permission_code", permissionCode)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public List<SysPermission> searchByPermissionCodeFuzzy(String permissionCode, int page, int size) {
        if (isBlank(permissionCode)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysPermission> wrapper = new QueryWrapper<>();
        wrapper.like("permission_code", permissionCode)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public List<SysPermission> searchByPermissionNamePrefix(String permissionName, int page, int size) {
        if (isBlank(permissionName)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysPermission> wrapper = new QueryWrapper<>();
        wrapper.likeRight("permission_name", permissionName)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public List<SysPermission> searchByPermissionNameFuzzy(String permissionName, int page, int size) {
        if (isBlank(permissionName)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysPermission> wrapper = new QueryWrapper<>();
        wrapper.like("permission_name", permissionName)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public List<SysPermission> searchByPermissionType(String permissionType, int page, int size) {
        if (isBlank(permissionType)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysPermission> wrapper = new QueryWrapper<>();
        wrapper.eq("permission_type", permissionType)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public List<SysPermission> searchByApiPathPrefix(String apiPath, int page, int size) {
        if (isBlank(apiPath)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysPermission> wrapper = new QueryWrapper<>();
        wrapper.likeRight("api_path", apiPath)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public List<SysPermission> searchByMenuPathPrefix(String menuPath, int page, int size) {
        if (isBlank(menuPath)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysPermission> wrapper = new QueryWrapper<>();
        wrapper.likeRight("menu_path", menuPath)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public List<SysPermission> searchByIsVisible(boolean isVisible, int page, int size) {
        validatePagination(page, size);
        QueryWrapper<SysPermission> wrapper = new QueryWrapper<>();
        wrapper.eq("is_visible", isVisible ? 1 : 0)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public List<SysPermission> searchByIsExternal(boolean isExternal, int page, int size) {
        validatePagination(page, size);
        QueryWrapper<SysPermission> wrapper = new QueryWrapper<>();
        wrapper.eq("is_external", isExternal ? 1 : 0)
                .orderByAsc("sort_order");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysPermissionCache")
    public List<SysPermission> searchByStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysPermission> wrapper = new QueryWrapper<>();
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

    public void markHistorySuccess(String idempotencyKey, Integer permissionId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(permissionId != null ? permissionId.longValue() : null);
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

    private List<SysPermission> fetchFromDatabase(QueryWrapper<SysPermission> wrapper, int page, int size) {
        Page<SysPermission> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysPermissionMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void validatePermission(SysPermission permission) {
        if (permission == null) {
            throw new IllegalArgumentException("SysPermission must not be null");
        }
        if (isBlank(permission.getPermissionCode())) {
            throw new IllegalArgumentException("Permission code must not be blank");
        }
        if (isBlank(permission.getPermissionName())) {
            throw new IllegalArgumentException("Permission name must not be blank");
        }
        if (permission.getCreatedAt() == null) {
            permission.setCreatedAt(LocalDateTime.now());
        }
        if (permission.getUpdatedAt() == null) {
            permission.setUpdatedAt(LocalDateTime.now());
        }
        if (isBlank(permission.getStatus())) {
            permission.setStatus("Active");
        }
    }

    private void validatePermissionId(SysPermission permission) {
        validatePermission(permission);
        requirePositive(permission.getPermissionId());
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("Permission ID must be greater than zero");
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
