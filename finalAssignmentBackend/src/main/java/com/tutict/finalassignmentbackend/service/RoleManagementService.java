package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import com.tutict.finalassignmentbackend.mapper.RoleManagementMapper;
import com.tutict.finalassignmentbackend.entity.RoleManagement;
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
    private final KafkaTemplate<String, RoleManagement> kafkaTemplate;

    @Autowired
    public RoleManagementService(RoleManagementMapper roleManagementMapper,
                                 RequestHistoryMapper requestHistoryMapper,
                                 KafkaTemplate<String, RoleManagement> kafkaTemplate) {
        this.roleManagementMapper = roleManagementMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "roleCache", allEntries = true)
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
        } catch (Exception e) {
            log.severe("Failed to insert requestHistory for idempotencyKey=" + idempotencyKey + ", " + e.getMessage());
            throw new RuntimeException("Duplicate request or DB insert error", e);
        }

        sendKafkaMessage("role_" + action, roleManagement);

        Integer roleId = roleManagement.getRoleId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(roleId);
        requestHistoryMapper.updateById(newRequest);
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
    @CacheEvict(cacheNames = "roleCache", allEntries = true)
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

    @Cacheable(cacheNames = "roleCache")
    public RoleManagement getRoleById(Integer roleId) {
        if (roleId == null || roleId <= 0 || roleId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid role ID" + roleId);
        }
        return roleManagementMapper.selectById(roleId);
    }

    @Cacheable(cacheNames = "roleCache")
    public List<RoleManagement> getAllRoles() {
        return roleManagementMapper.selectList(null);
    }

    @Cacheable(cacheNames = "roleCache")
    public RoleManagement getRoleByName(String roleName) {
        if (roleName == null || roleName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid role name");
        }
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("role_name", roleName);
        return roleManagementMapper.selectOne(queryWrapper);
    }

    @Cacheable(cacheNames = "roleCache")
    public List<RoleManagement> getRolesByNameLike(String roleName) {
        if (roleName == null || roleName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid role name");
        }
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("role_name", roleName);
        return roleManagementMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, RoleManagement role) {
        kafkaTemplate.send(topic, role);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}