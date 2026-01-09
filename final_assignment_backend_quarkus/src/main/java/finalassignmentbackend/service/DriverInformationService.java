package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.DriverInformation;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.DriverInformationMapper;
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
public class DriverInformationService {

    private static final Logger log = Logger.getLogger(DriverInformationService.class.getName());

    @Inject
    DriverInformationMapper driverInformationMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    @WsAction(service = "DriverInformationService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, DriverInformation driverInformation, String action) {
        Objects.requireNonNull(driverInformation, "Driver information must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            throw new RuntimeException("Duplicate driver request detected");
        }
        SysRequestHistory history = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(history);
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(driverInformation.getDriverId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    public DriverInformation createDriver(DriverInformation driverInformation) {
        validateDriver(driverInformation);
        driverInformationMapper.insert(driverInformation);
        return driverInformation;
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    public DriverInformation updateDriver(DriverInformation driverInformation) {
        validateDriverId(driverInformation);
        int rows = driverInformationMapper.updateById(driverInformation);
        if (rows == 0) {
            throw new IllegalStateException("Driver not found: " + driverInformation.getDriverId());
        }
        return driverInformation;
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    @WsAction(service = "DriverInformationService", action = "deleteDriver")
    public void deleteDriver(Long driverId) {
        validateDriverId(driverId);
        int rows = driverInformationMapper.deleteById(driverId);
        if (rows == 0) {
            throw new IllegalStateException("Driver not found: " + driverId);
        }
    }

    @CacheResult(cacheName = "driverCache")
    @WsAction(service = "DriverInformationService", action = "getDriverById")
    public DriverInformation getDriverById(Long driverId) {
        validateDriverId(driverId);
        return driverInformationMapper.selectById(driverId);
    }

    @CacheResult(cacheName = "driverCache")
    @WsAction(service = "DriverInformationService", action = "getAllDrivers")
    public List<DriverInformation> getAllDrivers() {
        return driverInformationMapper.selectList(null);
    }

    @CacheResult(cacheName = "driverCache")
    public List<DriverInformation> searchByIdCardNumber(String keywords, int page, int size) {
        if (isBlank(keywords)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<DriverInformation> wrapper = new QueryWrapper<>();
        wrapper.likeRight("id_card_number", keywords)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "driverCache")
    public List<DriverInformation> searchByDriverLicenseNumber(String keywords, int page, int size) {
        if (isBlank(keywords)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<DriverInformation> wrapper = new QueryWrapper<>();
        wrapper.likeRight("driver_license_number", keywords)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "driverCache")
    public List<DriverInformation> searchByName(String keywords, int page, int size) {
        if (isBlank(keywords)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<DriverInformation> wrapper = new QueryWrapper<>();
        wrapper.like("name", keywords)
                .orderByDesc("updated_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long driverId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(driverId);
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

    private List<DriverInformation> fetchFromDatabase(QueryWrapper<DriverInformation> wrapper, int page, int size) {
        Page<DriverInformation> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        driverInformationMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void validateDriver(DriverInformation driverInformation) {
        if (driverInformation == null) {
            throw new IllegalArgumentException("Driver information must not be null");
        }
        if (isBlank(driverInformation.getName())) {
            throw new IllegalArgumentException("Driver name must not be blank");
        }
        if (isBlank(driverInformation.getIdCardNumber())) {
            throw new IllegalArgumentException("Driver id card must not be blank");
        }
    }

    private void validateDriverId(DriverInformation driverInformation) {
        validateDriver(driverInformation);
        validateDriverId(driverInformation.getDriverId());
    }

    private void validateDriverId(Long driverId) {
        if (driverId == null || driverId <= 0) {
            throw new IllegalArgumentException("Invalid driver ID: " + driverId);
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
