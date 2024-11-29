package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.FineInformation;
import finalassignmentbackend.mapper.FineInformationMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

import java.util.Date;
import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class FineInformationService {

    private static final Logger log = Logger.getLogger(String.valueOf(FineInformationService.class));

    @Inject
    @Named("FineInformationMapper")
    FineInformationMapper fineInformationMapper;

    @Inject
    @Channel("fine-events-out")
    Emitter<FineInformation> fineEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "fineCache")
    public void createFine(FineInformation fineInformation) {
        try {
            sendKafkaMessage("fine_create", fineInformation);
            fineInformationMapper.insert(fineInformation);
        } catch (Exception e) {
            log.warning("Exception occurred while creating fine or sending Kafka message");
            throw new RuntimeException("Failed to create fine", e);
        }
    }

    @CacheResult(cacheName = "fineCache")
    public FineInformation getFineById(int fineId) {
        if (fineId <= 0) {
            throw new IllegalArgumentException("Invalid fine ID");
        }
        return fineInformationMapper.selectById(fineId);
    }

    @CacheResult(cacheName = "fineCache")
    public List<FineInformation> getAllFines() {
        return fineInformationMapper.selectList(null);
    }

    @Transactional
    @CacheInvalidate(cacheName = "fineCache")
    public void updateFine(FineInformation fineInformation) {
        try {
            sendKafkaMessage("fine_update", fineInformation);
            fineInformationMapper.updateById(fineInformation);
        } catch (Exception e) {
            log.warning("Exception occurred while updating fine or sending Kafka message");
            throw new RuntimeException("Failed to update fine", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "fineCache")
    public void deleteFine(int fineId) {
        try {
            int result = fineInformationMapper.deleteById(fineId);
            if (result > 0) {
                log.info(String.format("Fine with ID %s deleted successfully", fineId));
            } else {
                log.severe(String.format("Failed to delete fine with ID %s", fineId));
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting fine");
            throw new RuntimeException("Failed to delete fine", e);
        }
    }

    @CacheResult(cacheName = "fineCache")
    public List<FineInformation> getFinesByPayee(String payee) {
        if (payee == null || payee.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid payee");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("payee", payee);
        return fineInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "fineCache")
    public List<FineInformation> getFinesByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("fineTime", startTime, endTime);
        return fineInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "fineCache")
    public FineInformation getFineByReceiptNumber(String receiptNumber) {
        if (receiptNumber == null || receiptNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid receipt number");
        }
        QueryWrapper<FineInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("receiptNumber", receiptNumber);
        return fineInformationMapper.selectOne(queryWrapper);
    }

    private void sendKafkaMessage(String topic, FineInformation fineInformation) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build();
        KafkaRecord<String, FineInformation> record = (KafkaRecord<String, FineInformation>) KafkaRecord.of(fineInformation.getFineId().toString(), fineInformation).addMetadata(metadata);
        fineEmitter.send(record);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
