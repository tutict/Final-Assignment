package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.DeductionInformationMapper;
import com.tutict.finalassignmentbackend.entity.DeductionInformation;
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

import java.util.Date;
import java.util.List;

@Service
public class DeductionInformationService {

    // Logger用于记录日志信息
    private static final Logger log = LoggerFactory.getLogger(DeductionInformationService.class);

    // Mapper用于数据库操作
    private final DeductionInformationMapper deductionInformationMapper;
    // KafkaTemplate用于发送Kafka消息
    private final KafkaTemplate<String, DeductionInformation> kafkaTemplate;

    // 构造函数，通过@Autowired自动装配依赖项
    @Autowired
    public DeductionInformationService(DeductionInformationMapper deductionInformationMapper, KafkaTemplate<String, DeductionInformation> kafkaTemplate) {
        this.deductionInformationMapper = deductionInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建扣款信息，使用@Transactional确保事务一致性
    @Transactional
    @CacheEvict(value = "deductionCache", key = "#deduction.deductionId")
    public void createDeduction(DeductionInformation deduction) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("deduction_create", deduction);
            // 数据库插入
            deductionInformationMapper.insert(deduction);
        } catch (Exception e) {
            log.error("Exception occurred while creating deduction or sending Kafka message", e);
            throw new RuntimeException("Failed to create deduction", e);
        }
    }

    /**
     * 根据ID获取扣款信息
     * @param deductionId 扣款信息ID
     * @return 扣款信息对象
     * @throws IllegalArgumentException 如果deductionId无效
     */
    @Cacheable(value = "deductionCache", key = "#deductionId")
    public DeductionInformation getDeductionById(int deductionId) {
        if (deductionId <= 0) {
            throw new IllegalArgumentException("Invalid deduction ID");
        }
        return deductionInformationMapper.selectById(deductionId);
    }

    /**
     * 获取所有扣款信息
     * @return 扣款信息列表
     */
    @Cacheable(value = "deductionCache", key = "'allDeductions'")
    public List<DeductionInformation> getAllDeductions() {
        return deductionInformationMapper.selectList(null);
    }

    // 更新扣款信息，使用@Transactional确保事务一致性
    @Transactional
    @CachePut(value = "deductionCache", key = "#deduction.deductionId")
    public void updateDeduction(DeductionInformation deduction) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("deduction_update", deduction);
            // 更新数据库记录
            deductionInformationMapper.updateById(deduction);
        } catch (Exception e) {
            log.error("Exception occurred while updating deduction or sending Kafka message", e);
            throw new RuntimeException("Failed to update deduction", e);
        }
    }

    /**
     * 删除扣款信息
     * @param deductionId 扣款信息ID
     */
    @Transactional
    @CacheEvict(value = "deductionCache", key = "#deductionId")
    public void deleteDeduction(int deductionId) {
        try {
            int result = deductionInformationMapper.deleteById(deductionId);
            if (result > 0) {
                log.info("Deduction with ID {} deleted successfully", deductionId);
            } else {
                log.error("Failed to delete deduction with ID {}", deductionId);
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting deduction", e);
            throw new RuntimeException("Failed to delete deduction", e);
        }
    }

    /**
     * 获取指定处理人所有信息
     * @param handler 处理人姓名
     * @return 扣款信息列表
     * @throws IllegalArgumentException 如果处理人姓名为空或无效
     */
    @Cacheable(value = "deductionCache", key = "#root.methodName + '_' + #handler")
    public List<DeductionInformation> getDeductionsByHandler(String handler) {
        if (handler == null || handler.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid handler");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("handler", handler);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    /**
     * 获取指定时间范围内的扣款信息
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 扣款信息列表
     * @throws IllegalArgumentException 如果时间范围无效
     */
    @Cacheable(value = "deductionCache", key = "#root.methodName + '_' + #startTime + '-' + #endTime")
    public List<DeductionInformation> getDeductionsByByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("deductionTime", startTime, endTime);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    // 发送 Kafka 消息的私有方法
    private void sendKafkaMessage(String topic, DeductionInformation deduction) throws Exception {
        SendResult<String, DeductionInformation> sendResult = kafkaTemplate.send(topic, deduction).get();
        log.info("Message sent to Kafka topic {} successfully: {}", topic, sendResult.toString());
    }
}
