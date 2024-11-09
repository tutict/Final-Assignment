package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.AppealManagementMapper;
import com.tutict.finalassignmentbackend.mapper.OffenseInformationMapper;
import com.tutict.finalassignmentbackend.entity.AppealManagement;
import com.tutict.finalassignmentbackend.entity.OffenseInformation;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

// 申诉管理服务类
@Service
public class AppealManagementService {

    // 日志记录器
    private static final Logger log = LoggerFactory.getLogger(AppealManagementService.class);

    // 持久层映射器，用于申诉管理操作
    private final AppealManagementMapper appealManagementMapper;
    // 持久层映射器，用于违法行为信息操作
    private final OffenseInformationMapper offenseInformationMapper;
    // Kafka模板，用于发送申诉相关消息
    private final KafkaTemplate<String, AppealManagement> kafkaTemplate;

    // 构造函数，通过DI注入映射器和Kafka模板
    @Autowired
    public AppealManagementService(AppealManagementMapper appealManagementMapper, OffenseInformationMapper offenseInformationMapper, KafkaTemplate<String, AppealManagement> kafkaTemplate) {
        this.appealManagementMapper = appealManagementMapper;
        this.offenseInformationMapper = offenseInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建申诉记录
    @Transactional
    @CacheEvict(value = "appealCache", key = "#appeal.appealId")
    public void createAppeal(AppealManagement appeal) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("appeal_create", appeal);
            // 数据库插入
            appealManagementMapper.insert(appeal);
        } catch (Exception e) {
            log.error("Exception occurred while creating appeal or sending Kafka message", e);
            throw new RuntimeException("Failed to create appeal", e);
        }
    }

    /**
     * 根据申诉ID获取申诉记录
     * @param appealId 申诉ID
     * @return 申诉记录
     */
    @Cacheable(value = "appealCache", key = "#appealId")
    public AppealManagement getAppealById(Integer appealId) {
        return appealManagementMapper.selectById(appealId);
    }

    /**
     * 获取所有申诉记录
     * @return 所有申诉记录列表
     */
    @Cacheable(value = "appealCache", key = "'allAppeals'")
    public List<AppealManagement> getAllAppeals() {
        return appealManagementMapper.selectList(null);
    }

    // 更新申诉记录
    @Transactional
    @CachePut(value = "appealCache", key = "#appeal.appealId")
    public void updateAppeal(AppealManagement appeal) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("appeal_updated", appeal);
            // 更新数据库记录
            appealManagementMapper.updateById(appeal);
        } catch (Exception e) {
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            throw new RuntimeException("Failed to update appeal", e);
        }
    }

    /**
     * 删除申诉记录
     * @param appealId 申诉ID
     */
    @Transactional
    @CacheEvict(value = "appealCache", key = "#appealId")
    public void deleteAppeal(Integer appealId) {
        try {
            AppealManagement appeal = appealManagementMapper.selectById(appealId);
            if (appeal == null) {
                log.warn("Appeal with ID {} not found, cannot delete", appealId);
                return;
            }

            int result = appealManagementMapper.deleteById(appealId);
            if (result > 0) {
                log.info("Appeal with ID {} deleted successfully", appealId);
            } else {
                log.error("Failed to delete appeal with ID {}", appealId);
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting appeal", e);
            throw new RuntimeException("Failed to delete appeal", e);
        }
    }

    /**
     * 根据申诉状态查询申诉信息
     * @param processStatus 申诉状态
     * @return 申诉信息列表
     */
    @Cacheable(value = "appealCache", key = "#root.methodName + '_' + #processStatus")
    public List<AppealManagement> getAppealsByProcessStatus(String processStatus) {
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processStatus);
        return appealManagementMapper.selectList(queryWrapper);
    }

    /**
     * 根据申诉人姓名查询申诉信息
     * @param appealName 申诉人姓名
     * @return 申诉信息列表
     */
    @Cacheable(value = "appealCache", key = "#root.methodName + '_' + #appealName")
    public List<AppealManagement> getAppealsByAppealName(String appealName) {
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("appeal_name", appealName);
        return appealManagementMapper.selectList(queryWrapper);
    }

    /**
     * 根据申诉ID查询关联的违法行为信息
     * @param appealId 申诉ID
     * @return 关联的违法行为信息
     */
    @Cacheable(value = "appealCache", key = "#root.methodName + '_' + #appealId")
    public OffenseInformation getOffenseByAppealId(Integer appealId) {
        AppealManagement appeal = appealManagementMapper.selectById(appealId);
        if (appeal != null) {
            return offenseInformationMapper.selectById(appeal.getOffenseId());
        } else {
            log.warn("No appeal found with ID: {}", appealId);
            return null;
        }
    }

    // 发送 Kafka 消息的私有方法
    private void sendKafkaMessage(String topic, AppealManagement appeal) throws Exception {
        SendResult<String, AppealManagement> sendResult = kafkaTemplate.send(topic, appeal).get();
        log.info("Message sent to Kafka topic {} successfully: {}", topic, sendResult.toString());
    }
}
