package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.OffenseInformationMapper;
import finalassignmentbackend.entity.OffenseInformation;
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
public class OffenseInformationService {

    private static final Logger log = LoggerFactory.getLogger(OffenseInformationService.class);

    @Inject
    OffenseInformationMapper offenseInformationMapper;

    @Inject
    @Channel("offense_create")
    Emitter<OffenseInformation> offenseCreateEmitter;

    @Inject
    @Channel("offense_update")
    Emitter<OffenseInformation> offenseUpdateEmitter;

    @Transactional
    public void createOffense(OffenseInformation offenseInformation) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            offenseCreateEmitter.send(offenseInformation).toCompletableFuture().exceptionally(ex -> {

                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            offenseInformationMapper.insert(offenseInformation);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    public OffenseInformation getOffenseByOffenseId(int offenseId) {
        return offenseInformationMapper.selectById(offenseId);
    }

    public List<OffenseInformation> getOffensesInformation() {
        return offenseInformationMapper.selectList(null);
    }

    @Transactional
    public void updateOffense(OffenseInformation offenseInformation) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            offenseUpdateEmitter.send(offenseInformation).toCompletableFuture().exceptionally(ex -> {

                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            offenseInformationMapper.updateById(offenseInformation);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
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
