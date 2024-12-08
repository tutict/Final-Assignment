package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.RoleManagement;
import finalassignmentbackend.mapper.RoleManagementMapper;
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
public class RoleManagementService {

    private static final Logger log = Logger.getLogger(RoleManagementService.class.getName());

    @Inject
    RoleManagementMapper roleManagementMapper;

    @Inject
    @Channel("role-events-out")
    MutinyEmitter<RoleManagement> roleEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "roleCache")
    public void createRole(RoleManagement role) {
        try {
            sendKafkaMessage("role_create", role);
            roleManagementMapper.insert(role);
        } catch (Exception e) {
            log.warning("Exception occurred while creating role or sending Kafka message");
            throw new RuntimeException("Failed to create role", e);
        }
    }

    @CacheResult(cacheName = "roleCache")
    public RoleManagement getRoleById(int roleId) {
        return roleManagementMapper.selectById(roleId);
    }

    @CacheResult(cacheName = "roleCache")
    public List<RoleManagement> getAllRoles() {
        return roleManagementMapper.selectList(null);
    }

    @CacheResult(cacheName = "roleCache")
    public RoleManagement getRoleByName(String roleName) {
        if (roleName == null || roleName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid role name");
        }
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("role_name", roleName);
        return roleManagementMapper.selectOne(queryWrapper);
    }

    @CacheResult(cacheName = "roleCache")
    public List<RoleManagement> getRolesByNameLike(String roleName) {
        if (roleName == null || roleName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid role name");
        }
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("role_name", roleName);
        return roleManagementMapper.selectList(queryWrapper);
    }

    @Transactional
    @CacheInvalidate(cacheName = "roleCache")
    public void updateRole(RoleManagement role) {
        try {
            sendKafkaMessage("role_update", role);
            roleManagementMapper.updateById(role);
        } catch (Exception e) {
            log.warning("Exception occurred while updating role or sending Kafka message");
            throw new RuntimeException("Failed to update role", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "roleCache")
    public void deleteRole(int roleId) {
        try {
            RoleManagement roleToDelete = roleManagementMapper.selectById(roleId);
            if (roleToDelete != null) {
                int result = roleManagementMapper.deleteById(roleId);
                if (result > 0) {
                    log.info(String.format("Role with ID %s deleted successfully", roleId));
                } else {
                    log.severe(String.format("Failed to delete role with ID %s", roleId));
                }
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting role");
            throw new RuntimeException("Failed to delete role", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "roleCache")
    public void deleteRoleByName(String roleName) {
        if (roleName == null || roleName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid role name");
        }
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("role_name", roleName);
        RoleManagement roleToDelete = roleManagementMapper.selectOne(queryWrapper);
        if (roleToDelete != null) {
            int result = roleManagementMapper.delete(queryWrapper);
            if (result > 0) {
                log.info(String.format("Role with name '%s' deleted successfully", roleName));
            } else {
                log.severe(String.format("Failed to delete role with name '%s'", roleName));
            }
        }
    }

    private void sendKafkaMessage(String topic, RoleManagement role) {
        // 创建包含目标主题的元数据
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        // 创建包含负载和元数据的消息
        Message<RoleManagement> message = Message.of(role).addMetadata(metadata);

        // 使用 MutinyEmitter 的 sendMessage 方法返回 Uni<Void>
        Uni<Void> uni = roleEmitter.sendMessage(message);

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
