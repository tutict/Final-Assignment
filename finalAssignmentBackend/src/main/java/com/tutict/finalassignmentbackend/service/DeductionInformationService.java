package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.dao.DeductionInformationMapper;
import com.tutict.finalassignmentbackend.entity.DeductionInformation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class DeductionInformationService {

    private final DeductionInformationMapper deductionInformationMapper;

    @Autowired
    public DeductionInformationService(DeductionInformationMapper deductionInformationMapper) {
        this.deductionInformationMapper = deductionInformationMapper;
    }

    public void createDeduction(DeductionInformation deduction) {
        deductionInformationMapper.insert(deduction);
    }


    public DeductionInformation getDeductionById(int deductionId) {
        return deductionInformationMapper.selectById(deductionId);
    }

    public List<DeductionInformation> getAllDeductions() {
        return deductionInformationMapper.selectList(null);
    }

    public void updateDeduction(DeductionInformation deduction) {
        deductionInformationMapper.updateById(deduction);
    }

    public void deleteDeduction(int deductionId) {
        deductionInformationMapper.deleteById(deductionId);
    }

    //获取指定处理人所有信息
    public List<DeductionInformation> getDeductionsByHandler(String handler) {
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("handler", handler);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    //获取指定时间范围内的所有信息
    public List<DeductionInformation> getDeductionsByByTimeRange(Date startTime, Date endTime) {
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("deductionTime", startTime, endTime);
        return deductionInformationMapper.selectList(queryWrapper);
    }
}

