package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.entity.DeductionInformation;
import finalassignmentbackend.mapper.DeductionInformationMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class DeductionInformationService {

    private static final Logger log = Logger.getLogger(String.valueOf(DeductionInformationService.class));

    @Inject
    DeductionInformationMapper deductionInformationMapper;

    @Inject
    @Channel("deduction-events-out")
    Emitter<DeductionInformation> deductionEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "deductionCache")
    public void createDeduction(DeductionInformation deduction) {
        try {
            sendKafkaMessage("deduction_create", deduction);
            deductionInformationMapper.insert(deduction);
        } catch (Exception e) {
            log.warning("Exception occurred while creating deduction or sending Kafka message");
            throw new RuntimeException("Failed to create deduction", e);
        }
    }

    @CacheResult(cacheName = "deductionCache")
    public DeductionInformation getDeductionById(int deductionId) {
        if (deductionId <= 0) {
            throw new IllegalArgumentException("Invalid deduction ID");
        }
        return deductionInformationMapper.selectById(deductionId);
    }

    @CacheResult(cacheName = "deductionCache")
    public List<DeductionInformation> getAllDeductions() {
        return deductionInformationMapper.selectList(null);
    }

    @Transactional
    @CacheInvalidate(cacheName = "deductionCache")
    public void updateDeduction(DeductionInformation deduction) {
        try {
            sendKafkaMessage("deduction_update", deduction);
            deductionInformationMapper.updateById(deduction);
        } catch (Exception e) {
            log.warning("Exception occurred while updating deduction or sending Kafka message");
            throw new RuntimeException("Failed to update deduction", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "deductionCache")
    public void deleteDeduction(int deductionId) {
        try {
            int result = deductionInformationMapper.deleteById(deductionId);
            if (result > 0) {
                log.info(String.format("Deduction with ID %s deleted successfully", deductionId));
            } else {
                log.severe(String.format("Failed to delete deduction with ID %s", deductionId));
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting deduction");
            throw new RuntimeException("Failed to delete deduction", e);
        }
    }

    @CacheResult(cacheName = "deductionCache")
    public List<DeductionInformation> getDeductionsByHandler(String handler) {
        if (handler == null || handler.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid handler");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("handler", handler);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "deductionCache")
    public List<DeductionInformation> getDeductionsByByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<DeductionInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("deductionTime", startTime, endTime);
        return deductionInformationMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, DeductionInformation deduction) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build();
        KafkaRecord<String, DeductionInformation> record = (KafkaRecord<String, DeductionInformation>) KafkaRecord.of(deduction.getDeductionId().toString(), deduction).addMetadata(metadata);
        deductionEmitter.send(record);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
