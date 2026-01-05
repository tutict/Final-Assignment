package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.SysSettingsDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SysSettingsSearchRepository extends ElasticsearchRepository<SysSettingsDocument, Integer> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "match_phrase_prefix": {
                "settingKey": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysSettingsDocument> searchBySettingKeyPrefix(String settingKey, Pageable pageable);

    default SearchHits<SysSettingsDocument> searchBySettingKeyPrefix(String settingKey) {
        return searchBySettingKeyPrefix(settingKey, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match": {
                "settingKey": {
                  "query": "?0",
                  "fuzziness": "AUTO"
                }
              }
            }
            """)
    SearchHits<SysSettingsDocument> searchBySettingKeyFuzzy(String settingKey, Pageable pageable);

    default SearchHits<SysSettingsDocument> searchBySettingKeyFuzzy(String settingKey) {
        return searchBySettingKeyFuzzy(settingKey, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "settingType.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<SysSettingsDocument> searchBySettingType(String settingType, Pageable pageable);

    default SearchHits<SysSettingsDocument> searchBySettingType(String settingType) {
        return searchBySettingType(settingType, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "category.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<SysSettingsDocument> searchByCategory(String category, Pageable pageable);

    default SearchHits<SysSettingsDocument> searchByCategory(String category) {
        return searchByCategory(category, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "isEditable": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<SysSettingsDocument> searchByIsEditable(boolean isEditable, Pageable pageable);

    default SearchHits<SysSettingsDocument> searchByIsEditable(boolean isEditable) {
        return searchByIsEditable(isEditable, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "isEncrypted": {
                  "value": ?0
                }
              }
            }
            """)
    SearchHits<SysSettingsDocument> searchByIsEncrypted(boolean isEncrypted, Pageable pageable);

    default SearchHits<SysSettingsDocument> searchByIsEncrypted(boolean isEncrypted) {
        return searchByIsEncrypted(isEncrypted, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
