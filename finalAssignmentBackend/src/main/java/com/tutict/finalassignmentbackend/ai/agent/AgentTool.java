package com.tutict.finalassignmentbackend.ai.agent;

import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;

import java.util.Map;
import java.util.Set;

public interface AgentTool {

    String name();

    String description();

    Map<String, Object> parameterSchema();

    Set<AiAgentRole> roles();

    boolean mutation();

    default String risk() {
        return mutation() ? "high" : "low";
    }

    default String serviceName() {
        return name();
    }

    AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments);
}
