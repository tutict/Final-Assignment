package com.tutict.finalassignmentbackend.service;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch._types.aggregations.Aggregate;
import co.elastic.clients.elasticsearch._types.aggregations.Aggregation;
import co.elastic.clients.elasticsearch._types.aggregations.CalendarInterval;
import co.elastic.clients.elasticsearch._types.aggregations.StringTermsAggregate;
import co.elastic.clients.elasticsearch._types.query_dsl.Query;
import co.elastic.clients.elasticsearch._types.query_dsl.RangeQuery;
import co.elastic.clients.elasticsearch.core.SearchRequest;
import co.elastic.clients.elasticsearch.core.SearchResponse;
import co.elastic.clients.json.JsonData;
import com.tutict.finalassignmentbackend.entity.elastic.AppealManagementDocument;
import com.tutict.finalassignmentbackend.entity.elastic.FineInformationDocument;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseInformationDocument;
import com.tutict.finalassignmentbackend.repository.AppealManagementSearchRepository;
import com.tutict.finalassignmentbackend.repository.FineInformationSearchRepository;
import com.tutict.finalassignmentbackend.repository.OffenseInformationSearchRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.elasticsearch.UncategorizedElasticsearchException;
import org.springframework.data.elasticsearch.client.elc.ElasticsearchAggregation;
import org.springframework.data.elasticsearch.client.elc.ElasticsearchAggregations;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
public class TrafficViolationService {

    private static final Logger logger = LoggerFactory.getLogger(TrafficViolationService.class);

    private final OffenseInformationSearchRepository offenseRepository;
    private final AppealManagementSearchRepository appealRepository;
    private final FineInformationSearchRepository fineRepository;
    private final ElasticsearchClient elasticsearchClient;

    // 定义时间格式化器，支持无时区的输入
    private static final DateTimeFormatter ISO_LOCAL_DATE_TIME = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    @Autowired
    public TrafficViolationService(
            OffenseInformationSearchRepository offenseRepository,
            AppealManagementSearchRepository appealRepository,
            FineInformationSearchRepository fineRepository,
            ElasticsearchClient elasticsearchClient) {
        this.offenseRepository = offenseRepository;
        this.appealRepository = appealRepository;
        this.fineRepository = fineRepository;
        this.elasticsearchClient = elasticsearchClient;
    }

    public Map<String, Long> getViolationTypeCounts(String startTime, String driverName, String licensePlate) {
        try {
            List<Query> filters = new ArrayList<>();

            if (startTime != null && !startTime.isEmpty()) {
                try {
                    Instant instant;
                    try {
                        instant = Instant.parse(startTime);
                    } catch (DateTimeParseException e) {
                        LocalDateTime localDateTime = LocalDateTime.parse(startTime, ISO_LOCAL_DATE_TIME);
                        instant = localDateTime.atZone(ZoneOffset.UTC).toInstant();
                    }
                    Instant finalInstant = instant;
                    RangeQuery rangeQuery = RangeQuery.of(r -> r.untyped(u ->
                            u.field("offenseTime")
                                    .gte(JsonData.of(finalInstant.toString()))
                                    .format("yyyy-MM-dd'T'HH:mm:ss")
                    ));
                    filters.add(Query.of(q -> q.range(rangeQuery)));
                } catch (DateTimeParseException e) {
                    logger.error("Invalid startTime format: {}", startTime, e);
                    throw new IllegalArgumentException("Invalid startTime format, expected ISO-8601 (e.g., 2025-03-13T20:37:49Z or 2025-03-13T20:37:49)");
                }
            }

            if (driverName != null && !driverName.isEmpty()) {
                Query driverQuery = Query.of(q -> q.match(m -> m
                        .field("driverName")
                        .query(driverName)
                ));
                filters.add(driverQuery);
            }

            if (licensePlate != null && !licensePlate.isEmpty()) {
                Query licensePlateQuery = Query.of(q -> q.match(m -> m
                        .field("licensePlate")
                        .query(licensePlate)
                ));
                filters.add(licensePlateQuery);
            }

            Query boolQuery = Query.of(q -> q.bool(b -> b.filter(filters)));

            Aggregation aggregation = Aggregation.of(a -> a.terms(t -> t.field("offenseType.keyword")));

            SearchRequest searchRequest = SearchRequest.of(s -> s
                    .index("offense_information")
                    .query(boolQuery)
                    .aggregations("by_offense_type", aggregation)
            );

            logger.info("Executing Elasticsearch query for offense types: {}", searchRequest);

            SearchResponse<OffenseInformationDocument> searchResponse = elasticsearchClient.search(
                    searchRequest, OffenseInformationDocument.class);

            Map<String, Long> result = new HashMap<>();
            Aggregate agg = searchResponse.aggregations().get("by_offense_type");

            if (agg != null && agg.isSterms()) {
                StringTermsAggregate termsAgg = agg.sterms();
                termsAgg.buckets().array().forEach(bucket ->
                        result.put(String.valueOf(bucket.key()), bucket.docCount())
                );
            } else {
                logger.warn("No 'by_offense_type' aggregation found");
            }

            return result;
        } catch (Exception e) {
            String errorMsg = "Failed to retrieve offense type counts: " + e.getMessage();
            if (e.getMessage().contains("all shards failed")) {
                errorMsg += ". Possible causes: incorrect field mappings (e.g., 'offenseType' must be 'keyword', 'offenseTime' must be 'date'), index missing, or unhealthy cluster.";
            }
            logger.error(errorMsg, e);
            throw new UncategorizedElasticsearchException(errorMsg, e);
        }
    }

    public List<Map<String, Object>> getTimeSeriesData(String startTime, String driverName) {
        String fromTime = (startTime != null && !startTime.isEmpty())
                ? startTime
                : Instant.now().minus(30, ChronoUnit.DAYS).toString();

        logger.info("Querying time series data with fromTime: {}, driverName: {}", fromTime, driverName);

        try {
            try {
                // 验证时间格式
                Instant instant;
                try {
                    instant = Instant.parse(fromTime);
                } catch (DateTimeParseException e) {
                    LocalDateTime localDateTime = LocalDateTime.parse(fromTime, ISO_LOCAL_DATE_TIME);
                    instant = localDateTime.atZone(ZoneOffset.UTC).toInstant();
                }
                fromTime = instant.toString();
            } catch (DateTimeParseException e) {
                logger.error("Invalid fromTime format: {}", fromTime, e);
                throw new IllegalArgumentException("Invalid startTime format, expected ISO-8601 (e.g., 2025-03-13T20:37:49Z or 2025-03-13T20:37:49)");
            }

            SearchHits<OffenseInformationDocument> searchHits;
            if (driverName != null && !driverName.trim().isEmpty()) {
                logger.debug("Calling aggregateByDate with driverName: {}", driverName);
                searchHits = offenseRepository.aggregateByDate(fromTime, driverName);
            } else {
                logger.debug("Calling aggregateByDate without driverName");
                searchHits = offenseRepository.aggregateByDate(fromTime);
            }

            logger.debug("SearchHits retrieved: total hits = {}, aggregations present = {}",
                    searchHits.getTotalHits(), searchHits.hasAggregations());

            List<Map<String, Object>> dataList = new ArrayList<>();

            if (searchHits.hasAggregations()) {
                ElasticsearchAggregations aggregations = (ElasticsearchAggregations)
                        Objects.requireNonNull(searchHits.getAggregations(), "Aggregations are null");
                ElasticsearchAggregation byDayAgg = aggregations.get("by_day");

                if (byDayAgg == null) {
                    logger.warn("Aggregation 'by_day' not found in response");
                    return dataList;
                }

                var dateHistogram = byDayAgg.aggregation().getAggregate().dateHistogram();
                if (dateHistogram == null || dateHistogram.buckets().array().isEmpty()) {
                    logger.info("No buckets found in date_histogram for fromTime: {}, driverName: {}",
                            fromTime, driverName);
                    return dataList;
                }

                dateHistogram.buckets().array().forEach(bucket -> {
                    Map<String, Object> dataPoint = new HashMap<>();
                    dataPoint.put("time", bucket.keyAsString());
                    var totalFineAgg = bucket.aggregations().get("total_fine").sum();
                    var totalPointsAgg = bucket.aggregations().get("total_points").sum();
                    dataPoint.put("value1", totalFineAgg.value());
                    dataPoint.put("value2", totalPointsAgg.value());
                    dataList.add(dataPoint);
                });
                logger.debug("Parsed {} data points from aggregation", dataList.size());
            } else {
                logger.info("No aggregations found for fromTime: {}, driverName: {}", fromTime, driverName);
            }

            return dataList;
        } catch (Exception e) {
            logger.error("Failed to retrieve time series data for fromTime: {}, driverName: {}. Error: {}",
                    fromTime, driverName, e.getMessage(), e);
            throw new UncategorizedElasticsearchException("Failed to retrieve time series data", e);
        }
    }

    public List<Map<String, Object>> getTimeSeriesDataDirect(String startTime, String driverName) {
        try {
            String fromTime = (startTime != null && !startTime.isEmpty())
                    ? startTime
                    : Instant.now().minus(30, ChronoUnit.DAYS).toString();

            try {
                // 验证时间格式
                Instant instant;
                try {
                    instant = Instant.parse(fromTime);
                } catch (DateTimeParseException e) {
                    LocalDateTime localDateTime = LocalDateTime.parse(fromTime, ISO_LOCAL_DATE_TIME);
                    instant = localDateTime.atZone(ZoneOffset.UTC).toInstant();
                }
                fromTime = instant.toString();
            } catch (DateTimeParseException e) {
                logger.error("Invalid fromTime format: {}", fromTime, e);
                throw new IllegalArgumentException("Invalid startTime format, expected ISO-8601 (e.g., 2025-03-13T20:37:49Z or 2025-03-13T20:37:49)");
            }

            List<Query> filters = new ArrayList<>();
            String finalFromTime = fromTime;
            filters.add(Query.of(q -> q.range(r -> r.untyped(u ->
                    u.field("offenseTime")
                            .gte(JsonData.of(finalFromTime))
                            .format("yyyy-MM-dd'T'HH:mm:ss")
            ))));

            if (driverName != null && !driverName.isEmpty()) {
                filters.add(Query.of(q -> q.match(m -> m.field("driverName.keyword").query(driverName))));
            }

            Query boolQuery = Query.of(q -> q.bool(b -> b.filter(filters)));

            // 7.x 兼容方式：将聚合放在 SearchRequest 级别
            Map<String, Aggregation> aggregations = new HashMap<>();
            aggregations.put("by_day", Aggregation.of(a -> a
                    .dateHistogram(d -> d
                            .field("offenseTime")
                            .calendarInterval(CalendarInterval.Day)
                            .format("yyyy-MM-dd")
                    )
            ));
            aggregations.put("total_fine", Aggregation.of(a -> a.sum(s -> s.field("fineAmount"))));
            aggregations.put("total_points", Aggregation.of(a -> a.sum(s -> s.field("deductedPoints"))));

            SearchRequest request = SearchRequest.of(s -> s
                    .index("offense_information")
                    .query(boolQuery)
                    .aggregations(aggregations)
            );

            logger.info("Executing direct Elasticsearch query for time series: {}", request);

            SearchResponse<OffenseInformationDocument> response = elasticsearchClient.search(
                    request, OffenseInformationDocument.class);

            List<Map<String, Object>> dataList = new ArrayList<>();
            var buckets = response.aggregations().get("by_day").dateHistogram().buckets().array();
            for (var bucket : buckets) {
                Map<String, Object> dataPoint = new HashMap<>();
                dataPoint.put("time", bucket.keyAsString());
                // 注意：total_fine 和 total_points 是顶级聚合
                dataPoint.put("value1", response.aggregations().get("total_fine").sum().value());
                dataPoint.put("value2", response.aggregations().get("total_points").sum().value());
                dataList.add(dataPoint);
            }

            logger.debug("Parsed {} data points from direct query", dataList.size());
            return dataList;
        } catch (Exception e) {
            logger.error("Failed to retrieve time series data (direct): {}", e.getMessage(), e);
            throw new UncategorizedElasticsearchException("Failed to retrieve time series data (direct)", e);
        }
    }

    public Map<String, Integer> getAppealReasonCounts(String startTime, String appealReason) {
        String fromTime = startTime != null ? startTime : Instant.now().minus(30, ChronoUnit.DAYS).toString();
        String reasonFilter = appealReason != null ? appealReason : "";
        logger.debug("Querying appeal reasons with fromTime: {}, reasonFilter: {}", fromTime, reasonFilter);

        try {
            try {
                Instant instant;
                try {
                    instant = Instant.parse(fromTime);
                } catch (DateTimeParseException e) {
                    LocalDateTime localDateTime = LocalDateTime.parse(fromTime, ISO_LOCAL_DATE_TIME);
                    instant = localDateTime.atZone(ZoneOffset.UTC).toInstant();
                }
                fromTime = instant.toString();
            } catch (DateTimeParseException e) {
                logger.error("Invalid fromTime format: {}", fromTime, e);
                throw new IllegalArgumentException("Invalid startTime format, expected ISO-8601 (e.g., 2025-03-13T20:37:49Z or 2025-03-13T20:37:49)");
            }

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
            try {
                Instant instant;
                try {
                    instant = Instant.parse(fromTime);
                } catch (DateTimeParseException e) {
                    LocalDateTime localDateTime = LocalDateTime.parse(fromTime, ISO_LOCAL_DATE_TIME);
                    instant = localDateTime.atZone(ZoneOffset.UTC).toInstant();
                }
                fromTime = instant.toString();
            } catch (DateTimeParseException e) {
                logger.error("Invalid fromTime format: {}", fromTime, e);
                throw new IllegalArgumentException("Invalid startTime format, expected ISO-8601 (e.g., 2025-03-13T20:37:49Z or 2025-03-13T20:37:49)");
            }

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