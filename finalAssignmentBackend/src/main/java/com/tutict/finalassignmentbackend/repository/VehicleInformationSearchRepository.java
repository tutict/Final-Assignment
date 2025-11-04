package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.VehicleInformationDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VehicleInformationSearchRepository extends ElasticsearchRepository<VehicleInformationDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
    {
      "bool": {
        "must": [
          {
            "match_phrase_prefix": {
              "licensePlate": {
                "query": "?0"
              }
            }
          }
        ],
        "filter": [
          {
            "term": {
              "ownerIdCard.keyword": {
                "value": "?1"
              }
            }
          }
        ]
      }
    }
    """)
    SearchHits<VehicleInformationDocument> searchByLicensePlate(String prefix, String ownerIdCard, Pageable pageable);

    default SearchHits<VehicleInformationDocument> searchByLicensePlate(String prefix, String ownerIdCard) {
        return searchByLicensePlate(prefix, ownerIdCard, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "bool": {
        "must": [
          {
            "match": {
              "licensePlate": {
                "query": "?0",
                "fuzziness": "AUTO"
              }
            }
          }
        ],
        "filter": [
          {
            "term": {
              "ownerIdCard.keyword": {
                "value": "?1"
              }
            }
          }
        ]
      }
    }
    """)
    SearchHits<VehicleInformationDocument> searchByLicensePlateFuzzy(String plate, String ownerIdCard, Pageable pageable);

    default SearchHits<VehicleInformationDocument> searchByLicensePlateFuzzy(String plate, String ownerIdCard) {
        return searchByLicensePlateFuzzy(plate, ownerIdCard, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "bool": {
        "must": [
          {
            "match_phrase_prefix": {
              "vehicleType": {
                "query": "?0"
              }
            }
          }
        ],
        "filter": [
          {
            "term": {
              "ownerIdCard.keyword": {
                "value": "?1"
              }
            }
          }
        ]
      }
    }
    """)
    SearchHits<VehicleInformationDocument> searchByVehicleTypePrefix(String prefix, String ownerIdCard, Pageable pageable);

    default SearchHits<VehicleInformationDocument> searchByVehicleTypePrefix(String prefix, String ownerIdCard) {
        return searchByVehicleTypePrefix(prefix, ownerIdCard, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "bool": {
        "must": [
          {
            "match": {
              "vehicleType": {
                "query": "?0",
                "fuzziness": "AUTO"
              }
            }
          }
        ],
        "filter": [
          {
            "term": {
              "ownerIdCard.keyword": {
                "value": "?1"
              }
            }
          }
        ]
      }
    }
    """)
    SearchHits<VehicleInformationDocument> searchByVehicleTypeFuzzy(String vehicleType, String ownerIdCard, Pageable pageable);

    default SearchHits<VehicleInformationDocument> searchByVehicleTypeFuzzy(String vehicleType, String ownerIdCard) {
        return searchByVehicleTypeFuzzy(vehicleType, ownerIdCard, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "bool": {
        "must": [
          {
            "match_phrase_prefix": {
              "licensePlate": {
                "query": "?1"
              }
            }
          }
        ],
        "filter": [
          {
            "term": {
              "ownerIdCard.keyword": {
                "value": "?0"
              }
            }
          }
        ]
      }
    }
    """)
    SearchHits<VehicleInformationDocument> findCompletionSuggestions(String ownerIdCard, String prefix, Pageable pageable);

    default SearchHits<VehicleInformationDocument> findCompletionSuggestions(String ownerIdCard, String prefix, int maxSuggestions) {
        return findCompletionSuggestions(ownerIdCard, prefix, PageRequest.of(0, Math.max(1, maxSuggestions)));
    }

    @Query("""
    {
      "match_phrase_prefix": {
        "licensePlate": {
          "query": "?0"
        }
      }
    }
    """)
    SearchHits<VehicleInformationDocument> findCompletionSuggestionsGlobally(String prefix, Pageable pageable);

    default SearchHits<VehicleInformationDocument> findCompletionSuggestionsGlobally(String prefix, int maxSuggestions) {
        return findCompletionSuggestionsGlobally(prefix, PageRequest.of(0, Math.max(1, maxSuggestions)));
    }
}
