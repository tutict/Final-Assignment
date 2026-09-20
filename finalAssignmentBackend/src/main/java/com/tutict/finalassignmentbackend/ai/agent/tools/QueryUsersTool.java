package com.tutict.finalassignmentbackend.ai.agent.tools;

import com.tutict.finalassignmentbackend.ai.agent.AgentArgs;
import com.tutict.finalassignmentbackend.ai.agent.AgentDrafts;
import com.tutict.finalassignmentbackend.ai.agent.AgentTool;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolContext;
import com.tutict.finalassignmentbackend.ai.agent.AgentToolResult;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.entity.admin.SysUser;
import com.tutict.finalassignmentbackend.service.admin.SysUserService;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class QueryUsersTool implements AgentTool {
    private final SysUserService sysUserService;

    public QueryUsersTool(SysUserService sysUserService) {
        this.sysUserService = sysUserService;
    }

    @Override public String name() { return "query_users"; }
    @Override public String description() { return "超级管理员只读查询用户账号与状态，不返回证件号、手机号或密码。"; }
    @Override public Map<String, Object> parameterSchema() { return AgentDrafts.schema(); }
    @Override public Set<AiAgentRole> roles() { return Set.of(AiAgentRole.SUPER_ADMIN); }
    @Override public boolean mutation() { return false; }

    @Override
    public AgentToolResult execute(AgentToolContext context, Map<String, Object> arguments) {
        int size = AgentArgs.size(arguments, 10);
        String query = AgentArgs.str(arguments, "query", "username");
        List<SysUser> users = query == null || query.isBlank()
                ? sysUserService.findAll()
                : sysUserService.searchByUsernameFuzzy(query, 0, size);
        if (users.size() > size) {
            users = users.subList(0, size);
        }
        List<Map<String, Object>> items = new ArrayList<>();
        for (SysUser user : users) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", user.getUserId());
            item.put("username", user.getUsername());
            item.put("status", user.getStatus());
            item.put("department", user.getDepartment());
            items.add(item);
        }
        return AgentToolResult.result(
                items.isEmpty() ? "没有查询到用户。" : "共找到 " + items.size() + " 个用户账号。",
                items,
                AgentDrafts.navigate("打开用户与权限", "/admin/userManagementPage")
        );
    }
}
