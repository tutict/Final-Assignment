package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.SysBackupRestoreDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SysBackupRestoreSearchRepository extends ElasticsearchRepository<SysBackupRestoreDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
            {
              "term": {
                "backupType.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<SysBackupRestoreDocument> searchByBackupType(String backupType, Pageable pageable);

    default SearchHits<SysBackupRestoreDocument> searchByBackupType(String backupType) {
        return searchByBackupType(backupType, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "backupFileName": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysBackupRestoreDocument> searchByBackupFileNamePrefix(String backupFileName, Pageable pageable);

    default SearchHits<SysBackupRestoreDocument> searchByBackupFileNamePrefix(String backupFileName) {
        return searchByBackupFileNamePrefix(backupFileName, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "match_phrase_prefix": {
                "backupHandler": {
                  "query": "?0"
                }
              }
            }
            """)
    SearchHits<SysBackupRestoreDocument> searchByBackupHandler(String backupHandler, Pageable pageable);

    default SearchHits<SysBackupRestoreDocument> searchByBackupHandler(String backupHandler) {
        return searchByBackupHandler(backupHandler, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "term": {
                "restoreStatus.keyword": {
                  "value": "?0"
                }
              }
            }
            """)
    SearchHits<SysBackupRestoreDocument> searchByRestoreStatus(String restoreStatus, Pageable pageable);

    default SearchHits<SysBackupRestoreDocument> searchByRestoreStatus(String restoreStatus) {
        return searchByRestoreStatus(restoreStatus, PageRequest.of(0, DEFAULT_PAGE_SIZE));
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
    SearchHits<SysBackupRestoreDocument> searchByStatus(String status, Pageable pageable);

    default SearchHits<SysBackupRestoreDocument> searchByStatus(String status) {
        return searchByStatus(status, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "range": {
                "backupTime": {
                  "gte": "?0",
                  "lte": "?1"
                }
              }
            }
            """)
    SearchHits<SysBackupRestoreDocument> searchByBackupTimeRange(String startTime, String endTime, Pageable pageable);

    default SearchHits<SysBackupRestoreDocument> searchByBackupTimeRange(String startTime, String endTime) {
        return searchByBackupTimeRange(startTime, endTime, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
            {
              "range": {
                "restoreTime": {
                  "gte": "?0",
                  "lte": "?1"
                }
              }
            }
            """)
    SearchHits<SysBackupRestoreDocument> searchByRestoreTimeRange(String startTime, String endTime, Pageable pageable);

    default SearchHits<SysBackupRestoreDocument> searchByRestoreTimeRange(String startTime, String endTime) {
        return searchByRestoreTimeRange(startTime, endTime, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
