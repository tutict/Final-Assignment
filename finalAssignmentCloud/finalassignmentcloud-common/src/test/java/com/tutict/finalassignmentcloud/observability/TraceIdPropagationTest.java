package com.tutict.finalassignmentcloud.observability;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TraceIdPropagationTest {

    @Test
    void producerCopiesTheCurrentTraceAndConsumerRestoresIt() {
        TraceContext.put("trace-from-request");
        ProducerRecord<String, Object> produced = new ProducerRecord<>("payment_record_create", "key", "body");
        new TraceIdProducerInterceptor().onSend(produced);
        byte[] header = produced.headers().lastHeader(TraceContext.TRACE_ID_HEADER).value();
        assertEquals("trace-from-request", new String(header, StandardCharsets.UTF_8));

        ConsumerRecord<String, String> consumed = new ConsumerRecord<>("payment_record_create", 0, 0L, "key", "body");
        consumed.headers().add(TraceContext.TRACE_ID_HEADER, header);
        TraceContext.clear();
        TraceIdRecordInterceptor interceptor = new TraceIdRecordInterceptor();
        interceptor.intercept(consumed, null);
        assertEquals("trace-from-request", TraceContext.currentTraceId());
        interceptor.afterRecord(consumed, null);
        assertNull(TraceContext.currentTraceId());
    }

    @Test
    void listenerFactoriesRestoreTheTrace() throws Exception {
        Path cloud = Path.of("..");
        for (String relative : new String[] {
                "finalassignmentcloud-traffic/src/main/java/com/tutict/finalassignmentcloud/traffic/config/DevKafkaConfiguration.java",
                "finalassignmentcloud-user/src/main/java/com/tutict/finalassignmentcloud/user/config/DevKafkaConfiguration.java",
                "finalassignmentcloud-audit/src/main/java/com/tutict/finalassignmentcloud/audit/config/DevKafkaConfiguration.java",
                "finalassignmentcloud-system/src/main/java/com/tutict/finalassignmentcloud/system/config/DevKafkaConfiguration.java"
        }) {
            assertTrue(Files.readString(cloud.resolve(relative)).contains("LedgerKafkaSettings.rememberTrace(factory)"), relative);
        }
    }
}
