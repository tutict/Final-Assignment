package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.VehicleInformationMapper;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
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
    private final ElasticsearchOperations elasticsearchOperations;

    @Autowired
    public VehicleInformationService(
            VehicleInformationMapper vehicleInformationMapper,
            RequestHistoryMapper requestHistoryMapper,
            KafkaTemplate<String, VehicleInformation> kafkaTemplate,
            VehicleInformationSearchRepository vehicleInformationSearchRepository,
            ElasticsearchOperations elasticsearchOperations) {
        this.vehicleInformationMapper = vehicleInformationMapper;
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

        // Step 1: 使用仓库层获取补全建议
        log.log(Level.INFO, "Executing completion query for user: {0}, prefix: {1}, maxSuggestions: {2}", new Object[]{currentUsername, prefix, maxSuggestions});
        SearchHits<VehicleInformationDocument> suggestHits = null;
        try {
            suggestHits = vehicleInformationSearchRepository.findCompletionSuggestions(currentUsername, prefix, maxSuggestions);
        } catch (Exception e) {
            log.log(Level.WARNING, "Error executing completion query: {0} {1}", new Object[]{e.getMessage(), e});
        }

        // 处理补全建议结果
        if (suggestHits != null && suggestHits.getSuggest() != null) {
            suggestHits.getSuggest().getSuggestion("licensePlate-suggest")
                    .getEntries()
                    .forEach(entry -> entry.getOptions()
                            .forEach(option -> suggestions.add(option.getText())));
            log.log(Level.INFO, "Found {0} completion suggestions: {1}", new Object[]{suggestions.size(), suggestions});
        }

        // Step 2: 如果结果不足，执行模糊搜索
        if (suggestions.size() < maxSuggestions) {
            log.log(Level.INFO, "Executing fuzzy query for prefix: {0}, user: {1}", new Object[]{prefix, currentUsername});
            SearchHits<VehicleInformationDocument> fuzzyHits = null;
            try {
                // 使用仓库层的分页查询代替手动构建模糊查询
                fuzzyHits = elasticsearchOperations.search(
                        vehicleInformationSearchRepository.searchByLicensePlate(prefix, null).getQuery(),
                        VehicleInformationDocument.class
                );
            } catch (Exception e) {
                log.log(Level.WARNING, "Error executing fuzzy query: {0} {1}", new Object[]{e.getMessage(), e});
            }

            if (fuzzyHits != null) {
                for (SearchHit<VehicleInformationDocument> hit : fuzzyHits) {
                    VehicleInformationDocument doc = hit.getContent();
                    if (doc.getLicensePlate() != null && doc.getOwnerName().equals(currentUsername)) {
                        suggestions.add(doc.getLicensePlate());
                    }
                    if (suggestions.size() >= maxSuggestions) {
                        break;
                    }
                }
            }
            log.log(Level.INFO, "After fuzzy search, total suggestions: {}", suggestions.size());
        }

        List<String> resultList = new ArrayList<>(suggestions);
        return resultList.size() <= maxSuggestions ? resultList : resultList.subList(0, maxSuggestions);
    }

    public List<String> getVehicleTypeAutocompleteSuggestions(String currentUsername, String prefix, int maxSuggestions) {
        Set<String> suggestions = new HashSet<>();

        // Step 1: 使用仓库层获取车辆类型的补全建议
        log.log(Level.INFO, "Executing vehicle type completion query for user: {0}, prefix: {1}, maxSuggestions: {2}", new Object[]{currentUsername, prefix, maxSuggestions});

        // 因为 vehicleType 没有 completion 字段，改为直接模糊搜索
        SearchHits<VehicleInformationDocument> suggestHits = null;
        try {
            suggestHits = elasticsearchOperations.search(
                    vehicleInformationSearchRepository.searchByLicensePlate(prefix, null).getQuery(), // 这里改为 vehicleType 的查询
                    VehicleInformationDocument.class
            );
        } catch (Exception e) {
            log.log(Level.INFO, "Error executing vehicle type completion query: {0} {1}", new Object[]{e.getMessage(), e});
        }

        // 处理搜索结果（这里假设 vehicleType 使用 ik_max_word 分词）
        if (suggestHits != null) {
            for (SearchHit<VehicleInformationDocument> hit : suggestHits) {
                VehicleInformationDocument doc = hit.getContent();
                if (doc.getVehicleType() != null && doc.getOwnerName().equals(currentUsername)) {
                    suggestions.add(doc.getVehicleType());
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
        }
        log.log(Level.INFO, "Found {0} vehicle type suggestions: {1}", new Object[]{suggestions.size(), suggestions});

        // Step 2: 如果结果不足，执行模糊搜索（这里已包含在 Step 1 中）
        if (suggestions.size() < maxSuggestions) {
            log.log(Level.INFO, "No additional fuzzy search needed, total suggestions: {0}", suggestions.size());
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