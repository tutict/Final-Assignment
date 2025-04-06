package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.elastic.AppealManagementDocument;
import com.tutict.finalassignmentbackend.entity.elastic.FineInformationDocument;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseInformationDocument;
import com.tutict.finalassignmentbackend.repository.AppealManagementSearchRepository;
import com.tutict.finalassignmentbackend.repository.FineInformationSearchRepository;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.elasticsearch.client.elc.ElasticsearchAggregation;
import org.springframework.data.elasticsearch.client.elc.ElasticsearchAggregations;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
public class TrafficViolationService {

    private final OffenseInformationSearchRepository offenseRepository;
    private final AppealManagementSearchRepository appealRepository;
    private final FineInformationSearchRepository fineRepository;

    @Autowired
    public TrafficViolationService(
            OffenseInformationSearchRepository offenseRepository,
            AppealManagementSearchRepository appealRepository,
            FineInformationSearchRepository fineRepository
    ) {
        this.offenseRepository = offenseRepository;
        this.appealRepository = appealRepository;
        this.fineRepository = fineRepository;
    }

    public Map<String, Integer> getViolationTypeCounts(String startTime, String driverName, String licensePlate) {
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();
        SearchHits<OffenseInformationDocument> searchHits = offenseRepository.aggregateByOffenseType(fromTime);

        Map<String, Integer> typeCountMap = new HashMap<>();
        if (searchHits.hasAggregations()) {
            ElasticsearchAggregations aggregations =
                    (ElasticsearchAggregations) Objects.requireNonNull(searchHits.getAggregations());

            ElasticsearchAggregation byTypeAgg = aggregations.get("by_type");
            if (byTypeAgg == null) {
                throw new IllegalStateException("Aggregation 'by_type' not found");
            }

            var byType = byTypeAgg.aggregation().getAggregate().sterms();
            byType.buckets().array().forEach(bucket -> typeCountMap.put(bucket.key().stringValue(), (int) bucket.docCount()));
        }
        return typeCountMap;
    }

    public List<Map<String, Object>> getTimeSeriesData(String startTime, String driverName) {
        // Default to 30 days ago if no startTime is provided
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();

        // Assuming aggregateByDate returns SearchHits with a date histogram aggregation
        SearchHits<OffenseInformationDocument> searchHits = offenseRepository.aggregateByDate(fromTime);

        List<Map<String, Object>> dataList = new ArrayList<>();
        if (searchHits.hasAggregations()) {
            // Cast to ElasticsearchAggregations
            ElasticsearchAggregations aggregations =
                    (ElasticsearchAggregations) Objects.requireNonNull(searchHits.getAggregations());

            // Get the "by_day" aggregation by name
            ElasticsearchAggregation byDayAgg = aggregations.get("by_day");
            if (byDayAgg == null) {
                throw new IllegalStateException("Aggregation 'by_day' not found");
            }

            // Get the DateHistogramAggregation
            var dateHistogram = byDayAgg.aggregation().getAggregate().dateHistogram();

            // Iterate over the date histogram buckets
            dateHistogram.buckets().array().forEach(bucket -> {
                Map<String, Object> dataPoint = new HashMap<>();
                dataPoint.put("time", bucket.keyAsString()); // Date key as string

                // Get sub-aggregations for total_fine and total_points
                var totalFineAgg = bucket.aggregations().get("total_fine").sum();
                var totalPointsAgg = bucket.aggregations().get("total_points").sum();

                dataPoint.put("value1", totalFineAgg.value()); // Sum of fines
                dataPoint.put("value2", totalPointsAgg.value()); // Sum of points
                dataList.add(dataPoint);
            });
        }
        return dataList;
    }

    public Map<String, Integer> getAppealReasonCounts(String startTime, String appealReason) {
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();
        String reasonFilter = appealReason != null ? appealReason : "";

        SearchHits<AppealManagementDocument> searchHits = appealRepository.aggregateByAppealReason(fromTime, reasonFilter);

        Map<String, Integer> reasonCountMap = new HashMap<>();
        if (searchHits.hasAggregations()) {
            ElasticsearchAggregations aggregations =
                    (ElasticsearchAggregations) Objects.requireNonNull(searchHits.getAggregations());

            ElasticsearchAggregation byReasonAgg = aggregations.get("by_reason");
            if (byReasonAgg == null) {
                throw new IllegalStateException("Aggregation 'by_reason' not found");
            }

            var byReason = byReasonAgg.aggregation().getAggregate().sterms();
            byReason.buckets().array().forEach(bucket -> reasonCountMap.put(bucket.key().stringValue(), (int) bucket.docCount()));
        }
        return reasonCountMap;
    }

    // Updated getFinePaymentStatus
    public Map<String, Integer> getFinePaymentStatus(String startTime) {
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();

        SearchHits<FineInformationDocument> searchHits = fineRepository.aggregateByPaymentStatus(fromTime);

        Map<String, Integer> paymentStatusMap = new HashMap<>();
        if (searchHits.hasAggregations()) {
            ElasticsearchAggregations aggregations =
                    (ElasticsearchAggregations) Objects.requireNonNull(searchHits.getAggregations());

            ElasticsearchAggregation byPaidAgg = aggregations.get("by_paid");
            if (byPaidAgg == null) {
                throw new IllegalStateException("Aggregation 'by_paid' not found");
            }

            var byPaid = byPaidAgg.aggregation().getAggregate().sterms();
            byPaid.buckets().array().forEach(bucket -> {
                String key = bucket.key() == null || bucket.key().stringValue().isEmpty() ||
                        bucket.key().stringValue().equalsIgnoreCase("unpaid") ? "Unpaid" : "Paid";
                paymentStatusMap.put(key, (int) bucket.docCount());
            });
        }
        return paymentStatusMap;
    }
}