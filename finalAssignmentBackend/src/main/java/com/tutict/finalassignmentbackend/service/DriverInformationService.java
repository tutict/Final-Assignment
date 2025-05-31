package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.entity.elastic.DriverInformationDocument;
import com.tutict.finalassignmentbackend.entity.DriverInformation;
import com.tutict.finalassignmentbackend.mapper.DriverInformationMapper;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.UserManagementMapper;
import com.tutict.finalassignmentbackend.repository.DriverInformationSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@Service
public class DriverInformationService {

    private static final Logger log = Logger.getLogger(DriverInformationService.class.getName());

    private final DriverInformationMapper driverInformationMapper;
    private final UserManagementMapper userManagementMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, DriverInformation> kafkaTemplate;
    private final DriverInformationSearchRepository driverInformationSearchRepository;

    @Autowired
    public DriverInformationService(
            DriverInformationMapper driverInformationMapper,
            UserManagementMapper userManagementMapper,
            RequestHistoryMapper requestHistoryMapper,
            KafkaTemplate<String, DriverInformation> kafkaTemplate,
            DriverInformationSearchRepository driverInformationSearchRepository) {
        this.driverInformationMapper = driverInformationMapper;
        this.userManagementMapper = userManagementMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.driverInformationSearchRepository = driverInformationSearchRepository;
    }

    @Transactional
    @CacheEvict(cacheNames = "driverCache", allEntries = true)
    @WsAction(service = "DriverInformationService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, DriverInformation driverInformation, String action) {
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
        } catch (Exception e) {
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        sendKafkaMessage("driver_" + action, driverInformation);

        Integer driverId = driverInformation.getDriverId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(driverId != null ? driverId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "driverCache", allEntries = true)
    public void createDriver(DriverInformation driverInformation) {

        validateInput(driverInformation);
        if (driverInformation.getDriverId() != null && driverInformation.getDriverId() <= 0) {
            throw new IllegalArgumentException("Invalid driver ID: must be positive if provided");
        }

        try {
            log.log(Level.INFO, "Processing driver: {0}", driverInformation);
            DriverInformation existingDriver = driverInformationMapper.selectById(driverInformation.getDriverId());

            Integer driverId;
            if (existingDriver == null) {
                log.log(Level.INFO, "No existing driver found, inserting new record");
                driverInformationMapper.insert(driverInformation);
                driverId = driverInformation.getDriverId();
                if (driverId == null) {
                    throw new RuntimeException("Failed to generate driverId after insert");
                }
                log.log(Level.INFO, "Database insert successful, driverId={0}", driverId);
            } else {
                log.log(Level.INFO, "Existing driver found, updating record with driverId={0}", existingDriver.getDriverId());
                driverInformationMapper.updateById(driverInformation);
                driverId = driverInformation.getDriverId();
                log.log(Level.INFO, "Database update successful, driverId={0}", driverId);
            }

            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    DriverInformationDocument document = DriverInformationDocument.fromEntity(driverInformation);
                    if (document != null) {
                        driverInformationSearchRepository.save(document);
                        log.log(Level.INFO, "Post-commit: Elasticsearch indexed, driverId={0}", driverId);
                    } else {
                        log.log(Level.WARNING, "Failed to create DriverInformationDocument for driverId={0}", driverId);
                    }
                }
            });

        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to process driver: " + e.getMessage(), e);
            throw new RuntimeException("Failed to create or update driver", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "driverCache", allEntries = true)
    @WsAction(service = "DriverInformationService", action = "updateDriver")
    public void updateDriver(DriverInformation driverInformation) {
        if (driverInformation == null || driverInformation.getDriverId() == null) {
            throw new IllegalArgumentException("Driver information or ID cannot be null");
        }

        DriverInformation existingDriver = driverInformationMapper.selectById(driverInformation.getDriverId());
        if (existingDriver == null) {
            throw new IllegalStateException("Driver does not exist with ID: " + driverInformation.getDriverId());
        }

        driverInformationMapper.updateById(driverInformation);
        log.info(String.format("Driver updated with ID %s", driverInformation.getDriverId()));

        // Update UserManagement.modifiedTime
        UserManagement user = userManagementMapper.selectById(driverInformation.getDriverId());
        if (user != null) {
            user.setModifiedTime(LocalDateTime.now());
            userManagementMapper.updateById(user);
            log.info(String.format("UserManagement modifiedTime updated for userId %s", driverInformation.getDriverId()));
        } else {
            log.warning("No UserManagement found for driverId: " + driverInformation.getDriverId());
        }

        DriverInformationDocument document = DriverInformationDocument.fromEntity(driverInformation);
        if (document != null) {
            driverInformationSearchRepository.save(document);
            log.info(String.format("Driver synced to Elasticsearch with ID %s", driverInformation.getDriverId()));
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "driverCache", allEntries = true)
    @WsAction(service = "DriverInformationService", action = "deleteDriver")
    public void deleteDriver(int driverId) {
        if (driverId <= 0) {
            throw new IllegalArgumentException("Invalid driver ID");
        }

        int result = driverInformationMapper.deleteById(driverId);
        if (result > 0) {
            log.info(String.format("Driver with ID %s deleted successfully from database", driverId));
            driverInformationSearchRepository.deleteById(driverId);
            log.info(String.format("Driver with ID %s deleted from Elasticsearch", driverId));
        } else {
            log.severe(String.format("Failed to delete driver with ID %s from database", driverId));
            throw new IllegalStateException("Driver not found with ID: " + driverId);
        }
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriverById")
    public DriverInformation getDriverById(Integer driverId) {
        if (driverId == null || driverId <= 0 || driverId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid driver ID " + driverId);
        }

        DriverInformationDocument document = driverInformationSearchRepository.findById(driverId).orElse(null);
        if (document != null) {
            log.info(String.format("Driver with ID %s retrieved from Elasticsearch", driverId));
            return document.toEntity();
        }

        DriverInformation driver = driverInformationMapper.selectById(driverId);
        if (driver != null) {
            log.info(String.format("Driver with ID %s retrieved from database", driverId));
            driverInformationSearchRepository.save(DriverInformationDocument.fromEntity(driver));
        }
        return driver;
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getAllDrivers")
    public List<DriverInformation> getAllDrivers() {
        Iterable<DriverInformationDocument> documents = driverInformationSearchRepository.findAll();
        List<DriverInformation> driversFromEs = StreamSupport.stream(documents.spliterator(), false)
                .map(DriverInformationDocument::toEntity)
                .collect(Collectors.toList());

        if (!driversFromEs.isEmpty()) {
            log.info("Drivers retrieved from Elasticsearch");
            return driversFromEs;
        }

        List<DriverInformation> drivers = driverInformationMapper.selectList(null);
        if (!drivers.isEmpty()) {
            log.info("Drivers retrieved from database, syncing to Elasticsearch");
            drivers.forEach(driver -> driverInformationSearchRepository.save(DriverInformationDocument.fromEntity(driver)));
        }
        return drivers;
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriversByIdCardNumber")
    public List<DriverInformation> searchByIdCardNumber(String query, int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }

        Set<DriverInformation> suggestions = new HashSet<>();
        int maxSuggestions = page * size; // Total results to fetch for pagination
        int offset = (page - 1) * size; // Starting point for pagination

        log.log(Level.INFO, "Executing match query for idCardNumber: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});

        SearchHits<DriverInformationDocument> matchHits = null;
        try {
            matchHits = driverInformationSearchRepository.searchByIdCardNumber(query);
        } catch (Exception e) {
            log.log(Level.WARNING, "Error executing match query for idCardNumber: {0}", new Object[]{e.getMessage()});
        }

        if (matchHits != null && matchHits.hasSearchHits()) {
            for (SearchHit<DriverInformationDocument> hit : matchHits) {
                DriverInformationDocument doc = hit.getContent();
                if (doc.getIdCardNumber() != null) {
                    suggestions.add(doc.toEntity());
                    log.log(Level.INFO, "Found driver with ID: {0}", new Object[]{doc.getDriverId()});
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
            log.log(Level.INFO, "Found {0} match suggestions: {1}", new Object[]{suggestions.size(), suggestions});
        } else {
            log.log(Level.INFO, "No match suggestions found for idCardNumber: {0}", new Object[]{query});
        }

        // If results are insufficient, execute fuzzy query
        if (suggestions.size() < maxSuggestions) {
            log.log(Level.INFO, "Executing fuzzy query for idCardNumber: {0}", new Object[]{query});
            SearchHits<DriverInformationDocument> fuzzyHits = null;
            try {
                fuzzyHits = driverInformationSearchRepository.searchByIdCardNumberFuzzy(query);
                log.log(Level.INFO, "Fuzzy query returned {0} hits",
                        new Object[]{fuzzyHits != null ? fuzzyHits.getTotalHits() : 0});
            } catch (Exception e) {
                log.log(Level.WARNING, "Error executing fuzzy query for idCardNumber: {0}", new Object[]{e.getMessage()});
            }

            if (fuzzyHits != null && fuzzyHits.hasSearchHits()) {
                for (SearchHit<DriverInformationDocument> hit : fuzzyHits) {
                    DriverInformationDocument doc = hit.getContent();
                    if (doc.getIdCardNumber() != null) {
                        suggestions.add(doc.toEntity());
                        log.log(Level.INFO, "Found driver with ID: {0}", new Object[]{doc.getDriverId()});
                    }
                    if (suggestions.size() >= maxSuggestions) {
                        break;
                    }
                }
                log.log(Level.INFO, "After fuzzy search, total suggestions: {0}", new Object[]{suggestions.size()});
            } else {
                log.log(Level.INFO, "Fuzzy search returned no results for idCardNumber: {0}", new Object[]{query});
            }
        }

        List<DriverInformation> resultList = new ArrayList<>(suggestions);
        return resultList.stream()
                .skip(offset)
                .limit(size)
                .collect(Collectors.toList());
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriverByDriverLicenseNumber")
    public List<DriverInformation> searchByDriverLicenseNumber(String query, int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }

        Set<DriverInformation> suggestions = new HashSet<>();
        int maxSuggestions = page * size; // Total results to fetch for pagination
        int offset = (page - 1) * size; // Starting point for pagination

        log.log(Level.INFO, "Executing match query for driverLicenseNumber: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});

        SearchHits<DriverInformationDocument> matchHits = null;
        try {
            matchHits = driverInformationSearchRepository.searchByDriverLicenseNumber(query);
        } catch (Exception e) {
            log.log(Level.WARNING, "Error executing match query for driverLicenseNumber: {0}", new Object[]{e.getMessage()});
        }

        if (matchHits != null && matchHits.hasSearchHits()) {
            for (SearchHit<DriverInformationDocument> hit : matchHits) {
                DriverInformationDocument doc = hit.getContent();
                if (doc.getDriverLicenseNumber() != null) {
                    suggestions.add(doc.toEntity());
                    log.log(Level.INFO, "Found driver with ID: {0}", new Object[]{doc.getDriverId()});
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
            log.log(Level.INFO, "Found {0} match suggestions: {1}", new Object[]{suggestions.size(), suggestions});
        } else {
            log.log(Level.INFO, "No match suggestions found for driverLicenseNumber: {0}", new Object[]{query});
        }

        // If results are insufficient, execute fuzzy query
        if (suggestions.size() < maxSuggestions) {
            log.log(Level.INFO, "Executing fuzzy query for driverLicenseNumber: {0}", new Object[]{query});
            SearchHits<DriverInformationDocument> fuzzyHits = null;
            try {
                fuzzyHits = driverInformationSearchRepository.searchByDriverLicenseNumberFuzzy(query);
                log.log(Level.INFO, "Fuzzy query returned {0} hits",
                        new Object[]{fuzzyHits != null ? fuzzyHits.getTotalHits() : 0});
            } catch (Exception e) {
                log.log(Level.WARNING, "Error executing fuzzy query for driverLicenseNumber: {0}", new Object[]{e.getMessage()});
            }

            if (fuzzyHits != null && fuzzyHits.hasSearchHits()) {
                for (SearchHit<DriverInformationDocument> hit : fuzzyHits) {
                    DriverInformationDocument doc = hit.getContent();
                    if (doc.getDriverLicenseNumber() != null) {
                        suggestions.add(doc.toEntity());
                        log.log(Level.INFO, "Found driver with ID: {0}", new Object[]{doc.getDriverId()});
                    }
                    if (suggestions.size() >= maxSuggestions) {
                        break;
                    }
                }
                log.log(Level.INFO, "After fuzzy search, total suggestions: {0}", new Object[]{suggestions.size()});
            } else {
                log.log(Level.INFO, "Fuzzy search returned no results for driverLicenseNumber: {0}", new Object[]{query});
            }
        }

        List<DriverInformation> resultList = new ArrayList<>(suggestions);
        return resultList.stream()
                .skip(offset)
                .limit(size)
                .collect(Collectors.toList());
    }

    @Cacheable(cacheNames = "driverCache", unless = "#result == null")
    @WsAction(service = "DriverInformationService", action = "getDriversByName")
    public List<DriverInformation> searchByName(String query, int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }

        Set<DriverInformation> suggestions = new HashSet<>();
        int maxSuggestions = page * size; // Total results to fetch for pagination
        int offset = (page - 1) * size; // Starting point for pagination

        log.log(Level.INFO, "Executing match query for name: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});

        SearchHits<DriverInformationDocument> matchHits = null;
        try {
            matchHits = driverInformationSearchRepository.searchByNamePrefix(query);
        } catch (Exception e) {
            log.log(Level.WARNING, "Error executing match query for name: {0}", new Object[]{e.getMessage()});
        }

        if (matchHits != null && matchHits.hasSearchHits()) {
            for (SearchHit<DriverInformationDocument> hit : matchHits) {
                DriverInformationDocument doc = hit.getContent();
                if (doc.getName() != null) {
                    suggestions.add(doc.toEntity());
                    log.log(Level.INFO, "Found driver with ID: {0}", new Object[]{doc.getDriverId()});
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
            log.log(Level.INFO, "Found {0} match suggestions: {1}", new Object[]{suggestions.size(), suggestions});
        } else {
            log.log(Level.INFO, "No match suggestions found for name: {0}", new Object[]{query});
        }

        // If results are insufficient, execute fuzzy query
        if (suggestions.size() < maxSuggestions) {
            log.log(Level.INFO, "Executing fuzzy query for name: {0}", new Object[]{query});
            SearchHits<DriverInformationDocument> fuzzyHits = null;
            try {
                fuzzyHits = driverInformationSearchRepository.searchByNameFuzzy(query);
                log.log(Level.INFO, "Fuzzy query returned {0} hits",
                        new Object[]{fuzzyHits != null ? fuzzyHits.getTotalHits() : 0});
            } catch (Exception e) {
                log.log(Level.WARNING, "Error executing fuzzy query for name: {0}", new Object[]{e.getMessage()});
            }

            if (fuzzyHits != null && fuzzyHits.hasSearchHits()) {
                for (SearchHit<DriverInformationDocument> hit : fuzzyHits) {
                    DriverInformationDocument doc = hit.getContent();
                    if (doc.getName() != null) {
                        suggestions.add(doc.toEntity());
                        log.log(Level.INFO, "Found driver with ID: {0}", new Object[]{doc.getDriverId()});
                    }
                    if (suggestions.size() >= maxSuggestions) {
                        break;
                    }
                }
                log.log(Level.INFO, "After fuzzy search, total suggestions: {0}", new Object[]{suggestions.size()});
            } else {
                log.log(Level.INFO, "Fuzzy search returned no results for name: {0}", new Object[]{query});
            }
        }

        List<DriverInformation> resultList = new ArrayList<>(suggestions);
        return resultList.stream()
                .skip(offset)
                .limit(size)
                .collect(Collectors.toList());
    }

    private void sendKafkaMessage(String topic, DriverInformation driverInformation) {
        if (driverInformation == null || topic == null) {
            log.warning("Invalid input for sending Kafka message");
            return;
        }
        try {
            kafkaTemplate.send(topic, driverInformation);
            log.info(String.format("Message sent to Kafka topic %s successfully", topic));
        } catch (Exception e) {
            log.log(Level.WARNING, "Error sending Kafka message: {0}", new Object[]{e.getMessage()});
        }
    }

    private void validateInput(DriverInformation driverInformation) {
        if (driverInformation == null) {
            throw new IllegalArgumentException("Deduction information cannot be null");
        }
    }
}