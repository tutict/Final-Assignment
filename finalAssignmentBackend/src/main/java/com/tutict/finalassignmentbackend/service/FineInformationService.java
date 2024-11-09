package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.FineInformationMapper;
import com.tutict.finalassignmentbackend.entity.FineInformation;
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
public class FineInformationService {

    // 日志记录器，用于记录应用运行时的信息
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(FineInformationService.class);

    // MyBatis映射器，用于执行数据库操作
    private final FineInformationMapper fineInformationMapper;
    // Kafka模板，用于发送消息到Kafka
    private final KafkaTemplate<String, FineInformation> kafkaTemplate;

    // 构造函数，通过依赖注入初始化FineInformationMapper和KafkaTemplate
    @Autowired
    public FineInformationService(FineInformationMapper fineInformationMapper, KafkaTemplate<String, FineInformation> kafkaTemplate) {
        this.fineInformationMapper = fineInformationMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    /**
     * 创建罚款信息，并向Kafka发送消息
     * @param fineInformation 罚款信息对象
     */
    @Transactional
    @CacheEvict(value = "fineCache", key = "#fineInformation.fineId")
    public void createFine(FineInformation fineInformation) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("fine_create", fineInformation);
            // 数据库插入
            fineInformationMapper.insert(fineInformation);
        } catch (Exception e) {
            log.error("Exception occurred while creating fine or sending Kafka message", e);
            throw new RuntimeException("Failed to create fine", e);
        }
    }

    /**
     * 根据罚款ID获取罚款信息
     * @param fineId 罚款ID
     * @return 罚款信息对象
     * @throws IllegalArgumentException 如果提供的罚款ID无效
     */
    @Cacheable(value = "fineCache", key = "#fineId")
    public FineInformation getFineById(int fineId) {
        if (fineId <= 0) {
            throw new IllegalArgumentException("Invalid fine ID");
        }
        return fineInformationMapper.selectById(fineId);
    }

    /**
     * 获取所有罚款信息
     * @return 罚款信息列表
     */
    @Cacheable(value = "fineCache", key = "'allFines'")
    public List<FineInformation> getAllFines() {
        return fineInformationMapper.selectList(null);
    }

    /**
     * 更新罚款信息，并向Kafka发送消息
     * @param fineInformation 罚款信息对象
     */
    @Transactional
    @CachePut(value = "fineCache", key = "#fineInformation.fineId")
    public void updateFine(FineInformation fineInformation) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("fine_update", fineInformation);
            // 更新数据库记录
            fineInformationMapper.updateById(fineInformation);
        } catch (Exception e) {
            log.error("Exception occurred while updating fine or sending Kafka message", e);
            throw new RuntimeException("Failed to update fine", e);
        }
    }

    /**
     * 删除罚款信息
     * @param fineId 罚款ID
     */
    @Transactional
    @CacheEvict(value = "fineCache", key = "#fineId")
    public void deleteFine(int fineId) {
        try {
            int result = fineInformationMapper.deleteById(fineId);
            if (result > 0) {
                log.info("Fine with ID {} deleted successfully", fineId);
            } else {
                log.error("Failed to delete fine with ID {}", fineId);
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting fine", e);
            throw new RuntimeException("Failed to delete fine", e);
        }
    }

    /**
     * 根据付款人获取所有罚款信息
     * @param payee 付款人
     * @return 罚款信息列表
     * @throws IllegalArgumentException 如果提供的付款人无效
     */
    @Cacheable(value = "fineCache", key = "#root.methodName + '_' + #payee")
    public List<FineInformation> getFinesByPayee(String payee) {
        if (payee == null || payee.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid payee");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("payee", payee);
        return fineInformationMapper.selectList(queryWrapper);
    }

    /**
     * 根据时间范围获取所有罚款信息
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return 罚款信息列表
     * @throws IllegalArgumentException 如果提供的时间范围无效
     */
    @Cacheable(value = "fineCache", key = "#root.methodName + '_' + #startTime + '-' + #endTime")
    public List<FineInformation> getFinesByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("fineTime", startTime, endTime);
        return fineInformationMapper.selectList(queryWrapper);
    }

    /**
     * 根据收据编号获取罚款信息
     * @param receiptNumber 收据编号
     * @return 罚款信息对象
     * @throws IllegalArgumentException 如果提供的收据编号无效
     */
    @Cacheable(value = "fineCache", key = "#root.methodName + '_' + #receiptNumber")
    public FineInformation getFineByReceiptNumber(String receiptNumber) {
        if (receiptNumber == null || receiptNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid receipt number");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("receiptNumber", receiptNumber);
        return fineInformationMapper.selectOne(queryWrapper);
    }

    // 发送 Kafka 消息的私有方法
    private void sendKafkaMessage(String topic, FineInformation fineInformation) throws Exception {
        SendResult<String, FineInformation> sendResult = kafkaTemplate.send(topic, fineInformation).get();
        log.info("Message sent to Kafka topic {} successfully: {}", topic, sendResult.toString());
    }
}
