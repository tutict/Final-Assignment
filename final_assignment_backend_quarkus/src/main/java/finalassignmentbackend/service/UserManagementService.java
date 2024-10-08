package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.mapper.UserManagementMapper;
import finalassignmentbackend.entity.UserManagement;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.mindrot.jbcrypt.BCrypt;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

@ApplicationScoped
public class UserManagementService {

    private static final Logger log = LoggerFactory.getLogger(UserManagementService.class);

    @Inject
    UserManagementMapper userManagementMapper;

    @Inject
    @Channel("user_create")
    Emitter<UserManagement> userCreateEmitter;

    @Inject
    @Channel("user_update")
    Emitter<UserManagement> userUpdateEmitter;

    // 创建用户
    @Transactional
    public void createUser(UserManagement user) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            userCreateEmitter.send(user).toCompletableFuture().exceptionally(ex -> {
                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            userManagementMapper.insert(user);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 根据用户ID查询用户
    public UserManagement getUserById(int userId) {
        return userManagementMapper.selectById(userId);
    }

    // 根据用户名查询用户
    public UserManagement getUserByUsername(String username) {
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return userManagementMapper.selectOne(queryWrapper);
    }

    // 查询所有用户
    public List<UserManagement> getAllUsers() {
        return userManagementMapper.selectList(null);
    }

    // 根据用户类型查询用户
    public List<UserManagement> getUsersByType(String userType) {
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_type", userType);
        return userManagementMapper.selectList(queryWrapper);
    }

    // 根据用户状态查询用户
    public List<UserManagement> getUsersByStatus(String status) {
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", status);
        return userManagementMapper.selectList(queryWrapper);
    }

    // 更新用户
    @Transactional
    public void updateUser(UserManagement user) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            userUpdateEmitter.send(user).toCompletableFuture().exceptionally(ex -> {

                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            userManagementMapper.updateById(user);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 删除用户
    public void deleteUser(int userId) {
        UserManagement userToDelete = userManagementMapper.selectById(userId);
        if (userToDelete != null) {
            userManagementMapper.deleteById(userId);
        }
    }

    // 根据用户名删除用户
    public void deleteUserByUsername(String username) {
        UserManagement userToDelete = getUserByUsername(username);
        if (userToDelete != null) {
            userManagementMapper.delete(new QueryWrapper<UserManagement>().eq("username", username));
        }
    }

    // 检查用户名和密码是否匹配
    public boolean authenticate(String username, String password) {
        // 根据用户名查询用户
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        UserManagement user = userManagementMapper.selectOne(queryWrapper);

        if (user == null) {
            // 用户不存在
            return false;
        }
        // 使用 BCrypt 检查密码是否匹配
        return BCrypt.checkpw(password, user.getPassword());
    }

    // 检查用户名是否存在
    public boolean isUsernameExists(String username) {
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return userManagementMapper.selectCount(queryWrapper) > 0;
    }

}
