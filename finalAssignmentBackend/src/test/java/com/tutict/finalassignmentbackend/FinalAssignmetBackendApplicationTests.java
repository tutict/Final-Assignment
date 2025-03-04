package com.tutict.finalassignmentbackend;

import com.tutict.finalassignmentbackend.entity.UserManagement;
import com.tutict.finalassignmentbackend.service.UserManagementService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class FinalAssignmentBackendApplicationTests {

//    @Autowired
//    private UserManagementService userManagementService;
//
//    @BeforeEach
//    void setUp() {
//        // 可选：初始化测试数据，确保数据库中有已知用户
//        // 注意：实际测试中可能需要清空数据库或使用内存数据库（如 H2）
//        UserManagement testUser = new UserManagement();
//        testUser.setUsername("211@admin.com");
//        testUser.setPassword("123456");
//        testUser.setCreatedTime(LocalDateTime.now());
//        testUser.setStatus("Active");
//
//        // 如果用户不存在，则创建（假设数据库中没有此用户）
//        if (!userManagementService.isUsernameExists("211@admin.com")) {
//            userManagementService.createUser(testUser);
//        }
//    }
//
//    @Test
//    void testGetUserByUsername_UserExists() {
//        // 测试目标：查询存在的用户，应返回非空结果
//        String username = "211@admin.com";
//        UserManagement user = userManagementService.getUserByUsername(username);
//
//        // 断言
//        assertNotNull(user, "User should not be null for existing username: " + username);
//        assertEquals(username, user.getUsername(), "Username should match");
//        assertEquals("123456", user.getPassword(), "Password should match");
//        assertEquals("Active", user.getStatus(), "User status should be Active");
//    }
//
//    @Test
//    void testGetUserByUsername_UserDoesNotExist() {
//        // 测试目标：查询不存在的用户，应返回 null
//        String username = "nonexistent@admin.com";
//        UserManagement user = userManagementService.getUserByUsername(username);
//
//        // 断言
//        assertNull(user, "User should be null for non-existent username: " + username);
//    }
//
//    @Test
//    void testGetUserByUsername_InvalidInput() {
//        // 测试目标：传入 null 或空字符串，应抛出 IllegalArgumentException
//        assertThrows(IllegalArgumentException.class, () -> userManagementService.getUserByUsername(null), "Should throw IllegalArgumentException for null username");
//
//        assertThrows(IllegalArgumentException.class, () -> userManagementService.getUserByUsername(""), "Should throw IllegalArgumentException for empty username");
//
//        assertThrows(IllegalArgumentException.class, () -> {
//            userManagementService.getUserByUsername("   "); // 仅空格
//        }, "Should throw IllegalArgumentException for blank username");
//    }
//
//    @Test
//    void contextLoads() {
//        // 默认测试：确保 Spring 上下文加载成功
//        assertNotNull(userManagementService, "UserManagementService should be injected");
//    }
}