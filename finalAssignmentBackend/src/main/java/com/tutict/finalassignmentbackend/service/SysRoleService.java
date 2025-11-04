package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.SysRole;
import com.tutict.finalassignmentbackend.entity.elastic.SysRoleDocument;
import com.tutict.finalassignmentbackend.mapper.SysRoleMapper;
import com.tutict.finalassignmentbackend.repository.SysRoleSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SysRoleService extends AbstractElasticsearchCrudService<SysRole, SysRoleDocument, Integer> {

    private static final String CACHE_NAME = "sysRoleCache";

    @Autowired
    public SysRoleService(SysRoleMapper mapper,
                          SysRoleSearchRepository repository) {
        super(mapper,
                repository,
                SysRoleDocument::fromEntity,
                SysRoleDocument::toEntity,
                SysRole::getRoleId,
                CACHE_NAME);
    }
}
