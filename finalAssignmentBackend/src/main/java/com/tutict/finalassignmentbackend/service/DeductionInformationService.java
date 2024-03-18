package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.DeductionInformationMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class DeductionInformationService {

    private final DeductionInformationMapper deductionInformationMapper;

    @Autowired
    public DeductionInformationService(DeductionInformationMapper deductionInformationMapper) {
        this.deductionInformationMapper = deductionInformationMapper;
    }
}

