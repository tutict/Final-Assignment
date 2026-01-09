package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.entity.SysRole;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;
import finalassignmentbackend.mapper.SysRoleMapper;
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
public class SysRoleService {

    private static final Logger log = Logger.getLogger(SysRoleService.class.getName());

    @Inject
    SysRoleMapper sysRoleMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "sysRoleCache")
    @WsAction(service = "SysRoleService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysRole role, String action) {
        Objects.requireNonNull(role, "SysRole must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate role request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(role.getRoleId() != null ? role.getRoleId().longValue() : null);
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysRoleCache")
    public SysRole createSysRole(SysRole role) {
        validateRole(role);
        sysRoleMapper.insert(role);
        return role;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysRoleCache")
    public SysRole updateSysRole(SysRole role) {
        validateRoleId(role);
        int rows = sysRoleMapper.updateById(role);
        if (rows == 0) {
            throw new IllegalStateException("Role not found: " + role.getRoleId());
        }
        return role;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysRoleCache")
    public void deleteSysRole(Integer roleId) {
        requirePositive(roleId);
        int rows = sysRoleMapper.deleteById(roleId);
        if (rows == 0) {
            throw new IllegalStateException("Role not found: " + roleId);
        }
    }

    @CacheResult(cacheName = "sysRoleCache")
    public SysRole findById(Integer roleId) {
        requirePositive(roleId);
        return sysRoleMapper.selectById(roleId);
    }

    @CacheResult(cacheName = "sysRoleCache")
    public List<SysRole> findAll() {
        return sysRoleMapper.selectList(null);
    }

    @CacheResult(cacheName = "sysRoleCache")
    public SysRole findByRoleCode(String roleCode) {
        if (isBlank(roleCode)) {
            return null;
        }
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.eq("role_code", roleCode);
        return sysRoleMapper.selectOne(wrapper);
    }

    @CacheResult(cacheName = "sysRoleCache")
    public List<SysRole> searchByRoleCodePrefix(String roleCode, int page, int size) {
        if (isBlank(roleCode)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.likeRight("role_code", roleCode);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRoleCache")
    public List<SysRole> searchByRoleCodeFuzzy(String roleCode, int page, int size) {
        if (isBlank(roleCode)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.like("role_code", roleCode);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRoleCache")
    public List<SysRole> searchByRoleNamePrefix(String roleName, int page, int size) {
        if (isBlank(roleName)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.likeRight("role_name", roleName);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRoleCache")
    public List<SysRole> searchByRoleNameFuzzy(String roleName, int page, int size) {
        if (isBlank(roleName)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.like("role_name", roleName);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRoleCache")
    public List<SysRole> searchByRoleType(String roleType, int page, int size) {
        if (isBlank(roleType)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.eq("role_type", roleType);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRoleCache")
    public List<SysRole> searchByDataScope(String dataScope, int page, int size) {
        if (isBlank(dataScope)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.eq("data_scope", dataScope);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysRoleCache")
    public List<SysRole> searchByStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status);
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Integer roleId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(roleId != null ? roleId.longValue() : null);
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

    private List<SysRole> fetchFromDatabase(QueryWrapper<SysRole> wrapper, int page, int size) {
        Page<SysRole> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysRoleMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void validateRole(SysRole role) {
        if (role == null) {
            throw new IllegalArgumentException("SysRole must not be null");
        }
        if (isBlank(role.getRoleCode())) {
            throw new IllegalArgumentException("Role code must not be blank");
        }
        if (isBlank(role.getRoleName())) {
            throw new IllegalArgumentException("Role name must not be blank");
        }
        if (role.getCreatedAt() == null) {
            role.setCreatedAt(LocalDateTime.now());
        }
        if (role.getUpdatedAt() == null) {
            role.setUpdatedAt(LocalDateTime.now());
        }
        if (isBlank(role.getStatus())) {
            role.setStatus("Active");
        }
    }

    private void validateRoleId(SysRole role) {
        validateRole(role);
        requirePositive(role.getRoleId());
    }

    private void requirePositive(Number number) {
        if (number == null || number.longValue() <= 0) {
            throw new IllegalArgumentException("Role ID must be greater than zero");
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
