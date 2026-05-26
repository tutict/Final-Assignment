package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.admin.SysUser;
import com.tutict.finalassignmentbackend.service.admin.SysUserService;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@EnableKafka
// Kafka 监听器，处理消息
public class SysUserKafkaListener {

    private static final Logger log = Logger.getLogger(SysUserKafkaListener.class.getName());

    private final SysUserService sysUserService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    // 构造器注入依赖
    @Autowired
    public SysUserKafkaListener(SysUserService sysUserService,
                                IdempotentKafkaMessageProcessor messageProcessor) {
        this.sysUserService = sysUserService;
        this.messageProcessor = messageProcessor;
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.sys-user.create:sys_user_create}", groupId = "${kafka.groups.sys-user:sysUserGroup}", concurrency = "3")
    public void onSysUserCreateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processRecord(record, "create", ack);
    }

    // 监听 Kafka 消息
    @KafkaListener(topics = "${kafka.topics.sys-user.update:sys_user_update}", groupId = "${kafka.groups.sys-user:sysUserGroup}", concurrency = "3")
    public void onSysUserUpdateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processRecord(record, "update", ack);
    }

    private void processRecord(ConsumerRecord<String, String> record, String action, Acknowledgment ack) {
        messageProcessor.process(
                record,
                ack,
                "SysUser",
                action,
                sysUserService::shouldSkipProcessing,
                payload -> processMessage(payload, action),
                (key, entity) -> {
                    if (entity != null && entity.getUserId() != null) {
                        sysUserService.markHistorySuccess(key, entity.getUserId());
                    }
                },
                (key, ex) -> sysUserService.markHistoryFailure(key, ex.getMessage())
        );
    }

    // 统一处理消息并执行业务逻辑
    private SysUser processMessage(String message, String action) {
        try {
            SysUser entity = messageProcessor.deserialize(message, SysUser.class);
            if ("create".equals(action)) {
                entity.setUserId(null);
                entity = sysUserService.createSysUser(entity);
            } else if ("update".equals(action)) {
                entity = sysUserService.updateSysUser(entity);
            } else {
                log.log(Level.WARNING, "Unsupported action: {0}", action);
                return null;
            }
            log.info(String.format("SysUser %s action processed successfully", action));
            return entity;
        } catch (Exception e) {
            log.log(Level.SEVERE, String.format("Error processing %s SysUser message (payload omitted)", action), e);
            throw new RuntimeException(String.format("Failed to process %s SysUser message", action), e);
        }
    }
}
