package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.SysUserDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SysUserSearchRepository extends ElasticsearchRepository<SysUserDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "match_phrase_prefix": {
                "username": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysUserDocument> searchByUsernamePrefix(String username, Pageable pageable);

    default SearchHits<SysUserDocument> searchByUsernamePrefix(String username) {
        return searchByUsernamePrefix(username, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "username": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<SysUserDocument> searchByUsernameFuzzy(String username, Pageable pageable);

    default SearchHits<SysUserDocument> searchByUsernameFuzzy(String username) {
        return searchByUsernameFuzzy(username, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "realName": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysUserDocument> searchByRealNamePrefix(String realName, Pageable pageable);

    default SearchHits<SysUserDocument> searchByRealNamePrefix(String realName) {
        return searchByRealNamePrefix(realName, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "realName": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<SysUserDocument> searchByRealNameFuzzy(String realName, Pageable pageable);

    default SearchHits<SysUserDocument> searchByRealNameFuzzy(String realName) {
        return searchByRealNameFuzzy(realName, PageRequest.of(0, DEFAULT_PAGE_SIZE));
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
    SearchHits<SysUserDocument> searchByIdCardNumber(String idCardNumber, Pageable pageable);

    default SearchHits<SysUserDocument> searchByIdCardNumber(String idCardNumber) {
        return searchByIdCardNumber(idCardNumber, PageRequest.of(0, DEFAULT_PAGE_SIZE));
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
    SearchHits<SysUserDocument> searchByContactNumber(String contactNumber, Pageable pageable);

    default SearchHits<SysUserDocument> searchByContactNumber(String contactNumber) {
        return searchByContactNumber(contactNumber, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "department": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysUserDocument> searchByDepartment(String department, Pageable pageable);

    default SearchHits<SysUserDocument> searchByDepartment(String department) {
        return searchByDepartment(department, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "employeeNumber": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysUserDocument> searchByEmployeeNumber(String employeeNumber, Pageable pageable);

    default SearchHits<SysUserDocument> searchByEmployeeNumber(String employeeNumber) {
        return searchByEmployeeNumber(employeeNumber, PageRequest.of(0, DEFAULT_PAGE_SIZE));
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
    SearchHits<SysUserDocument> searchByStatus(String status, Pageable pageable);

    default SearchHits<SysUserDocument> searchByStatus(String status) {
        return searchByStatus(status, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "range": {
                "lastLoginTime": {
                  "gte": "?0",
                  "lte": "?1"
                }
              }
            }
            """)
    SearchHits<SysUserDocument> searchByLastLoginTimeRange(String startTime, String endTime, Pageable pageable);

    default SearchHits<SysUserDocument> searchByLastLoginTimeRange(String startTime, String endTime) {
        return searchByLastLoginTimeRange(startTime, endTime, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
