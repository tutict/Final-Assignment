package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.elastic.AppealManagementDocument;
import com.tutict.finalassignmentbackend.entity.elastic.FineInformationDocument;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseInformationDocument;
import com.tutict.finalassignmentbackend.repository.AppealManagementSearchRepository;
import com.tutict.finalassignmentbackend.repository.FineInformationSearchRepository;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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

    private static final Logger logger = LoggerFactory.getLogger(TrafficViolationService.class);

    private final OffenseInformationSearchRepository offenseRepository;
    private final AppealManagementSearchRepository appealRepository;
    private final FineInformationSearchRepository fineRepository;

    @Autowired
    public TrafficViolationService(
            OffenseInformationSearchRepository offenseRepository,
            AppealManagementSearchRepository appealRepository,
            FineInformationSearchRepository fineRepository) {
        this.offenseRepository = offenseRepository;
        this.appealRepository = appealRepository;
        this.fineRepository = fineRepository;
    }

    public Map<String, Integer> getViolationTypeCounts(String startTime, String driverName, String licensePlate) {
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();
        logger.debug("Querying offense types with fromTime: {}, driverName: {}, licensePlate: {}",
                fromTime, driverName, licensePlate);

        try {
            SearchHits<OffenseInformationDocument> searchHits = offenseRepository.aggregateByOffenseType(fromTime);
            Map<String, Integer> typeCountMap = new HashMap<>();

            if (searchHits.hasAggregations()) {
                ElasticsearchAggregations aggregations = (ElasticsearchAggregations) Objects.requireNonNull(searchHits.getAggregations());
                ElasticsearchAggregation byTypeAgg = aggregations.get("by_type");

                if (byTypeAgg == null) {
                    throw new IllegalStateException("Aggregation 'by_type' not found in response");
                }

                var byType = byTypeAgg.aggregation().getAggregate().sterms();
                byType.buckets().array().forEach(bucket ->
                        typeCountMap.put(bucket.key().stringValue(), (int) bucket.docCount()));
            } else {
                logger.warn("No aggregations found for violation type counts with fromTime: {}", fromTime);
            }

            return typeCountMap;
        } catch (Exception e) {
            logger.error("Failed to retrieve violation type counts: {}", e.getMessage(), e);
            throw e; // Re-throw to be caught in controller
        }
    }

    public List<Map<String, Object>> getTimeSeriesData(String startTime, String driverName) {
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();
        logger.debug("Querying time series data with fromTime: {}, driverName: {}", fromTime, driverName);

        try {
            SearchHits<OffenseInformationDocument> searchHits = offenseRepository.aggregateByDate(fromTime);
            List<Map<String, Object>> dataList = new ArrayList<>();

            if (searchHits.hasAggregations()) {
                ElasticsearchAggregations aggregations = (ElasticsearchAggregations) Objects.requireNonNull(searchHits.getAggregations());
                ElasticsearchAggregation byDayAgg = aggregations.get("by_day");

                if (byDayAgg == null) {
                    throw new IllegalStateException("Aggregation 'by_day' not found in response");
                }

                var dateHistogram = byDayAgg.aggregation().getAggregate().dateHistogram();
                dateHistogram.buckets().array().forEach(bucket -> {
                    Map<String, Object> dataPoint = new HashMap<>();
                    dataPoint.put("time", bucket.keyAsString());

                    var totalFineAgg = bucket.aggregations().get("total_fine").sum();
                    var totalPointsAgg = bucket.aggregations().get("total_points").sum();

                    dataPoint.put("value1", totalFineAgg.value());
                    dataPoint.put("value2", totalPointsAgg.value());
                    dataList.add(dataPoint);
                });
            } else {
                logger.warn("No aggregations found for time series data with fromTime: {}", fromTime);
            }

            return dataList;
        } catch (Exception e) {
            logger.error("Failed to retrieve time series data: {}", e.getMessage(), e);
            throw e;
        }
    }

    public Map<String, Integer> getAppealReasonCounts(String startTime, String appealReason) {
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();
        String reasonFilter = appealReason != null ? appealReason : "";
        logger.debug("Querying appeal reasons with fromTime: {}, reasonFilter: {}", fromTime, reasonFilter);

        try {
            SearchHits<AppealManagementDocument> searchHits = appealRepository.aggregateByAppealReason(fromTime, reasonFilter);
            Map<String, Integer> reasonCountMap = new HashMap<>();

            if (searchHits.hasAggregations()) {
                ElasticsearchAggregations aggregations = (ElasticsearchAggregations) Objects.requireNonNull(searchHits.getAggregations());
                ElasticsearchAggregation byReasonAgg = aggregations.get("by_reason");

                if (byReasonAgg == null) {
                    throw new IllegalStateException("Aggregation 'by_reason' not found in response");
                }

                var byReason = byReasonAgg.aggregation().getAggregate().sterms();
                byReason.buckets().array().forEach(bucket ->
                        reasonCountMap.put(bucket.key().stringValue(), (int) bucket.docCount()));
            } else {
                logger.warn("No aggregations found for appeal reasons with fromTime: {}", fromTime);
            }

            return reasonCountMap;
        } catch (Exception e) {
            logger.error("Failed to retrieve appeal reason counts: {}", e.getMessage(), e);
            throw e;
        }
    }

    public Map<String, Integer> getFinePaymentStatus(String startTime) {
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();
        logger.debug("Querying fine payment status with fromTime: {}", fromTime);

        try {
            SearchHits<FineInformationDocument> searchHits = fineRepository.aggregateByPaymentStatus(fromTime);
            Map<String, Integer> paymentStatusMap = new HashMap<>();

            if (searchHits.hasAggregations()) {
                ElasticsearchAggregations aggregations = (ElasticsearchAggregations) Objects.requireNonNull(searchHits.getAggregations());
                ElasticsearchAggregation byPaidAgg = aggregations.get("by_paid");

                if (byPaidAgg == null) {
                    throw new IllegalStateException("Aggregation 'by_paid' not found in response");
                }

                var byPaid = byPaidAgg.aggregation().getAggregate().sterms();
                byPaid.buckets().array().forEach(bucket -> {
                    String key = bucket.key() == null || bucket.key().stringValue().isEmpty() ||
                            bucket.key().stringValue().equalsIgnoreCase("unpaid") ? "Unpaid" : "Paid";
                    paymentStatusMap.put(key, (int) bucket.docCount());
                });
            } else {
                logger.warn("No aggregations found for fine payment status with fromTime: {}", fromTime);
            }

            return paymentStatusMap;
        } catch (Exception e) {
            logger.error("Failed to retrieve fine payment status: {}", e.getMessage(), e);
            throw e;
        }
    }
}