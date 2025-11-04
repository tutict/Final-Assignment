package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.entity.OffenseTypeDict;
import com.tutict.finalassignmentbackend.entity.elastic.OffenseTypeDictDocument;
import com.tutict.finalassignmentbackend.mapper.OffenseTypeDictMapper;
import com.tutict.finalassignmentbackend.repository.OffenseTypeDictSearchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class OffenseTypeDictService extends AbstractElasticsearchCrudService<OffenseTypeDict, OffenseTypeDictDocument, Integer> {

    private static final String CACHE_NAME = "offenseTypeDictCache";

    @Autowired
    public OffenseTypeDictService(OffenseTypeDictMapper mapper,
                                  OffenseTypeDictSearchRepository repository) {
        super(mapper,
                repository,
                OffenseTypeDictDocument::fromEntity,
                OffenseTypeDictDocument::toEntity,
                OffenseTypeDict::getTypeId,
                CACHE_NAME);
    }
}
