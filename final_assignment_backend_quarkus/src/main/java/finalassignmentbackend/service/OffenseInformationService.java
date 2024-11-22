package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.mapper.OffenseInformationMapper;
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
import java.util.Date;
import java.util.List;

@ApplicationScoped
public class OffenseInformationService {

    private static final Logger log = Logger.getLogger(OffenseInformationService.class);

    @Inject
    OffenseInformationMapper offenseInformationMapper;

    @Inject
    @Channel("offense-events-out")
    Emitter<OffenseInformation> offenseEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "offenseCache")
    public void createOffense(OffenseInformation offenseInformation) {
        try {
            sendKafkaMessage("offense_create", offenseInformation);
            offenseInformationMapper.insert(offenseInformation);
        } catch (Exception e) {
            log.error("Exception occurred while creating offense or sending Kafka message", e);
            throw new RuntimeException("Failed to create offense", e);
        }
    }

    @CacheResult(cacheName = "offenseCache")
    public OffenseInformation getOffenseByOffenseId(int offenseId) {
        return offenseInformationMapper.selectById(offenseId);
    }

    @CacheResult(cacheName = "offenseCache")
    public List<OffenseInformation> getOffensesInformation() {
        return offenseInformationMapper.selectList(null);
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseCache")
    public void updateOffense(OffenseInformation offenseInformation) {
        try {
            sendKafkaMessage("offense_update", offenseInformation);
            offenseInformationMapper.updateById(offenseInformation);
        } catch (Exception e) {
            log.error("Exception occurred while updating offense or sending Kafka message", e);
            throw new RuntimeException("Failed to update offense", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "offenseCache")
    public void deleteOffense(int offenseId) {
        try {
            if (offenseId <= 0) {
                throw new IllegalArgumentException("Invalid offense ID");
            }
            int result = offenseInformationMapper.deleteById(offenseId);
            if (result > 0) {
                log.info("Offense with ID {} deleted successfully");
            } else {
                log.error("Failed to delete offense with ID {}");
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting offense", e);
            throw new RuntimeException("Failed to delete offense", e);
        }
    }

    @CacheResult(cacheName = "offenseCache")
    public List<OffenseInformation> getOffensesByTimeRange(Date startTime, Date endTime) {
        if (startTime == null || endTime == null || startTime.after(endTime)) {
            throw new IllegalArgumentException("Invalid time range");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.between("offense_time", startTime, endTime);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "offenseCache")
    public List<OffenseInformation> getOffensesByProcessState(String processState) {
        if (processState == null || processState.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid process state");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("process_status", processState);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "offenseCache")
    public List<OffenseInformation> getOffensesByDriverName(String driverName) {
        if (driverName == null || driverName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid driver name");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_name", driverName);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "offenseCache")
    public List<OffenseInformation> getOffensesByLicensePlate(String offenseLicensePlate) {
        if (offenseLicensePlate == null || offenseLicensePlate.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid license plate");
        }
        QueryWrapper<OffenseInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("license_plate", offenseLicensePlate);
        return offenseInformationMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, OffenseInformation offenseInformation) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build();
        KafkaRecord<String, OffenseInformation> record = (KafkaRecord<String, OffenseInformation>) KafkaRecord.of(offenseInformation.getOffenseId().toString(), offenseInformation).addMetadata(metadata);
        offenseEmitter.send(record);
        log.info("Message sent to Kafka topic {} successfully");
    }
}
