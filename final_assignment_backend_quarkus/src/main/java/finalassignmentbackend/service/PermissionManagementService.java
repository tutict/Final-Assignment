package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.PermissionManagement;
import finalassignmentbackend.mapper.PermissionManagementMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.mutiny.Uni;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.List;
import java.util.concurrent.CompletionStage;
import java.util.logging.Logger;

@ApplicationScoped
public class PermissionManagementService {

    private static final Logger log = Logger.getLogger(PermissionManagementService.class.getName());

    @Inject
    PermissionManagementMapper permissionManagementMapper;

    @Inject
    @Channel("permission-events-out")
    MutinyEmitter<PermissionManagement> permissionEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "permissionCache")
    public void createPermission(PermissionManagement permission) {
        try {
            sendKafkaMessage("permission_create", permission);
            permissionManagementMapper.insert(permission);
        } catch (Exception e) {
            log.warning("Exception occurred while creating permission or sending Kafka message");
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
            log.warning("Exception occurred while updating permission or sending Kafka message");
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
                    log.info(String.format("Permission with ID %s deleted successfully", permissionId));
                } else {
                    log.severe(String.format("Failed to delete permission with ID %s", permissionId));
                }
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting permission");
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
                log.info(String.format("Permission with name '%s' deleted successfully", permissionName));
            } else {
                log.severe(String.format("Failed to delete permission with name '%s'", permissionName));
            }
        }
    }

    private void sendKafkaMessage(String topic, PermissionManagement permission) {
        // 创建包含目标主题的元数据
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        // 创建包含负载和元数据的消息
        Message<PermissionManagement> message = Message.of(permission).addMetadata(metadata);

        // 使用 MutinyEmitter 的 sendMessage 方法返回 Uni<Void>
        Uni<Void> uni = permissionEmitter.sendMessage(message);

        // 将 Uni<Void> 转换为 CompletionStage<Void>
        CompletionStage<Void> sendStage = uni.subscribe().asCompletionStage();

        sendStage.whenComplete((ignored, throwable) -> {
            if (throwable != null) {
                log.severe(String.format("Failed to send message to Kafka topic %s: %s", topic, throwable.getMessage()));
            } else {
                log.info(String.format("Message sent to Kafka topic %s successfully", topic));
            }
        });
    }
}
