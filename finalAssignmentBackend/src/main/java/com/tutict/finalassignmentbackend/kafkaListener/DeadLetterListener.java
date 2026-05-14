package com.tutict.finalassignmentbackend.kafkaListener;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

import java.util.logging.Level;
import java.util.logging.Logger;

@Component
public class DeadLetterListener {

    private static final Logger log = Logger.getLogger(DeadLetterListener.class.getName());

    @KafkaListener(topics = {
            "${kafka.topics.offense.create-dlt:offense_record_create.DLT}",
            "${kafka.topics.offense.update-dlt:offense_record_update.DLT}",
            "${kafka.topics.payment.create-dlt:payment_record_create.DLT}",
            "${kafka.topics.payment.update-dlt:payment_record_update.DLT}",
            "${kafka.topics.appeal.create-dlt:appeal_record_create.DLT}",
            "${kafka.topics.appeal.update-dlt:appeal_record_update.DLT}"
    }, groupId = "deadLetterMonitorGroup")
    public void onDeadLetter(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.SEVERE,
                "Dead letter received: topic={0}, partition={1}, offset={2}, key={3}",
                new Object[]{record.topic(), record.partition(), record.offset(), record.key()});
        ack.acknowledge();
    }
}
