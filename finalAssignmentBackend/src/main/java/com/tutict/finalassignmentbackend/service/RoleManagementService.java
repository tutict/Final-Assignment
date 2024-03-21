package com.tutict.finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.dao.RoleManagementMapper;
import com.tutict.finalassignmentbackend.entity.RoleManagement;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RoleManagementService {

    private final RoleManagementMapper roleManagementMapper;

    @Autowired
    public RoleManagementService(RoleManagementMapper roleManagementMapper) {
        this.roleManagementMapper = roleManagementMapper;
    }

    // 创建角色
    public void createRole(RoleManagement role) {
        roleManagementMapper.insert(role);
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
    public void updateRole(RoleManagement role) {
        roleManagementMapper.updateById(role);
    }

    // 删除角色
    public void deleteRole(int roleId) {
        roleManagementMapper.deleteById(roleId);
    }

    // 根据角色名称删除角色
    public void deleteRoleByName(String roleName) {
        QueryWrapper<RoleManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("role_name", roleName);
        roleManagementMapper.delete(queryWrapper);
    }

    // 根据角色ID查询权限列表
    public String getPermissionListByRoleId(int roleId) {
        RoleManagement role = roleManagementMapper.selectById(roleId);
        return role != null ? role.getPermissionList() : null;
    }

}