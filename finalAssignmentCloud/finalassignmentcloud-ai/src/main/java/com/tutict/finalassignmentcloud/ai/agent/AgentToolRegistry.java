package com.tutict.finalassignmentcloud.ai.agent;

import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Component
public class AgentToolRegistry {

    private final Map<String, AgentTool> tools = new LinkedHashMap<>();

    public AgentToolRegistry(List<AgentTool> tools) {
        for (AgentTool tool : tools) {
            this.tools.put(tool.name(), tool);
        }
    }

    public Optional<AgentTool> find(String name) {
        return Optional.ofNullable(tools.get(name));
    }

    public void register(AgentTool tool) {
        if (tool != null && tool.name() != null && !tool.name().isBlank()) {
            tools.put(tool.name(), tool);
        }
    }

    public List<AgentTool> toolsFor(AiAgentRole role) {
        AiAgentRole effective = role == null ? AiAgentRole.DRIVER : role;
        List<AgentTool> visible = new ArrayList<>();
        for (AgentTool tool : tools.values()) {
            if (tool.roles().contains(effective)) {
                visible.add(tool);
            }
        }
        return List.copyOf(visible);
    }

    public List<Map<String, Object>> openAiTools(AiAgentRole role) {
        List<Map<String, Object>> specs = new ArrayList<>();
        for (AgentTool tool : toolsFor(role)) {
            Map<String, Object> function = new LinkedHashMap<>();
            function.put("name", tool.name());
            function.put("description", tool.description());
            function.put("parameters", tool.parameterSchema());
            specs.add(Map.of("type", "function", "function", function));
        }
        return specs;
    }

    public List<String> namesFor(AiAgentRole role) {
        return toolsFor(role).stream().map(AgentTool::name).toList();
    }
}
