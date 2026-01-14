package com.tutict.finalassignmentcloud.traffic.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.config.websocket.WsAction;
import com.tutict.finalassignmentcloud.entity.DriverInformation;
import com.tutict.finalassignmentcloud.entity.SysRequestHistory;
import com.tutict.finalassignmentcloud.entity.SysUser;
import com.tutict.finalassignmentcloud.entity.elastic.DriverInformationDocument;
import com.tutict.finalassignmentcloud.traffic.client.UserClient;
import com.tutict.finalassignmentcloud.traffic.mapper.DriverInformationMapper;
import com.tutict.finalassignmentcloud.traffic.mapper.SysRequestHistoryMapper;
import com.tutict.finalassignmentcloud.traffic.repository.DriverInformationSearchRepository;
import feign.FeignException;
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

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@Service
public class DriverInformationService {

    private static final Logger log = Logger.getLogger(DriverInformationService.class.getName());
    private static final String CACHE_NAME = "driverCache";

    private final DriverInformationMapper driverInformationMapper;
    private final UserClient userClient;
    private final SysRequestHistoryMapper sysRequestHistoryMapper;
    private final DriverInformationSearchRepository driverInformationSearchRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Autowired
    public DriverInformationService(DriverInformationMapper driverInformationMapper,
                                    UserClient userClient,
                                    SysRequestHistoryMapper sysRequestHistoryMapper,
                                    KafkaTemplate<String, String> kafkaTemplate,
                                    DriverInformationSearchRepository driverInformationSearchRepository,
                                    ObjectMapper objectMapper) {
        this.driverInformationMapper = driverInformationMapper;
        this.userClient = userClient;
        this.sysRequestHistoryMapper = sysRequestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.driverInformationSearchRepository = driverInformationSearchRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "DriverInformationService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, DriverInformation driverInformation, String action) {
        if (driverInformation == null) {
            throw new IllegalArgumentException("Driver information cannot be null");
        }
        SysRequestHistory existing = sysRequestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            log.warning(() -> String.format("Duplicate driver request detected (key=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate driver request detected");
        }

        SysRequestHistory history = new SysRequestHistory();
        history.setIdempotencyKey(idempotencyKey);
        history.setBusinessStatus("PROCESSING");
        sysRequestHistoryMapper.insert(history);

        sendKafkaMessage("driver_" + action, idempotencyKey, driverInformation);

        history.setBusinessStatus("SUCCESS");
        history.setBusinessId(driverInformation.getDriverId());
        history.setRequestParams("PENDING");
        sysRequestHistoryMapper.updateById(history);
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public DriverInformation createDriver(DriverInformation driverInformation) {
        validateDriver(driverInformation);
        log.log(Level.INFO, "Creating driver: {0}", driverInformation);
        driverInformationMapper.insert(driverInformation);
        syncToIndexAfterCommit(driverInformation);
        return driverInformation;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "DriverInformationService", action = "updateDriver")
    public DriverInformation updateDriver(DriverInformation driverInformation) {
        validateDriverId(driverInformation);
        driverInformationMapper.updateById(driverInformation);

        SysUser sysUser = safeGetUser(driverInformation.getDriverId());
        if (sysUser != null) {
            sysUser.setUpdatedAt(LocalDateTime.now());
            safeUpdateUser(sysUser);
        }

        syncToIndexAfterCommit(driverInformation);
        return driverInformation;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    @WsAction(service = "DriverInformationService", action = "deleteDriver")
    public void deleteDriver(Long driverId) {
        validateDriverId(driverId);
        int rows = driverInformationMapper.deleteById(driverId);
        if (rows == 0) {
            throw new IllegalStateException("Driver not found: " + driverId);
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                driverInformationSearchRepository.deleteById(driverId);
            }
        });
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "#driverId", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriverById")
    public DriverInformation getDriverById(Long driverId) {
        validateDriverId(driverId);
        return driverInformationSearchRepository.findById(driverId)
                .map(DriverInformationDocument::toEntity)
                .orElseGet(() -> {
                    DriverInformation dbEntity = driverInformationMapper.selectById(driverId);
                    if (dbEntity != null) {
                        driverInformationSearchRepository.save(DriverInformationDocument.fromEntity(dbEntity));
                    }
                    return dbEntity;
                });
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'all'", unless = "#result == null || #result.isEmpty()")
    @WsAction(service = "DriverInformationService", action = "getAllDrivers")
    public List<DriverInformation> getAllDrivers() {
        List<DriverInformation> fromIndex = StreamSupport.stream(
                        driverInformationSearchRepository.findAll().spliterator(), false)
                .map(DriverInformationDocument::toEntity)
                .collect(Collectors.toList());
        if (!fromIndex.isEmpty()) {
            return fromIndex;
        }
        List<DriverInformation> db = driverInformationMapper.selectList(null);
        db.stream()
                .map(DriverInformationDocument::fromEntity)
                .filter(Objects::nonNull)
                .forEach(driverInformationSearchRepository::save);
        return db;
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'idCard:' + #query + ':' + #page + ':' + #size")
    @WsAction(service = "DriverInformationService", action = "searchByIdCardNumber")
    public List<DriverInformation> searchByIdCardNumber(String query, int page, int size) {
        return aggregatedSearch(query, page, size,
                q -> driverInformationSearchRepository.searchByIdCardNumber(q, pageable(page, size)),
                q -> driverInformationSearchRepository.searchByIdCardNumberFuzzy(q, pageable(page, size)),
                DriverInformationDocument::getIdCardNumber);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'license:' + #query + ':' + #page + ':' + #size")
    @WsAction(service = "DriverInformationService", action = "searchByDriverLicenseNumber")
    public List<DriverInformation> searchByDriverLicenseNumber(String query, int page, int size) {
        return aggregatedSearch(query, page, size,
                q -> driverInformationSearchRepository.searchByDriverLicenseNumber(q, pageable(page, size)),
                q -> driverInformationSearchRepository.searchByDriverLicenseNumberFuzzy(q, pageable(page, size)),
                DriverInformationDocument::getDriverLicenseNumber);
    }

    @Cacheable(cacheNames = CACHE_NAME, key = "'name:' + #query + ':' + #page + ':' + #size")
    @WsAction(service = "DriverInformationService", action = "searchByName")
    public List<DriverInformation> searchByName(String query, int page, int size) {
        return aggregatedSearch(query, page, size,
                q -> driverInformationSearchRepository.searchByNamePrefix(q, pageable(page, size)),
                q -> driverInformationSearchRepository.searchByNameFuzzy(q, pageable(page, size)),
                DriverInformationDocument::getName);
    }

    private List<DriverInformation> aggregatedSearch(String query,
                                                     int page,
                                                     int size,
                                                     FunctionWithException<String, SearchHits<DriverInformationDocument>> prefixQuery,
                                                     FunctionWithException<String, SearchHits<DriverInformationDocument>> fuzzyQuery,
                                                     FunctionWithException<DriverInformationDocument, String> fieldSelector) {
        validatePagination(page, size);
        if (query == null || query.trim().isEmpty()) {
            return List.of();
        }

        Set<DriverInformation> buffer = new HashSet<>();
        searchAndCollect(query, prefixQuery, fieldSelector, buffer);
        if (buffer.size() < size) {
            searchAndCollect(query, fuzzyQuery, fieldSelector, buffer);
        }
        return buffer.stream()
                .skip((long) (page - 1) * size)
                .limit(size)
                .collect(Collectors.toList());
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

    private void searchAndCollect(String query,
                                  FunctionWithException<String, SearchHits<DriverInformationDocument>> executor,
                                  FunctionWithException<DriverInformationDocument, String> fieldSelector,
                                  Set<DriverInformation> sink) {
        try {
            SearchHits<DriverInformationDocument> hits = executor.apply(query);
            if (hits == null || !hits.hasSearchHits()) {
                return;
            }
            for (SearchHit<DriverInformationDocument> hit : hits) {
                DriverInformationDocument doc = hit.getContent();
                if (fieldSelector.apply(doc) != null) {
                    sink.add(doc.toEntity());
                }
            }
        } catch (Exception e) {
            log.log(Level.WARNING, "Error executing driver search", e);
        }
    }

    private Pageable pageable(int page, int size) {
        return PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
    }

    private void syncToIndexAfterCommit(DriverInformation driverInformation) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                DriverInformationDocument doc = DriverInformationDocument.fromEntity(driverInformation);
                if (doc != null) {
                    driverInformationSearchRepository.save(doc);
                }
            }
        });
    }

    private void sendKafkaMessage(String topic, String idempotencyKey, DriverInformation driverInformation) {
        try {
            String payload = objectMapper.writeValueAsString(driverInformation);
            kafkaTemplate.send(topic, idempotencyKey, payload);
        } catch (Exception e) {
            log.log(Level.WARNING, "Failed to send driver Kafka message", e);
            throw new RuntimeException("Failed to send driver event", e);
        }
    }

    private SysUser safeGetUser(Long userId) {
        if (userId == null) {
            return null;
        }
        try {
            return userClient.getById(userId);
        } catch (FeignException.NotFound ex) {
            return null;
        } catch (FeignException ex) {
            log.log(Level.WARNING, "Failed to fetch user by id=" + userId, ex);
            return null;
        }
    }

    private void safeUpdateUser(SysUser user) {
        if (user == null || user.getUserId() == null) {
            return;
        }
        try {
            userClient.update(user.getUserId(), user, null);
        } catch (FeignException ex) {
            log.log(Level.WARNING, "Failed to update user id=" + user.getUserId(), ex);
        }
    }

    private void validateDriver(DriverInformation driverInformation) {
        if (driverInformation == null) {
            throw new IllegalArgumentException("Driver information cannot be null");
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

    private void validatePagination(int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
    }

    private String truncate(String value) {
        if (value == null) {
            return null;
        }
        return value.length() <= 500 ? value : value.substring(0, 500);
    }

    @FunctionalInterface
    private interface FunctionWithException<T, R> {
        R apply(T t) throws Exception;
    }
}