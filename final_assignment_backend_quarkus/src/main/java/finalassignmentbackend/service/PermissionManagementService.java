package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.PermissionManagement;
import finalassignmentbackend.entity.RequestHistory;
import finalassignmentbackend.mapper.PermissionManagementMapper;
import finalassignmentbackend.mapper.RequestHistoryMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Event;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.event.TransactionPhase;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import lombok.Getter;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class PermissionManagementService {

    private static final Logger log = Logger.getLogger(PermissionManagementService.class.getName());

    @Inject
    PermissionManagementMapper permissionManagementMapper;

    @Inject
    RequestHistoryMapper requestHistoryMapper;

    @Inject
    Event<PermissionEvent> permissionEvent;

    @Inject
    @Channel("permission-events-out")
    MutinyEmitter<PermissionManagement> permissionEmitter;

    @Getter
    public static class PermissionEvent {
        private final PermissionManagement permission;
        private final String action; // "create" or "update"

        public PermissionEvent(PermissionManagement permission, String action) {
            this.permission = permission;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "permissionCache")
    public void checkAndInsertIdempotency(String idempotencyKey, PermissionManagement permissionManagement, String action) {
        // 查询 request_history
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            // 已有此 key -> 重复请求
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        // 不存在 -> 插入一条 PROCESSING
        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
        } catch (Exception e) {
            // 若并发下同 key 导致唯一索引冲突
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        permissionEvent.fire(new PermissionManagementService.PermissionEvent(permissionManagement, action));

        Integer permissionId = permissionManagement.getPermissionId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(permissionId);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheInvalidate(cacheName = "permissionCache")
    public void createPermission(PermissionManagement permission) {
        PermissionManagement existingPermission = permissionManagementMapper.selectById(permission.getPermissionId());
        if (existingPermission == null) {
            permissionManagementMapper.insert(permission);
        } else {
            permissionManagementMapper.updateById(permission);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "permissionCache")
    public void updatePermission(PermissionManagement permission) {
        PermissionManagement existingPermission = permissionManagementMapper.selectById(permission.getPermissionId());
        if (existingPermission == null) {
            permissionManagementMapper.insert(permission);
        } else {
            permissionManagementMapper.updateById(permission);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "permissionCache")
    public void deletePermission(int permissionId) {
        if (permissionId <= 0) {
            throw new IllegalArgumentException("Invalid permission ID");
        }
        int result = permissionManagementMapper.deleteById(permissionId);
        if (result > 0) {
            log.info(String.format("Permission with ID %s deleted successfully", permissionId));
        } else {
            log.severe(String.format("Failed to delete permission with ID %s", permissionId));
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

    @CacheResult(cacheName = "permissionCache")
    public PermissionManagement getPermissionById(Integer permissionId) {
        if (permissionId == null || permissionId <= 0 || permissionId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid permission ID" + permissionId);
        }
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

    public void onPermissionEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) PermissionEvent event) {
        String topic = event.getAction().equals("create") ? "permission_processed_create" : "permission_processed_update";
        sendKafkaMessage(topic, event.getPermission());
    }

    private void sendKafkaMessage(String topic, PermissionManagement permission) {
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<PermissionManagement> message = Message.of(permission).addMetadata(metadata);

        permissionEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
