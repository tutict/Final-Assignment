package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.SysSettings;
import com.tutict.finalassignmentbackend.entity.elastic.SysSettingsDocument;
import com.tutict.finalassignmentbackend.mapper.SysSettingsMapper;
import com.tutict.finalassignmentbackend.repository.SysSettingsSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SysSettingsService extends AbstractElasticsearchCrudService<SysSettings, SysSettingsDocument, Integer> {

    private static final String CACHE_NAME = "sysSettingsCache";

    @Autowired
    public SysSettingsService(SysSettingsMapper mapper,
                              SysSettingsSearchRepository repository) {
        super(mapper,
                repository,
                SysSettingsDocument::fromEntity,
                SysSettingsDocument::toEntity,
                SysSettings::getSettingId,
                CACHE_NAME);
    }
}
