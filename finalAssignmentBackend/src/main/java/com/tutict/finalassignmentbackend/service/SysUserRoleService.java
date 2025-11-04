package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.SysUserRole;
import com.tutict.finalassignmentbackend.entity.elastic.SysUserRoleDocument;
import com.tutict.finalassignmentbackend.mapper.SysUserRoleMapper;
import com.tutict.finalassignmentbackend.repository.SysUserRoleSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SysUserRoleService extends AbstractElasticsearchCrudService<SysUserRole, SysUserRoleDocument, Long> {

    private static final String CACHE_NAME = "sysUserRoleCache";

    @Autowired
    public SysUserRoleService(SysUserRoleMapper mapper,
                              SysUserRoleSearchRepository repository) {
        super(mapper,
                repository,
                SysUserRoleDocument::fromEntity,
                SysUserRoleDocument::toEntity,
                SysUserRole::getId,
                CACHE_NAME);
    }
}
