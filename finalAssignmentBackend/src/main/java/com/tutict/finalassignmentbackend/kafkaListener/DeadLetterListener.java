package com.tutict.finalassignmentbackend.kafkaListener;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.service.messaging.BusinessEventPushService;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@Component
public class DeadLetterListener {

    private static final Logger log = Logger.getLogger(DeadLetterListener.class.getName());

    private final ObjectMapper objectMapper;
    private final BusinessEventPushService businessEventPushService;

    public DeadLetterListener(ObjectMapper objectMapper, BusinessEventPushService businessEventPushService) {
        this.objectMapper = objectMapper;
        this.businessEventPushService = businessEventPushService;
    }

    @KafkaListener(topics = {
            "${kafka.topics.offense.create-dlt:offense_record_create.DLT}",
            "${kafka.topics.offense.update-dlt:offense_record_update.DLT}",
            "${kafka.topics.payment.create-dlt:payment_record_create.DLT}",
            "${kafka.topics.payment.update-dlt:payment_record_update.DLT}",
            "${kafka.topics.appeal.create-dlt:appeal_record_create.DLT}",
            "${kafka.topics.appeal.update-dlt:appeal_record_update.DLT}",
            "${kafka.topics.sys-user.create-dlt:sys_user_create.DLT}",
            "${kafka.topics.sys-user.update-dlt:sys_user_update.DLT}",
            "${kafka.topics.sys-settings.create-dlt:sys_settings_create.DLT}",
            "${kafka.topics.sys-settings.update-dlt:sys_settings_update.DLT}",
            "${kafka.topics.vehicle.create-dlt:vehicle_information_create.DLT}",
            "${kafka.topics.vehicle.update-dlt:vehicle_information_update.DLT}"
    }, groupId = "${kafka.groups.dead-letter:deadLetterMonitorGroup}")
    public void onDeadLetter(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.SEVERE,
                "Dead letter received: topic={0}, partition={1}, offset={2}, key={3}",
                new Object[]{record.topic(), record.partition(), record.offset(), record.key()});
        notifyAsyncFailure(record);
        ack.acknowledge();
    }

    private void notifyAsyncFailure(ConsumerRecord<String, String> record) {
        try {
            Map<String, Object> payload = objectMapper.readValue(
                    record.value(),
                    new TypeReference<>() {
                    }
            );
            String userId = firstNonBlank(
                    asString(payload.get("userId")),
                    asString(payload.get("createdBy")),
                    asString(payload.get("updatedBy")),
                    asString(payload.get("username")),
                    asString(payload.get("payerContact")),
                    asString(payload.get("appellantContact"))
            );
            if (userId != null) {
                businessEventPushService.pushAsyncFailure(
                        userId,
                        record.topic().replace(".DLT", ""),
                        buildUserFriendlyMessage(record.topic())
                );
            }
        } catch (Exception ex) {
            log.log(Level.WARNING, "Failed to parse DLT message for notification", ex);
        }
    }

    private String buildUserFriendlyMessage(String topic) {
        return switch (topic) {
            case "offense_record_create.DLT", "offense_record_update.DLT" -> "Offense async operation failed";
            case "payment_record_create.DLT", "payment_record_update.DLT" -> "Payment async operation failed";
            case "appeal_record_create.DLT", "appeal_record_update.DLT" -> "Appeal async operation failed";
            case "sys_user_create.DLT", "sys_user_update.DLT" -> "User async operation failed";
            case "vehicle_information_create.DLT", "vehicle_information_update.DLT" -> "Vehicle async operation failed";
            default -> "Async operation failed";
        };
    }
    private String asString(Object value) {
        return value == null ? null : value.toString();
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return null;
    }
}
