package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.SysBackupRestore;
import com.tutict.finalassignmentbackend.entity.elastic.SysBackupRestoreDocument;
import com.tutict.finalassignmentbackend.mapper.SysBackupRestoreMapper;
import com.tutict.finalassignmentbackend.repository.SysBackupRestoreSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SysBackupRestoreService extends AbstractElasticsearchCrudService<SysBackupRestore, SysBackupRestoreDocument, Long> {

    private static final String CACHE_NAME = "sysBackupRestoreCache";

    @Autowired
    public SysBackupRestoreService(SysBackupRestoreMapper mapper,
                                   SysBackupRestoreSearchRepository repository) {
        super(mapper,
                repository,
                SysBackupRestoreDocument::fromEntity,
                SysBackupRestoreDocument::toEntity,
                SysBackupRestore::getBackupId,
                CACHE_NAME);
    }
}
