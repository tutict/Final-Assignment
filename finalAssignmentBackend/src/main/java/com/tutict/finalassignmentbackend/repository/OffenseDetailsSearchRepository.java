package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.OffenseDetailsDocument;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public interface OffenseDetailsSearchRepository extends ElasticsearchRepository<OffenseDetailsDocument, Integer> {

    @Query("{\"bool\": {\"filter\": [{\"match\": {\"driverName.keyword\": \"?0\"}}]}}")
    List<OffenseDetailsDocument> findByDriverNameKeyword(String driverName);

    @Query("{\"bool\": {\"filter\": [{\"match\": {\"licensePlate.ngram\": \"?0\"}}]}}")
    List<OffenseDetailsDocument> findByLicensePlateNgram(String licensePlate);

    @Query("{\"bool\": {\"filter\": [{\"match\": {\"offenseType.keyword\": \"?0\"}}]}}")
    List<OffenseDetailsDocument> findByOffenseTypeKeyword(String offenseType);

    @Query("{\"bool\": {\"filter\": [{\"range\": {\"offenseTime\": {\"gte\": \"?0\", \"lte\": \"?1\"}}}}]}}")
    List<OffenseDetailsDocument> findByOffenseTimeBetween(LocalDateTime startTime, LocalDateTime endTime);

    @Query("{\"bool\": {\"filter\": [{\"match\": {\"driverIdCardNumber.ngram\": \"?0\"}}]}}")
    List<OffenseDetailsDocument> findByDriverIdCardNumberNgram(String idCardNumber);

    @Query("{\"bool\": {\"filter\": [{\"match\": {\"offenseLocation\": \"?0\"}}]}}")
    List<OffenseDetailsDocument> findByOffenseLocation(String location);

    @Query("{\"query\": {\"bool\": {\"filter\": [{\"range\": {\"offenseTime\": {\"gte\": \"?0\", \"lte\": \"?1\"}}}" +
            "{% if ?2 != null %},{\"match\": {\"driverName.keyword\": \"?2\"}}{% endif %}]}}, " +
            "\"aggs\": {\"by_type\": {\"terms\": {\"field\": \"offenseType.keyword\", \"size\": 100}}}}")
    Map<String, Long> aggregateOffenseTypeCounts(LocalDateTime startTime, LocalDateTime endTime, String driverName);

    @Query("{\"query\": {\"bool\": {\"filter\": [{\"range\": {\"offenseTime\": {\"gte\": \"?0\", \"lte\": \"?1\"}}}" +
            "{% if ?2 != null %},{\"match\": {\"licensePlate.keyword\": \"?2\"}}{% endif %}]}}, " +
            "\"aggs\": {\"by_vehicle\": {\"terms\": {\"field\": \"vehicleType.keyword\", \"size\": 100}}}}")
    Map<String, Long> aggregateVehicleTypeCounts(LocalDateTime startTime, LocalDateTime endTime, String licensePlate);

    @Query("{\"bool\": {\"filter\": [" +
            "{% if ?0 != null %}{\"match\": {\"driverName.keyword\": \"?0\"}},{% endif %}" +
            "{% if ?1 != null %}{\"match\": {\"licensePlate.ngram\": \"?1\"}},{% endif %}" +
            "{% if ?2 != null %}{\"match\": {\"offenseType.keyword\": \"?2\"}},{% endif %}" +
            "{% if ?3 != null && ?4 != null %}{\"range\": {\"offenseTime\": {\"gte\": \"?3\", \"lte\": \"?4\"}}},{% endif %}" +
            "]}}")
    List<OffenseDetailsDocument> findByCriteria(String driverName, String licensePlate, String offenseType,
                                                LocalDateTime startTime, LocalDateTime endTime);
}