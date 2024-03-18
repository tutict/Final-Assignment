package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.FineInformationMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class FineInformationService {

    public final FineInformationMapper fineInformationMapper;

    @Autowired
    public FineInformationService(FineInformationMapper fineInformationMapper) {
        this.fineInformationMapper = fineInformationMapper;
    }
}
