package finalassignmentbackend.service;

import finalassignmentbackend.mapper.SystemSettingsMapper;
import finalassignmentbackend.entity.SystemSettings;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ApplicationScoped
public class SystemSettingsService {

    private static final Logger log = LoggerFactory.getLogger(SystemLogsService.class);

    @Inject
    SystemSettingsMapper systemSettingsMapper;

    @Inject
    @Channel("system_settings_update")
    Emitter<SystemSettings> systemSettingsUpdateEmitter;

    @Inject
    @Channel("system_settings_create")
    Emitter<SystemSettings> systemSettingsCreateEmitter;

    // 获取系统设置
    public SystemSettings getSystemSettings() {
        return systemSettingsMapper.selectById(1);
    }

    // 更新系统设置
    @Transactional
    public void updateSystemSettings(SystemSettings systemSettings) {
        try {
            // 异步发送消息到 Kafka，并处理发送结果
            systemSettingsCreateEmitter.send(systemSettings).toCompletableFuture().exceptionally(ex -> {

                // 处理发送失败的情况
                log.error("Failed to send message to Kafka, triggering transaction rollback", ex);
                // 抛出异常
                throw new RuntimeException("Kafka message send failure", ex);
            });

            // 由于是异步发送，不需要等待发送完成，Spring事务管理器将处理事务
            systemSettingsMapper.updateById(systemSettings);

        } catch (Exception e) {
            // 记录异常信息
            log.error("Exception occurred while updating appeal or sending Kafka message", e);
            // 异常将由Spring事务管理器处理，可能触发事务回滚
            throw e;
        }
    }

    // 获取系统名称
    public String getSystemName() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getSystemName() : null;
    }

    // 获取系统版本
    public String getSystemVersion() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getSystemVersion() : null;
    }

    // 获取系统描述
    public String getSystemDescription() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getSystemDescription() : null;
    }

    // 获取版权信息
    public String getCopyrightInfo() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getCopyrightInfo() : null;
    }

    // 获取存储路径
    public String getStoragePath() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getStoragePath() : null;
    }

    // 获取登录超时时间
    public int getLoginTimeout() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getLoginTimeout() : 0;
    }

    // 获取会话超时时间
    public int getSessionTimeout() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getSessionTimeout() : 0;
    }

    // 获取日期格式
    public String getDateFormat() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getDateFormat() : null;
    }

    // 获取分页大小
    public int getPageSize() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getPageSize() : 0;
    }

    // 获取SMTP服务器
    public String getSmtpServer() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getSmtpServer() : null;
    }

    // 获取邮箱账号
    public String getEmailAccount() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getEmailAccount() : null;
    }

    // 获取邮箱密码
    public String getEmailPassword() {
        SystemSettings systemSettings = systemSettingsMapper.selectById(1);
        return systemSettings != null ? systemSettings.getEmailPassword() : null;
    }

}
