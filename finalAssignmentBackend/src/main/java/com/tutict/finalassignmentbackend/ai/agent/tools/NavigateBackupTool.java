package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;

@Component
public class NavigateBackupTool implements AgentTool {
    @Override public String name() { return "navigate_backup"; }
    @Override public String description() { return "只跳转到备份恢复页面，不执行备份或恢复。"; }
    @Override public Map<String, Object> parameterSchema() { return Map.of("type", "object", "properties", Map.of()); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }

    @Override
    public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        return AgentToolResult.action(
                "备份恢复需要在系统页面人工确认，助手不会自动执行。",
                AgentDrafts.navigate("打开备份与恢复", "/admin/backupAndRestore")
        );
    }
}
