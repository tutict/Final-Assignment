package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.SysRolePermissionDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SysRolePermissionSearchRepository extends ElasticsearchRepository<SysRolePermissionDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "term": {
                "roleId": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<SysRolePermissionDocument> findByRoleId(Integer roleId, Pageable pageable);

    default SearchHits<SysRolePermissionDocument> findByRoleId(Integer roleId) {
        return findByRoleId(roleId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "permissionId": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<SysRolePermissionDocument> findByPermissionId(Integer permissionId, Pageable pageable);

    default SearchHits<SysRolePermissionDocument> findByPermissionId(Integer permissionId) {
        return findByPermissionId(permissionId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "bool": {
                "must": [
                  {
                    "term": {
                      "roleId": {
                        "value": ?0
                      }
                    }
                  },
                  {
                    "term": {
                      "permissionId": {
                        "value": ?1
                      }
                    }
                  }
                ]
              }
            }
            """)
    SearchHits<SysRolePermissionDocument> findByRoleIdAndPermissionId(Integer roleId, Integer permissionId, Pageable pageable);

    default SearchHits<SysRolePermissionDocument> findByRoleIdAndPermissionId(Integer roleId, Integer permissionId) {
        return findByRoleIdAndPermissionId(roleId, permissionId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
