package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.SysUser;
import com.tutict.finalassignmentbackend.entity.elastic.SysUserDocument;
import com.tutict.finalassignmentbackend.mapper.SysUserMapper;
import com.tutict.finalassignmentbackend.repository.SysUserSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SysUserService extends AbstractElasticsearchCrudService<SysUser, SysUserDocument, Long> {

    private static final String CACHE_NAME = "sysUserCache";

    @Autowired
    public SysUserService(SysUserMapper mapper,
                          SysUserSearchRepository repository) {
        super(mapper,
                repository,
                SysUserDocument::fromEntity,
                SysUserDocument::toEntity,
                SysUser::getUserId,
                CACHE_NAME);
    }
}
