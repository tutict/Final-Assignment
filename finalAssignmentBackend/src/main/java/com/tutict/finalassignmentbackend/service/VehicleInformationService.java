package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import com.tutict.finalassignmentbackend.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.VehicleInformationMapper;
import com.tutict.finalassignmentbackend.repository.VehicleInformationSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@Service
public class VehicleInformationService {

    private static final Logger log = Logger.getLogger(VehicleInformationService.class.getName());
    private static final String CACHE_NAME = "vehicleCache";

    private final VehicleInformationMapper vehicleInformationMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final KafkaTemplate<String, VehicleInformation> kafkaTemplate;
    private final VehicleInformationSearchRepository vehicleInformationSearchRepository;

    @Autowired
    public VehicleInformationService(VehicleInformationMapper vehicleInformationMapper,
                                     SysRequestHistoryMapper sysRequestHistoryMapper,
                                     KafkaTemplate<String, VehicleInformation> kafkaTemplate,
                                     VehicleInformationSearchRepository vehicleInformationSearchRepository) {
        this.vehicleInformationMapper = vehicleInformationMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.vehicleInformationSearchRepository = vehicleInformationSearchRepository;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "VehicleInformationService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, VehicleInformation vehicleInformation, String action) {
        Objects.requireNonNull(vehicleInformation, "Vehicle information cannot be null");
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            log.warning(() -> String.format("Duplicate vehicle request detected (key=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate vehicle request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        history.setCreatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage(action, vehicleInformation);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(Optional.ofNullable(vehicleInformation.getVehicleId()).map(Long::valueOf).orElse(null));
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public VehicleInformation createVehicleInformation(VehicleInformation vehicleInformation) {
        validateVehicle(vehicleInformation);
        vehicleInformationMapper.insert(vehicleInformation);
        syncToIndexAfterCommit(vehicleInformation);
        return vehicleInformation;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "VehicleInformationService", action = "updateVehicleInformation")
    public VehicleInformation updateVehicleInformation(VehicleInformation vehicleInformation) {
        validateVehicleId(vehicleInformation);
        int rows = vehicleInformationMapper.updateById(vehicleInformation);
        if (rows == 0) {
            throw new IllegalStateException("Vehicle not found with ID: " + vehicleInformation.getVehicleId());
        }
        syncToIndexAfterCommit(vehicleInformation);
        return vehicleInformation;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteVehicleInformation(long vehicleId) {
        validateVehicleId(vehicleId);
        int rows = vehicleInformationMapper.deleteById(vehicleId);
        if (rows == 0) {
            throw new IllegalStateException("Vehicle not found with ID: " + vehicleId);
        }
        syncDeleteAfterCommit(vehicleId);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void deleteVehicleInformationByLicensePlate(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate");
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.eq("license_plate", licensePlate);
        List<VehicleInformation> vehicles = vehicleInformationMapper.selectList(wrapper);
        if (vehicles.isEmpty()) {
            return;
        }
        vehicleInformationMapper.delete(wrapper);
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                vehicles.stream()
                        .map(VehicleInformation::getVehicleId)
                        .filter(Objects::nonNull)
                        .forEach(vehicleInformationSearchRepository::deleteById);
            }
        });
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "#vehicleId", unless = "#result == null")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationById")
    public VehicleInformation getVehicleInformationById(long vehicleId) {
        validateVehicleId(vehicleId);
        return vehicleInformationSearchRepository.findById(vehicleId)
                .map(VehicleInformationDocument::toEntity)
                .orElseGet(() -> {
                    VehicleInformation entity = vehicleInformationMapper.selectById(vehicleId);
                    if (entity != null) {
                        vehicleInformationSearchRepository.save(VehicleInformationDocument.fromEntity(entity));
                    }
                    return entity;
                });
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    @WsAction(service = "VehicleInformationService", action = "getAllVehicleInformation")
    public List<VehicleInformation> getAllVehicleInformation() {
        List<VehicleInformation> fromIndex = StreamSupport.stream(
                        vehicleInformationSearchRepository.findAll().spliterator(), false)
                .map(VehicleInformationDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<VehicleInformation> db = vehicleInformationMapper.selectList(null);
        db.stream()
                .map(VehicleInformationDocument::fromEntity)
                .filter(Objects::nonNull)
                .forEach(vehicleInformationSearchRepository::save);
        return db;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'plate:' + #licensePlate")
    public VehicleInformation getVehicleInformationByLicensePlate(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate");
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.eq("license_plate", licensePlate);
        VehicleInformation entity = vehicleInformationMapper.selectOne(wrapper);
        if (entity != null) {
            vehicleInformationSearchRepository.save(VehicleInformationDocument.fromEntity(entity));
        }
        return entity;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'license:global:' + #prefix + ':' + #maxSuggestions")
    public List<String> getVehicleInformationByLicensePlateGlobally(String prefix, int maxSuggestions) {
        validateInput(prefix, "Invalid license plate prefix");
        Pageable pageable = PageRequest.of(0, Math.max(maxSuggestions, 1));
        SearchHits<VehicleInformationDocument> hits = vehicleInformationSearchRepository
                .findCompletionSuggestionsGlobally(prefix, pageable);
        return mapLicensePlateSuggestions(hits);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'type:' + #vehicleType")
    public List<VehicleInformation> getVehicleInformationByType(String vehicleType) {
        validateInput(vehicleType, "Invalid vehicle type");
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.eq("vehicle_type", vehicleType);
        return vehicleInformationMapper.selectList(wrapper);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'owner:' + #ownerName")
    public List<VehicleInformation> getVehicleInformationByOwnerName(String ownerName) {
        validateInput(ownerName, "Invalid owner name");
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.eq("owner_name", ownerName);
        return vehicleInformationMapper.selectList(wrapper);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'idcard:' + #idCardNumber")
    public List<VehicleInformation> getVehicleInformationByIdCardNumber(String idCardNumber) {
        validateInput(idCardNumber, "Invalid ID card number");
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.eq("owner_id_card", idCardNumber);
        return vehicleInformationMapper.selectList(wrapper);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'status:' + #status")
    public List<VehicleInformation> getVehicleInformationByStatus(String status) {
        validateInput(status, "Invalid status");
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status);
        return vehicleInformationMapper.selectList(wrapper);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'search:' + #query + ':' + #page + ':' + #size")
    public List<VehicleInformation> searchVehicles(String query, int page, int size) {
        validatePagination(page, size);
        if (query == null || query.trim().isEmpty()) {
            return Collections.emptyList();
        }
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.lambda()
                .like(VehicleInformation::getLicensePlate, query)
                .or()
                .like(VehicleInformation::getOwnerName, query)
                .or()
                .like(VehicleInformation::getVehicleType, query)
                .or()
                .like(VehicleInformation::getBrand, query);
        List<VehicleInformation> list = vehicleInformationMapper.selectList(wrapper);
        int fromIndex = Math.min((page - 1) * size, list.size());
        int toIndex = Math.min(fromIndex + size, list.size());
        return list.subList(fromIndex, toIndex);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'autocomplete:me:' + #idCardNumber + ':' + #prefix + ':' + #maxSuggestions")
    public List<String> getLicensePlateAutocompleteSuggestions(String prefix, int maxSuggestions, String idCardNumber) {
        validateInput(idCardNumber, "Invalid ID card number");
        validateInput(prefix, "Invalid license plate prefix");
        Pageable pageable = PageRequest.of(0, Math.max(maxSuggestions, 1));
        SearchHits<VehicleInformationDocument> hits = vehicleInformationSearchRepository
                .findCompletionSuggestions(idCardNumber, prefix, pageable);
        return mapLicensePlateSuggestions(hits);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'autocomplete:type:me:' + #idCardNumber + ':' + #prefix + ':' + #maxSuggestions")
    public List<String> getVehicleTypeAutocompleteSuggestions(String idCardNumber, String prefix, int maxSuggestions) {
        validateInput(idCardNumber, "Invalid ID card number");
        validateInput(prefix, "Invalid vehicle type prefix");
        Pageable pageable = PageRequest.of(0, Math.max(maxSuggestions, 1));
        SearchHits<VehicleInformationDocument> hits = vehicleInformationSearchRepository
                .searchByVehicleTypePrefix(prefix, idCardNumber, pageable);
        return mapVehicleTypeSuggestions(hits);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'autocomplete:type:global:' + #prefix + ':' + #maxSuggestions")
    public List<String> getVehicleTypesByPrefixGlobally(String prefix, int maxSuggestions) {
        validateInput(prefix, "Invalid vehicle type prefix");
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.select("DISTINCT vehicle_type").like("vehicle_type", prefix);
        List<VehicleInformation> result = vehicleInformationMapper.selectList(wrapper);
        return result.stream()
                .map(VehicleInformation::getVehicleType)
                .filter(Objects::nonNull)
                .map(type -> URLDecoder.decode(type, StandardCharsets.UTF_8))
                .limit(Math.max(maxSuggestions, 1))
                .collect(Collectors.toList());
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'exists:' + #licensePlate")
    public boolean isLicensePlateExists(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate");
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.eq("license_plate", licensePlate);
        return vehicleInformationMapper.selectCount(wrapper) > 0;
    }

    private List<String> mapLicensePlateSuggestions(SearchHits<VehicleInformationDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return Collections.emptyList();
        }
        return hits.getSearchHits().stream()
                .map(SearchHit::getContent)
                .map(VehicleInformationDocument::getLicensePlate)
                .filter(Objects::nonNull)
                .map(plate -> URLDecoder.decode(plate, StandardCharsets.UTF_8))
                .distinct()
                .collect(Collectors.toList());
    }

    private List<String> mapVehicleTypeSuggestions(SearchHits<VehicleInformationDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return Collections.emptyList();
        }
        return hits.getSearchHits().stream()
                .map(SearchHit::getContent)
                .map(VehicleInformationDocument::getVehicleType)
                .filter(Objects::nonNull)
                .map(type -> URLDecoder.decode(type, StandardCharsets.UTF_8))
                .distinct()
                .collect(Collectors.toList());
    }

    private void syncToIndexAfterCommit(VehicleInformation vehicleInformation) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                VehicleInformationDocument doc = VehicleInformationDocument.fromEntity(vehicleInformation);
                if (doc != null) {
                    vehicleInformationSearchRepository.save(doc);
                }
            }
        });
    }

    private void syncDeleteAfterCommit(Long vehicleId) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                vehicleInformationSearchRepository.deleteById(vehicleId);
            }
        });
    }

    private void sendKafkaMessage(String action, VehicleInformation vehicleInformation) {
        String topic = "vehicle_" + action.toLowerCase(Locale.ROOT);
        try {
            kafkaTemplate.send(topic, vehicleInformation);
        } catch (Exception e) {
            log.log(Level.WARNING, "Failed to send vehicle Kafka message", e);
        }
    }

    private void validateVehicle(VehicleInformation vehicleInformation) {
        if (vehicleInformation == null) {
            throw new IllegalArgumentException("Vehicle information cannot be null");
        }
        validateInput(vehicleInformation.getLicensePlate(), "License plate cannot be empty");
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

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private void validateInput(String value, String message) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException(message);
        }
    }
}
