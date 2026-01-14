package com.tutict.finalassignmentcloud.user.repository;

import com.tutict.finalassignmentcloud.entity.elastic.SysRoleDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SysRoleSearchRepository extends ElasticsearchRepository<SysRoleDocument, Integer> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "match_phrase_prefix": {
                "roleCode": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysRoleDocument> searchByRoleCodePrefix(String roleCode, Pageable pageable);

    default SearchHits<SysRoleDocument> searchByRoleCodePrefix(String roleCode) {
        return searchByRoleCodePrefix(roleCode, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "roleCode": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<SysRoleDocument> searchByRoleCodeFuzzy(String roleCode, Pageable pageable);

    default SearchHits<SysRoleDocument> searchByRoleCodeFuzzy(String roleCode) {
        return searchByRoleCodeFuzzy(roleCode, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "roleName": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysRoleDocument> searchByRoleNamePrefix(String roleName, Pageable pageable);

    default SearchHits<SysRoleDocument> searchByRoleNamePrefix(String roleName) {
        return searchByRoleNamePrefix(roleName, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "roleName": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<SysRoleDocument> searchByRoleNameFuzzy(String roleName, Pageable pageable);

    default SearchHits<SysRoleDocument> searchByRoleNameFuzzy(String roleName) {
        return searchByRoleNameFuzzy(roleName, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "roleType.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<SysRoleDocument> searchByRoleType(String roleType, Pageable pageable);

    default SearchHits<SysRoleDocument> searchByRoleType(String roleType) {
        return searchByRoleType(roleType, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "dataScope.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<SysRoleDocument> searchByDataScope(String dataScope, Pageable pageable);

    default SearchHits<SysRoleDocument> searchByDataScope(String dataScope) {
        return searchByDataScope(dataScope, PageRequest.of(0, DEFAULT_PAGE_SIZE));
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
    SearchHits<SysRoleDocument> searchByStatus(String status, Pageable pageable);

    default SearchHits<SysRoleDocument> searchByStatus(String status) {
        return searchByStatus(status, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}

