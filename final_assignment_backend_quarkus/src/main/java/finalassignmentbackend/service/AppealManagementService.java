package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.mapper.AppealManagementMapper;
import finalassignmentbackend.mapper.OffenseInformationMapper;
import finalassignmentbackend.entity.AppealManagement;
import finalassignmentbackend.entity.OffenseInformation;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import org.jboss.logging.Logger;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;

@ApplicationScoped
public class AppealManagementService {

    private static final Logger log = Logger.getLogger(AppealManagementService.class);

    @Inject
    AppealManagementMapper appealManagementMapper;

    @Inject
    OffenseInformationMapper offenseInformationMapper;

    @Inject
    @Channel("appeal-events-out")
    Emitter<AppealManagement> appealEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public void createAppeal(AppealManagement appeal) {
        try {
            sendKafkaMessage("appeal_create", appeal);
            appealManagementMapper.insert(appeal);
        } catch (Exception e) {
            log.error("Exception occurred while creating appeal or sending Kafka message", e);
            throw new RuntimeException("Failed to create appeal", e);
        }
    }

    @CacheResult(cacheName = "appealCache")
    public AppealManagement getAppealById(Integer appealId) {
        return appealManagementMapper.selectById(appealId);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealManagement> getAllAppeals() {
        return appealManagementMapper.selectList(null);
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public void updateAppeal(AppealManagement appeal) {
        try {
            sendKafkaMessage("appeal_updated", appeal);
            appealManagementMapper.updateById(appeal);
        } catch (Exception e) {
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            throw new RuntimeException("Failed to update appeal", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "appealCache")
    public void deleteAppeal(Integer appealId) {
        try {
            AppealManagement appeal = appealManagementMapper.selectById(appealId);
            if (appeal == null) {
                log.warn("Appeal with ID {} not found, cannot delete");
                return;
            }
            int result = appealManagementMapper.deleteById(appealId);
            if (result > 0) {
                log.info("Appeal with ID {} deleted successfully");
            } else {
                log.error("Failed to delete appeal with ID {}");
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting appeal", e);
            throw new RuntimeException("Failed to delete appeal", e);
        }
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealManagement> getAppealsByProcessStatus(String processStatus) {
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processStatus);
        return appealManagementMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "appealCache")
    public List<AppealManagement> getAppealsByAppealName(String appealName) {
        QueryWrapper<AppealManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("appeal_name", appealName);
        return appealManagementMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "appealCache")
    public OffenseInformation getOffenseByAppealId(Integer appealId) {
        AppealManagement appeal = appealManagementMapper.selectById(appealId);
        if (appeal != null) {
            return offenseInformationMapper.selectById(appeal.getOffenseId());
        } else {
            log.warn("No appeal found with ID: {}");
            return null;
        }
    }

    private void sendKafkaMessage(String topic, AppealManagement appeal) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build();
        KafkaRecord<String, AppealManagement> record = (KafkaRecord<String, AppealManagement>) KafkaRecord.of(topic, appeal).addMetadata(metadata);
        appealEmitter.send(record);
        log.info("Message sent to Kafka topic {} successfully");
    }
}
