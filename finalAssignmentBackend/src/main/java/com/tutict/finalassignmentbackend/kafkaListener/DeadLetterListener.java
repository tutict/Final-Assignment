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
            "offense-topic.DLT",
            "payment-topic.DLT",
            "appeal-topic.DLT",
            "offense_record_create.DLT",
            "offense_record_update.DLT",
            "payment_record_create.DLT",
            "payment_record_update.DLT",
            "appeal_record_create.DLT",
            "appeal_record_update.DLT"
    }, groupId = "deadLetterMonitorGroup")
    public void onDeadLetter(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.log(Level.SEVERE,
                "Dead letter received: topic={0}, partition={1}, offset={2}, key={3}",
                new Object[]{record.topic(), record.partition(), record.offset(), record.key()});
        ack.acknowledge();
    }
}
