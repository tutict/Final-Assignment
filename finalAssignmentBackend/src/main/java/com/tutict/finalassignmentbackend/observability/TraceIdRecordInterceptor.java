package com.tutict.finalassignmentbackend.observability;

import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.header.Header;
import org.springframework.kafka.listener.RecordInterceptor;

public class TraceIdRecordInterceptor implements RecordInterceptor<String, String> {

    @Override
    public ConsumerRecord<String, String> intercept(
            ConsumerRecord<String, String> record,
            Consumer<String, String> consumer) {
        Header traceHeader = record.headers().lastHeader(TraceContext.TRACE_ID_HEADER);
        String traceId = traceHeader == null ? null : TraceContext.decode(traceHeader.value());
        TraceContext.put(traceId);
        return record;
    }

    @Override
    public void afterRecord(ConsumerRecord<String, String> record, Consumer<String, String> consumer) {
        TraceContext.clear();
    }
}
