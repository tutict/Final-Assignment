package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.SysDictDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SysDictSearchRepository extends ElasticsearchRepository<SysDictDocument, Integer> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "term": {
                "dictType.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<SysDictDocument> searchByDictType(String dictType, Pageable pageable);

    default SearchHits<SysDictDocument> searchByDictType(String dictType) {
        return searchByDictType(dictType, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "dictCode": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysDictDocument> searchByDictCodePrefix(String dictCode, Pageable pageable);

    default SearchHits<SysDictDocument> searchByDictCodePrefix(String dictCode) {
        return searchByDictCodePrefix(dictCode, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "dictLabel": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysDictDocument> searchByDictLabelPrefix(String dictLabel, Pageable pageable);

    default SearchHits<SysDictDocument> searchByDictLabelPrefix(String dictLabel) {
        return searchByDictLabelPrefix(dictLabel, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "dictLabel": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<SysDictDocument> searchByDictLabelFuzzy(String dictLabel, Pageable pageable);

    default SearchHits<SysDictDocument> searchByDictLabelFuzzy(String dictLabel) {
        return searchByDictLabelFuzzy(dictLabel, PageRequest.of(0, DEFAULT_PAGE_SIZE));
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
    SearchHits<SysDictDocument> findByParentId(Integer parentId, Pageable pageable);

    default SearchHits<SysDictDocument> findByParentId(Integer parentId) {
        return findByParentId(parentId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "isDefault": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<SysDictDocument> searchByIsDefault(boolean isDefault, Pageable pageable);

    default SearchHits<SysDictDocument> searchByIsDefault(boolean isDefault) {
        return searchByIsDefault(isDefault, PageRequest.of(0, DEFAULT_PAGE_SIZE));
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
    SearchHits<SysDictDocument> searchByStatus(String status, Pageable pageable);

    default SearchHits<SysDictDocument> searchByStatus(String status) {
        return searchByStatus(status, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
