package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import finalassignmentbackend.config.websocket.WsAction;
import finalassignmentbackend.entity.SysRequestHistory;
import finalassignmentbackend.entity.VehicleInformation;
import finalassignmentbackend.mapper.SysRequestHistoryMapper;
import finalassignmentbackend.mapper.VehicleInformationMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.quarkus.runtime.annotations.RegisterForReflection;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@ApplicationScoped
@RegisterForReflection
public class VehicleInformationService {

    private static final Logger log = Logger.getLogger(VehicleInformationService.class.getName());

    @Inject
    VehicleInformationMapper vehicleInformationMapper;

    @Inject
    SysRequestHistoryMapper sysRequestHistoryMapper;

    @Transactional
    @CacheInvalidate(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, VehicleInformation vehicleInformation, String action) {
        Objects.requireNonNull(vehicleInformation, "Vehicle information must not be null");
        if (isBlank(idempotencyKey)) {
            throw new IllegalArgumentException("Idempotency key must not be blank");
        }
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            throw new RuntimeException("Duplicate vehicle request detected");
        }
        SysRequestHistory history = buildHistory(idempotencyKey);
        sysRequestHistoryMapper.insert(history);
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(vehicleInformation.getVehicleId());
        history.setRequestParams("PENDING");
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheInvalidate(cacheName = "vehicleCache")
    public VehicleInformation createVehicleInformation(VehicleInformation vehicleInformation) {
        validateVehicle(vehicleInformation);
        vehicleInformationMapper.insert(vehicleInformation);
        return vehicleInformation;
    }

    @Transactional
    @CacheInvalidate(cacheName = "vehicleCache")
    public VehicleInformation updateVehicleInformation(VehicleInformation vehicleInformation) {
        validateVehicleId(vehicleInformation);
        int rows = vehicleInformationMapper.updateById(vehicleInformation);
        if (rows == 0) {
            throw new IllegalStateException("Vehicle not found: " + vehicleInformation.getVehicleId());
        }
        return vehicleInformation;
    }

    @Transactional
    @CacheInvalidate(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "deleteVehicleInformation")
    public void deleteVehicleInformation(Long vehicleId) {
        validateVehicleId(vehicleId);
        int rows = vehicleInformationMapper.deleteById(vehicleId);
        if (rows == 0) {
            throw new IllegalStateException("Vehicle not found: " + vehicleId);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "deleteVehicleInformationByLicensePlate")
    public void deleteVehicleInformationByLicensePlate(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        vehicleInformationMapper.delete(queryWrapper);
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationById")
    public VehicleInformation getVehicleInformationById(Long vehicleId) {
        validateVehicleId(vehicleId);
        return vehicleInformationMapper.selectById(vehicleId);
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getAllVehicleInformation")
    public List<VehicleInformation> getAllVehicleInformation() {
        return vehicleInformationMapper.selectList(null);
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByLicensePlate")
    public VehicleInformation getVehicleInformationByLicensePlate(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        return vehicleInformationMapper.selectOne(queryWrapper);
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByIdCardNumber")
    public List<VehicleInformation> getVehicleInformationByIdCardNumber(String idCardNumber) {
        validateInput(idCardNumber, "Invalid id card number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("owner_id_card", idCardNumber);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByType")
    public List<VehicleInformation> getVehicleInformationByType(String vehicleType) {
        validateInput(vehicleType, "Invalid vehicle type");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("vehicle_type", vehicleType);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByOwnerName")
    public List<VehicleInformation> getVehicleInformationByOwnerName(String ownerName) {
        validateInput(ownerName, "Invalid owner name");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("owner_name", ownerName);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByStatus")
    public List<VehicleInformation> getVehicleInformationByStatus(String status) {
        validateInput(status, "Invalid status");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", status);
        return vehicleInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "searchVehicles")
    public List<VehicleInformation> searchVehicles(String keywords, int page, int size) {
        if (isBlank(keywords)) {
            return List.of();
        }
        validatePagination(page, size);
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("license_plate", keywords)
                .or().like("owner_name", keywords)
                .or().like("owner_id_card", keywords)
                .orderByDesc("updated_at");
        return fetchFromDatabase(queryWrapper, page, size);
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByLicensePlateGlobally")
    public List<String> getVehicleInformationByLicensePlateGlobally(String prefix, int size) {
        if (isBlank(prefix)) {
            return List.of();
        }
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.likeRight("license_plate", prefix)
                .last("LIMIT " + Math.max(size, 1));
        return vehicleInformationMapper.selectList(queryWrapper).stream()
                .map(VehicleInformation::getLicensePlate)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getLicensePlateAutocompleteSuggestions")
    public List<String> getLicensePlateAutocompleteSuggestions(String prefix, int size, String idCard) {
        if (isBlank(prefix) || isBlank(idCard)) {
            return List.of();
        }
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("owner_id_card", idCard)
                .likeRight("license_plate", prefix)
                .last("LIMIT " + Math.max(size, 1));
        return vehicleInformationMapper.selectList(queryWrapper).stream()
                .map(VehicleInformation::getLicensePlate)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleTypeAutocompleteSuggestions")
    public List<String> getVehicleTypeAutocompleteSuggestions(String idCard, String prefix, int size) {
        if (isBlank(idCard) || isBlank(prefix)) {
            return List.of();
        }
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("owner_id_card", idCard)
                .likeRight("vehicle_type", prefix)
                .last("LIMIT " + Math.max(size, 1));
        return vehicleInformationMapper.selectList(queryWrapper).stream()
                .map(VehicleInformation::getVehicleType)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleTypesByPrefixGlobally")
    public List<String> getVehicleTypesByPrefixGlobally(String prefix, int size) {
        if (isBlank(prefix)) {
            return List.of();
        }
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.likeRight("vehicle_type", prefix)
                .last("LIMIT " + Math.max(size, 1));
        return vehicleInformationMapper.selectList(queryWrapper).stream()
                .map(VehicleInformation::getVehicleType)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
    }

    @CacheResult(cacheName = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "isLicensePlateExists")
    public boolean isLicensePlateExists(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        return vehicleInformationMapper.selectCount(queryWrapper) > 0;
    }

    public boolean shouldSkipProcessing(String idempotencyKey) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        return history != null
                && "SUCCESS".equalsIgnoreCase(history.getBusinessStatus())
                && "DONE".equalsIgnoreCase(history.getRequestParams());
    }

    public void markHistorySuccess(String idempotencyKey, Long vehicleId) {
        SysRequestHistory history = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (history == null) {
            log.log(Level.WARNING, "Cannot mark success for missing idempotency key {0}", idempotencyKey);
            return;
        }
        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(vehicleId);
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

    private List<VehicleInformation> fetchFromDatabase(QueryWrapper<VehicleInformation> wrapper, int page, int size) {
        Page<VehicleInformation> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        vehicleInformationMapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void validateVehicle(VehicleInformation vehicleInformation) {
        if (vehicleInformation == null) {
            throw new IllegalArgumentException("Vehicle information must not be null");
        }
        if (isBlank(vehicleInformation.getLicensePlate())) {
            throw new IllegalArgumentException("License plate must not be blank");
        }
    }

    private void validateVehicleId(VehicleInformation vehicleInformation) {
        validateVehicle(vehicleInformation);
        validateVehicleId(vehicleInformation.getVehicleId());
    }

    private void validateVehicleId(Long vehicleId) {
        if (vehicleId == null || vehicleId <= 0) {
            throw new IllegalArgumentException("Invalid vehicle ID: " + vehicleId);
        }
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
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
