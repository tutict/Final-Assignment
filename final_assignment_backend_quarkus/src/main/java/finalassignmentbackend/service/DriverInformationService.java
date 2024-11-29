package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.DriverInformation;
import finalassignmentbackend.mapper.DriverInformationMapper;
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

import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class DriverInformationService {

    private static final Logger log = Logger.getLogger(String.valueOf(DriverInformationService.class));

    @Inject
    @Named("DriverInformationMapper")
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
            log.warning("Exception occurred while creating driver or sending Kafka message");
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
            log.warning("Exception occurred while updating driver or sending Kafka message");
            throw new RuntimeException("Failed to update driver", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "driverCache")
    public void deleteDriver(int driverId) {
        try {
            int result = driverInformationMapper.deleteById(driverId);
            if (result > 0) {
                log.info(String.format("Driver with ID %s deleted successfully", driverId));
            } else {
                log.severe(String.format("Failed to delete driver with ID %s", driverId));
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting driver");
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
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
