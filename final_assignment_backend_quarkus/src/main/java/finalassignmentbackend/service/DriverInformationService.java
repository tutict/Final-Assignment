package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.DriverInformationMapper;
import finalassignmentbackend.entity.DriverInformation;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

@ApplicationScoped
public class DriverInformationService {

    private static final Logger log = LoggerFactory.getLogger(DriverInformationService.class);

    @Inject
    DriverInformationMapper driverInformationMapper;

    @Inject
    @Channel("driver_create")
    Emitter<DriverInformation> driverCreateEmitter;

    @Inject
    @Channel("driver_update")
    Emitter<DriverInformation> driverUpdateEmitter;

    @Transactional
    public void createDriver(DriverInformation driverInformation) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            driverCreateEmitter.send(driverInformation).toCompletableFuture().exceptionally(ex -> {

                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，事务管理器将处理事务
            driverInformationMapper.insert(driverInformation);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    public DriverInformation getDriverById(int driverId) {
        return driverInformationMapper.selectById(driverId);
    }

    public List<DriverInformation> getAllDrivers() {
        return driverInformationMapper.selectList(null);
    }

    @Transactional
    public void updateDriver(DriverInformation driverInformation) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            driverUpdateEmitter.send(driverInformation).toCompletableFuture().exceptionally(ex -> {

                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，事务管理器将处理事务
            driverInformationMapper.updateById(driverInformation);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    public void deleteDriver(int driverId) {
        driverInformationMapper.deleteById(driverId);
    }

    // get driver by id card number
    public List<DriverInformation> getDriversByIdCardNumber(String idCardNumber) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("id_card_number", idCardNumber);
        return driverInformationMapper.selectList(queryWrapper);
    }

    // get driver by driver license number
    public DriverInformation getDriverByDriverLicenseNumber(String driverLicenseNumber) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("driver_license_number", driverLicenseNumber);
        return driverInformationMapper.selectOne(queryWrapper);
    }

    // get driver by name
    public List<DriverInformation> getDriversByName(String Name) {
        QueryWrapper<DriverInformation> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("name", Name);
        return driverInformationMapper.selectList(queryWrapper);
    }
}
