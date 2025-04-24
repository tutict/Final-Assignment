package com.tutict.finalassignmentbackend.service;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch._types.aggregations.Aggregation;
import co.elastic.clients.elasticsearch._types.aggregations.CalendarInterval;
import co.elastic.clients.elasticsearch._types.aggregations.StringTermsAggregate;
import co.elastic.clients.elasticsearch._types.query_dsl.Query;
import co.elastic.clients.elasticsearch.core.SearchRequest;
import co.elastic.clients.elasticsearch.core.SearchResponse;
import co.elastic.clients.json.JsonData;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseInformationDocument;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.elasticsearch.UncategorizedElasticsearchException;
import org.springframework.stereotype.Service;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
public class TrafficViolationService {

    private static final Logger logger = LoggerFactory.getLogger(TrafficViolationService.class);
    private static final DateTimeFormatter ISO_LOCAL_DATE_TIME =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    private final ElasticsearchClient elasticsearchClient;

    public TrafficViolationService(ElasticsearchClient elasticsearchClient) {
        this.elasticsearchClient = elasticsearchClient;
    }

    /**
     * 按天聚合违法事件的罚款和扣分总计。
     *
     * @param startTime  可选 ISO-8601 字符串（带Z或不带都支持），为空则过去30天。
     * @param driverName 可选驾驶人姓名过滤，空则不过滤。
     * @return 每天一条：{ time: "yyyy-MM-dd", value1: 累计罚款, value2: 累计扣分 }
     */
    public List<Map<String, Object>> getTimeSeriesData(String startTime, String driverName) {
        // 1) 解析 startTime
        Instant fromInstant;
        try {
            if (startTime == null || startTime.isBlank()) {
                fromInstant = Instant.now().minus(30, ChronoUnit.DAYS);
            } else {
                try {
                    fromInstant = Instant.parse(startTime);
                } catch (DateTimeParseException ex) {
                    LocalDateTime ldt = LocalDateTime.parse(startTime, ISO_LOCAL_DATE_TIME);
                    fromInstant = ldt.toInstant(ZoneOffset.UTC);
                }
            }
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid startTime 格式，需 ISO-8601", ex);
        }
        String fromTimeIso = fromInstant.toString();

        try {
            // 2) 构造时间范围 filter（通过 untyped 接口）
            Query timeRangeQuery = Query.of(q -> q
                    .range(r -> r
                            .untyped(u -> u
                                    .field("offenseTime")
                                    .gte(JsonData.of(fromTimeIso))
                                    .format("strict_date_optional_time")
                            )
                    )
            );

            // 3) 如果提供了 driverName，就再加一个 match filter
            Query fullBool = Query.of(q -> q.bool(b -> {
                b.filter(timeRangeQuery);
                if (driverName != null && !driverName.isBlank()) {
                    b.filter(Query.of(m -> m
                            .match(mm -> mm
                                    .field("driverName.keyword")
                                    .query(driverName)
                            )
                    ));
                }
                return b;
            }));

            // 4) 顶层聚合：按天分桶 + 两个 sum
            Map<String, Aggregation> aggs = new LinkedHashMap<>();
            aggs.put("by_day", Aggregation.of(a -> a
                    .dateHistogram(dh -> dh
                            .field("offenseTime")
                            .calendarInterval(CalendarInterval.Day)
                            .format("yyyy-MM-dd")
                    )
            ));
            aggs.put("total_fine", Aggregation.of(a -> a.sum(s -> s.field("fineAmount"))));
            aggs.put("total_points", Aggregation.of(a -> a.sum(s -> s.field("deductedPoints"))));

            // 5) 构造并执行 SearchRequest
            SearchRequest req = SearchRequest.of(s -> s
                    .index("offense_information")
                    .query(fullBool)
                    .aggregations(aggs)
            );
            logger.info("Executing time-series DSL query: {}", req);

            SearchResponse<OffenseInformationDocument> resp =
                    elasticsearchClient.search(req, OffenseInformationDocument.class);

            // 6) 解析结果
            var buckets = resp.aggregations()
                    .get("by_day")
                    .dateHistogram()
                    .buckets()
                    .array();

            List<Map<String, Object>> out = new ArrayList<>();
            for (var b : buckets) {
                Map<String, Object> point = new HashMap<>();
                point.put("time", b.keyAsString());
                point.put("value1", b.aggregations().get("total_fine").sum().value());
                point.put("value2", b.aggregations().get("total_points").sum().value());
                out.add(point);
            }
            return out;

        } catch (Exception ex) {
            logger.error("Failed to retrieve time series data", ex);
            throw new UncategorizedElasticsearchException("Failed to retrieve time series data", ex);
        }
    }

    // ────────────────────────────────────────────────────────────────────────────
    // 新增 1. 按违法类型统计
    // ────────────────────────────────────────────────────────────────────────────
    public Map<String, Integer> getViolationTypeCounts(String startTime,
                                                       String driverName,
                                                       String licensePlate) {
        // 解析时间
        Instant fromInstant;
        try {
            if (startTime == null || startTime.isBlank()) {
                fromInstant = Instant.now().minus(30, ChronoUnit.DAYS);
            } else {
                try {
                    fromInstant = Instant.parse(startTime);
                } catch (DateTimeParseException ex) {
                    LocalDateTime ldt = LocalDateTime.parse(startTime, ISO_LOCAL_DATE_TIME);
                    fromInstant = ldt.toInstant(ZoneOffset.UTC);
                }
            }
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid startTime 格式，需 ISO-8601", ex);
        }
        String fromTimeIso = fromInstant.toString();

        try {
            // time range filter
            Query timeFilter = Query.of(q -> q
                    .range(r -> r
                            .untyped(u -> u
                                    .field("offenseTime")
                                    .gte(JsonData.of(fromTimeIso))
                                    .format("strict_date_optional_time")
                            )
                    )
            );

            // bool query 合并 driverName / licensePlate
            Query boolQ = Query.of(q -> q.bool(b -> {
                b.filter(timeFilter);
                if (driverName != null && !driverName.isBlank()) {
                    b.filter(Query.of(m -> m
                            .match(mm -> mm
                                    .field("driverName.keyword")
                                    .query(driverName)
                            )
                    ));
                }
                if (licensePlate != null && !licensePlate.isBlank()) {
                    b.filter(Query.of(m -> m
                            .match(mm -> mm
                                    .field("licensePlate.keyword")
                                    .query(licensePlate)
                            )
                    ));
                }
                return b;
            }));

            // terms 聚合：offenseType.keyword
            Map<String, Aggregation> aggs = Map.of(
                    "by_offense_type", Aggregation.of(a -> a
                            .terms(t -> t.field("offenseType.keyword"))
                    )
            );

            SearchRequest req = SearchRequest.of(s -> s
                    .index("offense_information")
                    .query(boolQ)
                    .aggregations(aggs)
            );
            logger.info("Executing violation-type DSL query: {}", req);

            SearchResponse<OffenseInformationDocument> resp =
                    elasticsearchClient.search(req, OffenseInformationDocument.class);

            // 解析结果
            StringTermsAggregate terms = resp.aggregations()
                    .get("by_offense_type").sterms();

            Map<String, Integer> result = new LinkedHashMap<>();
            terms.buckets().array().forEach(bucket ->
                    result.put(bucket.key().toString(), (int) bucket.docCount())
            );
            return result;

        } catch (Exception ex) {
            logger.error("Failed to retrieve violation type counts", ex);
            throw new UncategorizedElasticsearchException("Failed to retrieve violation type counts", ex);
        }
    }

    // 按申诉原因统计
    public Map<String, Integer> getAppealReasonCounts(String startTime,
                                                      String appealReason) {
        // 时间范围同上，假设文档索引为 "appeal_management" 并字段名为 appealTime / appealReason.keyword
        Instant fromInstant;
        try {
            if (startTime == null || startTime.isBlank()) {
                fromInstant = Instant.now().minus(30, ChronoUnit.DAYS);
            } else {
                try {
                    fromInstant = Instant.parse(startTime);
                } catch (DateTimeParseException ex) {
                    LocalDateTime ldt = LocalDateTime.parse(startTime, ISO_LOCAL_DATE_TIME);
                    fromInstant = ldt.toInstant(ZoneOffset.UTC);
                }
            }
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid startTime 格式，需 ISO-8601", ex);
        }
        String fromTimeIso = fromInstant.toString();

        try {
            Query timeFilter = Query.of(q -> q
                    .range(r -> r
                            .untyped(u -> u
                                    .field("appealTime")
                                    .gte(JsonData.of(fromTimeIso))
                                    .format("strict_date_optional_time")
                            )
                    )
            );

            Query boolQ = Query.of(q -> q.bool(b -> {
                b.filter(timeFilter);
                if (appealReason != null && !appealReason.isBlank()) {
                    b.filter(Query.of(m -> m
                            .match(mm -> mm
                                    .field("appealReason.keyword")
                                    .query(appealReason)
                            )
                    ));
                }
                return b;
            }));

            Map<String, Aggregation> aggs = Map.of(
                    "by_reason", Aggregation.of(a -> a
                            .terms(t -> t.field("appealReason.keyword"))
                    )
            );

            SearchRequest req = SearchRequest.of(s -> s
                    .index("appeal_management")
                    .query(boolQ)
                    .aggregations(aggs)
            );
            logger.info("Executing appeal-reason DSL query: {}", req);

            SearchResponse<Void> resp = elasticsearchClient.search(req, Void.class);

            StringTermsAggregate terms = resp.aggregations()
                    .get("by_reason").sterms();

            Map<String, Integer> result = new LinkedHashMap<>();
            terms.buckets().array().forEach(bucket ->
                    result.put(bucket.key().toString(), (int) bucket.docCount())
            );
            return result;

        } catch (Exception ex) {
            logger.error("Failed to retrieve appeal reason counts", ex);
            throw new UncategorizedElasticsearchException("Failed to retrieve appeal reason counts", ex);
        }
    }

    // 按罚款支付状态统计
    public Map<String, Integer> getFinePaymentStatus(String startTime) {
        // 时间范围，同 getTimeSeriesData
        Instant fromInstant;
        try {
            if (startTime == null || startTime.isBlank()) {
                fromInstant = Instant.now().minus(30, ChronoUnit.DAYS);
            } else {
                try {
                    fromInstant = Instant.parse(startTime);
                } catch (DateTimeParseException ex) {
                    LocalDateTime ldt = LocalDateTime.parse(startTime, ISO_LOCAL_DATE_TIME);
                    fromInstant = ldt.toInstant(ZoneOffset.UTC);
                }
            }
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid startTime 格式，需 ISO-8601", ex);
        }
        String fromTimeIso = fromInstant.toString();

        try {
            Query timeFilter = Query.of(q -> q
                    .range(r -> r
                            .untyped(u -> u
                                    .field("fineTime")
                                    .gte(JsonData.of(fromTimeIso))
                                    .format("strict_date_optional_time")
                            )
                    )
            );

            Query boolQ = Query.of(q -> q.bool(b -> {
                b.filter(timeFilter);
                return b;
            }));

            Map<String, Aggregation> aggs = Map.of(
                    "by_paid", Aggregation.of(a -> a
                            .terms(t -> t
                                    .field("receiptNumber.keyword")
                                    .missing("unpaid")
                                    .size(2)
                            )
                    )
            );

            SearchRequest req = SearchRequest.of(s -> s
                    .index("fine_information")
                    .query(boolQ)
                    .aggregations(aggs)
            );
            logger.info("Executing fine-payment-status DSL query: {}", req);

            SearchResponse<Void> resp = elasticsearchClient.search(req, Void.class);

            StringTermsAggregate terms = resp.aggregations()
                    .get("by_paid").sterms();

            Map<String, Integer> result = new LinkedHashMap<>();
            terms.buckets().array().forEach(bucket -> {
                String key = bucket.key().toString();
                if ("unpaid".equals(key)) {
                    result.put("Unpaid", (int) bucket.docCount());
                } else {
                    result.put("Paid", (int) bucket.docCount());
                }
            });
            return result;

        } catch (Exception ex) {
            logger.error("Failed to retrieve fine payment status", ex);
            throw new UncategorizedElasticsearchException("Failed to retrieve fine payment status", ex);
        }
    }
}
