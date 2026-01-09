package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.entity.SysUserRole;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;
import finalassignmentbackend.mapper.SysUserRoleMapper;
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
public class SysUserRoleService {

    private static final Logger log = Logger.getLogger(SysUserRoleService.class.getName());

    @Inject
    SysUserRoleMapper sysUserRoleMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "sysUserRoleCache")
    @WsAction(service = "SysUserRoleService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysUserRole relation, String action) {
        Objects.requireNonNull(relation, "SysUserRole relation must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate user-role request detected");
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
    @CacheInvalidate(cacheName = "sysUserRoleCache")
    public SysUserRole createRelation(SysUserRole relation) {
        validateRelation(relation);
        sysUserRoleMapper.insert(relation);
        return relation;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysUserRoleCache")
    public SysUserRole updateRelation(SysUserRole relation) {
        validateRelationId(relation);
        int rows = sysUserRoleMapper.updateById(relation);
        if (rows == 0) {
            throw new IllegalStateException("SysUserRole relation not found: " + relation.getId());
        }
        return relation;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysUserRoleCache")
    public void deleteRelation(Long relationId) {
        validateRelationId(relationId);
        int rows = sysUserRoleMapper.deleteById(relationId);
        if (rows == 0) {
            throw new IllegalStateException("SysUserRole relation not found: " + relationId);
        }
    }

    @CacheResult(cacheName = "sysUserRoleCache")
    public SysUserRole findById(Long relationId) {
        validateRelationId(relationId);
        return sysUserRoleMapper.selectById(relationId);
    }

    @CacheResult(cacheName = "sysUserRoleCache")
    public List<SysUserRole> findAll(int page, int size) {
        validatePagination(page, size);
        Page<SysUserRole> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysUserRoleMapper.selectPage(mpPage, null);
        return mpPage.getRecords();
    }

    @CacheResult(cacheName = "sysUserRoleCache")
    public List<SysUserRole> findAll() {
        return sysUserRoleMapper.selectList(null);
    }

    @CacheResult(cacheName = "sysUserRoleCache")
    public List<SysUserRole> findByUserId(Long userId, int page, int size) {
        if (userId == null || userId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUserRole> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysUserRoleCache")
    public List<SysUserRole> findByRoleId(Integer roleId, int page, int size) {
        if (roleId == null || roleId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUserRole> wrapper = new QueryWrapper<>();
        wrapper.eq("role_id", roleId);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysUserRoleCache")
    public List<SysUserRole> findByUserIdAndRoleId(Long userId, Integer roleId, int page, int size) {
        if (userId == null || userId <= 0 || roleId == null || roleId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUserRole> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId).eq("role_id", roleId);
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

    private List<SysUserRole> fetchFromDatabase(QueryWrapper<SysUserRole> wrapper, int page, int size) {
        Page<SysUserRole> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysUserRoleMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void validateRelation(SysUserRole relation) {
        if (relation == null) {
            throw new IllegalArgumentException("SysUserRole relation must not be null");
        }
        if (relation.getUserId() == null || relation.getUserId() <= 0) {
            throw new IllegalArgumentException("User ID must be greater than zero");
        }
        if (relation.getRoleId() == null || relation.getRoleId() <= 0) {
            throw new IllegalArgumentException("Role ID must be greater than zero");
        }
    }

    private void validateRelationId(SysUserRole relation) {
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
