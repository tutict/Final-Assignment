package com.tutict.finalassignmentbackend.service.view;

import com.tutict.finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import com.tutict.finalassignmentbackend.entity.view.OffenseDetails;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class OffenseDetailsService {

    private final OffenseDetailsMapper offenseDetailsMapper;

    @Autowired
    public OffenseDetailsService(OffenseDetailsMapper offenseDetailsMapper) {
        this.offenseDetailsMapper = offenseDetailsMapper;
    }

    public List<OffenseDetails> getAllOffenseDetails() {
        return offenseDetailsMapper.selectList(null);
    }

    public OffenseDetails getOffenseDetailsById(Integer id) {
        return offenseDetailsMapper.selectById(id);
    }
}
