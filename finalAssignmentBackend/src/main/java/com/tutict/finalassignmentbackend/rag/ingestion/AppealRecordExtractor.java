package com.tutict.finalassignmentbackend.rag.ingestion;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.AppealRecord;
import com.tutict.finalassignmentbackend.rag.dto.RagSourceDocument;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Component
@ConditionalOnProperty(prefix = "rag", name = "enabled", havingValue = "true")
public class AppealRecordExtractor implements RagSourceExtractor<AppealRecord> {

    private static final String TABLE = "appeal_record";

    private final ObjectMapper objectMapper;

    public AppealRecordExtractor(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public String sourceTable() {
        return TABLE;
    }

    @Override
    public RagSourceDocument extract(AppealRecord source) {
        Objects.requireNonNull(source, "source must not be null");
        String sourceId = String.valueOf(Objects.requireNonNull(source.getAppealId(), "appealId must not be null"));
        String title = firstNonBlank(source.getAppealNumber(), "Appeal " + sourceId);
        String content = Stream.of(
                        line("appeal_number", source.getAppealNumber()),
                        line("offense_id", source.getOffenseId()),
                        line("appellant_name", source.getAppellantName()),
                        line("appeal_type", source.getAppealType()),
                        line("appeal_reason", source.getAppealReason()),
                        line("appeal_time", source.getAppealTime()),
                        line("evidence_description", source.getEvidenceDescription()),
                        line("acceptance_status", source.getAcceptanceStatus()),
                        line("rejection_reason", source.getRejectionReason()),
                        line("process_status", source.getProcessStatus()),
                        line("process_result", source.getProcessResult()),
                        line("remarks", source.getRemarks())
                )
                .filter(value -> !value.isBlank())
                .collect(Collectors.joining("\n"));

        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("source", TABLE);
        metadata.put("appeal_number", source.getAppealNumber());
        metadata.put("appeal_type", source.getAppealType());
        metadata.put("acceptance_status", source.getAcceptanceStatus());
        metadata.put("process_status", source.getProcessStatus());

        return new RagSourceDocument(
                "BUSINESS",
                TABLE,
                sourceId,
                version(source.getUpdatedAt(), source.getCreatedAt()),
                title,
                content,
                "USER",
                "/appeals/" + sourceId,
                writeJson(metadata),
                "appeal_reason"
        );
    }

    private String writeJson(Map<String, Object> metadata) {
        try {
            return objectMapper.writeValueAsString(metadata);
        } catch (JsonProcessingException error) {
            return "{}";
        }
    }

    private static String version(LocalDateTime updatedAt, LocalDateTime createdAt) {
        LocalDateTime versionTime = updatedAt != null ? updatedAt : createdAt;
        return versionTime == null ? "v1" : versionTime.toString();
    }

    private static String line(String key, Object value) {
        return value == null || value.toString().isBlank() ? "" : key + ": " + value;
    }

    private static String firstNonBlank(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
