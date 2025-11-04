package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.OffenseRecordDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OffenseInformationSearchRepository extends ElasticsearchRepository<OffenseRecordDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
    {
      "term": {
        "driverId": {
          "value": ?0
        }
      }
    }
    """)
    SearchHits<OffenseRecordDocument> findByDriverId(Long driverId, Pageable pageable);

    default SearchHits<OffenseRecordDocument> findByDriverId(Long driverId) {
        return findByDriverId(driverId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "term": {
        "vehicleId": {
          "value": ?0
        }
      }
    }
    """)
    SearchHits<OffenseRecordDocument> findByVehicleId(Long vehicleId, Pageable pageable);

    default SearchHits<OffenseRecordDocument> findByVehicleId(Long vehicleId) {
        return findByVehicleId(vehicleId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "match_phrase_prefix": {
        "offenseCode": {
          "query": "?0"
        }
      }
    }
    """)
    SearchHits<OffenseRecordDocument> searchByOffenseCode(String offenseCode, Pageable pageable);

    default SearchHits<OffenseRecordDocument> searchByOffenseCode(String offenseCode) {
        return searchByOffenseCode(offenseCode, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "term": {
        "processStatus.keyword": {
          "value": "?0"
        }
      }
    }
    """)
    SearchHits<OffenseRecordDocument> searchByProcessStatus(String processStatus, Pageable pageable);

    default SearchHits<OffenseRecordDocument> searchByProcessStatus(String processStatus) {
        return searchByProcessStatus(processStatus, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "range": {
        "offenseTime": {
          "gte": "?0",
          "lte": "?1"
        }
      }
    }
    """)
    SearchHits<OffenseRecordDocument> searchByOffenseTimeRange(String startTime, String endTime, Pageable pageable);

    default SearchHits<OffenseRecordDocument> searchByOffenseTimeRange(String startTime, String endTime) {
        return searchByOffenseTimeRange(startTime, endTime, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "match_phrase_prefix": {
        "offenseNumber": {
          "query": "?0"
        }
      }
    }
    """)
    SearchHits<OffenseRecordDocument> searchByOffenseNumber(String offenseNumber, Pageable pageable);

    default SearchHits<OffenseRecordDocument> searchByOffenseNumber(String offenseNumber) {
        return searchByOffenseNumber(offenseNumber, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
