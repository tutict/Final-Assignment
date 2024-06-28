package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.RoleManagementMapper;
import finalassignmentbackend.entity.RoleManagement;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

@ApplicationScoped
public class RoleManagementService {

    private static final Logger log = LoggerFactory.getLogger(RoleManagementService.class);

    @Inject
    RoleManagementMapper roleManagementMapper;

    @Inject
    @Channel("role_create")
    Emitter<RoleManagement> roleCreateEmitter;

    @Inject
    @Channel("role_update")
    Emitter<RoleManagement> roleUpdateEmitter;

    // 创建角色
    @Transactional
    public void createRole(RoleManagement role) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            roleCreateEmitter.send(role).toCompletableFuture().exceptionally(ex -> {

                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，事务管理器将处理事务
            roleManagementMapper.insert(role);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 根据角色ID查询角色
    public RoleManagement getRoleById(int roleId) {
        return roleManagementMapper.selectById(roleId);
    }

    // 查询所有角色
    public List<RoleManagement> getAllRoles() {
        return roleManagementMapper.selectList(null);
    }

    // 根据角色名称查询角色
    public RoleManagement getRoleByName(String roleName) {
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("role_name", roleName);
        return roleManagementMapper.selectOne(queryWrapper);
    }

    // 根据角色名称模糊查询角色
    public List<RoleManagement> getRolesByNameLike(String roleName) {
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.like("role_name", roleName);
        return roleManagementMapper.selectList(queryWrapper);
    }

    // 更新角色
    @Transactional
    public void updateRole(RoleManagement role) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            roleUpdateEmitter.send(role).toCompletableFuture().exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，事务管理器将处理事务
            roleManagementMapper.updateById(role);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 删除角色
    public void deleteRole(int roleId) {
        RoleManagement roleToDelete = roleManagementMapper.selectById(roleId);
        if (roleToDelete != null) {
            roleManagementMapper.deleteById(roleId);
        }
    }

    // 根据角色名称删除角色
    public void deleteRoleByName(String roleName) {
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("role_name", roleName);
        RoleManagement roleToDelete = roleManagementMapper.selectOne(queryWrapper);
        if (roleToDelete != null) {
            roleManagementMapper.delete(queryWrapper);
        }
    }

    // 根据角色ID查询权限列表
    public String getPermissionListByRoleId(int roleId) {
        RoleManagement role = roleManagementMapper.selectById(roleId);
        return role != null ? role.getPermissionList() : null;
    }
}
