package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.SysPermission;
import com.tutict.finalassignmentbackend.entity.elastic.SysPermissionDocument;
import com.tutict.finalassignmentbackend.mapper.SysPermissionMapper;
import com.tutict.finalassignmentbackend.repository.SysPermissionSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SysPermissionService extends AbstractElasticsearchCrudService<SysPermission, SysPermissionDocument, Integer> {

    private static final String CACHE_NAME = "sysPermissionCache";

    @Autowired
    public SysPermissionService(SysPermissionMapper mapper,
                                SysPermissionSearchRepository repository) {
        super(mapper,
                repository,
                SysPermissionDocument::fromEntity,
                SysPermissionDocument::toEntity,
                SysPermission::getPermissionId,
                CACHE_NAME);
    }
}
