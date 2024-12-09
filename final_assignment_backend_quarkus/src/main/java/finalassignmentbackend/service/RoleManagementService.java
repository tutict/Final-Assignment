package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.RoleManagement;
import finalassignmentbackend.mapper.RoleManagementMapper;
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
public class RoleManagementService {

    private static final Logger log = Logger.getLogger(RoleManagementService.class.getName());

    @Inject
    RoleManagementMapper roleManagementMapper;

    @Inject
    Event<RoleEvent> roleEvent;

    @Inject
    @Channel("role-events-out")
    MutinyEmitter<RoleManagement> roleEmitter;

    @Getter
    public static class RoleEvent {
        private final RoleManagement role;
        private final String action; // "create" or "update"

        public RoleEvent(RoleManagement role, String action) {
            this.role = role;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "roleCache")
    public void createRole(RoleManagement role) {
        RoleManagement existingRole = roleManagementMapper.selectById(role.getRoleId());
        if (existingRole == null) {
            roleManagementMapper.insert(role);
        } else {
            roleManagementMapper.updateById(role);
        }
        roleEvent.fire(new RoleEvent(role, "create"));
    }

    @Transactional
    @CacheInvalidate(cacheName = "roleCache")
    public void updateRole(RoleManagement role) {
        RoleManagement existingRole = roleManagementMapper.selectById(role.getRoleId());
        if (existingRole == null) {
            roleManagementMapper.insert(role);
        } else {
            roleManagementMapper.updateById(role);
        }
        roleEvent.fire(new RoleEvent(role, "update"));
    }

    @Transactional
    @CacheInvalidate(cacheName = "roleCache")
    public void deleteRole(int roleId) {
        if (roleId <= 0) {
            throw new IllegalArgumentException("Invalid role ID");
        }
        int result = roleManagementMapper.deleteById(roleId);
        if (result > 0) {
            log.info(String.format("Role with ID %s deleted successfully", roleId));
        } else {
            log.severe(String.format("Failed to delete role with ID %s", roleId));
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

    @CacheResult(cacheName = "roleCache")
    public RoleManagement getRoleById(int roleId) {
        if (roleId <= 0) {
            throw new IllegalArgumentException("Invalid role ID");
        }
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

    public void onRoleEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) RoleEvent event) {
        String topic = event.getAction().equals("create") ? "role_processed_create" : "role_processed_update";
        sendKafkaMessage(topic, event.getRole());
    }

    private void sendKafkaMessage(String topic, RoleManagement role) {
        OutgoingKafkaRecordMetadata<String> metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<RoleManagement> message = Message.of(role).addMetadata(metadata);

        roleEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}
