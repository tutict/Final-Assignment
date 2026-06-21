package com.tutict.finalassignmentbackend.kafkaListener;

import com.tutict.finalassignmentbackend.common.idempotency.IdempotentKafkaMessageProcessor;
import com.tutict.finalassignmentbackend.entity.system.SysSettings;
import com.tutict.finalassignmentbackend.service.admin.SysSettingsService;
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
public class SysSettingsKafkaListener {

    private static final Logger log = Logger.getLogger(SysSettingsKafkaListener.class.getName());

    private final SysSettingsService sysSettingsService;
    private final IdempotentKafkaMessageProcessor messageProcessor;

    @Autowired
    public SysSettingsKafkaListener(SysSettingsService sysSettingsService,
                                    IdempotentKafkaMessageProcessor messageProcessor) {
        this.sysSettingsService = sysSettingsService;
        this.messageProcessor = messageProcessor;
    }

    @KafkaListener(topics = "${kafka.topics.sys-settings.create:sys_settings_create}", groupId = "${kafka.groups.sys-settings:sysSettingsGroup}", concurrency = "3")
    public void onSysSettingsCreateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for create (payload omitted)");
        processRecord(record, "create", ack);
    }

    @KafkaListener(topics = "${kafka.topics.sys-settings.update:sys_settings_update}", groupId = "${kafka.groups.sys-settings:sysSettingsGroup}", concurrency = "3")
    public void onSysSettingsUpdateReceived(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.INFO, "Received Kafka message for update (payload omitted)");
        processRecord(record, "update", ack);
    }

    private void processRecord(ConsumerRecord<String, String> record, String action, Acknowledgment ack) {
        messageProcessor.process(
                record,
                ack,
                "SysSettings",
                action,
                sysSettingsService::shouldSkipProcessing,
                payload -> processPayload(payload, action),
                (key, result) -> {
                    if (result != null && result.getSettingId() != null) {
                        sysSettingsService.markHistorySuccess(key, result.getSettingId());
                    }
                },
                (key, ex) -> sysSettingsService.markHistoryFailure(key, ex.getMessage())
        );
    }

    private SysSettings processPayload(String message, String action) {
        SysSettings entity = messageProcessor.deserialize(message, SysSettings.class);
        if ("create".equalsIgnoreCase(action)) {
            entity.setSettingId(null);
            return sysSettingsService.createSysSettings(entity);
        }
        if ("update".equalsIgnoreCase(action)) {
            return sysSettingsService.updateSysSettings(entity);
        }
        log.log(Level.WARNING, "Unsupported action: {0}", action);
        return null;
    }
}
