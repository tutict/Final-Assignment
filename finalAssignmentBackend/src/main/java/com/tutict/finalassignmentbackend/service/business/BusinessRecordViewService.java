package com.tutict.finalassignmentbackend.service.business;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.entity.admin.SysUser;
import com.tutict.finalassignmentbackend.entity.appeal.AppealRecord;
import com.tutict.finalassignmentbackend.entity.driver.DriverInformation;
import com.tutict.finalassignmentbackend.entity.driver.VehicleInformation;
import com.tutict.finalassignmentbackend.entity.offense.DeductionRecord;
import com.tutict.finalassignmentbackend.entity.offense.FineRecord;
import com.tutict.finalassignmentbackend.entity.offense.OffenseRecord;
import com.tutict.finalassignmentbackend.mapper.admin.SysUserMapper;
import com.tutict.finalassignmentbackend.mapper.appeal.AppealRecordMapper;
import com.tutict.finalassignmentbackend.mapper.driver.DriverInformationMapper;
import com.tutict.finalassignmentbackend.mapper.driver.VehicleInformationMapper;
import com.tutict.finalassignmentbackend.mapper.offense.DeductionRecordMapper;
import com.tutict.finalassignmentbackend.mapper.offense.FineRecordMapper;
import com.tutict.finalassignmentbackend.mapper.offense.OffenseRecordMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.Serializable;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class BusinessRecordViewService {

    private final DriverInformationMapper driverInformationMapper;
    private final VehicleInformationMapper vehicleInformationMapper;
    private final OffenseRecordMapper offenseRecordMapper;
    private final FineRecordMapper fineRecordMapper;
    private final DeductionRecordMapper deductionRecordMapper;
    private final AppealRecordMapper appealRecordMapper;
    private final SysUserMapper sysUserMapper;

    public BusinessRecordViewService(DriverInformationMapper driverInformationMapper,
                                     VehicleInformationMapper vehicleInformationMapper,
                                     OffenseRecordMapper offenseRecordMapper,
                                     FineRecordMapper fineRecordMapper,
                                     DeductionRecordMapper deductionRecordMapper,
                                     AppealRecordMapper appealRecordMapper,
                                     SysUserMapper sysUserMapper) {
        this.driverInformationMapper = driverInformationMapper;
        this.vehicleInformationMapper = vehicleInformationMapper;
        this.offenseRecordMapper = offenseRecordMapper;
        this.fineRecordMapper = fineRecordMapper;
        this.deductionRecordMapper = deductionRecordMapper;
        this.appealRecordMapper = appealRecordMapper;
        this.sysUserMapper = sysUserMapper;
    }

    @Transactional(readOnly = true)
    public OffenseRecord enrichOffense(OffenseRecord record) {
        if (record == null) {
            return null;
        }
        enrichOffenses(List.of(record));
        return record;
    }

    @Transactional(readOnly = true)
    public List<OffenseRecord> enrichOffenses(List<OffenseRecord> records) {
        if (isEmpty(records)) {
            return List.of();
        }
        Map<Long, DriverInformation> drivers = driversById(records.stream()
                .map(OffenseRecord::getDriverId)
                .collect(Collectors.toSet()));
        Map<Long, VehicleInformation> vehicles = vehiclesById(records.stream()
                .map(OffenseRecord::getVehicleId)
                .collect(Collectors.toSet()));
        records.forEach(record -> {
            applyDriver(record, drivers.get(record.getDriverId()));
            applyVehicle(record, vehicles.get(record.getVehicleId()));
            record.setOffenseType(resolveOffenseType(record));
        });
        return records;
    }

    @Transactional(readOnly = true)
    public FineRecord enrichFine(FineRecord record) {
        if (record == null) {
            return null;
        }
        enrichFines(List.of(record));
        return record;
    }

    @Transactional(readOnly = true)
    public List<FineRecord> enrichFines(List<FineRecord> records) {
        if (isEmpty(records)) {
            return List.of();
        }
        Map<Long, OffenseRecord> offenses = offensesById(records.stream()
                .map(FineRecord::getOffenseId)
                .collect(Collectors.toSet()));
        Set<Long> driverIds = new HashSet<>();
        Set<Long> vehicleIds = new HashSet<>();
        for (FineRecord record : records) {
            collectFineContextIds(record, offenses.get(record.getOffenseId()), driverIds, vehicleIds);
        }
        Map<Long, DriverInformation> drivers = driversById(driverIds);
        Map<Long, VehicleInformation> vehicles = vehiclesById(vehicleIds);
        records.forEach(record -> applyFineContext(
                record,
                offenses.get(record.getOffenseId()),
                drivers,
                vehicles
        ));
        return records;
    }

    @Transactional(readOnly = true)
    public DeductionRecord enrichDeduction(DeductionRecord record) {
        if (record == null) {
            return null;
        }
        enrichDeductions(List.of(record));
        return record;
    }

    @Transactional(readOnly = true)
    public List<DeductionRecord> enrichDeductions(List<DeductionRecord> records) {
        if (isEmpty(records)) {
            return List.of();
        }
        Map<Long, OffenseRecord> offenses = offensesById(records.stream()
                .map(DeductionRecord::getOffenseId)
                .collect(Collectors.toSet()));
        Set<Long> driverIds = new HashSet<>();
        Set<Long> vehicleIds = new HashSet<>();
        for (DeductionRecord record : records) {
            OffenseRecord offense = offenses.get(record.getOffenseId());
            collectDriverAndVehicleIds(record.getDriverId(), offense, driverIds, vehicleIds);
        }
        Map<Long, DriverInformation> drivers = driversById(driverIds);
        Map<Long, VehicleInformation> vehicles = vehiclesById(vehicleIds);
        records.forEach(record -> applyDeductionContext(
                record,
                offenses.get(record.getOffenseId()),
                drivers,
                vehicles
        ));
        return records;
    }

    @Transactional(readOnly = true)
    public AppealRecord enrichAppeal(AppealRecord record) {
        if (record == null) {
            return null;
        }
        enrichAppeals(List.of(record));
        return record;
    }

    @Transactional(readOnly = true)
    public List<AppealRecord> enrichAppeals(List<AppealRecord> records) {
        if (isEmpty(records)) {
            return List.of();
        }
        Map<Long, OffenseRecord> offenses = offensesById(records.stream()
                .map(AppealRecord::getOffenseId)
                .collect(Collectors.toSet()));
        Set<Long> driverIds = new HashSet<>();
        Set<Long> vehicleIds = new HashSet<>();
        for (AppealRecord record : records) {
            OffenseRecord offense = offenses.get(record.getOffenseId());
            collectDriverAndVehicleIds(record.getDriverId(), offense, driverIds, vehicleIds);
        }
        Map<Long, DriverInformation> drivers = driversById(driverIds);
        Map<Long, VehicleInformation> vehicles = vehiclesById(vehicleIds);
        records.forEach(record -> applyAppealContext(
                record,
                offenses.get(record.getOffenseId()),
                drivers,
                vehicles
        ));
        return records;
    }

    @Transactional(readOnly = true)
    public List<AppealRecord> listAppeals(int page, int size) {
        QueryWrapper<AppealRecord> wrapper = new QueryWrapper<AppealRecord>()
                .orderByDesc("appeal_time");
        return enrichAppeals(selectPage(appealRecordMapper, wrapper, page, size));
    }

    @Transactional(readOnly = true)
    public DriverInformation enrichDriver(DriverInformation record) {
        if (record == null) {
            return null;
        }
        enrichDrivers(List.of(record));
        return record;
    }

    @Transactional(readOnly = true)
    public List<DriverInformation> enrichDrivers(List<DriverInformation> records) {
        if (isEmpty(records)) {
            return List.of();
        }
        Map<Long, SysUser> users = usersById(records.stream()
                .map(DriverInformation::getAuthUserId)
                .collect(Collectors.toSet()));
        records.forEach(driver -> {
            SysUser user = users.get(driver.getAuthUserId());
            if (user != null) {
                driver.setUsername(user.getUsername());
                driver.setAccountStatus(user.getStatus());
            }
            driver.setVehicleCount(countByDriver(vehicleInformationMapper, "driver_id", driver.getDriverId()));
            driver.setOffenseCount(countByDriver(offenseRecordMapper, "driver_id", driver.getDriverId()));
            driver.setUnpaidFineCount(countUnpaidFinesByDriver(driver.getDriverId()));
            driver.setAppealCount(countByDriver(appealRecordMapper, "driver_id", driver.getDriverId()));
        });
        return records;
    }

    @Transactional(readOnly = true)
    public VehicleInformation enrichVehicle(VehicleInformation record) {
        if (record == null) {
            return null;
        }
        enrichVehicles(List.of(record));
        return record;
    }

    @Transactional(readOnly = true)
    public List<VehicleInformation> enrichVehicles(List<VehicleInformation> records) {
        if (isEmpty(records)) {
            return List.of();
        }
        Map<Long, DriverInformation> drivers = driversById(records.stream()
                .map(VehicleInformation::getDriverId)
                .collect(Collectors.toSet()));
        records.forEach(vehicle -> {
            DriverInformation driver = drivers.get(vehicle.getDriverId());
            applyDriver(vehicle, driver);
            vehicle.setOffenseCount(countByVehicle(offenseRecordMapper, "vehicle_id", vehicle.getVehicleId()));
            vehicle.setUnpaidFineCount(countUnpaidFinesByVehicle(vehicle.getVehicleId()));
            vehicle.setAppealCount(countAppealsByVehicle(vehicle.getVehicleId()));
        });
        return records;
    }

    private void applyDriver(OffenseRecord record, DriverInformation driver) {
        if (record == null || driver == null) {
            return;
        }
        record.setDriverName(driver.getName());
        record.setDriverLicenseNumber(driver.getDriverLicenseNumber());
        record.setDriverIdCardNumber(driver.getIdCardNumber());
        record.setDriverContactNumber(driver.getContactNumber());
    }

    private void applyVehicle(OffenseRecord record, VehicleInformation vehicle) {
        if (record == null || vehicle == null) {
            return;
        }
        record.setLicensePlate(vehicle.getLicensePlate());
        record.setVehicleType(vehicle.getVehicleType());
        record.setVehicleBrand(vehicle.getBrand());
        record.setVehicleModel(vehicle.getModel());
    }

    private void applyDriver(VehicleInformation record, DriverInformation driver) {
        if (record == null || driver == null) {
            return;
        }
        record.setDriverName(driver.getName());
        record.setDriverLicenseNumber(driver.getDriverLicenseNumber());
        record.setDriverIdCardNumber(driver.getIdCardNumber());
        record.setDriverContactNumber(driver.getContactNumber());
    }

    private void applyFineContext(FineRecord fine,
                                  OffenseRecord offense,
                                  Map<Long, DriverInformation> drivers,
                                  Map<Long, VehicleInformation> vehicles) {
        if (fine == null) {
            return;
        }
        Long driverId = firstNonNull(fine.getDriverId(), offense == null ? null : offense.getDriverId());
        Long vehicleId = offense == null ? null : offense.getVehicleId();
        DriverInformation driver = drivers.get(driverId);
        VehicleInformation vehicle = vehicles.get(vehicleId);
        if (fine.getDriverId() == null) {
            fine.setDriverId(driverId);
        }
        applyOffenseFields(fine, offense);
        if (driver != null) {
            fine.setDriverName(driver.getName());
            fine.setDriverLicenseNumber(driver.getDriverLicenseNumber());
            fine.setDriverIdCardNumber(driver.getIdCardNumber());
        }
        if (vehicle != null) {
            fine.setLicensePlate(vehicle.getLicensePlate());
            fine.setVehicleType(vehicle.getVehicleType());
        }
    }

    private void applyDeductionContext(DeductionRecord deduction,
                                       OffenseRecord offense,
                                       Map<Long, DriverInformation> drivers,
                                       Map<Long, VehicleInformation> vehicles) {
        if (deduction == null) {
            return;
        }
        Long driverId = firstNonNull(deduction.getDriverId(), offense == null ? null : offense.getDriverId());
        Long vehicleId = offense == null ? null : offense.getVehicleId();
        DriverInformation driver = drivers.get(driverId);
        VehicleInformation vehicle = vehicles.get(vehicleId);
        if (deduction.getDriverId() == null) {
            deduction.setDriverId(driverId);
        }
        applyOffenseFields(deduction, offense);
        if (driver != null) {
            deduction.setDriverName(driver.getName());
            deduction.setDriverLicenseNumber(driver.getDriverLicenseNumber());
            deduction.setDriverIdCardNumber(driver.getIdCardNumber());
        }
        if (vehicle != null) {
            deduction.setLicensePlate(vehicle.getLicensePlate());
            deduction.setVehicleType(vehicle.getVehicleType());
        }
    }

    private void applyAppealContext(AppealRecord appeal,
                                    OffenseRecord offense,
                                    Map<Long, DriverInformation> drivers,
                                    Map<Long, VehicleInformation> vehicles) {
        if (appeal == null) {
            return;
        }
        Long driverId = firstNonNull(appeal.getDriverId(), offense == null ? null : offense.getDriverId());
        Long vehicleId = offense == null ? null : offense.getVehicleId();
        DriverInformation driver = drivers.get(driverId);
        VehicleInformation vehicle = vehicles.get(vehicleId);
        if (appeal.getDriverId() == null) {
            appeal.setDriverId(driverId);
        }
        applyOffenseFields(appeal, offense);
        if (driver != null) {
            appeal.setDriverName(driver.getName());
            appeal.setDriverLicenseNumber(driver.getDriverLicenseNumber());
            appeal.setDriverIdCardNumber(driver.getIdCardNumber());
            if (appeal.getAppellantName() == null) {
                appeal.setAppellantName(driver.getName());
            }
            if (appeal.getAppellantIdCard() == null) {
                appeal.setAppellantIdCard(driver.getIdCardNumber());
            }
            if (appeal.getAppellantContact() == null) {
                appeal.setAppellantContact(driver.getContactNumber());
            }
        }
        if (vehicle != null) {
            appeal.setLicensePlate(vehicle.getLicensePlate());
            appeal.setVehicleType(vehicle.getVehicleType());
        }
    }

    private void applyOffenseFields(FineRecord fine, OffenseRecord offense) {
        if (fine == null || offense == null) {
            return;
        }
        fine.setOffenseNumber(offense.getOffenseNumber());
        fine.setOffenseCode(offense.getOffenseCode());
        fine.setOffenseType(resolveOffenseType(offense));
        fine.setOffenseLocation(offense.getOffenseLocation());
        fine.setOffenseTime(offense.getOffenseTime());
    }

    private void applyOffenseFields(DeductionRecord deduction, OffenseRecord offense) {
        if (deduction == null || offense == null) {
            return;
        }
        deduction.setOffenseNumber(offense.getOffenseNumber());
        deduction.setOffenseCode(offense.getOffenseCode());
        deduction.setOffenseType(resolveOffenseType(offense));
        deduction.setOffenseLocation(offense.getOffenseLocation());
        deduction.setOffenseTime(offense.getOffenseTime());
    }

    private void applyOffenseFields(AppealRecord appeal, OffenseRecord offense) {
        if (appeal == null || offense == null) {
            return;
        }
        appeal.setOffenseNumber(offense.getOffenseNumber());
        appeal.setOffenseCode(offense.getOffenseCode());
        appeal.setOffenseType(resolveOffenseType(offense));
        appeal.setOffenseLocation(offense.getOffenseLocation());
        appeal.setOffenseTime(offense.getOffenseTime());
    }

    private void collectFineContextIds(FineRecord record,
                                       OffenseRecord offense,
                                       Set<Long> driverIds,
                                       Set<Long> vehicleIds) {
        collectDriverAndVehicleIds(record == null ? null : record.getDriverId(), offense, driverIds, vehicleIds);
    }

    private void collectDriverAndVehicleIds(Long explicitDriverId,
                                            OffenseRecord offense,
                                            Set<Long> driverIds,
                                            Set<Long> vehicleIds) {
        addIfPresent(driverIds, explicitDriverId);
        if (offense != null) {
            addIfPresent(driverIds, offense.getDriverId());
            addIfPresent(vehicleIds, offense.getVehicleId());
        }
    }

    private Map<Long, DriverInformation> driversById(Collection<Long> ids) {
        return selectMap(driverInformationMapper, ids, DriverInformation::getDriverId);
    }

    private Map<Long, VehicleInformation> vehiclesById(Collection<Long> ids) {
        return selectMap(vehicleInformationMapper, ids, VehicleInformation::getVehicleId);
    }

    private Map<Long, OffenseRecord> offensesById(Collection<Long> ids) {
        return selectMap(offenseRecordMapper, ids, OffenseRecord::getOffenseId);
    }

    private Map<Long, SysUser> usersById(Collection<Long> ids) {
        return selectMap(sysUserMapper, ids, SysUser::getUserId);
    }

    private <T> Map<Long, T> selectMap(BaseMapper<T> mapper,
                                       Collection<Long> ids,
                                       Function<T, Long> idExtractor) {
        Set<Long> normalized = ids == null ? Set.of() : ids.stream()
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        if (normalized.isEmpty()) {
            return Map.of();
        }
        return mapper.selectBatchIds(normalized.stream()
                        .map(Serializable.class::cast)
                        .collect(Collectors.toSet()))
                .stream()
                .filter(Objects::nonNull)
                .collect(Collectors.toMap(idExtractor, Function.identity(), (left, ignored) -> left));
    }

    private <T> List<T> selectPage(BaseMapper<T> mapper, QueryWrapper<T> wrapper, int page, int size) {
        Page<T> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        mapper.selectPage(mpPage, wrapper);
        return mpPage.getRecords();
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private Long countByDriver(BaseMapper mapper, String column, Long driverId) {
        if (driverId == null) {
            return 0L;
        }
        return mapper.selectCount(new QueryWrapper<>().eq(column, driverId));
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private Long countByVehicle(BaseMapper mapper, String column, Long vehicleId) {
        if (vehicleId == null) {
            return 0L;
        }
        return mapper.selectCount(new QueryWrapper<>().eq(column, vehicleId));
    }

    private Long countUnpaidFinesByDriver(Long driverId) {
        if (driverId == null) {
            return 0L;
        }
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<FineRecord>()
                .eq("driver_id", driverId)
                .and(scope -> scope.ne("payment_status", "Paid").or().isNull("payment_status"));
        return fineRecordMapper.selectCount(wrapper);
    }

    private Long countUnpaidFinesByVehicle(Long vehicleId) {
        Set<Long> offenseIds = offenseIdsByVehicle(vehicleId);
        if (offenseIds.isEmpty()) {
            return 0L;
        }
        QueryWrapper<FineRecord> wrapper = new QueryWrapper<FineRecord>()
                .in("offense_id", offenseIds)
                .and(scope -> scope.ne("payment_status", "Paid").or().isNull("payment_status"));
        return fineRecordMapper.selectCount(wrapper);
    }

    private Long countAppealsByVehicle(Long vehicleId) {
        Set<Long> offenseIds = offenseIdsByVehicle(vehicleId);
        if (offenseIds.isEmpty()) {
            return 0L;
        }
        return appealRecordMapper.selectCount(new QueryWrapper<AppealRecord>().in("offense_id", offenseIds));
    }

    private Set<Long> offenseIdsByVehicle(Long vehicleId) {
        if (vehicleId == null) {
            return Set.of();
        }
        QueryWrapper<OffenseRecord> wrapper = new QueryWrapper<OffenseRecord>()
                .select("offense_id")
                .eq("vehicle_id", vehicleId);
        return offenseRecordMapper.selectList(wrapper).stream()
                .map(OffenseRecord::getOffenseId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
    }

    private String resolveOffenseType(OffenseRecord offense) {
        if (offense == null) {
            return null;
        }
        return firstNonBlank(offense.getOffenseDescription(), offense.getOffenseCode());
    }

    private String firstNonBlank(String first, String second) {
        if (first != null && !first.isBlank()) {
            return first;
        }
        return second;
    }

    private <T> T firstNonNull(T first, T second) {
        return first != null ? first : second;
    }

    private void addIfPresent(Set<Long> values, Long value) {
        if (value != null) {
            values.add(value);
        }
    }

    private boolean isEmpty(Collection<?> records) {
        return records == null || records.isEmpty();
    }
}
