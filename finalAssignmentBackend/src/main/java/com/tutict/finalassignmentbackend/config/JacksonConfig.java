package com.tutict.finalassignmentbackend.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JacksonConfig {

    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        // Register available Jackson modules (e.g. JavaTimeModule).
        mapper.findAndRegisterModules();
        return mapper;
    }
}
