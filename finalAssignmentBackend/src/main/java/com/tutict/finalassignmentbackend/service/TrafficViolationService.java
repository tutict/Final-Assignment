package com.tutict.finalassignmentbackend.service;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch._types.aggregations.Aggregate;
import co.elastic.clients.elasticsearch._types.aggregations.Aggregation;
import co.elastic.clients.elasticsearch._types.aggregations.StringTermsAggregate;
import co.elastic.clients.elasticsearch._types.query_dsl.Query;
import co.elastic.clients.elasticsearch._types.query_dsl.RangeQuery;
import co.elastic.clients.elasticsearch.core.SearchRequest;
import co.elastic.clients.elasticsearch.core.SearchResponse;
import co.elastic.clients.json.JsonData;
import com.tutict.finalassignmentbackend.entity.VehicleInformation;
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
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
public class TrafficViolationService {

    private static final Logger logger = LoggerFactory.getLogger(TrafficViolationService.class);

    private final OffenseInformationSearchRepository offenseRepository;
    private final AppealManagementSearchRepository appealRepository;
    private final FineInformationSearchRepository fineRepository;
    private final ElasticsearchClient elasticsearchClient;

    @Autowired
    public TrafficViolationService(
            OffenseInformationSearchRepository offenseRepository,
            AppealManagementSearchRepository appealRepository,
            FineInformationSearchRepository fineRepository, ElasticsearchClient elasticsearchClient) {
        this.offenseRepository = offenseRepository;
        this.appealRepository = appealRepository;
        this.fineRepository = fineRepository;
        this.elasticsearchClient = elasticsearchClient;
    }

    public Map<String, Long> getViolationTypeCounts(String startTime, String driverName, String licensePlate) {
        try {
            // 1. 构造 bool 查询的过滤条件列表
            List<Query> filters = new ArrayList<>();

            // 如果提供了 startTime，则构造日期范围查询
            if (startTime != null && !startTime.isEmpty()) {
                // 使用 untyped 变体构造范围查询，采用 JsonData.of(startTime) 来包装字符串
                RangeQuery rangeQuery = RangeQuery.of(r -> r.untyped(u ->
                        u.field("violationDate")
                                .gte(JsonData.of(startTime))
                                .format("yyyy-MM-dd'T'HH:mm:ss")
                ));
                filters.add(Query.of(q -> q.range(rangeQuery)));
            }

            // 如果提供了 driverName，则构造 match 查询
            if (driverName != null && !driverName.isEmpty()) {
                Query driverQuery = Query.of(q -> q.match(m -> m
                        .field("driverName")
                        .query(driverName)
                ));
                filters.add(driverQuery);
            }

            // 如果提供了 licensePlate，则构造 match 查询
            if (licensePlate != null && !licensePlate.isEmpty()) {
                Query licensePlateQuery = Query.of(q -> q.match(m -> m
                        .field("licensePlate")
                        .query(licensePlate)
                ));
                filters.add(licensePlateQuery);
            }

            // 构造 bool 查询，将所有过滤条件加入 filter 数组中
            Query boolQuery = Query.of(q -> q.bool(b -> b.filter(filters)));

            // 2. 构造基于 violationType 的 terms 聚合
            Aggregation aggregation = Aggregation.of(a -> a.terms(t -> t.field("violationType")));

            // 3. 构造 SearchRequest，指定查询和聚合（索引名称如有需要可在这里设置）
            SearchRequest searchRequest = SearchRequest.of(s -> s
                    .query(boolQuery)
                    .aggregations("by_violation_type", aggregation)
            );

            logger.info("Executing Elasticsearch query: {}", searchRequest.toString());

            // 4. 执行查询，VehicleInformation 为你的文档实体类
            SearchResponse<VehicleInformation> searchResponse = elasticsearchClient.search(
                    searchRequest, VehicleInformation.class);

            // 5. 从聚合结果中提取各 violationType 的文档数量
            Map<String, Long> result = new HashMap<>();
            Aggregate agg = searchResponse.aggregations().get("by_violation_type");

            if (agg != null && agg.isSterms()) {
                // 获取字符串类型的 terms 聚合结果
                StringTermsAggregate termsAgg = agg.sterms();
                termsAgg.buckets().array().forEach(bucket ->
                        result.put(String.valueOf(bucket.key()), bucket.docCount())
                );
            } else {
                logger.warn("没有获取到 'by_violation_type' 的 StringTerms 聚合结果。");
            }

            return result;
        } catch (Exception e) {
            logger.error("Failed to retrieve violation type counts: {}", e.getMessage(), e);
            throw new UncategorizedElasticsearchException("Failed to retrieve violation type counts", e);
        }
    }

    public List<Map<String, Object>> getTimeSeriesData(String startTime, String driverName) {
        // 如果 startTime 为 null，默认取最近 30 天的数据
        String fromTime = (startTime != null && !startTime.isEmpty())
                ? startTime
                : Instant.now().minus(30, ChronoUnit.DAYS).toString();

        logger.debug("Querying time series data with fromTime: {}, driverName: {}", fromTime, driverName);

        try {
            // 调用 repository 自定义方法获取查询结果
            SearchHits<OffenseInformationDocument> searchHits = offenseRepository.aggregateByDate(fromTime);
            List<Map<String, Object>> dataList = new ArrayList<>();

            if (searchHits.hasAggregations()) {
                // 这里将 SearchHits 中的 aggregations 转换为 ElasticsearchAggregations 类型
                ElasticsearchAggregations aggregations = (ElasticsearchAggregations)
                        Objects.requireNonNull(searchHits.getAggregations());
                // 获取名为 "by_day" 的聚合
                ElasticsearchAggregation byDayAgg = aggregations.get("by_day");

                if (byDayAgg == null) {
                    throw new IllegalStateException("Aggregation 'by_day' not found in response");
                }

                // 解析日期直方图聚合
                var dateHistogram = byDayAgg.aggregation().getAggregate().dateHistogram();
                dateHistogram.buckets().array().forEach(bucket -> {
                    Map<String, Object> dataPoint = new HashMap<>();
                    // 将 bucket 的 keyAsString（即日期字符串）设置到 time 字段
                    dataPoint.put("time", bucket.keyAsString());

                    // 从该 bucket 中获取内部聚合：total_fine 和 total_points
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