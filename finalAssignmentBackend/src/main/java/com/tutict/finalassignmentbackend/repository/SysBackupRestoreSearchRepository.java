package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.SysBackupRestoreDocument;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SysBackupRestoreSearchRepository extends ElasticsearchRepository<SysBackupRestoreDocument, Long> {
}
