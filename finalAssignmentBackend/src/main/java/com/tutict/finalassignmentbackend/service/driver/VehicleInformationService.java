package com.tutict.finalassignmentbackend.service.driver;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.system.SysRequestHistory;
import com.tutict.finalassignmentbackend.entity.driver.VehicleInformation;
import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import com.tutict.finalassignmentbackend.mapper.system.SysRequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.driver.VehicleInformationMapper;
import com.tutict.finalassignmentbackend.repository.VehicleInformationSearchRepository;
import com.tutict.finalassignmentbackend.security.crypto.SensitiveDataPersistenceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
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
    private static final String VEHICLE_INFO_CACHE = "vehicleInfo";
    private static final String VEHICLE_INFO_LIST_CACHE = "vehicleInfoList";

    private final VehicleInformationMapper vehicleInformationMapper;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final KafkaTemplate<String, VehicleInformation> kafkaTemplate;
    private final VehicleInformationSearchRepository vehicleInformationSearchRepository;
    private final SensitiveDataPersistenceService sensitiveDataPersistenceService;

    @Autowired
    public VehicleInformationService(VehicleInformationMapper vehicleInformationMapper,
                                     SysRequestHistoryMapper sysRequestHistoryMapper,
                                     KafkaTemplate<String, VehicleInformation> kafkaTemplate,
                                     VehicleInformationSearchRepository vehicleInformationSearchRepository,
                                     SensitiveDataPersistenceService sensitiveDataPersistenceService) {
        this.vehicleInformationMapper = vehicleInformationMapper;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.vehicleInformationSearchRepository = vehicleInformationSearchRepository;
        this.sensitiveDataPersistenceService = sensitiveDataPersistenceService;
    }

    @Transactional
    @CacheEvict(cacheNames = VEHICLE_INFO_LIST_CACHE, allEntries = true)
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

        sensitiveDataPersistenceService.prepare(vehicleInformation);
        sendKafkaMessage(action, idempotencyKey, vehicleInformation);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(vehicleInformation.getVehicleId());
        history.setUpdatedAt(LocalDateTime.now());
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = VEHICLE_INFO_LIST_CACHE, allEntries = true)
    public VehicleInformation createVehicleInformation(VehicleInformation vehicleInformation) {
        validateVehicle(vehicleInformation);
        sensitiveDataPersistenceService.prepare(vehicleInformation);
        vehicleInformationMapper.insert(vehicleInformation);
        syncToIndexAfterCommit(vehicleInformation);
        return vehicleInformation;
    }

    @Transactional
    @Caching(evict = {
            @CacheEvict(cacheNames = VEHICLE_INFO_CACHE, key = "#vehicleInformation.vehicleId"),
            @CacheEvict(cacheNames = VEHICLE_INFO_LIST_CACHE, allEntries = true)
    })
    @WsAction(service = "VehicleInformationService", action = "updateVehicleInformation")
    public VehicleInformation updateVehicleInformation(VehicleInformation vehicleInformation) {
        validateVehicleId(vehicleInformation);
        sensitiveDataPersistenceService.prepare(vehicleInformation);
        int rows = vehicleInformationMapper.updateById(vehicleInformation);
        if (rows == 0) {
            throw new IllegalStateException("Vehicle not found with ID: " + vehicleInformation.getVehicleId());
        }
        syncToIndexAfterCommit(vehicleInformation);
        return vehicleInformation;
    }

    @Transactional
    @Caching(evict = {
            @CacheEvict(cacheNames = VEHICLE_INFO_CACHE, key = "#vehicleId"),
            @CacheEvict(cacheNames = VEHICLE_INFO_LIST_CACHE, allEntries = true)
    })
    public void deleteVehicleInformation(long vehicleId) {
        validateVehicleId(vehicleId);
        int rows = vehicleInformationMapper.deleteById(vehicleId);
        if (rows == 0) {
            throw new IllegalStateException("Vehicle not found with ID: " + vehicleId);
        }
        syncDeleteAfterCommit(vehicleId);
    }

    @Transactional
    @CacheEvict(cacheNames = VEHICLE_INFO_LIST_CACHE, allEntries = true)
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

    @Cacheable(cacheNames = VEHICLE_INFO_CACHE, key = "#vehicleId", unless = "#result == null")
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

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'all'", unless = "#result == null || #result.isEmpty()")
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

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'driver:' + #driverId + ':' + #page + ':' + #size")
    public List<VehicleInformation> getVehicleInformationByDriverId(Long driverId, int page, int size) {
        validateVehicleId(driverId);
        validatePagination(page, size);
        SearchHits<VehicleInformationDocument> hits = vehicleInformationSearchRepository
                .findByDriverId(driverId, pageable(page, size));
        List<VehicleInformation> fromIndex = mapVehicleHits(hits);
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.eq("driver_id", driverId)
                .orderByDesc("registration_date");
        return vehicleInformationMapper.selectList(wrapper);
    }

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'plate:' + #licensePlate")
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

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'license:global:' + #prefix + ':' + #maxSuggestions")
    public List<String> getVehicleInformationByLicensePlateGlobally(String prefix, int maxSuggestions) {
        validateInput(prefix, "Invalid license plate prefix");
        Pageable pageable = PageRequest.of(0, Math.max(maxSuggestions, 1));
        SearchHits<VehicleInformationDocument> hits = vehicleInformationSearchRepository
                .findCompletionSuggestionsGlobally(prefix, pageable);
        return mapLicensePlateSuggestions(hits);
    }

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'type:' + #vehicleType")
    public List<VehicleInformation> getVehicleInformationByType(String vehicleType) {
        validateInput(vehicleType, "Invalid vehicle type");
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.eq("vehicle_type", vehicleType);
        return vehicleInformationMapper.selectList(wrapper);
    }

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'owner:' + #ownerName")
    public List<VehicleInformation> getVehicleInformationByOwnerName(String ownerName) {
        validateInput(ownerName, "Invalid owner name");
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.eq("owner_name", ownerName);
        return vehicleInformationMapper.selectList(wrapper);
    }

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'idcard:' + #idCardNumber")
    public List<VehicleInformation> getVehicleInformationByIdCardNumber(String idCardNumber) {
        validateInput(idCardNumber, "Invalid ID card number");
        return searchOwnerIdCardExact(idCardNumber, 1, Integer.MAX_VALUE);
    }

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'status:' + #status")
    public List<VehicleInformation> getVehicleInformationByStatus(String status) {
        validateInput(status, "Invalid status");
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status);
        return vehicleInformationMapper.selectList(wrapper);
    }

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'ownerNameSearch:' + #ownerName + ':' + #page + ':' + #size")
    public List<VehicleInformation> searchByOwnerName(String ownerName, int page, int size) {
        validateInput(ownerName, "Invalid owner name");
        validatePagination(page, size);
        SearchHits<VehicleInformationDocument> hits = vehicleInformationSearchRepository
                .searchByOwnerName(ownerName, pageable(page, size));
        List<VehicleInformation> fromIndex = mapVehicleHits(hits);
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.likeRight("owner_name", ownerName);
        return vehicleInformationMapper.selectList(wrapper);
    }

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'ownerIdCardSearch:' + #ownerIdCard + ':' + #page + ':' + #size")
    public List<VehicleInformation> searchByOwnerIdCard(String ownerIdCard, int page, int size) {
        validateInput(ownerIdCard, "Invalid owner id card");
        validatePagination(page, size);
        return searchOwnerIdCardExact(ownerIdCard, page, size);
    }

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'statusSearch:' + #status + ':' + #page + ':' + #size")
    public List<VehicleInformation> searchByStatus(String status, int page, int size) {
        validateInput(status, "Invalid status");
        validatePagination(page, size);
        SearchHits<VehicleInformationDocument> hits = vehicleInformationSearchRepository
                .searchByStatus(status, pageable(page, size));
        List<VehicleInformation> fromIndex = mapVehicleHits(hits);
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.eq("status", status);
        return vehicleInformationMapper.selectList(wrapper);
    }

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'search:' + #query + ':' + #page + ':' + #size")
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

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'autocomplete:me:' + #idCardNumber + ':' + #prefix + ':' + #maxSuggestions")
    public List<String> getLicensePlateAutocompleteSuggestions(String prefix, int maxSuggestions, String idCardNumber) {
        validateInput(idCardNumber, "Invalid ID card number");
        validateInput(prefix, "Invalid license plate prefix");
        QueryWrapper<VehicleInformation> wrapper = ownerIdCardScopedWrapper(idCardNumber);
        wrapper.select("license_plate")
                .likeRight("license_plate", prefix)
                .last("LIMIT " + Math.max(maxSuggestions, 1));
        return vehicleInformationMapper.selectList(wrapper).stream()
                .map(VehicleInformation::getLicensePlate)
                .filter(Objects::nonNull)
                .map(plate -> URLDecoder.decode(plate, StandardCharsets.UTF_8))
                .distinct()
                .collect(Collectors.toList());
    }

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'autocomplete:global:' + #prefix + ':' + #limit")
    public List<String> suggestPlates(String prefix, int limit) {
        validateInput(prefix, "Invalid license plate prefix");
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.select("license_plate")
                .likeRight("license_plate", prefix)
                .last("LIMIT " + Math.max(limit, 1));
        return vehicleInformationMapper.selectList(wrapper).stream()
                .map(VehicleInformation::getLicensePlate)
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
    }

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'autocomplete:type:me:' + #idCardNumber + ':' + #prefix + ':' + #maxSuggestions")
    public List<String> getVehicleTypeAutocompleteSuggestions(String idCardNumber, String prefix, int maxSuggestions) {
        validateInput(idCardNumber, "Invalid ID card number");
        validateInput(prefix, "Invalid vehicle type prefix");
        QueryWrapper<VehicleInformation> wrapper = ownerIdCardScopedWrapper(idCardNumber);
        wrapper.select("DISTINCT vehicle_type")
                .likeRight("vehicle_type", prefix)
                .last("LIMIT " + Math.max(maxSuggestions, 1));
        return vehicleInformationMapper.selectList(wrapper).stream()
                .map(VehicleInformation::getVehicleType)
                .filter(Objects::nonNull)
                .map(type -> URLDecoder.decode(type, StandardCharsets.UTF_8))
                .distinct()
                .collect(Collectors.toList());
    }

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'autocomplete:type:global:' + #prefix + ':' + #maxSuggestions")
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

    @Cacheable(cacheNames = VEHICLE_INFO_LIST_CACHE, key = "'exists:' + #licensePlate")
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

    private List<VehicleInformation> mapVehicleHits(SearchHits<VehicleInformationDocument> hits) {
        if (hits == null || !hits.hasSearchHits()) {
            return Collections.emptyList();
        }
        return hits.getSearchHits().stream()
                .map(SearchHit::getContent)
                .map(VehicleInformationDocument::toEntity)
                .collect(Collectors.toList());
    }

    private List<VehicleInformation> searchOwnerIdCardExact(String ownerIdCard, int page, int size) {
        String blindIndex = sensitiveDataPersistenceService.blindIndex(ownerIdCard);
        if (blindIndex != null && !blindIndex.isBlank()) {
            QueryWrapper<VehicleInformation> blindWrapper = new QueryWrapper<>();
            blindWrapper.eq("owner_id_card_blind_index", blindIndex);
            List<VehicleInformation> exact = fetchFromDatabase(blindWrapper, page, size);
            if (!exact.isEmpty()) {
                return exact;
            }
        }
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        wrapper.likeRight("owner_id_card", ownerIdCard);
        return fetchFromDatabase(wrapper, page, size);
    }

    private QueryWrapper<VehicleInformation> ownerIdCardScopedWrapper(String idCardNumber) {
        String blindIndex = sensitiveDataPersistenceService.blindIndex(idCardNumber);
        QueryWrapper<VehicleInformation> wrapper = new QueryWrapper<>();
        if (blindIndex != null && !blindIndex.isBlank()) {
            wrapper.eq("owner_id_card_blind_index", blindIndex);
            return wrapper;
        }
        wrapper.eq("owner_id_card", idCardNumber.trim());
        return wrapper;
    }

    private List<VehicleInformation> fetchFromDatabase(QueryWrapper<VehicleInformation> wrapper, int page, int size) {
        Page<VehicleInformation> mpPage = new Page<>(Math.max(page, 1), Math.max(size, 1));
        vehicleInformationMapper.selectPage(mpPage, wrapper);
        List<VehicleInformation> records = mpPage.getRecords();
        records.stream()
                .map(VehicleInformationDocument::fromEntity)
                .filter(Objects::nonNull)
                .forEach(vehicleInformationSearchRepository::save);
        return records;
    }

    private Pageable pageable(int page, int size) {
        return PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
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

    private void sendKafkaMessage(String action, String idempotencyKey, VehicleInformation vehicleInformation) {
        String topic = "vehicle_information_" + action.toLowerCase(Locale.ROOT);
        try {
            Runnable sendTask = () -> kafkaTemplate.send(topic, idempotencyKey, vehicleInformation).whenComplete((result, ex) -> {
                if (ex != null) {
                    log.log(Level.SEVERE, "Failed to send vehicle Kafka message", ex);
                } else {
                    log.log(Level.FINE, "Vehicle Kafka message sent: topic={0}, partition={1}, offset={2}",
                            new Object[]{
                                    topic,
                                    result.getRecordMetadata().partition(),
                                    result.getRecordMetadata().offset()
                            });
                }
            });
            if (TransactionSynchronizationManager.isSynchronizationActive()) {
                TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                    @Override
                    public void afterCommit() {
                        sendTask.run();
                    }
                });
            } else {
                sendTask.run();
            }
        } catch (Exception e) {
            log.log(Level.WARNING, "Failed to send vehicle Kafka message", e);
        }
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

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 255 ? value : value.substring(0, 255);
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
