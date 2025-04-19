package com.tutict.finalassignmentbackend.service.view;

import com.tutict.finalassignmentbackend.entity.OffenseDetails;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseDetailsDocument;
import com.tutict.finalassignmentbackend.repository.OffenseDetailsSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

// 服务类，用于处理违规详情的Elasticsearch操作
@Service
public class OffenseDetailsService {

    private static final Logger log = Logger.getLogger(OffenseDetailsService.class.getName());

    private final OffenseDetailsSearchRepository offenseDetailsSearchRepository;

    @Autowired
    public OffenseDetailsService(OffenseDetailsSearchRepository offenseDetailsSearchRepository) {
        this.offenseDetailsSearchRepository = offenseDetailsSearchRepository;
    }

    @Cacheable(cacheNames = "offenseDetailsCache")
    public List<OffenseDetails> getAllOffenseDetails() {
        Iterable<OffenseDetailsDocument> documents = offenseDetailsSearchRepository.findAll();
        return StreamSupport.stream(documents.spliterator(), false)
                .map(OffenseDetailsDocument::toEntity)
                .collect(Collectors.toList());
    }

    @Cacheable(cacheNames = "offenseDetailsCache")
    public OffenseDetails getOffenseDetailsById(Integer id) {
        if (id == null || id <= 0 || id >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid offense ID: " + id);
        }
        return offenseDetailsSearchRepository.findById(id)
                .map(OffenseDetailsDocument::toEntity)
                .orElseThrow(() -> new RuntimeException("Offense details not found for ID: " + id));
    }

    @Cacheable(cacheNames = "offenseDetailsCache")
    public Map<String, Long> getOffenseTypeCounts(LocalDateTime startTime, LocalDateTime endTime, String driverName) {
        if (startTime == null || endTime == null) {
            throw new IllegalArgumentException("Start time and end time must not be null");
        }
        return offenseDetailsSearchRepository.aggregateOffenseTypeCounts(startTime, endTime, driverName);
    }

    @Cacheable(cacheNames = "offenseDetailsCache")
    public Map<String, Long> getVehicleTypeCounts(LocalDateTime startTime, LocalDateTime endTime, String licensePlate) {
        if (startTime == null || endTime == null) {
            throw new IllegalArgumentException("Start time and end time must not be null");
        }
        return offenseDetailsSearchRepository.aggregateVehicleTypeCounts(startTime, endTime, licensePlate);
    }

    @Cacheable(cacheNames = "offenseDetailsCache")
    public List<OffenseDetails> findByCriteria(String driverName, String licensePlate, String offenseType,
                                               LocalDateTime startTime, LocalDateTime endTime) {
        return offenseDetailsSearchRepository.findByCriteria(driverName, licensePlate, offenseType, startTime, endTime)
                .stream()
                .map(OffenseDetailsDocument::toEntity)
                .collect(Collectors.toList());
    }
}