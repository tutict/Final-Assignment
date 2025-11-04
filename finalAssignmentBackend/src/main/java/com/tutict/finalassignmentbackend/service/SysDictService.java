package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.SysDict;
import com.tutict.finalassignmentbackend.entity.elastic.SysDictDocument;
import com.tutict.finalassignmentbackend.mapper.SysDictMapper;
import com.tutict.finalassignmentbackend.repository.SysDictSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SysDictService extends AbstractElasticsearchCrudService<SysDict, SysDictDocument, Integer> {

    private static final String CACHE_NAME = "sysDictCache";

    @Autowired
    public SysDictService(SysDictMapper mapper,
                          SysDictSearchRepository repository) {
        super(mapper,
                repository,
                SysDictDocument::fromEntity,
                SysDictDocument::toEntity,
                SysDict::getDictId,
                CACHE_NAME);
    }
}
