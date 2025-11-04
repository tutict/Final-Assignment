package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.entity.DriverVehicle;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.entity.elastic.DriverVehicleDocument;
import com.tutict.finalassignmentbackend.mapper.DriverVehicleMapper;
import com.tutict.finalassignmentbackend.mapper.VehicleInformationMapper;
import com.tutict.finalassignmentbackend.repository.DriverVehicleSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Objects;
import java.util.logging.Level;

@Service
public class DriverVehicleService extends AbstractElasticsearchCrudService<DriverVehicle, DriverVehicleDocument, Long> {

    private static final String CACHE_NAME = "driverVehicleCache";

    private final DriverVehicleSearchRepository repository;
    private final VehicleInformationMapper vehicleInformationMapper;

    @Autowired
    public DriverVehicleService(DriverVehicleMapper mapper,
                                DriverVehicleSearchRepository repository,
                                VehicleInformationMapper vehicleInformationMapper) {
        super(mapper,
                repository,
                DriverVehicleDocument::fromEntity,
                DriverVehicleDocument::toEntity,
                DriverVehicle::getId,
                CACHE_NAME);
        this.repository = repository;
        this.vehicleInformationMapper = vehicleInformationMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public DriverVehicle createBinding(DriverVehicle binding) {
        validateBinding(binding);
        enforcePrimaryConstraints(binding);
        return create(binding);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public DriverVehicle updateBinding(DriverVehicle binding) {
        validateBinding(binding);
        requirePositive(binding.getId(), "Binding ID");
        enforcePrimaryConstraints(binding);
        return update(binding);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteBinding(Long id) {
        requirePositive(id, "Binding ID");
        delete(id);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'driver:' + #driverId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<DriverVehicle> findByDriverId(Long driverId, int page, int size) {
        requirePositive(driverId, "Driver ID");
        validatePagination(page, size);
        List<DriverVehicle> fromIndex = mapHits(repository.findByDriverId(driverId, page(page, size)));
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        QueryWrapper<DriverVehicle> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .orderByDesc("is_primary");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'vehicle:' + #vehicleId + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<DriverVehicle> findByVehicleId(Long vehicleId, int page, int size) {
        requirePositive(vehicleId, "Vehicle ID");
        validatePagination(page, size);
        List<DriverVehicle> fromIndex = mapHits(repository.findByVehicleId(vehicleId, page(page, size)));
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        QueryWrapper<DriverVehicle> wrapper = new QueryWrapper<>();
        wrapper.eq("vehicle_id", vehicleId)
                .orderByDesc("is_primary");
        return fetchFromDatabase(wrapper, page, size);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'primary:' + #driverId", unless = "#result == null || #result.isEmpty()")
    public List<DriverVehicle> findPrimaryBinding(Long driverId) {
        requirePositive(driverId, "Driver ID");
        List<DriverVehicle> fromIndex = mapHits(repository.findPrimaryBinding(driverId, page(1, 5)));
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        QueryWrapper<DriverVehicle> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .eq("is_primary", true);
        return fetchFromDatabase(wrapper, 1, 5);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'relationship:' + #relationship + ':' + #page + ':' + #size", unless = "#result == null || #result.isEmpty()")
    public List<DriverVehicle> searchByRelationship(String relationship, int page, int size) {
        if (relationship == null || relationship.isBlank()) {
            return List.of();
        }
        validatePagination(page, size);
        List<DriverVehicle> fromIndex = mapHits(repository.searchByRelationship(relationship, page(page, size)));
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        QueryWrapper<DriverVehicle> wrapper = new QueryWrapper<>();
        wrapper.like("relationship", relationship);
        return fetchFromDatabase(wrapper, page, size);
    }

    private List<DriverVehicle> fetchFromDatabase(QueryWrapper<DriverVehicle> wrapper, int page, int size) {
        Page<DriverVehicle> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        mapper().selectPage(mpPage, wrapper);
        List<DriverVehicle> records = mpPage.getRecords();
        syncBatchToIndexAfterCommit(records);
        return records;
    }

    private void validateBinding(DriverVehicle binding) {
        Objects.requireNonNull(binding, "Binding cannot be null");
        requirePositive(binding.getDriverId(), "Driver ID");
        requirePositive(binding.getVehicleId(), "Vehicle ID");
        VehicleInformation vehicle = vehicleInformationMapper.selectById(binding.getVehicleId());
        if (vehicle == null) {
            throw new IllegalArgumentException("Vehicle does not exist: " + binding.getVehicleId());
        }
        if (binding.getBindDate() == null) {
            binding.setBindDate(LocalDate.now());
        }
        if (binding.getIsPrimary() == null) {
            binding.setIsPrimary(false);
        }
        if (binding.getStatus() == null || binding.getStatus().isBlank()) {
            binding.setStatus("Active");
        }
    }

    private void enforcePrimaryConstraints(DriverVehicle binding) {
        if (Boolean.TRUE.equals(binding.getIsPrimary())) {
            QueryWrapper<DriverVehicle> wrapper = new QueryWrapper<>();
            wrapper.eq("driver_id", binding.getDriverId())
                    .eq("is_primary", true);
            DriverVehicle existing = mapper().selectOne(wrapper);
            if (existing != null && !Objects.equals(existing.getId(), binding.getId())) {
                logger().log(Level.INFO, "Demoting existing primary binding {0} for driver {1}",
                        new Object[]{existing.getId(), binding.getDriverId()});
                existing.setIsPrimary(false);
                mapper().updateById(existing);
                syncToIndexAfterCommit(existing);
            }
        }
    }
}
