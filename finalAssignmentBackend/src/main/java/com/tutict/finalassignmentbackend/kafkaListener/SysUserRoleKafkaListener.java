package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.admin.SysUserRole;
import com.tutict.finalassignmentbackend.service.admin.SysUserRoleService;
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
public class SysUserRoleKafkaListener {

    private static final Logger log = Logger.getLogger(SysUserRoleKafkaListener.class.getName());

    private final SysUserRoleService sysUserRoleService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public SysUserRoleKafkaListener(SysUserRoleService sysUserRoleService,
                                    IdempotentKafkaMessageProcessor messageProcessor) {
        this.sysUserRoleService = sysUserRoleService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.sys-user-role.create:sys_user_role_create}", groupId = "${kafka.groups.sys-user-role:sysUserRoleGroup}", concurrency = "3")
    public void onSysUserRoleCreateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processRecord(record, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.sys-user-role.update:sys_user_role_update}", groupId = "${kafka.groups.sys-user-role:sysUserRoleGroup}", concurrency = "3")
    public void onSysUserRoleUpdateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processRecord(record, "update", ack);
    }

    private void processRecord(ConsumerRecord<String, String> record, String action, Acknowledgment ack) {
        messageProcessor.process(
                record,
                ack,
                "SysUserRole",
                action,
                sysUserRoleService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getId() != null) {
                        sysUserRoleService.markHistorySuccess(key, result.getId());
                    }
                },
                (key, ex) -> sysUserRoleService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private SysUserRole processPayload(String message, String action) {
        SysUserRole entity = messageProcessor.deserialize(message, SysUserRole.class);
        if ("create".equalsIgnoreCase(action)) {
            entity.setId(null);
            return sysUserRoleService.createRelation(entity);
        }
        if ("update".equalsIgnoreCase(action)) {
            return sysUserRoleService.updateRelation(entity);
        }
        log.log(Level.WARNING, "Unsupported action: {0}", action);
        return null;
    }
}
