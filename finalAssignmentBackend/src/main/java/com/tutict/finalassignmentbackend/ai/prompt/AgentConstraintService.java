package com.tutict.finalassignmentbackend.ai.prompt;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class AgentConstraintService {

    public static final String DEFAULT_BASE_PATH = "classpath:ai/agent-constraints/";

    private final ResourceLoader resourceLoader;
    private final String basePath;
    private final Map<AiAgentRole, String> cache = new ConcurrentHashMap<>();

    public AgentConstraintService(
            ResourceLoader resourceLoader,
            @Value("${ai.agent.constraints.base-path:" + DEFAULT_BASE_PATH + "}") String basePath
    ) {
        this.resourceLoader = resourceLoader;
        this.basePath = basePath.endsWith("/") ? basePath : basePath + "/";
    }

    public String constraintsFor(AiAgentRole role) {
        AiAgentRole resolvedRole = role == null ? AiAgentRole.DRIVER : role;
        return cache.computeIfAbsent(resolvedRole, this::load);
    }

    private String load(AiAgentRole role) {
        Resource resource = resourceLoader.getResource(basePath + role.policyFileName() + ".md");
        if (!resource.exists()) {
            throw new IllegalStateException("AI agent constraint file not found: " + resource.getDescription());
        }
        try {
            return resource.getContentAsString(StandardCharsets.UTF_8).strip();
        } catch (IOException e) {
            throw new IllegalStateException("Failed to read AI agent constraint file: " + resource.getDescription(), e);
        }
    }
}
