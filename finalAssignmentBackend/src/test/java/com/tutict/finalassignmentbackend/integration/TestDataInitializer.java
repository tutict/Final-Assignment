package com.tutict.finalassignmentbackend.integration;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.tutict.finalassignmentbackend.entity.admin.SysRole;
import com.tutict.finalassignmentbackend.entity.admin.SysUser;
import com.tutict.finalassignmentbackend.entity.admin.SysUserRole;
import com.tutict.finalassignmentbackend.mapper.admin.SysRoleMapper;
import com.tutict.finalassignmentbackend.mapper.admin.SysUserMapper;
import com.tutict.finalassignmentbackend.mapper.admin.SysUserRoleMapper;
import jakarta.annotation.PostConstruct;
import java.time.LocalDateTime;
import org.springframework.boot.sql.init.dependency.DependsOnDatabaseInitialization;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@Profile("test")
@ConditionalOnProperty(name = "test.data.initializer.enabled", havingValue = "true")
@DependsOnDatabaseInitialization
public class TestDataInitializer {

    private final SysUserMapper userMapper;
    private final SysRoleMapper roleMapper;
    private final SysUserRoleMapper userRoleMapper;
    private final PasswordEncoder passwordEncoder;

    public TestDataInitializer(SysUserMapper userMapper,
                               SysRoleMapper roleMapper,
                               SysUserRoleMapper userRoleMapper,
                               PasswordEncoder passwordEncoder) {
        this.userMapper = userMapper;
        this.roleMapper = roleMapper;
        this.userRoleMapper = userRoleMapper;
        this.passwordEncoder = passwordEncoder;
    }

    @PostConstruct
    @Transactional
    public void initTestData() {
        createRoleIfNotExists("SUPER_ADMIN", "超级管理员", "System", "All", 1);
        createRoleIfNotExists("ADMIN", "管理员", "System", "Department", 2);
        createRoleIfNotExists("USER", "普通用户", "Business", "Self", 3);

        createOrUpdateTestUser("admin", "Admin@123456", "ADMIN", "测试管理员", "13800138001");
        createOrUpdateTestUser("testuser", "User@123456", "USER", "测试用户", "13800138002");
        createOrUpdateTestUser("superadmin", "SuperAdmin@123456", "SUPER_ADMIN", "测试超级管理员", "13800138003");
    }

    private SysRole createRoleIfNotExists(String roleCode,
                                          String roleName,
                                          String roleType,
                                          String dataScope,
                                          int sortOrder) {
        SysRole role = findRole(roleCode);
        if (role == null) {
            role = new SysRole();
            role.setRoleCode(roleCode);
            role.setCreatedAt(LocalDateTime.now());
            role.setCreatedBy("TestDataInitializer");
        }
        role.setRoleName(roleName);
        role.setRoleType(roleType);
        role.setDataScope(dataScope);
        role.setRoleDescription("Integration test role: " + roleCode);
        role.setStatus("Active");
        role.setSortOrder(sortOrder);
        role.setUpdatedAt(LocalDateTime.now());

        if (role.getRoleId() == null) {
            roleMapper.insert(role);
        } else {
            roleMapper.updateById(role);
        }
        return role;
    }

    private void createOrUpdateTestUser(String username,
                                        String rawPassword,
                                        String roleCode,
                                        String realName,
                                        String contactNumber) {
        SysUser user = findUser(username);
        if (user == null) {
            user = new SysUser();
            user.setUsername(username);
            user.setCreatedAt(LocalDateTime.now());
            user.setCreatedBy("TestDataInitializer");
        }

        user.setPassword(passwordEncoder.encode(rawPassword));
        user.setSalt(null);
        user.setRealName(realName);
        user.setContactNumber(contactNumber);
        user.setEmail(username + "@test.com");
        user.setStatus("Active");
        user.setLoginFailures(0);
        user.setPasswordUpdateTime(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());

        if (user.getUserId() == null) {
            userMapper.insert(user);
        } else {
            userMapper.updateById(user);
        }

        SysRole role = findRole(roleCode);
        if (role == null) {
            throw new IllegalStateException("Missing test role: " + roleCode);
        }
        bindRoleIfMissing(user.getUserId(), role.getRoleId());
    }

    private SysUser findUser(String username) {
        QueryWrapper<SysUser> wrapper = new QueryWrapper<>();
        wrapper.eq("username", username).isNull("deleted_at").last("LIMIT 1");
        return userMapper.selectOne(wrapper);
    }

    private SysRole findRole(String roleCode) {
        QueryWrapper<SysRole> wrapper = new QueryWrapper<>();
        wrapper.eq("role_code", roleCode).isNull("deleted_at").last("LIMIT 1");
        return roleMapper.selectOne(wrapper);
    }

    private void bindRoleIfMissing(Long userId, Integer roleId) {
        QueryWrapper<SysUserRole> wrapper = new QueryWrapper<>();
        wrapper.eq("user_id", userId)
            .eq("role_id", roleId)
            .isNull("deleted_at")
            .last("LIMIT 1");
        if (userRoleMapper.selectOne(wrapper) != null) {
            return;
        }

        SysUserRole relation = new SysUserRole();
        relation.setUserId(userId);
        relation.setRoleId(roleId);
        relation.setCreatedAt(LocalDateTime.now());
        relation.setCreatedBy("TestDataInitializer");
        userRoleMapper.insert(relation);
    }
}
