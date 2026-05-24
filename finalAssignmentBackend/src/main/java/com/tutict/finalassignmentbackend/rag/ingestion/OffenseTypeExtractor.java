package com.tutict.finalassignmentbackend.rag.ingestion;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.entity.offense.OffenseTypeDict;
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
public class OffenseTypeExtractor implements RagSourceExtractor<OffenseTypeDict> {

    private static final String TABLE = "offense_type_dict";

    private final ObjectMapper objectMapper;

    public OffenseTypeExtractor(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public String sourceTable() {
        return TABLE;
    }

    @Override
    public RagSourceDocument extract(OffenseTypeDict source) {
        Objects.requireNonNull(source, "source must not be null");
        String sourceId = String.valueOf(Objects.requireNonNull(source.getTypeId(), "typeId must not be null"));
        String title = firstNonBlank(
                join(" - ", source.getOffenseCode(), source.getOffenseName()),
                "Offense Type " + sourceId
        );
        String content = Stream.of(
                        line("offense_code", source.getOffenseCode()),
                        line("offense_name", source.getOffenseName()),
                        line("category", source.getCategory()),
                        line("description", source.getDescription()),
                        line("standard_fine_amount", source.getStandardFineAmount()),
                        line("min_fine_amount", source.getMinFineAmount()),
                        line("max_fine_amount", source.getMaxFineAmount()),
                        line("deducted_points", source.getDeductedPoints()),
                        line("detention_days", source.getDetentionDays()),
                        line("license_suspension_days", source.getLicenseSuspensionDays()),
                        line("severity_level", source.getSeverityLevel()),
                        line("legal_basis", source.getLegalBasis()),
                        line("status", source.getStatus()),
                        line("remarks", source.getRemarks())
                )
                .filter(value -> !value.isBlank())
                .collect(Collectors.joining("\n"));

        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("source", TABLE);
        metadata.put("offense_code", source.getOffenseCode());
        metadata.put("category", source.getCategory());
        metadata.put("severity_level", source.getSeverityLevel());

        return new RagSourceDocument(
                "BUSINESS",
                TABLE,
                sourceId,
                version(source.getUpdatedAt(), source.getCreatedAt()),
                title,
                content,
                "PUBLIC",
                "/offense-types/" + sourceId,
                writeJson(metadata),
                "description"
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

    private static String join(String separator, String first, String second) {
        return Stream.of(first, second)
                .filter(value -> value != null && !value.isBlank())
                .collect(Collectors.joining(separator));
    }

    private static String firstNonBlank(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
