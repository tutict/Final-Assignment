package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.SysRolePermission;
import com.tutict.finalassignmentbackend.entity.elastic.SysRolePermissionDocument;
import com.tutict.finalassignmentbackend.mapper.SysRolePermissionMapper;
import com.tutict.finalassignmentbackend.repository.SysRolePermissionSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SysRolePermissionService extends AbstractElasticsearchCrudService<SysRolePermission, SysRolePermissionDocument, Long> {

    private static final String CACHE_NAME = "sysRolePermissionCache";

    @Autowired
    public SysRolePermissionService(SysRolePermissionMapper mapper,
                                    SysRolePermissionSearchRepository repository) {
        super(mapper,
                repository,
                SysRolePermissionDocument::fromEntity,
                SysRolePermissionDocument::toEntity,
                SysRolePermission::getId,
                CACHE_NAME);
    }
}
