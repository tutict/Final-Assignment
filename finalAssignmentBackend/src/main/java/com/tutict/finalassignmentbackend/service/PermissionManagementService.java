package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.PermissionManagementMapper;
import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
public class PermissionManagementService {

    private static final Logger log = LoggerFactory.getLogger(PermissionManagementService.class);


    private final PermissionManagementMapper permissionManagementMapper;
    private final KafkaTemplate<String, PermissionManagement> kafkaTemplate;

    @Autowired
    public PermissionManagementService(PermissionManagementMapper permissionManagementMapper, KafkaTemplate<String, PermissionManagement> kafkaTemplate) {
        this.permissionManagementMapper = permissionManagementMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建权限
    @Transactional
    public void createPermission(PermissionManagement permission) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, PermissionManagement>> future = kafkaTemplate.send("permission_create", permission);

            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Create message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            permissionManagementMapper.insert(permission);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 根据权限ID查询权限
    public PermissionManagement getPermissionById(int permissionId) {
        return permissionManagementMapper.selectById(permissionId);
    }

    // 查询所有权限
    public List<PermissionManagement> getAllPermissions() {
        return permissionManagementMapper.selectList(null);
    }

    // 根据权限名称查询权限
    public PermissionManagement getPermissionByName(String permissionName) {
        QueryWrapper<PermissionManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("permission_name", permissionName);
        return permissionManagementMapper.selectOne(queryWrapper);
    }

    // 根据权限名称模糊查询权限
    public List<PermissionManagement> getPermissionsByNameLike(String permissionName) {
        QueryWrapper<PermissionManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("permission_name", permissionName);
        return permissionManagementMapper.selectList(queryWrapper);
    }

    // 更新权限
    @Transactional
    public void updatePermission(PermissionManagement permission) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            CompletableFuture<SendResult<String, PermissionManagement>> future = kafkaTemplate.send("permission_update", permission);
            // 处理发送成功的情况
            future.thenAccept(sendResult -> log.info("Update message sent to Kafka successfully: {}", sendResult.toString())).exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            permissionManagementMapper.updateById(permission);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 删除权限
    public void deletePermission(int permissionId) {
        PermissionManagement permissionToDelete = permissionManagementMapper.selectById(permissionId);
        if (permissionToDelete != null) {
            permissionManagementMapper.deleteById(permissionId);
        }
    }

    // 根据权限名称删除权限
    public void deletePermissionByName(String permissionName) {
        QueryWrapper<PermissionManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("permission_name", permissionName);
        PermissionManagement permissionToDelete = permissionManagementMapper.selectOne(queryWrapper);
        if (permissionToDelete != null) {
            permissionManagementMapper.delete(queryWrapper);
        }
    }
}
