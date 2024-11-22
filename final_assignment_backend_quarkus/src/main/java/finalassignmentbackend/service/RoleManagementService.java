package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.oracle.svm.core.annotate.Inject;
import finalassignmentbackend.mapper.RoleManagementMapper;
import finalassignmentbackend.entity.RoleManagement;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import org.jboss.logging.Logger;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;

@ApplicationScoped
public class RoleManagementService {

    private static final Logger log = Logger.getLogger(RoleManagementService.class);

    @Inject
    RoleManagementMapper roleManagementMapper;

    @Inject
    @Channel("role-events-out")
    Emitter<RoleManagement> roleEmitter;

    @Transactional
    @CacheInvalidate(cacheName = "roleCache")
    public void createRole(RoleManagement role) {
        try {
            sendKafkaMessage("role_create", role);
            roleManagementMapper.insert(role);
        } catch (Exception e) {
            log.error("Exception occurred while creating role or sending Kafka message", e);
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
            log.error("Exception occurred while updating role or sending Kafka message", e);
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
                    log.info("Role with ID {} deleted successfully");
                } else {
                    log.error("Failed to delete role with ID {}");
                }
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting role", e);
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
                log.info("Role with name '{}' deleted successfully");
            } else {
                log.error("Failed to delete role with name '{}'");
            }
        }
    }

    private void sendKafkaMessage(String topic, RoleManagement role) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build();
        KafkaRecord<String, RoleManagement> record = (KafkaRecord<String, RoleManagement>) KafkaRecord.of(role.getRoleId().toString(), role).addMetadata(metadata);
        roleEmitter.send(record);
        log.info("Message sent to Kafka topic {} successfully");
    }
}
