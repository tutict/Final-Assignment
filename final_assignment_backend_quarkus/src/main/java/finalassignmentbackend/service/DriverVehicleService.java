package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.DriverVehicle;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.mapper.DriverVehicleMapper;
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
public class DriverVehicleService {

    private static final Logger log = Logger.getLogger(DriverVehicleService.class.getName());

    @Inject
    DriverVehicleMapper driverVehicleMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "driverVehicleCache")
    @WsAction(service = "DriverVehicleService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, DriverVehicle relation, String action) {
        Objects.requireNonNull(relation, "DriverVehicle relation must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history != null) {
            throw new RuntimeException("Duplicate driver-vehicle request detected");
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
    @CacheInvalidate(cacheName = "driverVehicleCache")
    public DriverVehicle createBinding(DriverVehicle relation) {
        validateRelation(relation);
        driverVehicleMapper.insert(relation);
        return relation;
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverVehicleCache")
    public DriverVehicle updateBinding(DriverVehicle relation) {
        validateRelationId(relation);
        int rows = driverVehicleMapper.updateById(relation);
        if (rows == 0) {
            throw new IllegalStateException("DriverVehicle binding not found: " + relation.getId());
        }
        return relation;
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverVehicleCache")
    public void deleteBinding(Long bindingId) {
        validateRelationId(bindingId);
        int rows = driverVehicleMapper.deleteById(bindingId);
        if (rows == 0) {
            throw new IllegalStateException("DriverVehicle binding not found: " + bindingId);
        }
    }

    @CacheResult(cacheName = "driverVehicleCache")
    public DriverVehicle findById(Long bindingId) {
        validateRelationId(bindingId);
        return driverVehicleMapper.selectById(bindingId);
    }

    @CacheResult(cacheName = "driverVehicleCache")
    public List<DriverVehicle> findAll() {
        return driverVehicleMapper.selectList(null);
    }

    @CacheResult(cacheName = "driverVehicleCache")
    public List<DriverVehicle> findByVehicleId(Long vehicleId, int page, int size) {
        if (vehicleId == null || vehicleId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<DriverVehicle> wrapper = new QueryWrapper<>();
        wrapper.eq("vehicle_id", vehicleId)
                .orderByDesc("created_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "driverVehicleCache")
    public List<DriverVehicle> findByDriverId(Long driverId, int page, int size) {
        if (driverId == null || driverId <= 0) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<DriverVehicle> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .orderByDesc("created_at");
        return fetchFromDatabase(wrapper, page, size);
    }

    @CacheResult(cacheName = "driverVehicleCache")
    public List<DriverVehicle> findPrimaryBinding(Long driverId) {
        if (driverId == null || driverId <= 0) {
            return List.of();
        }
        QueryWrapper<DriverVehicle> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .eq("is_primary", 1);
        return driverVehicleMapper.selectList(wrapper);
    }

    @CacheResult(cacheName = "driverVehicleCache")
    public List<DriverVehicle> searchByRelationship(String relationship, int page, int size) {
        if (isBlank(relationship)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<DriverVehicle> wrapper = new QueryWrapper<>();
        wrapper.eq("relationship", relationship);
        return fetchFromDatabase(wrapper, page, size);
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long bindingId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(bindingId);
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

    private List<DriverVehicle> fetchFromDatabase(QueryWrapper<DriverVehicle> wrapper, int page, int size) {
        Page<DriverVehicle> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        driverVehicleMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void validateRelation(DriverVehicle relation) {
        if (relation == null) {
            throw new IllegalArgumentException("DriverVehicle relation must not be null");
        }
        if (relation.getDriverId() == null || relation.getDriverId() <= 0) {
            throw new IllegalArgumentException("Driver ID must be greater than zero");
        }
        if (relation.getVehicleId() == null || relation.getVehicleId() <= 0) {
            throw new IllegalArgumentException("Vehicle ID must be greater than zero");
        }
    }

    private void validateRelationId(DriverVehicle relation) {
        validateRelation(relation);
        validateRelationId(relation.getId());
    }

    private void validateRelationId(Long bindingId) {
        if (bindingId == null || bindingId <= 0) {
            throw new IllegalArgumentException("Invalid binding ID: " + bindingId);
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
