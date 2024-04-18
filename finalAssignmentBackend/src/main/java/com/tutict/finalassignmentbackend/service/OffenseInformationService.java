package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.OffenseInformationMapper;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class OffenseInformationService {

    private final OffenseInformationMapper offenseInformationMapper;
    private final KafkaTemplate<String, OffenseInformation> kafkaTemplate;

    @Autowired
    public OffenseInformationService(OffenseInformationMapper offenseInformationMapper, KafkaTemplate<String, OffenseInformation> kafkaTemplate) {
        this.offenseInformationMapper = offenseInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    public void createOffense(OffenseInformation offenseInformation) {
        offenseInformationMapper.insert(offenseInformation);
        // 发送违法信息到 Kafka 主题
        kafkaTemplate.send("offense_topic", offenseInformation);
    }

    public OffenseInformation getOffenseByOffenseId(int offenseId) {
        return offenseInformationMapper.selectById(offenseId);
    }

    public List<OffenseInformation> getOffensesInformation() {
        return offenseInformationMapper.selectList(null);
    }

    public void updateOffense(OffenseInformation offenseInformation) {
        offenseInformationMapper.updateById(offenseInformation);
    }

    public void deleteOffense(int offenseId) {
        offenseInformationMapper.deleteById(offenseId);
    }

    // 根据时间范围查询
    public List<OffenseInformation> getOffensesByTimeRange(Date startTime, Date endTime) {
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("offense_time", startTime, endTime);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    // 根据处理状态查询
    public List<OffenseInformation> getOffensesByProcessState(String processState) {
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processState);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    // 根据驾驶员姓名查询
    public List<OffenseInformation> getOffensesByDriverName(String driverName) {
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_name", driverName);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    // 根据车牌号查询
    public List<OffenseInformation> getOffensesByLicensePlate(String offenseLicensePlate) {
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", offenseLicensePlate);
        return offenseInformationMapper.selectList(queryWrapper);
    }
}
