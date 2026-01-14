package com.tutict.finalassignmentcloud.traffic.repository;

import com.tutict.finalassignmentcloud.entity.elastic.DriverVehicleDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverVehicleSearchRepository extends ElasticsearchRepository<DriverVehicleDocument, Long> {

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
    SearchHits<DriverVehicleDocument> findByDriverId(Long driverId, Pageable pageable);

    default SearchHits<DriverVehicleDocument> findByDriverId(Long driverId) {
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
    SearchHits<DriverVehicleDocument> findByVehicleId(Long vehicleId, Pageable pageable);

    default SearchHits<DriverVehicleDocument> findByVehicleId(Long vehicleId) {
        return findByVehicleId(vehicleId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "bool": {
                "must": [
                  {
                    "term": {
                      "driverId": {
                        "value": ?0
                      }
                    }
                  },
                  {
                    "term": {
                      "isPrimary": {
                        "value": true
                      }
                    }
                  }
                ]
              }
            }
            """)
    SearchHits<DriverVehicleDocument> findPrimaryBinding(Long driverId, Pageable pageable);

    default SearchHits<DriverVehicleDocument> findPrimaryBinding(Long driverId) {
        return findPrimaryBinding(driverId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "relationship": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<DriverVehicleDocument> searchByRelationship(String relationship, Pageable pageable);

    default SearchHits<DriverVehicleDocument> searchByRelationship(String relationship) {
        return searchByRelationship(relationship, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}

