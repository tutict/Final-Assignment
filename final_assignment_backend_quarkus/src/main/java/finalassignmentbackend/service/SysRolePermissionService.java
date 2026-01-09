package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.entity.SysRolePermission;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;
import finalassignmentbackend.mapper.SysRolePermissionMapper;
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
public class SysRolePermissionService {

    private static final Logger log = Logger.getLogger(SysRolePermissionService.class.getName());

    @Inject
    SysRolePermissionMapper sysRolePermissionMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "sysRolePermissionCache")
    @WsAction(service = "SysRolePermissionService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysRolePermission relation, String action) {
        Objects.requireNonNull(relation, "SysRolePermission relation must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate role-permission request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(relation.getId());
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysRolePermissionCache")
    public SysRolePermission createRelation(SysRolePermission relation) {
        validateRelation(relation);
        sysRolePermissionMapper.insert(relation);
        return relation;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysRolePermissionCache")
    public SysRolePermission updateRelation(SysRolePermission relation) {
        validateRelationId(relation);
        int rows = sysRolePermissionMapper.updateById(relation);
        if (rows == 0) {
            throw new IllegalStateException("SysRolePermission relation not found: " + relation.getId());
        }
        return relation;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysRolePermissionCache")
    public void deleteRelation(Long relationId) {
        validateRelationId(relationId);
        int rows = sysRolePermissionMapper.deleteById(relationId);
        if (rows == 0) {
            throw new IllegalStateException("SysRolePermission relation not found: " + relationId);
        }
    }

    @CacheResult(cacheName = "sysRolePermissionCache")
    public SysRolePermission findById(Long relationId) {
        validateRelationId(relationId);
        return sysRolePermissionMapper.selectById(relationId);
    }

    @CacheResult(cacheName = "sysRolePermissionCache")
    public List<SysRolePermission> findAll(int page, int size) {
        validatePagination(page, size);
        Page<SysRolePermission> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysRolePermissionMapper.selectPage(mpPage, null);
        return mpPage.getRecords();
    }

    @CacheResult(cacheName = "sysRolePermissionCache")
    public List<SysRolePermission> findByRoleId(Integer roleId, int page, int size) {
        if (roleId == null || roleId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRolePermission> wrapper = new QueryWrapper<>();
        wrapper.eq("role_id", roleId);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRolePermissionCache")
    public List<SysRolePermission> findByPermissionId(Integer permissionId, int page, int size) {
        if (permissionId == null || permissionId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRolePermission> wrapper = new QueryWrapper<>();
        wrapper.eq("permission_id", permissionId);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRolePermissionCache")
    public List<SysRolePermission> findByRoleIdAndPermissionId(Integer roleId, Integer permissionId, int page, int size) {
        if (roleId == null || roleId <= 0 || permissionId == null || permissionId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRolePermission> wrapper = new QueryWrapper<>();
        wrapper.eq("role_id", roleId).eq("permission_id", permissionId);
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long relationId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(relationId);
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

    private List<SysRolePermission> fetchFromDatabase(QueryWrapper<SysRolePermission> wrapper, int page, int size) {
        Page<SysRolePermission> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysRolePermissionMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void validateRelation(SysRolePermission relation) {
        if (relation == null) {
            throw new IllegalArgumentException("SysRolePermission relation must not be null");
        }
        if (relation.getRoleId() == null || relation.getRoleId() <= 0) {
            throw new IllegalArgumentException("Role ID must be greater than zero");
        }
        if (relation.getPermissionId() == null || relation.getPermissionId() <= 0) {
            throw new IllegalArgumentException("Permission ID must be greater than zero");
        }
    }

    private void validateRelationId(SysRolePermission relation) {
        validateRelation(relation);
        validateRelationId(relation.getId());
    }

    private void validateRelationId(Long relationId) {
        if (relationId == null || relationId <= 0) {
            throw new IllegalArgumentException("Invalid relation ID: " + relationId);
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
