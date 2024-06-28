package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.DeductionInformationMapper;
import finalassignmentbackend.entity.DeductionInformation;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Date;
import java.util.List;

@ApplicationScoped
public class DeductionInformationService {

    private static final Logger log = LoggerFactory.getLogger(DeductionInformationService.class);

    @Inject
    DeductionInformationMapper deductionInformationMapper;

    @Inject
    @Channel("deduction_create")
    Emitter<DeductionInformation> deductionCreateEmitter;

    @Inject
    @Channel("deduction_update")
    Emitter<DeductionInformation> deductionUpdateEmitter;

    @Transactional
    public void createDeduction(DeductionInformation deduction) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            deductionCreateEmitter.send(deduction).toCompletableFuture().exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，事务管理器将处理事务
            deductionInformationMapper.insert(deduction);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    public DeductionInformation getDeductionById(int deductionId) {
        return deductionInformationMapper.selectById(deductionId);
    }

    public List<DeductionInformation> getAllDeductions() {
        return deductionInformationMapper.selectList(null);
    }

    @Transactional
    public void updateDeduction(DeductionInformation deduction) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            deductionUpdateEmitter.send(deduction).toCompletableFuture().exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，事务管理器将处理事务
            deductionInformationMapper.updateById(deduction);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
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
