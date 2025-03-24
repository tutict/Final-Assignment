package com.tutict.finalassignmentbackend.service;

import co.elastic.clients.elasticsearch._types.query_dsl.Query;
import co.elastic.clients.elasticsearch.core.search.Suggester;
import org.springframework.data.elasticsearch.client.elc.NativeQuery;
import org.springframework.data.elasticsearch.client.elc.NativeQueryBuilder;
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

        // Step 1: 使用 NativeSearchQueryBuilder 构建 Completion 建议查询
        Query filterQuery = new Query.Builder()
                .term(t -> t
                        .field("ownerName.keyword")
                        .value(currentUsername))
                .build();

        Suggester suggester = Suggester.of(s -> s
                .suggesters("licensePlate-suggest", fs -> fs
                        .completion(c -> c
                                .field("licensePlate.completion")
                                .analyzer(prefix) // analyzer 需为 String
                                .size(maxSuggestions) // maxSuggestions 需为 int
                                .skipDuplicates(true)
                                .fuzzy(f -> f.fuzziness("1"))
                        )
                )
        );
        NativeQueryBuilder queryBuilder = new NativeQueryBuilder()
                .withQuery(filterQuery)
                .withSuggester(suggester);

        NativeQuery nativeQuery = queryBuilder.build();
        log.log(Level.FINE, "Executing completion query for user: {0}, prefix: {1}, maxSuggestions: {2}",
                new Object[]{currentUsername, prefix, maxSuggestions});
        log.log(Level.FINE, "Native completion query: {0}", Objects.requireNonNull(nativeQuery.getQuery()).toString());

        SearchHits<VehicleInformationDocument> suggestHits;
        try {
            suggestHits = elasticsearchOperations.search(nativeQuery, VehicleInformationDocument.class);
        } catch (Exception e) {
            log.log(Level.SEVERE, "Error executing completion query: {0}", e.getMessage());
            throw e; // 抛出异常由控制器处理
        }

        // 处理 Completion 建议结果
        if (suggestHits.getSuggest() != null) {
            suggestHits.getSuggest().getSuggestion("licensePlate-suggest")
                    .getEntries()
                    .forEach(entry -> entry.getOptions()
                            .forEach(option -> suggestions.add(option.getText())));
            log.log(Level.FINE, "Found {0} completion suggestions: {1}",
                    new Object[]{suggestions.size(), suggestions});
        } else {
            log.log(Level.FINE, "No completion suggestions found");
        }

        // Step 2: 如果结果不足，执行模糊搜索
        if (suggestions.size() < maxSuggestions) {
            Query fuzzyQuery = new Query.Builder()
                    .fuzzy(f -> f
                            .field("licensePlate.ngram")
                            .value(prefix)
                            .fuzziness("1")
                            .prefixLength(1))
                    .build();

            Query combinedQuery = new Query.Builder()
                    .bool(b -> b
                            .must(fuzzyQuery)
                            .filter(new Query.Builder()
                                    .term(t -> t
                                            .field("ownerName.keyword")
                                            .value(currentUsername))
                                    .build()))
                    .build();

            NativeQueryBuilder fuzzyQueryBuilder = new NativeQueryBuilder()
                    .withQuery(combinedQuery);

            NativeQuery fuzzyNativeQuery = fuzzyQueryBuilder.build();
            log.log(Level.FINE, "Executing fuzzy query for prefix: {0}, user: {1}",
                    new Object[]{prefix, currentUsername});
            log.log(Level.FINE, "Fuzzy query: {0}", Objects.requireNonNull(fuzzyNativeQuery.getQuery()).toString());

            SearchHits<VehicleInformationDocument> fuzzyHits;
            try {
                fuzzyHits = elasticsearchOperations.search(fuzzyNativeQuery, VehicleInformationDocument.class);
            } catch (Exception e) {
                log.log(Level.SEVERE, "Error executing fuzzy query: {0}", e.getMessage());
                throw e; // 抛出异常由控制器处理
            }

            for (SearchHit<VehicleInformationDocument> hit : fuzzyHits) {
                VehicleInformationDocument doc = hit.getContent();
                if (doc.getLicensePlate() != null) {
                    suggestions.add(doc.getLicensePlate());
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
            log.log(Level.FINE, "After fuzzy search, total suggestions: {0}",
                    new Object[]{suggestions.size()});
        }

        List<String> resultList = new ArrayList<>(suggestions);
        return resultList.size() <= maxSuggestions ?
                resultList :
                resultList.subList(0, maxSuggestions);
    }

    public List<String> getVehicleTypeAutocompleteSuggestions(
            String currentUsername, String prefix, int maxSuggestions) {

        Set<String> suggestions = new HashSet<>();

        // Step 1: Completion suggestion query
        String suggestQuery = String.format(
                """
                        {
                          "query": {
                            "bool": {
                              "filter": {
                                "term": {
                                  "ownerName.keyword": "%s"
                                }
                              }
                            }
                          },
                          "suggest": {
                            "vehicleType-suggest": {
                              "prefix": "%s",
                              "completion": {
                                "field": "vehicleType.completion",
                                "fuzzy": {
                                  "fuzziness": "1"
                                },
                                "size": %d,
                                "skip_duplicates": true
                              }
                            }
                          }
                        }""", currentUsername, prefix, maxSuggestions);
        log.log(Level.SEVERE, "Vehicle type completion query: {}", suggestQuery);
        StringQuery completionQuery = new StringQuery(suggestQuery);
        SearchHits<VehicleInformationDocument> suggestHits = elasticsearchOperations.search(
                completionQuery, VehicleInformationDocument.class);

        // Process completion suggestions
        if (suggestHits.getSuggest() != null) {
            suggestHits.getSuggest().getSuggestion("vehicleType-suggest")
                    .getEntries()
                    .forEach(entry -> entry.getOptions()
                            .forEach(option -> suggestions.add(option.getText())));
        }

        // Step 2: If insufficient results, fall back to fuzzy search
        if (suggestions.size() < maxSuggestions) {
            String fuzzyQuery = String.format(
                    """
                            {
                              "query": {
                                "bool": {
                                  "must": {
                                    "fuzzy": {
                                      "vehicleType.ngram": {
                                        "value": "%s",
                                        "fuzziness": "1",
                                        "prefix_length": 1
                                      }
                                    }
                                  },
                                  "filter": {
                                    "term": {
                                      "ownerName.keyword": "%s"
                                    }
                                  }
                                }
                              }
                            }""", prefix, currentUsername);
            log.log(Level.SEVERE, "Vehicle type fuzzy query: {}", fuzzyQuery);
            StringQuery fuzzySearchQuery = new StringQuery(fuzzyQuery);
            SearchHits<VehicleInformationDocument> fuzzyHits = elasticsearchOperations.search(
                    fuzzySearchQuery, VehicleInformationDocument.class);

            for (SearchHit<VehicleInformationDocument> hit : fuzzyHits) {
                VehicleInformationDocument doc = hit.getContent();
                if (doc.getVehicleType() != null) {
                    suggestions.add(doc.getVehicleType());
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
        }

        List<String> resultList = new ArrayList<>(suggestions);
        return resultList.size() <= maxSuggestions ?
                resultList :
                resultList.subList(0, maxSuggestions);
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
            org.springframework.data.elasticsearch.core.query.Query searchQuery = new StringQuery(queryString).setPageable(pageable);
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