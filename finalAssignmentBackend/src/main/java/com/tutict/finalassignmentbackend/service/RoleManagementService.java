package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.entity.UserRole;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.RoleManagementMapper;
import com.tutict.finalassignmentbackend.entity.RoleManagement;
import com.tutict.finalassignmentbackend.mapper.UserRoleMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.logging.Logger;

@Service
public class RoleManagementService {

    private static final Logger log = Logger.getLogger(RoleManagementService.class.getName());

    private final RoleManagementMapper roleManagementMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final UserRoleMapper userRoleMapper;
    private final KafkaTemplate<String, RoleManagement> kafkaTemplate;

    @Autowired
    public RoleManagementService(RoleManagementMapper roleManagementMapper,
                                 RequestHistoryMapper requestHistoryMapper, UserRoleMapper userRoleMapper,
                                 KafkaTemplate<String, RoleManagement> kafkaTemplate) {
        this.roleManagementMapper = roleManagementMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.userRoleMapper = userRoleMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "roleCache", allEntries = true)
    public void assignRole(int userId, int roleId) {
        if (userId <= 0 || roleId <= 0) {
            throw new IllegalArgumentException("Invalid user ID or role ID");
        }
        UserRole userRole = new UserRole();
        userRole.setUserId(userId);
        userRole.setRoleId(roleId);
        try {
            userRoleMapper.insert(userRole);
            log.info(String.format("Role %d assigned to user %d successfully", roleId, userId));
        } catch (Exception e) {
            log.severe(String.format("Failed to assign role %d to user %d: %s", roleId, userId, e.getMessage()));
            throw new RuntimeException("Role assignment failed", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "roleCache", allEntries = true)
    @WsAction(service = "RoleManagementService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, RoleManagement roleManagement, String action) {
        RequestHistory existingRequest = requestHistoryMapper.selectByIdempotencyKey(idempotencyKey);
        if (existingRequest != null) {
            log.warning(String.format("Duplicate request detected (idempotencyKey=%s)", idempotencyKey));
            throw new RuntimeException("Duplicate request detected");
        }

        RequestHistory newRequest = new RequestHistory();
        newRequest.setIdempotentKey(idempotencyKey);
        newRequest.setBusinessStatus("PROCESSING");

        try {
            requestHistoryMapper.insert(newRequest);
            sendKafkaMessage("role_" + action, roleManagement);
            newRequest.setBusinessStatus("SUCCESS");
            newRequest.setBusinessId(roleManagement.getRoleId());
            requestHistoryMapper.updateById(newRequest);
        } catch (Exception e) {
            log.severe("Failed to process idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "roleCache", allEntries = true)
    public void createRole(RoleManagement role) {
        RoleManagement existingRole = roleManagementMapper.selectById(role.getRoleId());
        if (existingRole == null) {
            roleManagementMapper.insert(role);
        } else {
            roleManagementMapper.updateById(role);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "roleCache", allEntries = true)
    public void updateRole(RoleManagement role) {
        RoleManagement existingRole = roleManagementMapper.selectById(role.getRoleId());
        if (existingRole == null) {
            roleManagementMapper.insert(role);
        } else {
            roleManagementMapper.updateById(role);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "roleCache", allEntries = true)
    @WsAction(service = "RoleManagementService", action = "deleteRole")
    public void deleteRole(int roleId) {
        if (roleId <= 0) {
            throw new IllegalArgumentException("Invalid role ID");
        }
        int result = roleManagementMapper.deleteById(roleId);
        if (result > 0) {
            log.info(String.format("Role with ID %d deleted successfully", roleId));
        } else {
            log.severe(String.format("Failed to delete role with ID %d", roleId));
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "roleCache", allEntries = true)
    @WsAction(service = "RoleManagementService", action = "deleteRoleByName")
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

    @Cacheable(cacheNames = "roleCache", unless = "#result == null")
    @WsAction(service = "RoleManagementService", action = "getRoleById")
    public RoleManagement getRoleById(Integer roleId) {
        if (roleId == null || roleId <= 0 || roleId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid role ID: " + roleId);
        }
        RoleManagement role = roleManagementMapper.selectById(roleId);
        if (role == null) {
            log.warning(String.format("Role not found for ID: %d", roleId));
        }
        return role;
    }

    @Cacheable(cacheNames = "roleCache", unless = "#result == null || #result.isEmpty()")
    @WsAction(service = "RoleManagementService", action = "getAllRoles")
    public List<RoleManagement> getAllRoles() {
        List<RoleManagement> roles = roleManagementMapper.selectList(null);
        if (roles.isEmpty()) {
            log.warning("No roles found in the system");
        }
        return roles;
    }

    @Cacheable(cacheNames = "roleCache", unless = "#result == null")
    @WsAction(service = "RoleManagementService", action = "getRoleByName")
    public RoleManagement getRoleByName(String roleName) {
        if (roleName == null || roleName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid role name");
        }
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("role_name", roleName);
        RoleManagement role = roleManagementMapper.selectOne(queryWrapper);
        if (role == null) {
            log.warning(String.format("Role not found for name: %s", roleName));
        }
        return role;
    }

    @Cacheable(cacheNames = "roleCache", unless = "#result == null || #result.isEmpty()")
    @WsAction(service = "RoleManagementService", action = "getRolesByNameLike")
    public List<RoleManagement> getRolesByNameLike(String roleName) {
        if (roleName == null || roleName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid role name");
        }
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("role_name", roleName);
        List<RoleManagement> roles = roleManagementMapper.selectList(queryWrapper);
        if (roles.isEmpty()) {
            log.warning(String.format("No roles found matching name: %s", roleName));
        }
        return roles;
    }

    @Cacheable(cacheNames = "roleCache", unless = "#result == null || #result.isEmpty()")
    @WsAction(service = "RoleManagementService", action = "getRolesByUserId")
    public List<RoleManagement> getRolesByUserId(int userId) {
        if (userId <= 0) {
            throw new IllegalArgumentException("Invalid user ID: " + userId);
        }
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.inSql("role_id", "SELECT role_id FROM user_role WHERE user_id = " + userId); // 临时保留
        List<RoleManagement> roles = roleManagementMapper.selectList(queryWrapper);
        if (roles.isEmpty()) {
            log.warning(String.format("No roles found for user ID: %d", userId));
        }
        return roles;
    }

    private void sendKafkaMessage(String topic, RoleManagement role) {
        kafkaTemplate.send(topic, role);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}