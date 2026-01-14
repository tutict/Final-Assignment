package com.tutict.finalassignmentcloud.traffic.repository;

import com.tutict.finalassignmentcloud.entity.elastic.DriverInformationDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DriverInformationSearchRepository extends ElasticsearchRepository<DriverInformationDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "match_phrase_prefix": {
                "name": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<DriverInformationDocument> searchByNamePrefix(String name, Pageable pageable);

    default SearchHits<DriverInformationDocument> searchByNamePrefix(String name) {
        return searchByNamePrefix(name, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "name": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<DriverInformationDocument> searchByNameFuzzy(String name, Pageable pageable);

    default SearchHits<DriverInformationDocument> searchByNameFuzzy(String name) {
        return searchByNameFuzzy(name, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "idCardNumber": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<DriverInformationDocument> searchByIdCardNumber(String idCardNumber, Pageable pageable);

    default SearchHits<DriverInformationDocument> searchByIdCardNumber(String idCardNumber) {
        return searchByIdCardNumber(idCardNumber, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "idCardNumber": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<DriverInformationDocument> searchByIdCardNumberFuzzy(String idCardNumber, Pageable pageable);

    default SearchHits<DriverInformationDocument> searchByIdCardNumberFuzzy(String idCardNumber) {
        return searchByIdCardNumberFuzzy(idCardNumber, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "driverLicenseNumber": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<DriverInformationDocument> searchByDriverLicenseNumber(String driverLicenseNumber, Pageable pageable);

    default SearchHits<DriverInformationDocument> searchByDriverLicenseNumber(String driverLicenseNumber) {
        return searchByDriverLicenseNumber(driverLicenseNumber, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "driverLicenseNumber": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<DriverInformationDocument> searchByDriverLicenseNumberFuzzy(String driverLicenseNumber, Pageable pageable);

    default SearchHits<DriverInformationDocument> searchByDriverLicenseNumberFuzzy(String driverLicenseNumber) {
        return searchByDriverLicenseNumberFuzzy(driverLicenseNumber, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "driverId": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<DriverInformationDocument> findByDriverId(Long driverId, Pageable pageable);

    default SearchHits<DriverInformationDocument> findByDriverId(Long driverId) {
        return findByDriverId(driverId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "status.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<DriverInformationDocument> searchByStatus(String status, Pageable pageable);

    default SearchHits<DriverInformationDocument> searchByStatus(String status) {
        return searchByStatus(status, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "contactNumber": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<DriverInformationDocument> searchByContactNumber(String contactNumber, Pageable pageable);

    default SearchHits<DriverInformationDocument> searchByContactNumber(String contactNumber) {
        return searchByContactNumber(contactNumber, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}

