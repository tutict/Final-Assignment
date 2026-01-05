package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.SysUserRoleDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SysUserRoleSearchRepository extends ElasticsearchRepository<SysUserRoleDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "term": {
                "userId": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<SysUserRoleDocument> findByUserId(Long userId, Pageable pageable);

    default SearchHits<SysUserRoleDocument> findByUserId(Long userId) {
        return findByUserId(userId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "roleId": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<SysUserRoleDocument> findByRoleId(Integer roleId, Pageable pageable);

    default SearchHits<SysUserRoleDocument> findByRoleId(Integer roleId) {
        return findByRoleId(roleId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "bool": {
                "must": [
                  {
                    "term": {
                      "userId": {
                        "value": ?0
                      }
                    }
                  },
                  {
                    "term": {
                      "roleId": {
                        "value": ?1
                      }
                    }
                  }
                ]
              }
            }
            """)
    SearchHits<SysUserRoleDocument> findByUserIdAndRoleId(Long userId, Integer roleId, Pageable pageable);

    default SearchHits<SysUserRoleDocument> findByUserIdAndRoleId(Long userId, Integer roleId) {
        return findByUserIdAndRoleId(userId, roleId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
