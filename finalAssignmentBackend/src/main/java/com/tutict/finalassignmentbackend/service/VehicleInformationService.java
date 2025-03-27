package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.DriverInformationDocument;
import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.VehicleInformationMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
import com.tutict.finalassignmentbackend.repository.DriverInformationSearchRepository;
import com.tutict.finalassignmentbackend.repository.VehicleInformationSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.core.query.Query;
import org.springframework.data.elasticsearch.core.query.StringQuery;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class VehicleInformationService {

    private static final Logger log = Logger.getLogger(VehicleInformationService.class.getName());

    private final VehicleInformationMapper vehicleInformationMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, VehicleInformation> kafkaTemplate;
    private final VehicleInformationSearchRepository vehicleInformationSearchRepository;
    private final DriverInformationSearchRepository  driverInformationSearchRepository;
    private final ElasticsearchOperations elasticsearchOperations;

    @Autowired
    public VehicleInformationService(
            VehicleInformationMapper vehicleInformationMapper,
            RequestHistoryMapper requestHistoryMapper,
            KafkaTemplate<String, VehicleInformation> kafkaTemplate,
            VehicleInformationSearchRepository vehicleInformationSearchRepository,
            DriverInformationSearchRepository driverInformationSearchRepository,
            ElasticsearchOperations elasticsearchOperations) {
        this.vehicleInformationMapper = vehicleInformationMapper;
        this.driverInformationSearchRepository = driverInformationSearchRepository;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.vehicleInformationSearchRepository = vehicleInformationSearchRepository;
        this.elasticsearchOperations = elasticsearchOperations;
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    @WsAction(service = "VehicleInformationService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, VehicleInformation vehicleInformation, String action) {
        if (idempotencyKey == null || idempotencyKey.trim().isEmpty()) {
            throw new IllegalArgumentException("Idempotency key cannot be null or empty");
        }

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
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ": " + e.getMessage());
            throw new RuntimeException("Failed to insert request history", e);
        }

        sendKafkaMessage(vehicleInformation, action);

        Integer vehicleId = vehicleInformation.getVehicleId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(vehicleId != null ? vehicleId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    public void createVehicleInformation(VehicleInformation vehicleInformation) {
        validateInput(vehicleInformation.getLicensePlate(), "License plate cannot be null or empty");
        try {
            log.log(Level.INFO, "Creating vehicle: {0}", vehicleInformation);
            vehicleInformationMapper.insert(vehicleInformation);
            Integer vehicleId = vehicleInformation.getVehicleId();
            if (vehicleId == null) {
                throw new RuntimeException("Failed to generate vehicleId after insert");
            }
            log.info("Database insert successful, vehicleId=" + vehicleId);

            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    VehicleInformationDocument doc = VehicleInformationDocument.fromEntity(vehicleInformation);
                    vehicleInformationSearchRepository.save(doc);
                    log.info(String.format("Post-commit: Kafka message sent and Elasticsearch indexed, vehicleId=%d", vehicleId));
                }
            });
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to create vehicle information: " + e.getMessage(), e);
            throw new RuntimeException("Failed to create vehicle information", e);
        }
    }

    @Cacheable(cacheNames = "vehicleCache", unless = "#result == null")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationById")
    public VehicleInformation getVehicleInformationById(Integer vehicleId) {
        if (vehicleId == null || vehicleId <= 0 || vehicleId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid vehicle ID: " + vehicleId);
        }
        VehicleInformation vehicle = vehicleInformationMapper.selectById(vehicleId);
        if (vehicle == null) {
            log.info("Vehicle not found for ID: " + vehicleId);
        }
        return vehicle;
    }

    @Cacheable(cacheNames = "vehicleCache", unless = "#result == null")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByLicensePlate")
    public VehicleInformation getVehicleInformationByLicensePlate(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        List<VehicleInformation> results = vehicleInformationMapper.selectList(queryWrapper);
        if (results.isEmpty()) {
            log.info("No vehicle found for license plate: " + licensePlate);
            return null;
        } else if (results.size() > 1) {
            log.warning("Multiple vehicles found for license plate: " + licensePlate + ". Returning first result.");
            return results.getFirst();
        }
        return results.getFirst();
    }

    @Cacheable(cacheNames = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getAllVehicleInformation")
    public List<VehicleInformation> getAllVehicleInformation() {
        List<VehicleInformation> result = vehicleInformationMapper.selectList(null);
        return result != null ? result : Collections.emptyList();
    }

    @Cacheable(cacheNames = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByType")
    public List<VehicleInformation> getVehicleInformationByType(String vehicleType) {
        validateInput(vehicleType, "Invalid vehicle type");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("vehicle_type", vehicleType);
        List<VehicleInformation> result = vehicleInformationMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList();
    }

    @Cacheable(cacheNames = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByOwnerName")
    public List<VehicleInformation> getVehicleInformationByOwnerName(String ownerName) {
        validateInput(ownerName, "Invalid owner name");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("owner_name", ownerName);
        List<VehicleInformation> result = vehicleInformationMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList();
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    public void updateVehicleInformation(VehicleInformation vehicleInformation) {
        if (vehicleInformation.getVehicleId() == null || vehicleInformation.getVehicleId() <= 0) {
            throw new IllegalArgumentException("Vehicle ID cannot be null or invalid");
        }
        validateInput(vehicleInformation.getLicensePlate(), "License plate cannot be null or empty");
        try {
            int rowsAffected = vehicleInformationMapper.updateById(vehicleInformation);
            if (rowsAffected == 0) {
                log.warning("No vehicle found to update for ID: " + vehicleInformation.getVehicleId());
                throw new RuntimeException("Vehicle not found");
            }
            vehicleInformationSearchRepository.save(VehicleInformationDocument.fromEntity(vehicleInformation));
            log.info(String.format("Vehicle updated successfully, vehicleId=%d", vehicleInformation.getVehicleId()));
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to update vehicle information: " + e.getMessage(), e);
            throw new RuntimeException("Failed to update vehicle information", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    @WsAction(service = "VehicleInformationService", action = "deleteVehicleInformation")
    public void deleteVehicleInformation(int vehicleId) {
        if (vehicleId <= 0) {
            throw new IllegalArgumentException("Invalid vehicle ID: " + vehicleId);
        }
        try {
            int rowsAffected = vehicleInformationMapper.deleteById(vehicleId);
            if (rowsAffected == 0) {
                log.warning("No vehicle found to delete for ID: " + vehicleId);
                throw new RuntimeException("Vehicle not found");
            }
            vehicleInformationSearchRepository.deleteById(vehicleId);
            log.info(String.format("Vehicle with ID %d deleted successfully from both DB and Elasticsearch", vehicleId));
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to delete vehicle information: " + e.getMessage(), e);
            throw new RuntimeException("Failed to delete vehicle information", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "vehicleCache", allEntries = true)
    @WsAction(service = "VehicleInformationService", action = "deleteVehicleInformationByLicensePlate")
    public void deleteVehicleInformationByLicensePlate(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        try {
            List<VehicleInformation> vehicles = vehicleInformationMapper.selectList(queryWrapper);
            if (vehicles.isEmpty()) {
                log.info("No vehicle found to delete for license plate: " + licensePlate);
                return;
            }
            vehicleInformationMapper.delete(queryWrapper);
            vehicles.forEach(vehicle ->
                    vehicleInformationSearchRepository.deleteById(vehicle.getVehicleId()));
            log.info("Vehicles with license plate " + licensePlate + " deleted successfully");
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to delete vehicle by license plate: " + e.getMessage(), e);
            throw new RuntimeException("Failed to delete vehicle by license plate", e);
        }
    }

    @Cacheable(cacheNames = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "isLicensePlateExists")
    public boolean isLicensePlateExists(String licensePlate) {
        validateInput(licensePlate, "Invalid license plate number");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", licensePlate);
        return vehicleInformationMapper.selectCount(queryWrapper) > 0;
    }

    public List<String> getLicensePlateAutocompleteSuggestions(String currentUsername, String prefix, int maxSuggestions) {
        Set<String> suggestions = new HashSet<>();

        // Step 1: 通过 currentUsername 查询 DriverInformationDocument 获取所有匹配的 name
        log.log(Level.INFO, "Querying driver information for username: {0}", new Object[]{currentUsername});
        List<DriverInformationDocument> driverDocs = driverInformationSearchRepository.findByName(currentUsername);
        if (driverDocs.isEmpty()) {
            log.log(Level.WARNING, "No driver found for username: {0}", new Object[]{currentUsername});
            return new ArrayList<>();
        }

        // 收集所有匹配的 name
        List<String> ownerNames = new ArrayList<>();
        for (DriverInformationDocument doc : driverDocs) {
            String ownerName = doc.getName();
            ownerNames.add(ownerName);
            log.log(Level.INFO, "Found driver with name: {0} for username: {1}", new Object[]{ownerName, currentUsername});
        }

        // Step 2: 对每个 ownerName 执行模糊查询
        for (String ownerName : ownerNames) {
            log.log(Level.INFO, "Executing match query for ownerName: {0}, prefix: {1}, maxSuggestions: {2}",
                    new Object[]{ownerName, prefix, maxSuggestions});

            SearchHits<VehicleInformationDocument> matchHits = null;
            try {
                matchHits = vehicleInformationSearchRepository.findCompletionSuggestions(ownerName, prefix, maxSuggestions);
            } catch (Exception e) {
                log.log(Level.WARNING, "Error executing match query: {0} {1}", new Object[]{e.getMessage(), e});
            }

            if (matchHits != null && matchHits.hasSearchHits()) {
                for (SearchHit<VehicleInformationDocument> hit : matchHits) {
                    VehicleInformationDocument doc = hit.getContent();
                    if (doc.getLicensePlate() != null) {
                        suggestions.add(doc.getLicensePlate());
                        log.log(Level.INFO, "Found license plate: {0}", new Object[]{doc.getLicensePlate()});
                    }
                    if (suggestions.size() >= maxSuggestions) {
                        break;
                    }
                }
                log.log(Level.INFO, "Found {0} match suggestions: {1}", new Object[]{suggestions.size(), suggestions});
            } else {
                log.log(Level.INFO, "No match suggestions found for prefix: {0}", new Object[]{prefix});
            }

            // 如果已经收集到足够的建议，提前退出
            if (suggestions.size() >= maxSuggestions) {
                break;
            }

            // Step 3: 如果结果不足，执行备用模糊查询
            log.log(Level.INFO, "Executing fuzzy query for prefix: {0}, ownerName: {1}", new Object[]{prefix, ownerName});
            SearchHits<VehicleInformationDocument> fuzzyHits = null;
            try {
                fuzzyHits = vehicleInformationSearchRepository.searchByLicensePlate(prefix, ownerName);
                log.log(Level.INFO, "Fuzzy query returned {0} hits", new Object[]{fuzzyHits != null ? fuzzyHits.getTotalHits() : 0});
            } catch (Exception e) {
                log.log(Level.WARNING, "Error executing fuzzy query: {0} {1}", new Object[]{e.getMessage(), e});
            }

            if (fuzzyHits != null && fuzzyHits.hasSearchHits()) {
                for (SearchHit<VehicleInformationDocument> hit : fuzzyHits) {
                    VehicleInformationDocument doc = hit.getContent();
                    if (doc.getLicensePlate() != null) {
                        suggestions.add(doc.getLicensePlate());
                        log.log(Level.INFO, "Found license plate: {0}", new Object[]{doc.getLicensePlate()});
                    }
                    if (suggestions.size() >= maxSuggestions) {
                        break;
                    }
                }
                log.log(Level.INFO, "After fuzzy search, total suggestions: {0}", new Object[]{suggestions.size()});
            } else {
                log.log(Level.INFO, "Fuzzy search returned no results for prefix: {0}", new Object[]{prefix});
            }

            if (suggestions.size() >= maxSuggestions) {
                break;
            }
        }

        List<String> resultList = new ArrayList<>(suggestions);
        return resultList.size() <= maxSuggestions ? resultList : resultList.subList(0, maxSuggestions);
    }

    public List<String> getVehicleTypeAutocompleteSuggestions(String currentUsername, String prefix, int maxSuggestions) {
        Set<String> suggestions = new HashSet<>();

        // 通过 currentUsername 查询 DriverInformationDocument 获取所有匹配的 name
        log.log(Level.INFO, "Querying driver information for username: {0}", new Object[]{currentUsername});
        List<DriverInformationDocument> driverDocs = driverInformationSearchRepository.findByName(currentUsername);
        if (driverDocs.isEmpty()) {
            log.log(Level.WARNING, "No driver found for username: {0}", new Object[]{currentUsername});
            return new ArrayList<>();
        }

        // 收集所有匹配的 name
        List<String> ownerNames = new ArrayList<>();
        for (DriverInformationDocument doc : driverDocs) {
            String ownerName = doc.getName();
            ownerNames.add(ownerName);
            log.log(Level.INFO, "Found driver with name: {0} for username: {1}", new Object[]{ownerName, currentUsername});
        }

        // 对每个 ownerName 执行查询
        for (String ownerName : ownerNames) {
            log.log(Level.INFO, "Executing vehicle type search for ownerName: {0}, prefix: {1}, maxSuggestions: {2}",
                    new Object[]{ownerName, prefix, maxSuggestions});

            SearchHits<VehicleInformationDocument> suggestHits = null;
            try {
                suggestHits = vehicleInformationSearchRepository.searchByVehicleType(prefix, ownerName);
            } catch (Exception e) {
                log.log(Level.WARNING, "Error executing vehicle type search query: {0} {1}", new Object[]{e.getMessage(), e});
            }

            if (suggestHits != null && suggestHits.hasSearchHits()) {
                for (SearchHit<VehicleInformationDocument> hit : suggestHits) {
                    VehicleInformationDocument doc = hit.getContent();
                    if (doc.getVehicleType() != null) {
                        suggestions.add(doc.getVehicleType());
                    }
                    if (suggestions.size() >= maxSuggestions) {
                        break;
                    }
                }
                log.log(Level.INFO, "Found {0} vehicle type suggestions: {1}", new Object[]{suggestions.size(), suggestions});
            } else {
                log.log(Level.INFO, "No vehicle type suggestions found for prefix: {0}", new Object[]{prefix});
            }

            if (suggestions.size() >= maxSuggestions) {
                break;
            }
        }

        List<String> resultList = new ArrayList<>(suggestions);
        return resultList.size() <= maxSuggestions ? resultList : resultList.subList(0, maxSuggestions);
    }

    public List<VehicleInformation> searchVehicles(String query, int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }
        if (query == null || query.trim().isEmpty()) {
            log.info("Query is null or empty, returning empty list");
            return Collections.emptyList();
        }

        try {
            Pageable pageable = PageRequest.of(page - 1, size);

            // 修复查询字符串，去掉外层 "query"
            String queryString = "{\"match\":{\"ownerName\":\"" + query + "\"}}";
            Query searchQuery = new StringQuery(queryString).setPageable(pageable);
            SearchHits<VehicleInformationDocument> searchHits = elasticsearchOperations.search(searchQuery, VehicleInformationDocument.class);
            List<VehicleInformationDocument> results = searchHits.stream()
                    .map(SearchHit::getContent)
                    .toList();

            return results.stream()
                    .map(VehicleInformationDocument::toEntity)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to search vehicles in index 'vehicles': {0}", new Object[]{e.getMessage()});
            return Collections.emptyList();
        }
    }

    @Cacheable(cacheNames = "vehicleCache")
    @WsAction(service = "VehicleInformationService", action = "getVehicleInformationByStatus")
    public List<VehicleInformation> getVehicleInformationByStatus(String currentStatus) {
        validateInput(currentStatus, "Invalid current status");
        QueryWrapper<VehicleInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("current_status", currentStatus);
        List<VehicleInformation> result = vehicleInformationMapper.selectList(queryWrapper);
        return result != null ? result : Collections.emptyList();
    }

    public void sendKafkaMessage(VehicleInformation vehicleInformation, String action) {
        if (vehicleInformation == null || action == null) {
            log.warning("Cannot send Kafka message with null vehicleInformation or action");
            return;
        }
        String topic = "vehicle_" + action.toLowerCase();
        try {
            kafkaTemplate.send(topic, vehicleInformation);
            log.info(String.format("Message sent to Kafka topic %s successfully with vehicleId=%d",
                    topic, vehicleInformation.getVehicleId()));
        } catch (Exception e) {
            log.log(Level.SEVERE, "Failed to send Kafka message to topic " + topic + ": " + e.getMessage(), e);
        }
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }
}