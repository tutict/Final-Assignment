package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.PermissionManagementMapper;
import finalassignmentbackend.entity.PermissionManagement;
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
public class PermissionManagementService {

    private static final Logger log = Logger.getLogger(PermissionManagementService.class);

    @Inject
    PermissionManagementMapper permissionManagementMapper;

    @Inject
    @Channel("permission-events-out")
    Emitter<PermissionManagement> permissionEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "permissionCache")
    public void createPermission(PermissionManagement permission) {
        try {
            sendKafkaMessage("permission_create", permission);
            permissionManagementMapper.insert(permission);
        } catch (Exception e) {
            log.error("Exception occurred while creating permission or sending Kafka message", e);
            throw new RuntimeException("Failed to create permission", e);
        }
    }

    @CacheResult(cacheName = "permissionCache")
    public PermissionManagement getPermissionById(int permissionId) {
        return permissionManagementMapper.selectById(permissionId);
    }

    @CacheResult(cacheName = "permissionCache")
    public List<PermissionManagement> getAllPermissions() {
        return permissionManagementMapper.selectList(null);
    }

    @CacheResult(cacheName = "permissionCache")
    public PermissionManagement getPermissionByName(String permissionName) {
        if (permissionName == null || permissionName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid permission name");
        }
        QueryWrapper<PermissionManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("permission_name", permissionName);
        return permissionManagementMapper.selectOne(queryWrapper);
    }

    @CacheResult(cacheName = "permissionCache")
    public List<PermissionManagement> getPermissionsByNameLike(String permissionName) {
        if (permissionName == null || permissionName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid permission name");
        }
        QueryWrapper<PermissionManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("permission_name", permissionName);
        return permissionManagementMapper.selectList(queryWrapper);
    }

    @Transactional
    @CacheInvalidate(cacheName = "permissionCache")
    public void updatePermission(PermissionManagement permission) {
        try {
            sendKafkaMessage("permission_update", permission);
            permissionManagementMapper.updateById(permission);
        } catch (Exception e) {
            log.error("Exception occurred while updating permission or sending Kafka message", e);
            throw new RuntimeException("Failed to update permission", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "permissionCache")
    public void deletePermission(int permissionId) {
        try {
            PermissionManagement permissionToDelete = permissionManagementMapper.selectById(permissionId);
            if (permissionToDelete != null) {
                int result = permissionManagementMapper.deleteById(permissionId);
                if (result > 0) {
                    log.info("Permission with ID {} deleted successfully");
                } else {
                    log.error("Failed to delete permission with ID {}");
                }
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting permission", e);
            throw new RuntimeException("Failed to delete permission", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "permissionCache")
    public void deletePermissionByName(String permissionName) {
        if (permissionName == null || permissionName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid permission name");
        }
        QueryWrapper<PermissionManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("permission_name", permissionName);
        PermissionManagement permissionToDelete = permissionManagementMapper.selectOne(queryWrapper);
        if (permissionToDelete != null) {
            int result = permissionManagementMapper.delete(queryWrapper);
            if (result > 0) {
                log.info("Permission with name '{}' deleted successfully");
            } else {
                log.error("Failed to delete permission with name '{}'");
            }
        }
    }

    private void sendKafkaMessage(String topic, PermissionManagement permission) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build();
        KafkaRecord<String, PermissionManagement> record = (KafkaRecord<String, PermissionManagement>) KafkaRecord.of(permission.getPermissionId().toString(), permission).addMetadata(metadata);
        permissionEmitter.send(record);
        log.info("Message sent to Kafka topic {} successfully");
    }
}
