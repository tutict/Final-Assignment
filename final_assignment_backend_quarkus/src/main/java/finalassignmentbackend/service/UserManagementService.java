package finalassignmentbackend.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import finalassignmentbackend.entity.UserManagement;
import finalassignmentbackend.mapper.UserManagementMapper;
import io.quarkus.cache.CacheInvalidate;
import io.quarkus.cache.CacheResult;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Event;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.event.TransactionPhase;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import lombok.Getter;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class UserManagementService {

    private static final Logger log = Logger.getLogger(UserManagementService.class.getName());

    @Inject
    UserManagementMapper userManagementMapper;

    @Inject
    Event<UserEvent> userEvent;

    @Inject
    @Channel("user-events-out")
    MutinyEmitter<UserManagement> userEmitter;

    @Getter
    public static class UserEvent {
        private final UserManagement user;
        private final String action; // "create" or "update"

        public UserEvent(UserManagement user, String action) {
            this.user = user;
            this.action = action;
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "userCache")
    public void createUser(UserManagement user) {
        try {
            userManagementMapper.insert(user);
            userEvent.fire(new UserEvent(user, "create"));
        } catch (Exception e) {
            log.warning("Exception occurred while creating user or firing event");
            throw new RuntimeException("Failed to create user", e);
        }
    }

    @CacheResult(cacheName = "userCache")
    public UserManagement getUserById(int userId) {
        return userManagementMapper.selectById(userId);
    }

    @CacheResult(cacheName = "userCache")
    public UserManagement getUserByUsername(String username) {
        validateInput(username, "Invalid username");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return userManagementMapper.selectOne(queryWrapper);
    }

    @CacheResult(cacheName = "userCache")
    public List<UserManagement> getAllUsers() {
        return userManagementMapper.selectList(null);
    }

    @CacheResult(cacheName = "userCache")
    public List<UserManagement> getUsersByType(String userType) {
        validateInput(userType, "Invalid user type");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_type", userType);
        return userManagementMapper.selectList(queryWrapper);
    }

    @CacheResult(cacheName = "userCache")
    public List<UserManagement> getUsersByStatus(String status) {
        validateInput(status, "Invalid status");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", status);
        return userManagementMapper.selectList(queryWrapper);
    }

    @Transactional
    @CacheInvalidate(cacheName = "userCache")
    public UserManagement updateUser(UserManagement user) {
        try {
            userManagementMapper.updateById(user);
            userEvent.fire(new UserEvent(user, "update"));
            return user;
        } catch (Exception e) {
            log.warning("Exception occurred while updating user or firing event");
            throw new RuntimeException("Failed to update user", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "userCache")
    public void deleteUser(int userId) {
        try {
            UserManagement userToDelete = userManagementMapper.selectById(userId);
            if (userToDelete != null) {
                userManagementMapper.deleteById(userId);
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting user");
            throw new RuntimeException("Failed to delete user", e);
        }
    }

    @Transactional
    @CacheInvalidate(cacheName = "userCache")
    public void deleteUserByUsername(String username) {
        validateInput(username, "Invalid username");
        try {
            QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
            queryWrapper.eq("username", username);
            UserManagement userToDelete = userManagementMapper.selectOne(queryWrapper);
            if (userToDelete != null) {
                userManagementMapper.delete(queryWrapper);
            }
        } catch (Exception e) {
            log.warning("Exception occurred while deleting user");
            throw new RuntimeException("Failed to delete user", e);
        }
    }

    @CacheResult(cacheName = "userCache")
    public boolean isUsernameExists(String username) {
        validateInput(username, "Invalid username");
        QueryWrapper<UserManagement> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("username", username);
        return userManagementMapper.selectCount(queryWrapper) > 0;
    }

    public void onUserEvent(@Observes(during = TransactionPhase.AFTER_SUCCESS) UserEvent event) {
        String topic = event.getAction().equals("create") ? "user_create" : "user_update";
        sendKafkaMessage(topic, event.getUser());
    }

    private void sendKafkaMessage(String topic, UserManagement user) {
        var metadata = OutgoingKafkaRecordMetadata.<String>builder()
                .withTopic(topic)
                .build();

        Message<UserManagement> message = Message.of(user).addMetadata(metadata);

        userEmitter.sendMessage(message)
                .await().indefinitely();

        log.info(String.format("Message sent to Kafka topic %s successfully", topic));
    }

    private void validateInput(String input, String errorMessage) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(errorMessage);
        }
    }
}
