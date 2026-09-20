package com.tutict.finalassignmentcloud.ai.agent;

import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class AgentIntentRouter {

    private static final Pattern DRAFT_ID = Pattern.compile(
            "([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})"
    );

    public boolean isConfirm(String message) {
        if (message == null) {
            return false;
        }
        String normalized = message.replaceAll("\\s+", "");
        return normalized.contains("确认办理")
                || normalized.equals("确认")
                || normalized.equals("确定")
                || normalized.startsWith("确认")
                || normalized.toLowerCase(Locale.ROOT).startsWith("confirm");
    }

    public String extractDraftId(String message) {
        if (message == null) {
            return null;
        }
        Matcher matcher = DRAFT_ID.matcher(message);
        return matcher.find() ? matcher.group(1) : null;
    }

    public List<AgentToolCall> route(String message, AiAgentRole role) {
        if (message == null || message.isBlank() || isExplicitOpen(message)) {
            return List.of();
        }
        String text = message.toLowerCase(Locale.ROOT);
        AiAgentRole effective = role == null ? AiAgentRole.DRIVER : role;
        List<AgentToolCall> calls = new ArrayList<>();
        if (isConfirm(message)) {
            Map<String, Object> args = new LinkedHashMap<>();
            String draftId = extractDraftId(message);
            if (draftId != null) {
                args.put("draftId", draftId);
            }
            calls.add(new AgentToolCall("intent-confirm", "confirm_draft", args));
            return calls;
        }
        if (containsAny(text, "违法", "违章", "处罚记录", "offense")) {
            calls.add(call(effective == AiAgentRole.DRIVER ? "query_my_offenses" : "query_offenses"));
        }
        if (containsAny(text, "罚款", "缴款", "fine")) {
            calls.add(call(effective == AiAgentRole.DRIVER ? "query_my_fines" : "query_fines"));
        }
        if (containsAny(text, "申诉", "appeal")) {
            if (containsAny(text, "提交", "申请", "我要申诉", "起草")) {
                calls.add(call("prepare_appeal"));
            } else if (effective != AiAgentRole.DRIVER && containsAny(text, "审批", "审核")) {
                calls.add(call("query_appeals"));
            } else {
                calls.add(call(effective == AiAgentRole.DRIVER ? "query_my_appeals" : "query_appeals"));
            }
        }
        if (containsAny(text, "车辆", "车牌", "绑车")) {
            if (containsAny(text, "绑定", "登记", "录入")) {
                calls.add(call("prepare_vehicle_bind"));
            } else {
                calls.add(call(effective == AiAgentRole.DRIVER ? "query_my_vehicles" : "query_vehicles"));
            }
        }
        if (containsAny(text, "进度", "办理状态", "处理结果")) {
            calls.add(call("query_progress"));
        }
        if (containsAny(text, "资料", "个人信息", "驾驶证") && containsAny(text, "改", "补", "更新")) {
            calls.add(call("prepare_profile_update"));
        }
        if (effective != AiAgentRole.DRIVER && containsAny(text, "驾驶员", "司机")) {
            calls.add(call("query_drivers"));
        }
        if (effective != AiAgentRole.DRIVER && containsAny(text, "录入违法", "新增违法", "创建违法")) {
            calls.add(call("prepare_offense_create"));
        }
        if (effective != AiAgentRole.DRIVER && containsAny(text, "审批通过", "驳回申诉", "审核申诉")) {
            calls.add(call("prepare_appeal_review"));
        }
        if (effective == AiAgentRole.SUPER_ADMIN && containsAny(text, "日志", "审计")) {
            calls.add(call("query_logs"));
        }
        if (effective == AiAgentRole.SUPER_ADMIN && containsAny(text, "用户", "账号", "角色")) {
            calls.add(call("query_users"));
        }
        if (effective == AiAgentRole.SUPER_ADMIN && containsAny(text, "rag", "知识库", "资料录入")) {
            if (containsAny(text, "录入", "上传", "写入")) {
                calls.add(call("ingest_rag_document"));
            } else {
                calls.add(call("query_rag_status"));
            }
        }
        if (containsAny(text, "备份", "恢复") && containsAny(text, "打开", "进入", "系统")) {
            calls.add(call("navigate_backup"));
        }
        return calls;
    }

    private static AgentToolCall call(String name) {
        return new AgentToolCall("intent-" + name, name, Map.of());
    }

    private static boolean isExplicitOpen(String message) {
        return message.contains("打开") || message.contains("前往") || message.contains("跳转到") || message.contains("进入");
    }

    private static boolean containsAny(String text, String... parts) {
        for (String part : parts) {
            if (text.contains(part.toLowerCase(Locale.ROOT))) {
                return true;
            }
        }
        return false;
    }
}
