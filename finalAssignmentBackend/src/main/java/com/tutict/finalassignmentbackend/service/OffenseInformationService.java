package com.tutict.finalassignmentbackend.service;

import com.tutict.finalassignmentbackend.dao.OffenseInformationMapper;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class OffenseInformationService {

    private final OffenseInformationMapper offenseInformationMapper;

    @Autowired
    public OffenseInformationService(OffenseInformationMapper offenseInformationMapper) {
        this.offenseInformationMapper = offenseInformationMapper;
    }

    public List<OffenseInformation> getAllOffenses() {
        return offenseInformationMapper.selectList(null);
    }

    public OffenseInformation getOffenseById(Long offenseId) {
        return offenseInformationMapper.selectById(offenseId);
    }

    public int saveOffenseInformation(OffenseInformation offenseInformation) {
        return offenseInformationMapper.insert(offenseInformation);
    }

    public int deleteOffenseInformation(Long offenseId) {
        return offenseInformationMapper.deleteById(offenseId);
    }

    public int updateOffenseInformation(OffenseInformation offenseInformation) {
       return offenseInformationMapper.updateById(offenseInformation);
    }

}
