package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.mapper.RoleManagementMapper;
import com.tutict.finalassignmentbackend.entity.RoleManagement;
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
import java.util.concurrent.CompletableFuture;

@Service
public class RoleManagementService {

    // 日志记录器
    private static final Logger log = LoggerFactory.getLogger(RoleManagementService.class);


    // RoleManagement的Mapper，用于数据库操作
    private final RoleManagementMapper roleManagementMapper;
    // Kafka消息模板，用于发送Kafka消息
    private final KafkaTemplate<String, RoleManagement> kafkaTemplate;

    // 构造函数，通过DI注入RoleManagementMapper和KafkaTemplate
    @Autowired
    public RoleManagementService(RoleManagementMapper roleManagementMapper, KafkaTemplate<String, RoleManagement> kafkaTemplate) {
        this.roleManagementMapper = roleManagementMapper;
        this.kafkaTemplate = kafkaTemplate;
    }

    /**
     * 创建角色
     * @param role 要创建的角色对象
     */
    @Transactional
    @CacheEvict(cacheNames = "roleCache", allEntries = true, key = "#role.roleId")
    public void createRole(RoleManagement role) {
        try {
            // 异步发送创建角色消息到Kafka
            CompletableFuture<SendResult<String, RoleManagement>> future = kafkaTemplate.send("role_create", role);

            // 处理消息发送成功的情况
            future.thenAccept(sendResult -> log.info("Create message sent to Kafka successfully: {}", sendResult.toString()))
                    // 处理消息发送失败的情况
                    .exceptionally(ex -> {
                        log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                        throw new RuntimeException("Kafka message send failure", ex);
                    });

            // 插入角色到数据库，Spring事务管理器管理整个过程
            roleManagementMapper.insert(role);

        } catch (Exception e) {
            // 记录异常
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 抛出异常，可能触发事务回滚
            throw e;
        }
    }

    /**
     * 根据角色ID查询角色
     * @param roleId 角色ID
     * @return 查询到的角色对象，如果没有找到则返回null
     */
    @Cacheable(cacheNames = "roleCache", key = "#roleId")
    public RoleManagement getRoleById(int roleId) {
        return roleManagementMapper.selectById(roleId);
    }

    /**
     * 查询所有角色
     * @return 所有角色的列表
     */
    @Cacheable(cacheNames = "roleCache")
    public List<RoleManagement> getAllRoles() {
        return roleManagementMapper.selectList(null);
    }

    /**
     * 根据角色名称查询角色
     * @param roleName 角色名称
     * @return 查询到的角色对象，如果没有找到则返回null
     * @throws IllegalArgumentException 如果角色名称为空或空字符串
     */
    @Cacheable(cacheNames = "roleCache", key = "#roleName")
    public RoleManagement getRoleByName(String roleName) {
        if (roleName == null || roleName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid role name");
        }
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("role_name", roleName);
        return roleManagementMapper.selectOne(queryWrapper);
    }

    /**
     * 根据角色名称模糊查询角色
     * @param roleName 角色名称的部分字符串
     * @return 模糊查询到的角色列表
     * @throws IllegalArgumentException 如果角色名称为空或空字符串
     */
    @Cacheable(cacheNames = "roleCache", key = "#roleName")
    public List<RoleManagement> getRolesByNameLike(String roleName) {
        if (roleName == null || roleName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid role name");
        }
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("role_name", roleName);
        return roleManagementMapper.selectList(queryWrapper);
    }

    /**
     * 更新角色
     * @param role 要更新的角色对象
     */
    @Transactional
    @CachePut(cacheNames = "roleCache", key = "#role.roleId")
    public void updateRole(RoleManagement role) {
        try {
            // 异步发送更新角色消息到Kafka
            CompletableFuture<SendResult<String, RoleManagement>> future = kafkaTemplate.send("role_update", role);

            // 处理消息发送成功的情况
            future.thenAccept(sendResult -> log.info("Update message sent to Kafka successfully: {}", sendResult.toString()))
                    // 处理消息发送失败的情况
                    .exceptionally(ex -> {
                        log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                        throw new RuntimeException("Kafka message send failure", ex);
                    });

            // 更新数据库中的角色信息
            roleManagementMapper.updateById(role);

        } catch (Exception e) {
            // 记录异常
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 抛出异常，可能触发事务回滚
            throw e;
        }
    }

    /**
     * 删除角色
     * @param roleId 角色ID
     */
    @CacheEvict(cacheNames = "roleCache", key = "#roleId")
    public void deleteRole(int roleId) {
        try {
            RoleManagement roleToDelete = roleManagementMapper.selectById(roleId);
            if (roleToDelete != null) {
                roleManagementMapper.deleteById(roleId);
            }
        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while deleting role", e);
        }
    }

    /**
     * 根据角色名称删除角色
     * @param roleName 角色名称
     * @throws IllegalArgumentException 如果角色名称为空或空字符串
     */
    @CacheEvict(cacheNames = "roleCache", key = "#roleName")
    public void deleteRoleByName(String roleName) {
        if (roleName == null || roleName.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid role name");
        }
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("role_name", roleName);
        RoleManagement roleToDelete = roleManagementMapper.selectOne(queryWrapper);
        if (roleToDelete != null) {
            roleManagementMapper.delete(queryWrapper);
        }
    }
}
