package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.FineInformationMapper;
import com.tutict.finalassignmentbackend.entity.FineInformation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class FineInformationService {

    public final FineInformationMapper fineInformationMapper;

    @Autowired
    public FineInformationService(FineInformationMapper fineInformationMapper) {
        this.fineInformationMapper = fineInformationMapper;
    }

    public void createFine(FineInformation fineInformation) {
        fineInformationMapper.insert(fineInformation);
    }

    public FineInformation getFineById(int fineId) {
        return fineInformationMapper.selectById(fineId);
    }

    public List<FineInformation> getAllFines() {
        return fineInformationMapper.selectList(null);
    }

    public void updateFine(FineInformation fineInformation) {
        fineInformationMapper.updateById(fineInformation);
    }

    public void deleteFine(int fineId) {
        fineInformationMapper.deleteById(fineId);
    }

    // get all fines by payee
    public List<FineInformation> getFinesByPayee(String payee) {
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("payee", payee);
        return fineInformationMapper.selectList(queryWrapper);
    }

    // get all fines by time range
    public List<FineInformation> getFinesByTimeRange(Date startTime, Date endTime) {
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("fineTime", startTime, endTime);
        return fineInformationMapper.selectList(queryWrapper);
    }

    public FineInformation getFineByReceiptNumber(String receiptNumber) {
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("receiptNumber", receiptNumber);
        return fineInformationMapper.selectOne(queryWrapper);
    }
}
