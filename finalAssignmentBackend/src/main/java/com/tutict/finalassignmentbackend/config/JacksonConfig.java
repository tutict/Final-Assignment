package com.tutict.finalassignmentbackend.config;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.module.SimpleModule;
import org.springframework.boot.jackson.autoconfigure.JsonMapperBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import tools.jackson.core.JsonParser;
import tools.jackson.databind.DeserializationContext;
import tools.jackson.databind.ValueDeserializer;
import tools.jackson.databind.json.JsonMapper;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;

@Configuration
public class JacksonConfig {

    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.findAndRegisterModules();
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        mapper.disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);
        SimpleModule module = new SimpleModule("flexible-java-time-v2");
        module.addDeserializer(LocalDate.class, new Jackson2LocalDateDeserializer());
        module.addDeserializer(LocalDateTime.class, new Jackson2LocalDateTimeDeserializer());
        mapper.registerModule(module);
        return mapper;
    }

    @Bean
    public JsonMapperBuilderCustomizer flexibleJavaTime() {
        return builder -> {
            tools.jackson.databind.module.SimpleModule module =
                    new tools.jackson.databind.module.SimpleModule("flexible-java-time");
            module.addDeserializer(LocalDate.class, new Jackson3LocalDateDeserializer());
            module.addDeserializer(LocalDateTime.class, new Jackson3LocalDateTimeDeserializer());
            builder.addModule(module);
        };
    }

    static final class Jackson3LocalDateDeserializer extends ValueDeserializer<LocalDate> {
        @Override
        public LocalDate deserialize(JsonParser parser, DeserializationContext context) {
            return FlexibleTemporal.parseDate(parser.getValueAsString());
        }
    }

    static final class Jackson3LocalDateTimeDeserializer extends ValueDeserializer<LocalDateTime> {
        @Override
        public LocalDateTime deserialize(JsonParser parser, DeserializationContext context) {
            return FlexibleTemporal.parseDateTime(parser.getValueAsString());
        }
    }

    static final class Jackson2LocalDateDeserializer extends com.fasterxml.jackson.databind.JsonDeserializer<LocalDate> {
        @Override
        public LocalDate deserialize(com.fasterxml.jackson.core.JsonParser parser,
                                     com.fasterxml.jackson.databind.DeserializationContext context)
                throws java.io.IOException {
            return FlexibleTemporal.parseDate(parser.getValueAsString());
        }
    }

    static final class Jackson2LocalDateTimeDeserializer extends com.fasterxml.jackson.databind.JsonDeserializer<LocalDateTime> {
        @Override
        public LocalDateTime deserialize(com.fasterxml.jackson.core.JsonParser parser,
                                         com.fasterxml.jackson.databind.DeserializationContext context)
                throws java.io.IOException {
            return FlexibleTemporal.parseDateTime(parser.getValueAsString());
        }
    }

    static final class FlexibleTemporal {
        private FlexibleTemporal() {
        }

        static LocalDate parseDate(String raw) {
            String text = normalize(raw);
            if (text == null) {
                return null;
            }
            if (text.length() == 10) {
                return LocalDate.parse(text);
            }
            if (hasZone(text)) {
                try {
                    return OffsetDateTime.parse(text).atZoneSameInstant(ZoneId.systemDefault()).toLocalDate();
                } catch (DateTimeParseException ignored) {
                    // Use the calendar-date prefix below.
                }
            }
            if (text.length() >= 10 && text.charAt(4) == '-' && text.charAt(7) == '-') {
                return LocalDate.parse(text.substring(0, 10));
            }
            return LocalDate.parse(text);
        }

        static LocalDateTime parseDateTime(String raw) {
            String text = normalize(raw);
            if (text == null) {
                return null;
            }
            if (hasZone(text)) {
                try {
                    return OffsetDateTime.parse(text).atZoneSameInstant(ZoneId.systemDefault()).toLocalDateTime();
                } catch (DateTimeParseException ignored) {
                    // Fall through to local date-time parsing.
                }
            }
            if (text.length() == 10) {
                return LocalDate.parse(text).atStartOfDay();
            }
            if (text.length() == 16) {
                return LocalDateTime.parse(text + ":00");
            }
            return LocalDateTime.parse(text);
        }

        private static String normalize(String raw) {
            if (raw == null || raw.isBlank()) {
                return null;
            }
            return raw.trim().replace(' ', 'T');
        }

        private static boolean hasZone(String text) {
            return text.endsWith("Z") || text.contains("+") || text.lastIndexOf('-') > 7;
        }
    }
}
