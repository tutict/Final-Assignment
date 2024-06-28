package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.AppealManagementMapper;
import finalassignmentbackend.mapper.OffenseInformationMapper;
import finalassignmentbackend.entity.AppealManagement;
import finalassignmentbackend.entity.OffenseInformation;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

@ApplicationScoped
public class AppealManagementService {

    private static final Logger log = LoggerFactory.getLogger(AppealManagementService.class);

    @Inject
    AppealManagementMapper appealManagementMapper;

    @Inject
    OffenseInformationMapper offenseInformationMapper;

    @Inject
    @Channel("appeal_create")
    Emitter<AppealManagement> appealCreateEmitter;

    @Inject
    @Channel("appeal_updated")
    Emitter<AppealManagement> appealUpdatedEmitter;


    @Transactional
    public void createAppeal(AppealManagement appeal) {
        try {
                // 异步发送消息到 Kafka，并处理发送结果
                appealCreateEmitter.send(appeal).toCompletableFuture().exceptionally(ex -> {
                    // 处理发送失败的情况
                    log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                    // 抛出异常
                    throw new RuntimeException("Kafka message send failure", ex);
                });

                // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
                appealManagementMapper.insert(appeal);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    public AppealManagement getAppealById(Long appealId) {
        return appealManagementMapper.selectById(appealId);
    }

    public List<AppealManagement> getAllAppeals() {
        return appealManagementMapper.selectList(null);
    }

    @Transactional
    public void updateAppeal(AppealManagement appeal) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            appealUpdatedEmitter.send(appeal).toCompletableFuture().exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            appealManagementMapper.updateById(appeal);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
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
