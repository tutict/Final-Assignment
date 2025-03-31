package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseInformationDocument;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import com.tutict.finalassignmentbackend.mapper.OffenseInformationMapper;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

@Service
public class OffenseInformationService {

    private static final Logger log = Logger.getLogger(OffenseInformationService.class.getName());

    private final OffenseInformationMapper offenseInformationMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, OffenseInformation> kafkaTemplate;
    private final OffenseInformationSearchRepository offenseSearchRepository;

    @Autowired
    public OffenseInformationService(OffenseInformationMapper offenseInformationMapper,
                                     RequestHistoryMapper requestHistoryMapper,
                                     KafkaTemplate<String, OffenseInformation> kafkaTemplate,
                                     OffenseInformationSearchRepository offenseSearchRepository) {
        this.offenseInformationMapper = offenseInformationMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.offenseSearchRepository = offenseSearchRepository;
    }

    @Transactional
    @CacheEvict(cacheNames = "offenseCache", allEntries = true)
    @WsAction(service = "OffenseInformationService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, OffenseInformation offenseInformation, String action) {
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

        sendKafkaMessage("offense_" + action, offenseInformation);

        Integer offenseId = offenseInformation.getOffenseId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(offenseId != null ? offenseId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "offenseCache", allEntries = true)
    public void createOffense(OffenseInformation offenseInformation) {
        OffenseInformation existingOffense = offenseInformationMapper.selectById(offenseInformation.getOffenseId());
        if (existingOffense == null) {
            offenseInformationMapper.insert(offenseInformation);
        } else {
            offenseInformationMapper.updateById(offenseInformation);
        }
        // Sync with Elasticsearch
        offenseSearchRepository.save(OffenseInformationDocument.fromEntity(offenseInformation));
    }

    @Transactional
    @CacheEvict(cacheNames = "offenseCache", allEntries = true)
    public void updateOffense(OffenseInformation offenseInformation) {
        OffenseInformation existingOffense = offenseInformationMapper.selectById(offenseInformation.getOffenseId());
        if (existingOffense == null) {
            offenseInformationMapper.insert(offenseInformation);
        } else {
            offenseInformationMapper.updateById(offenseInformation);
        }
        // Sync with Elasticsearch
        offenseSearchRepository.save(OffenseInformationDocument.fromEntity(offenseInformation));
    }

    @Transactional
    @CacheEvict(cacheNames = "offenseCache", allEntries = true)
    @WsAction(service = "OffenseInformationService", action = "deleteOffense")
    public void deleteOffense(int offenseId) {
        if (offenseId <= 0) {
            throw new IllegalArgumentException("Invalid offense ID");
        }
        int result = offenseInformationMapper.deleteById(offenseId);
        if (result > 0) {
            log.info(String.format("Offense with ID %s deleted successfully", offenseId));
            offenseSearchRepository.deleteById(offenseId); // Sync with Elasticsearch
        } else {
            log.severe(String.format("Failed to delete offense with ID %s", offenseId));
        }
    }

    @Cacheable(cacheNames = "offenseCache")
    @WsAction(service = "OffenseInformationService", action = "getOffenseByOffenseId")
    public OffenseInformation getOffenseByOffenseId(Integer offenseId) {
        if (offenseId == null || offenseId <= 0 || offenseId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid offense ID: " + offenseId);
        }
        return offenseInformationMapper.selectById(offenseId);
    }

    @Cacheable(cacheNames = "offenseCache")
    @WsAction(service = "OffenseInformationService", action = "getOffensesInformation")
    public List<OffenseInformation> getOffensesInformation() {
        return offenseInformationMapper.selectList(null);
    }

    @Cacheable(cacheNames = "offenseCache")
    @WsAction(service = "OffenseInformationService", action = "getOffensesByTimeRange")
    public List<OffenseInformation> getOffensesByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("offense_time", startTime, endTime);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    @Cacheable(cacheNames = "offenseCache")
    @WsAction(service = "OffenseInformationService", action = "searchByDriverName")
    public List<OffenseInformation> searchByDriverName(String query, int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }

        Set<OffenseInformation> suggestions = new HashSet<>();
        int maxSuggestions = page * size; // Total results to fetch for pagination
        int offset = (page - 1) * size; // Starting point for pagination

        log.log(Level.INFO, "Executing match query for driverName: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});

        SearchHits<OffenseInformationDocument> matchHits = null;
        try {
            matchHits = offenseSearchRepository.searchByDriverNamePrefix(query);
        } catch (Exception e) {
            log.log(Level.WARNING, "Error executing match query for driverName: {0}", new Object[]{e.getMessage()});
        }

        if (matchHits != null && matchHits.hasSearchHits()) {
            for (SearchHit<OffenseInformationDocument> hit : matchHits) {
                OffenseInformationDocument doc = hit.getContent();
                if (doc.getDriverName() != null) { // Check for non-null driverName
                    suggestions.add(doc.toEntity());
                    log.log(Level.INFO, "Found offense with ID: {0}", new Object[]{doc.getOffenseId()});
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
            log.log(Level.INFO, "Found {0} match suggestions: {1}", new Object[]{suggestions.size(), suggestions});
        } else {
            log.log(Level.INFO, "No match suggestions found for driverName: {0}", new Object[]{query});
        }

        // If results are insufficient, execute fuzzy query
        if (suggestions.size() < maxSuggestions) {
            log.log(Level.INFO, "Executing fuzzy query for driverName: {0}", new Object[]{query});
            SearchHits<OffenseInformationDocument> fuzzyHits = null;
            try {
                fuzzyHits = offenseSearchRepository.searchByDriverNameFuzzy(query);
                log.log(Level.INFO, "Fuzzy query returned {0} hits",
                        new Object[]{fuzzyHits != null ? fuzzyHits.getTotalHits() : 0});
            } catch (Exception e) {
                log.log(Level.WARNING, "Error executing fuzzy query for driverName: {0}", new Object[]{e.getMessage()});
            }

            if (fuzzyHits != null && fuzzyHits.hasSearchHits()) {
                for (SearchHit<OffenseInformationDocument> hit : fuzzyHits) {
                    OffenseInformationDocument doc = hit.getContent();
                    if (doc.getDriverName() != null) {
                        suggestions.add(doc.toEntity());
                        log.log(Level.INFO, "Found offense with ID: {0}", new Object[]{doc.getOffenseId()});
                    }
                    if (suggestions.size() >= maxSuggestions) {
                        break;
                    }
                }
                log.log(Level.INFO, "After fuzzy search, total suggestions: {0}", new Object[]{suggestions.size()});
            } else {
                log.log(Level.INFO, "Fuzzy search returned no results for driverName: {0}", new Object[]{query});
            }
        }

        List<OffenseInformation> resultList = new ArrayList<>(suggestions);
        // Apply pagination
        return resultList.stream()
                .skip(offset)
                .limit(size)
                .collect(Collectors.toList());
    }

    @Cacheable(cacheNames = "offenseCache")
    @WsAction(service = "OffenseInformationService", action = "searchByLicensePlate")
    public List<OffenseInformation> searchLicensePlate(String query, int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }

        Set<OffenseInformation> suggestions = new HashSet<>();
        int maxSuggestions = page * size; // Total results to fetch for pagination
        int offset = (page - 1) * size; // Starting point for pagination

        log.log(Level.INFO, "Executing match query for licensePlate: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});

        SearchHits<OffenseInformationDocument> matchHits = null;
        try {
            matchHits = offenseSearchRepository.searchByLicensePlate(query);
        } catch (Exception e) {
            log.log(Level.WARNING, "Error executing match query for licensePlate: {0}", new Object[]{e.getMessage()});
        }

        if (matchHits != null && matchHits.hasSearchHits()) {
            for (SearchHit<OffenseInformationDocument> hit : matchHits) {
                OffenseInformationDocument doc = hit.getContent();
                if (doc.getLicensePlate() != null) { // Check for non-null licensePlate
                    suggestions.add(doc.toEntity());
                    log.log(Level.INFO, "Found offense with ID: {0}", new Object[]{doc.getOffenseId()});
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
            log.log(Level.INFO, "Found {0} match suggestions: {1}", new Object[]{suggestions.size(), suggestions});
        } else {
            log.log(Level.INFO, "No match suggestions found for licensePlate: {0}", new Object[]{query});
        }

        // If results are insufficient, execute fuzzy query
        if (suggestions.size() < maxSuggestions) {
            log.log(Level.INFO, "Executing fuzzy query for licensePlate: {0}", new Object[]{query});
            SearchHits<OffenseInformationDocument> fuzzyHits = null;
            try {
                // Note: The repository doesn't have a fuzzy method for licensePlate, reusing prefix search as fallback
                fuzzyHits = offenseSearchRepository.searchByLicensePlateFuzzy(query);
                log.log(Level.INFO, "Fuzzy query returned {0} hits",
                        new Object[]{fuzzyHits != null ? fuzzyHits.getTotalHits() : 0});
            } catch (Exception e) {
                log.log(Level.WARNING, "Error executing fuzzy query for licensePlate: {0}", new Object[]{e.getMessage()});
            }

            if (fuzzyHits != null && fuzzyHits.hasSearchHits()) {
                for (SearchHit<OffenseInformationDocument> hit : fuzzyHits) {
                    OffenseInformationDocument doc = hit.getContent();
                    if (doc.getLicensePlate() != null) {
                        suggestions.add(doc.toEntity());
                        log.log(Level.INFO, "Found offense with ID: {0}", new Object[]{doc.getOffenseId()});
                    }
                    if (suggestions.size() >= maxSuggestions) {
                        break;
                    }
                }
                log.log(Level.INFO, "After fuzzy search, total suggestions: {0}", new Object[]{suggestions.size()});
            } else {
                log.log(Level.INFO, "Fuzzy search returned no results for licensePlate: {0}", new Object[]{query});
            }
        }

        List<OffenseInformation> resultList = new ArrayList<>(suggestions);
        // Apply pagination
        return resultList.stream()
                .skip(offset)
                .limit(size)
                .collect(Collectors.toList());
    }

    @Cacheable(cacheNames = "offenseCache")
    @WsAction(service = "OffenseInformationService", action = "searchByOffenseType")
    public List<OffenseInformation> searchOffenseType(String query, int page, int size) {
        if (page < 1 || size < 1) {
            throw new IllegalArgumentException("Page must be >= 1 and size must be >= 1");
        }

        Set<OffenseInformation> suggestions = new HashSet<>();
        int maxSuggestions = page * size; // Total results to fetch for pagination
        int offset = (page - 1) * size; // Starting point for pagination

        log.log(Level.INFO, "Executing match query for offenseType: {0}, page: {1}, size: {2}",
                new Object[]{query, page, size});

        SearchHits<OffenseInformationDocument> matchHits = null;
        try {
            matchHits = offenseSearchRepository.searchByOffenseTypePrefix(query);
        } catch (Exception e) {
            log.log(Level.WARNING, "Error executing match query for offenseType: {0}", new Object[]{e.getMessage()});
        }

        if (matchHits != null && matchHits.hasSearchHits()) {
            for (SearchHit<OffenseInformationDocument> hit : matchHits) {
                OffenseInformationDocument doc = hit.getContent();
                if (doc.getOffenseType() != null) { // Check for non-null offenseType
                    suggestions.add(doc.toEntity());
                    log.log(Level.INFO, "Found offense with ID: {0}", new Object[]{doc.getOffenseId()});
                }
                if (suggestions.size() >= maxSuggestions) {
                    break;
                }
            }
            log.log(Level.INFO, "Found {0} match suggestions: {1}", new Object[]{suggestions.size(), suggestions});
        } else {
            log.log(Level.INFO, "No match suggestions found for offenseType: {0}", new Object[]{query});
        }

        // If results are insufficient, execute fuzzy query
        if (suggestions.size() < maxSuggestions) {
            log.log(Level.INFO, "Executing fuzzy query for offenseType: {0}", new Object[]{query});
            SearchHits<OffenseInformationDocument> fuzzyHits = null;
            try {
                fuzzyHits = offenseSearchRepository.searchByOffenseTypeFuzzy(query);
                log.log(Level.INFO, "Fuzzy query returned {0} hits",
                        new Object[]{fuzzyHits != null ? fuzzyHits.getTotalHits() : 0});
            } catch (Exception e) {
                log.log(Level.WARNING, "Error executing fuzzy query for offenseType: {0}", new Object[]{e.getMessage()});
            }

            if (fuzzyHits != null && fuzzyHits.hasSearchHits()) {
                for (SearchHit<OffenseInformationDocument> hit : fuzzyHits) {
                    OffenseInformationDocument doc = hit.getContent();
                    if (doc.getOffenseType() != null) {
                        suggestions.add(doc.toEntity());
                        log.log(Level.INFO, "Found offense with ID: {0}", new Object[]{doc.getOffenseId()});
                    }
                    if (suggestions.size() >= maxSuggestions) {
                        break;
                    }
                }
                log.log(Level.INFO, "After fuzzy search, total suggestions: {0}", new Object[]{suggestions.size()});
            } else {
                log.log(Level.INFO, "Fuzzy search returned no results for offenseType: {0}", new Object[]{query});
            }
        }

        List<OffenseInformation> resultList = new ArrayList<>(suggestions);
        // Apply pagination
        return resultList.stream()
                .skip(offset)
                .limit(size)
                .collect(Collectors.toList());
    }

    private void sendKafkaMessage(String topic, OffenseInformation offenseInformation) {
        kafkaTemplate.send(topic, offenseInformation);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}