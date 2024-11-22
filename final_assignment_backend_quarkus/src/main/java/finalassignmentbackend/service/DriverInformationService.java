package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.DriverInformationMapper;
import finalassignmentbackend.entity.DriverInformation;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import org.jboss.logging.Logger;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import java.util.List;

@ApplicationScoped
public class DriverInformationService {

    private static final Logger log = Logger.getLogger(DriverInformationService.class);

    @Inject
    DriverInformationMapper driverInformationMapper;

    @Inject
    @Channel("driver-events-out")
    Emitter<DriverInformation> driverEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    public void createDriver(DriverInformation driverInformation) {
        try {
            sendKafkaMessage("driver_create", driverInformation);
            driverInformationMapper.insert(driverInformation);
        } catch (Exception e) {
            log.error("Exception occurred while creating driver or sending Kafka message", e);
            throw new RuntimeException("Failed to create driver", e);
        }
    }

    @CacheResult(cacheName = "driverCache")
    public DriverInformation getDriverById(int driverId) {
        return driverInformationMapper.selectById(driverId);
    }

    @CacheResult(cacheName = "driverCache")
    public List<DriverInformation> getAllDrivers() {
        return driverInformationMapper.selectList(null);
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    public void updateDriver(DriverInformation driverInformation) {
        try {
            sendKafkaMessage("driver_update", driverInformation);
            driverInformationMapper.updateById(driverInformation);
        } catch (Exception e) {
            log.error("Exception occurred while updating driver or sending Kafka message", e);
            throw new RuntimeException("Failed to update driver", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    public void deleteDriver(int driverId) {
        try {
            int result = driverInformationMapper.deleteById(driverId);
            if (result > 0) {
                log.info("Driver with ID {} deleted successfully");
            } else {
                log.error("Failed to delete driver with ID {}");
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting driver", e);
            throw new RuntimeException("Failed to delete driver", e);
        }
    }

    @CacheResult(cacheName = "driverCache")
    public List<DriverInformation> getDriversByIdCardNumber(String idCardNumber) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("id_card_number", idCardNumber);
        return driverInformationMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "driverCache")
    public DriverInformation getDriverByDriverLicenseNumber(String driverLicenseNumber) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_license_number", driverLicenseNumber);
        return driverInformationMapper.selectOne(queryWrapper);
    }

    @CacheResult(cacheName = "driverCache")
    public List<DriverInformation> getDriversByName(String name) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("name", name);
        return driverInformationMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, DriverInformation driverInformation) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build();
        KafkaRecord<String, DriverInformation> record = (KafkaRecord<String, DriverInformation>) KafkaRecord.of(driverInformation.getDriverId().toString(), driverInformation).addMetadata(metadata);
        driverEmitter.send(record);
        log.info("Message sent to Kafka topic {} successfully");
    }
}
