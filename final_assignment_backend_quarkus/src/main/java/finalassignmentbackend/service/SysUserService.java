package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.entity.SysUser;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;
import finalassignmentbackend.mapper.SysUserMapper;
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
import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
@RegisterForReflection
public class SysUserService {

    private static final Logger log = Logger.getLogger(SysUserService.class.getName());

    @Inject
    SysUserMapper sysUserMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "sysUserCache")
    @WsAction(service = "SysUserService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, SysUser user, String action) {
        Objects.requireNonNull(user, "SysUser must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate sys user request detected");
        }
        SysRequestHistory newHistory = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(newHistory);
        newHistory.setBusinessStatus("SUCCESS");
        newHistory.setBusinessId(user.getUserId());
        newHistory.setRequestParams("PENDING");
        newHistory.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(newHistory);
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysUserCache")
    public SysUser createSysUser(SysUser user) {
        validateUser(user);
        sysUserMapper.insert(user);
        return user;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysUserCache")
    public SysUser updateSysUser(SysUser user) {
        validateUserId(user);
        int rows = sysUserMapper.updateById(user);
        if (rows == 0) {
            throw new IllegalStateException("User not found: " + user.getUserId());
        }
        return user;
    }

    @Transactional
    @CacheInvalidate(cacheName = "sysUserCache")
    public void deleteSysUser(Long userId) {
        validateUserId(userId);
        int rows = sysUserMapper.deleteById(userId);
        if (rows == 0) {
            throw new IllegalStateException("User not found: " + userId);
        }
    }

    @CacheResult(cacheName = "sysUserCache")
    public SysUser findById(Long userId) {
        validateUserId(userId);
        return sysUserMapper.selectById(userId);
    }

    @CacheResult(cacheName = "sysUserCache")
    public List<SysUser> findAll() {
        return sysUserMapper.selectList(null);
    }

    @CacheResult(cacheName = "sysUserCache")
    public SysUser findByUsername(String username) {
        if (isBlank(username)) {
            return null;
        }
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.eq("username", username);
        return sysUserMapper.selectOne(wrapper);
    }

    @CacheResult(cacheName = "sysUserCache")
    public List<SysUser> searchByUsernamePrefix(String username, int page, int size) {
        if (isBlank(username)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.likeRight("username", username);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysUserCache")
    public List<SysUser> searchByUsernameFuzzy(String username, int page, int size) {
        if (isBlank(username)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.like("username", username);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysUserCache")
    public List<SysUser> searchByRealNamePrefix(String realName, int page, int size) {
        if (isBlank(realName)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.likeRight("real_name", realName);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysUserCache")
    public List<SysUser> searchByRealNameFuzzy(String realName, int page, int size) {
        if (isBlank(realName)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.like("real_name", realName);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysUserCache")
    public List<SysUser> searchByIdCardNumber(String idCardNumber, int page, int size) {
        if (isBlank(idCardNumber)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.likeRight("id_card_number", idCardNumber);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysUserCache")
    public List<SysUser> searchByContactNumber(String contactNumber, int page, int size) {
        if (isBlank(contactNumber)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.likeRight("contact_number", contactNumber);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysUserCache")
    public List<SysUser> findByStatus(String status, int page, int size) {
        if (isBlank(status)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysUserCache")
    public List<SysUser> findByDepartment(String department, int page, int size) {
        if (isBlank(department)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.eq("department", department);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysUserCache")
    public List<SysUser> searchByDepartmentPrefix(String department, int page, int size) {
        if (isBlank(department)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.likeRight("department", department);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysUserCache")
    public List<SysUser> searchByEmployeeNumber(String employeeNumber, int page, int size) {
        if (isBlank(employeeNumber)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.eq("employee_number", employeeNumber);
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "sysUserCache")
    public List<SysUser> searchByLastLoginTimeRange(String startTime, String endTime, int page, int size) {
        validatePagination(page, size);
        LocalDateTime start = parseDateTime(startTime, "startTime");
        LocalDateTime end = parseDateTime(endTime, "endTime");
        if (start == null || end == null) {
            return List.of();
        }
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.between("last_login_time", start, end);
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long userId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(userId);
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

    private List<SysUser> fetchFromDatabase(QueryWrapper<SysUser> wrapper, int page, int size) {
        Page<SysUser> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        sysUserMapper.selectPage(mpPage, wrapper);
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

    private void validateUser(SysUser user) {
        if (user == null) {
            throw new IllegalArgumentException("SysUser must not be null");
        }
        if (isBlank(user.getUsername())) {
            throw new IllegalArgumentException("Username must not be blank");
        }
        if (isBlank(user.getPassword())) {
            throw new IllegalArgumentException("Password must not be blank");
        }
        if (user.getCreatedAt() == null) {
            user.setCreatedAt(LocalDateTime.now());
        }
        if (user.getUpdatedAt() == null) {
            user.setUpdatedAt(LocalDateTime.now());
        }
        if (isBlank(user.getStatus())) {
            user.setStatus("Active");
        }
    }

    private void validateUserId(SysUser user) {
        validateUser(user);
        validateUserId(user.getUserId());
    }

    private void validateUserId(Long userId) {
        if (userId == null || userId <= 0) {
            throw new IllegalArgumentException("Invalid user ID: " + userId);
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
