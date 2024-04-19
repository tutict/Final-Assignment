package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.AppealManagementMapper;
import com.tutict.finalassignmentbackend.mapper.OffenseInformationMapper;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AppealManagementService {

    private final AppealManagementMapper appealManagementMapper;
    private final OffenseInformationMapper offenseInformationMapper;
    private final KafkaTemplate<String, AppealManagement> kafkaTemplate;

    @Autowired
    public AppealManagementService(AppealManagementMapper appealManagementMapper, OffenseInformationMapper offenseInformationMapper, KafkaTemplate<String, AppealManagement> kafkaTemplate) {
        this.appealManagementMapper = appealManagementMapper;
        this.offenseInformationMapper = offenseInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    public void createAppeal(AppealManagement appeal) {
        // 发送消息到 Kafka 主题
        kafkaTemplate.send("appeal_create", appeal);
        appealManagementMapper.insert(appeal);
    }

    public AppealManagement getAppealById(Long appealId) {
        return appealManagementMapper.selectById(appealId);
    }

    public List<AppealManagement> getAllAppeals() {
        return appealManagementMapper.selectList(null);
    }

    public void updateAppeal(AppealManagement appeal) {
        // 发送更新申述的消息到 Kafka 主题
        kafkaTemplate.send("appeal_updated", appeal);
        appealManagementMapper.updateById(appeal);
    }

    public void deleteAppeal(Long appealId) {
        appealManagementMapper.deleteById(appealId);
    }

    //根据申述状态查询申述信息
    public List<AppealManagement> getAppealsByProcessStatus(String processStatus) {
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processStatus);
        return appealManagementMapper.selectList(queryWrapper);
    }

    //根据申述人姓名查询申述信息
    public List<AppealManagement> getAppealsByAppealName(String appealName) {
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("appeal_name", appealName);
        return appealManagementMapper.selectList(queryWrapper);
    }

    //根据申述ID查询关联的违法行为信息
    public OffenseInformation getOffenseByAppealId(Long appealId) {
        AppealManagement appeal = appealManagementMapper.selectById(appealId);
        if (appeal != null) {
            return offenseInformationMapper.selectById(appeal.getOffenseId());
        }
        return null;
    }
}
