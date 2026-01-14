package com.tutict.finalassignmentcloud.user.repository;

import com.tutict.finalassignmentcloud.entity.elastic.SysPermissionDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SysPermissionSearchRepository extends ElasticsearchRepository<SysPermissionDocument, Integer> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "match_phrase_prefix": {
                "permissionCode": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysPermissionDocument> searchByPermissionCodePrefix(String permissionCode, Pageable pageable);

    default SearchHits<SysPermissionDocument> searchByPermissionCodePrefix(String permissionCode) {
        return searchByPermissionCodePrefix(permissionCode, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "permissionCode": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<SysPermissionDocument> searchByPermissionCodeFuzzy(String permissionCode, Pageable pageable);

    default SearchHits<SysPermissionDocument> searchByPermissionCodeFuzzy(String permissionCode) {
        return searchByPermissionCodeFuzzy(permissionCode, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "permissionName": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysPermissionDocument> searchByPermissionNamePrefix(String permissionName, Pageable pageable);

    default SearchHits<SysPermissionDocument> searchByPermissionNamePrefix(String permissionName) {
        return searchByPermissionNamePrefix(permissionName, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "permissionName": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<SysPermissionDocument> searchByPermissionNameFuzzy(String permissionName, Pageable pageable);

    default SearchHits<SysPermissionDocument> searchByPermissionNameFuzzy(String permissionName) {
        return searchByPermissionNameFuzzy(permissionName, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "permissionType.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<SysPermissionDocument> searchByPermissionType(String permissionType, Pageable pageable);

    default SearchHits<SysPermissionDocument> searchByPermissionType(String permissionType) {
        return searchByPermissionType(permissionType, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "parentId": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<SysPermissionDocument> findByParentId(Integer parentId, Pageable pageable);

    default SearchHits<SysPermissionDocument> findByParentId(Integer parentId) {
        return findByParentId(parentId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "apiPath": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysPermissionDocument> searchByApiPathPrefix(String apiPath, Pageable pageable);

    default SearchHits<SysPermissionDocument> searchByApiPathPrefix(String apiPath) {
        return searchByApiPathPrefix(apiPath, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "menuPath": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysPermissionDocument> searchByMenuPathPrefix(String menuPath, Pageable pageable);

    default SearchHits<SysPermissionDocument> searchByMenuPathPrefix(String menuPath) {
        return searchByMenuPathPrefix(menuPath, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "isVisible": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<SysPermissionDocument> searchByIsVisible(boolean isVisible, Pageable pageable);

    default SearchHits<SysPermissionDocument> searchByIsVisible(boolean isVisible) {
        return searchByIsVisible(isVisible, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "isExternal": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<SysPermissionDocument> searchByIsExternal(boolean isExternal, Pageable pageable);

    default SearchHits<SysPermissionDocument> searchByIsExternal(boolean isExternal) {
        return searchByIsExternal(isExternal, PageRequest.of(0, DEFAULT_PAGE_SIZE));
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
    SearchHits<SysPermissionDocument> searchByStatus(String status, Pageable pageable);

    default SearchHits<SysPermissionDocument> searchByStatus(String status) {
        return searchByStatus(status, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}

