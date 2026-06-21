package com.tutict.finalassignmentcloud.observability;

import org.apache.kafka.clients.producer.ProducerInterceptor;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;

import java.util.Map;

public class TraceIdProducerInterceptor implements ProducerInterceptor<String, Object> {

    @Override
    public ProducerRecord<String, Object> onSend(ProducerRecord<String, Object> record) {
        String traceId = TraceContext.currentTraceId();
        if (TraceContext.hasText(traceId) && record.headers().lastHeader(TraceContext.TRACE_ID_HEADER) == null) {
            record.headers().add(TraceContext.TRACE_ID_HEADER, TraceContext.encode(traceId));
        }
        return record;
    }

    @Override
    public void onAcknowledgement(RecordMetadata metadata, Exception exception) {
    }

    @Override
    public void close() {
    }

    @Override
    public void configure(Map<String, ?> configs) {
    }
}
