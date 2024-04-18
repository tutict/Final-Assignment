package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.PermissionManagementMapper;
import com.tutict.finalassignmentbackend.entity.PermissionManagement;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PermissionManagementService {

    private final PermissionManagementMapper permissionManagementMapper;
    private final KafkaTemplate<String, PermissionManagement> kafkaTemplate;

    @Autowired
    public PermissionManagementService(PermissionManagementMapper permissionManagementMapper, KafkaTemplate<String, PermissionManagement> kafkaTemplate) {
        this.permissionManagementMapper = permissionManagementMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    // 创建权限
    public void createPermission(PermissionManagement permission) {
        permissionManagementMapper.insert(permission);
        // 发送权限变更信息到 Kafka 主题
        kafkaTemplate.send("permission_management_topic", permission);
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
    public void updatePermission(PermissionManagement permission) {
        permissionManagementMapper.updateById(permission);
        // 发送权限变更信息到 Kafka 主题
        kafkaTemplate.send("permission_management_topic", permission);
    }

    // 删除权限
    public void deletePermission(int permissionId) {
        PermissionManagement permissionToDelete = permissionManagementMapper.selectById(permissionId);
        if (permissionToDelete != null) {
            permissionManagementMapper.deleteById(permissionId);
            // 发送完整的 PermissionManagement 对象到 Kafka 主题
            kafkaTemplate.send("permission_management_topic", permissionToDelete);
        }
    }

    // 根据权限名称删除权限
    public void deletePermissionByName(String permissionName) {
        QueryWrapper<PermissionManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("permission_name", permissionName);
        PermissionManagement permissionToDelete = permissionManagementMapper.selectOne(queryWrapper);
        if (permissionToDelete != null) {
            permissionManagementMapper.delete(queryWrapper);
            // 发送完整的 PermissionManagement 对象到 Kafka 主题
            kafkaTemplate.send("permission_management_topic", permissionToDelete);
        }
    }
}
