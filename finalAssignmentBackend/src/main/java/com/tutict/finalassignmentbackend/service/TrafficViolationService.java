package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.elastic.AppealManagementDocument;
import com.tutict.finalassignmentbackend.entity.elastic.FineInformationDocument;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseInformationDocument;
import com.tutict.finalassignmentbackend.repository.AppealManagementSearchRepository;
import com.tutict.finalassignmentbackend.repository.DeductionInformationSearchRepository;
import com.tutict.finalassignmentbackend.repository.FineInformationSearchRepository;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class TrafficViolationService {

    private final OffenseInformationSearchRepository offenseRepository;

    private final AppealManagementSearchRepository appealRepository;

    private final DeductionInformationSearchRepository deductionRepository;

    private final FineInformationSearchRepository fineRepository;

    private final ElasticsearchOperations elasticsearchOperations;

    @Autowired
    public TrafficViolationService(OffenseInformationSearchRepository offenseRepository, AppealManagementSearchRepository appealRepository, DeductionInformationSearchRepository deductionRepository, FineInformationSearchRepository fineRepository, ElasticsearchOperations elasticsearchOperations) {
        this.offenseRepository = offenseRepository;
        this.appealRepository = appealRepository;
        this.deductionRepository = deductionRepository;
        this.fineRepository = fineRepository;
        this.elasticsearchOperations = elasticsearchOperations;
    }

    // Violation type counts (Bar/Pie Chart)
    public Map<String, Integer> getViolationTypeCounts(String startTime, String driverName, String licensePlate) {
        // Assuming a similar aggregation method exists in OffenseInformationSearchRepository
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();
        SearchHits<OffenseInformationDocument> searchHits = offenseRepository.aggregateByOffenseType(fromTime);

        Map<String, Integer> typeCountMap = new HashMap<>();
        if (searchHits.hasAggregations()) {
            var aggregations = searchHits.getAggregations();
            var byType = aggregations.get("by_type").sterms();
            byType.buckets().array().forEach(bucket -> {
                typeCountMap.put(bucket.key(), (int) bucket.docCount());
            });
        }
        return typeCountMap;
    }

    // Time-series data (Line Chart)
    public List<Map<String, Object>> getTimeSeriesData(String startTime, String driverName) {
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();
        SearchHits<OffenseInformationDocument> searchHits = offenseRepository.aggregateByDate(fromTime);

        List<Map<String, Object>> dataList = new ArrayList<>();
        if (searchHits.hasAggregations()) {
            var aggregations = searchHits.getAggregations();
            var byDay = aggregations.get("by_day").dateHistogram();
            byDay.buckets().array().forEach(bucket -> {
                Map<String, Object> dataPoint = new HashMap<>();
                dataPoint.put("time", bucket.keyAsString());
                dataPoint.put("value1", bucket.aggregations().get("total_fine").sum().value());
                dataPoint.put("value2", bucket.aggregations().get("total_points").sum().value());
                dataList.add(dataPoint);
            });
        }
        return dataList;
    }

    // Appeal status counts (Pie Chart) - Modified to aggregate by appealReason
    public Map<String, Integer> getAppealReasonCounts(String startTime, String appealReason) {
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();
        String reasonFilter = appealReason != null && !appealReason.isEmpty() ? appealReason : "";

        SearchHits<AppealManagementDocument> searchHits = appealRepository.aggregateByAppealReason(fromTime, reasonFilter);

        Map<String, Integer> reasonCountMap = new HashMap<>();
        if (searchHits.hasAggregations()) {
            var aggregations = searchHits.getAggregations();
            var byReason = aggregations.get("by_reason").sterms();
            byReason.buckets().array().forEach(bucket -> {
                reasonCountMap.put(bucket.key(), (int) bucket.docCount());
            });
        }
        return reasonCountMap;
    }

    // Fine payment status (Bar Chart)
    public Map<String, Integer> getFinePaymentStatus(String startTime) {
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();
        SearchHits<FineInformationDocument> searchHits = fineRepository.aggregateByPaymentStatus(fromTime);

        Map<String, Integer> paymentStatusMap = new HashMap<>();
        if (searchHits.hasAggregations()) {
            var aggregations = searchHits.getAggregations();
            var byPaid = aggregations.get("by_paid").sterms();
            byPaid.buckets().array().forEach(bucket -> {
                String key = bucket.key() == null || bucket.key().isEmpty() || bucket.key().equals("unpaid") ? "Unpaid" : "Paid";
                paymentStatusMap.put(key, (int) bucket.docCount());
            });
        }
        return paymentStatusMap;
    }
}