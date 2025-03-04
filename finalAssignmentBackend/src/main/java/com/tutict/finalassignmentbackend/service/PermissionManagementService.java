package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.config.websocket.WsAction;
import com.tutict.finalassignmentbackend.entity.RequestHistory;
import com.tutict.finalassignmentbackend.mapper.PermissionManagementMapper;
import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import com.tutict.finalassignmentbackend.mapper.RequestHistoryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.logging.Logger;

@Service
public class PermissionManagementService {

    private static final Logger log = Logger.getLogger(PermissionManagementService.class.getName());

    private final PermissionManagementMapper permissionManagementMapper;
    private final RequestHistoryMapper requestHistoryMapper;
    private final KafkaTemplate<String, PermissionManagement> kafkaTemplate;

    @Autowired
    public PermissionManagementService(PermissionManagementMapper permissionManagementMapper,
                                       RequestHistoryMapper requestHistoryMapper,
                                       KafkaTemplate<String, PermissionManagement> kafkaTemplate) {
        this.permissionManagementMapper = permissionManagementMapper;
        this.requestHistoryMapper = requestHistoryMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    @CacheEvict(cacheNames = "permissionCache", allEntries = true)
    @WsAction(service = "PermissionManagementService", action = "checkAndInsertIdempotency")
    public void checkAndInsertIdempotency(String idempotencyKey, PermissionManagement permissionManagement, String action) {
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

        sendKafkaMessage("permission_" + action, permissionManagement);

        Integer permissionId = permissionManagement.getPermissionId();
        newRequest.setBusinessStatus("SUCCESS");
        newRequest.setBusinessId(permissionId != null ? permissionId.longValue() : null);
        requestHistoryMapper.updateById(newRequest);
    }

    @Transactional
    @CacheEvict(cacheNames = "permissionCache", allEntries = true)
    public void createPermission(PermissionManagement permission) {
        PermissionManagement existingPermission = permissionManagementMapper.selectById(permission.getPermissionId());
        if (existingPermission == null) {
            permissionManagementMapper.insert(permission);
        } else {
            permissionManagementMapper.updateById(permission);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "permissionCache", allEntries = true)
    public void updatePermission(PermissionManagement permission) {
        PermissionManagement existingPermission = permissionManagementMapper.selectById(permission.getPermissionId());
        if (existingPermission == null) {
            permissionManagementMapper.insert(permission);
        } else {
            permissionManagementMapper.updateById(permission);
        }
    }

    @Transactional
    @CacheEvict(cacheNames = "permissionCache", allEntries = true)
    @WsAction(service = "permissionManagementService", action = "deletePermission")
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
    @CacheEvict(cacheNames = "permissionCache", allEntries = true)
    @WsAction(service = "permissionManagementService", action = "deletePermissionByName")
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

    @Cacheable(cacheNames = "permissionCache")
    @WsAction(service = "PermissionManagementService", action = "getPermissionById")
    public PermissionManagement getPermissionById(Integer permissionId) {
        if (permissionId == null || permissionId <= 0 || permissionId >= Integer.MAX_VALUE) {
            throw new IllegalArgumentException("Invalid permission ID" + permissionId);
        }
        return permissionManagementMapper.selectById(permissionId);
    }

    @Cacheable(cacheNames = "permissionCache")
    @WsAction(service = "PermissionManagementService", action = "getAllPermissions")
    public List<PermissionManagement> getAllPermissions() {
        return permissionManagementMapper.selectList(null);
    }

    @Cacheable(cacheNames = "permissionCache")
    @WsAction(service = "PermissionManagementService", action = "getPermissionByName")
    public PermissionManagement getPermissionByName(String permissionName) {
        if (permissionName == null || permissionName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid permission name");
        }
        QueryWrapper<PermissionManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("permission_name", permissionName);
        return permissionManagementMapper.selectOne(queryWrapper);
    }

    @Cacheable(cacheNames = "permissionCache")
    @WsAction(service = "PermissionManagementService", action = "getPermissionsByNameLike")
    public List<PermissionManagement> getPermissionsByNameLike(String permissionName) {
        if (permissionName == null || permissionName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid permission name");
        }
        QueryWrapper<PermissionManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("permission_name", permissionName);
        return permissionManagementMapper.selectList(queryWrapper);
    }

    private void sendKafkaMessage(String topic, PermissionManagement permission) {
        kafkaTemplate.send(topic, permission);
        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }
}