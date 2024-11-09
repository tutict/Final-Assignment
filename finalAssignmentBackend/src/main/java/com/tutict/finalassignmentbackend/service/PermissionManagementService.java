package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.PermissionManagementMapper;
import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PermissionManagementService {

    // 日志记录器
    private static final Logger log = LoggerFactory.getLogger(PermissionManagementService.class);

    // 权限管理的数据库操作接口
    private final PermissionManagementMapper permissionManagementMapper;
    // Kafka消息模板，用于发送消息
    private final KafkaTemplate<String, PermissionManagement> kafkaTemplate;

    // 构造函数，通过DI注入必要的组件
    @Autowired
    public PermissionManagementService(PermissionManagementMapper permissionManagementMapper, KafkaTemplate<String, PermissionManagement> kafkaTemplate) {
        this.permissionManagementMapper = permissionManagementMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    /**
     * 创建权限
     * @param permission 待创建的权限对象
     */
    @Transactional
    @CacheEvict(value = "permissionCache", key = "#permission.permissionId")
    public void createPermission(PermissionManagement permission) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("permission_create", permission);
            // 数据库插入
            permissionManagementMapper.insert(permission);
        } catch (Exception e) {
            log.error("Exception occurred while creating permission or sending Kafka message", e);
            throw new RuntimeException("Failed to create permission", e);
        }
    }

    /**
     * 根据权限ID查询权限
     * @param permissionId 权限ID
     * @return 查询到的权限对象，如果不存在则返回null
     */
    @Cacheable(value = "permissionCache", key = "#permissionId")
    public PermissionManagement getPermissionById(int permissionId) {
        return permissionManagementMapper.selectById(permissionId);
    }

    /**
     * 查询所有权限
     * @return 所有权限的列表
     */
    @Cacheable(value = "permissionCache", key = "'allPermissions'")
    public List<PermissionManagement> getAllPermissions() {
        return permissionManagementMapper.selectList(null);
    }

    /**
     * 根据权限名称查询权限
     * @param permissionName 权限名称
     * @return 查询到的权限对象，如果不存在则返回null
     * @throws IllegalArgumentException 如果权限名称为空，则抛出此异常
     */
    @Cacheable(value = "permissionCache", key = "#root.methodName + '_' + #permissionName")
    public PermissionManagement getPermissionByName(String permissionName) {
        if (permissionName == null || permissionName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid permission name");
        }
        QueryWrapper<PermissionManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("permission_name", permissionName);
        return permissionManagementMapper.selectOne(queryWrapper);
    }

    /**
     * 根据权限名称模糊查询权限
     * @param permissionName 权限名称的部分字符串
     * @return 模糊查询到的所有权限列表
     * @throws IllegalArgumentException 如果权限名称为空，则抛出此异常
     */
    @Cacheable(value = "permissionCache", key = "#root.methodName + '_' + #permissionName")
    public List<PermissionManagement> getPermissionsByNameLike(String permissionName) {
        if (permissionName == null || permissionName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid permission name");
        }
        QueryWrapper<PermissionManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("permission_name", permissionName);
        return permissionManagementMapper.selectList(queryWrapper);
    }

    /**
     * 更新权限
     * @param permission 待更新的权限对象
     */
    @Transactional
    @CachePut(value = "permissionCache", key = "#permission.permissionId")
    public void updatePermission(PermissionManagement permission) {
        try {
            // 同步发送 Kafka 消息
            sendKafkaMessage("permission_update", permission);
            // 更新数据库记录
            permissionManagementMapper.updateById(permission);
        } catch (Exception e) {
            log.error("Exception occurred while updating permission or sending Kafka message", e);
            throw new RuntimeException("Failed to update permission", e);
        }
    }

    /**
     * 删除权限
     * @param permissionId 权限ID
     */
    @Transactional
    @CacheEvict(value = "permissionCache", key = "#permissionId")
    public void deletePermission(int permissionId) {
        try {
            PermissionManagement permissionToDelete = permissionManagementMapper.selectById(permissionId);
            if (permissionToDelete != null) {
                int result = permissionManagementMapper.deleteById(permissionId);
                if (result > 0) {
                    log.info("Permission with ID {} deleted successfully", permissionId);
                } else {
                    log.error("Failed to delete permission with ID {}", permissionId);
                }
            }
        } catch (Exception e) {
            log.error("Exception occurred while deleting permission", e);
            throw new RuntimeException("Failed to delete permission", e);
        }
    }

    /**
     * 根据权限名称删除权限
     * @param permissionName 权限名称
     * @throws IllegalArgumentException 如果权限名称为空或空字符串，则抛出此异常
     */
    @Transactional
    @CacheEvict(value = "permissionCache", key = "#permissionName")
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
                log.info("Permission with name '{}' deleted successfully", permissionName);
            } else {
                log.error("Failed to delete permission with name '{}'", permissionName);
            }
        }
    }

    // 发送 Kafka 消息的私有方法
    private void sendKafkaMessage(String topic, PermissionManagement permission) throws Exception {
        SendResult<String, PermissionManagement> sendResult = kafkaTemplate.send(topic, permission).get();
        log.info("Message sent to Kafka topic {} successfully: {}", topic, sendResult.toString());
    }
}
