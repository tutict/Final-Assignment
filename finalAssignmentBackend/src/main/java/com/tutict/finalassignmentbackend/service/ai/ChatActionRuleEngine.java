package com.tutict.finalassignmentbackend.service.ai;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.model.ai.ChatAction;
import com.tutict.finalassignmentbackend.model.ai.ChatActionResponse;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class ChatActionRuleEngine {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
    private static final Pattern LICENSE_PLATE_PATTERN = Pattern.compile(
            "[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领][A-Z][A-Z0-9]{5,6}",
            Pattern.CASE_INSENSITIVE
    );
    private static final Pattern PHONE_PATTERN = Pattern.compile("(?<!\\d)1[3-9]\\d{9}(?!\\d)");
    private static final Pattern ID_CARD_PATTERN = Pattern.compile("(?<!\\d)\\d{17}[0-9Xx](?!\\d)");

    private static final List<ActionRule> DRIVER_RULES = List.of(
            new ActionRule(List.of("违法详情", "违法记录", "违法处理", "交通违法", "查看违法", "offense detail", "violation detail"),
                    "已定位到违法详情页面，可查看个人违法记录、状态和关联车辆信息。",
                    "查看违法详情", "/userOffenseListPage"),
            new ActionRule(List.of("罚款缴纳", "缴纳罚款", "交罚款", "罚款支付", "fine payment", "pay fine"),
                    "已定位到罚款缴纳页面，可继续核对缴款信息并办理支付。",
                    "办理罚款缴纳", "/fineInformation"),
            new ActionRule(List.of("用户申诉", "提交申诉", "我要申诉", "申诉材料", "申诉办理", "submit appeal", "my appeal"),
                    "已定位到用户申诉页面，可提交材料并跟踪处理进度。",
                    "提交用户申诉", "/userAppeal"),
            new ActionRule(List.of("车辆登记", "登记车辆", "绑定车辆", "我的车辆", "vehicle registration", "register vehicle"),
                    "已定位到车辆登记管理页面，可补充或维护车辆信息。",
                    "维护车辆登记", "/vehicleManagement"),
            new ActionRule(List.of("办理进度", "进度消息", "处理进度", "消息进度", "progress message", "case progress"),
                    "已定位到进度消息页面，可查看业务处理进展。",
                    "查看进度消息", "/onlineProcessingProgress"),
            new ActionRule(List.of("个人资料", "个人信息", "驾驶证信息", "身份证信息", "profile", "personal info"),
                    "已定位到个人资料页面，可补全身份信息和驾驶证信息。",
                    "维护个人资料", "/personalMain"),
            new ActionRule(List.of("地图", "附近", "网点", "导航", "map", "nearby"),
                    "已定位到地图页面，可查看周边服务位置。",
                    "打开地图", "/admin/map")
    );

    private static final List<ActionRule> ADMIN_RULES = List.of(
            new ActionRule(List.of("申诉审批", "申诉管理", "审核申诉", "申诉办理", "appeal management", "appeal approval"),
                    "已定位到申诉审批管理页面，可处理驾驶员提交的申诉。",
                    "打开申诉审批", "/appealManagement"),
            new ActionRule(List.of("扣分管理", "扣分处理", "deduction management"),
                    "已定位到扣分管理页面，可维护违法扣分记录。",
                    "打开扣分管理", "/deductionManagement"),
            new ActionRule(List.of("罚款管理", "缴款管理", "fine management"),
                    "已定位到罚款管理页面，可查询和处理罚款记录。",
                    "打开罚款管理", "/fineList"),
            new ActionRule(List.of("司机管理", "驾驶员管理", "driver management"),
                    "已定位到司机管理页面，可查询和维护司机档案。",
                    "打开司机管理", "/driverList"),
            new ActionRule(List.of("车辆管理", "vehicle management"),
                    "已定位到车辆管理页面，可查询和维护车辆档案。",
                    "打开车辆管理", "/vehicleList"),
            new ActionRule(List.of("违法行为管理", "违法管理", "违法处理", "交通违法", "offense management", "violation management"),
                    "已定位到违法行为管理页面，可处理违法记录。",
                    "打开违法管理", "/offenseList"),
            new ActionRule(List.of("进度管理", "业务进度", "progress management"),
                    "已定位到进度管理页面，可跟踪业务办理状态。",
                    "打开进度管理", "/progressManagement")
    );

    private static final List<ActionRule> SUPER_ADMIN_RULES = List.of(
            new ActionRule(List.of("rag", "知识库", "资料录入", "文档录入", "向量", "检索资料"),
                    "已定位到 RAG 资料管理页面，可录入文档、表格并维护检索资料。",
                    "打开 RAG 资料管理", "/admin/ragManagement"),
            new ActionRule(List.of("日志审查", "操作日志", "登录日志", "审计日志", "operation log", "login log"),
                    "已定位到日志审查页面，可查看登录和操作审计记录。",
                    "打开日志审查", "/admin/logManagement"),
            new ActionRule(List.of("用户权限", "角色权限", "权限管理", "用户管理", "role permission", "user management"),
                    "已定位到用户权限管理页面，可维护用户、角色和权限。",
                    "打开用户权限管理", "/admin/userManagementPage"),
            new ActionRule(List.of("系统治理", "系统配置", "治理", "system governance"),
                    "已定位到系统治理页面，可查看治理规则和运行状态。",
                    "打开系统治理", "/admin/systemGovernance")
    );

    public Optional<ChatActionResponse> resolve(String message, AiAgentRole role) {
        if (message == null || message.isBlank()) {
            return Optional.empty();
        }
        AiAgentRole effectiveRole = role == null ? AiAgentRole.DRIVER : role;
        String normalizedMessage = normalize(message);
        for (ActionRule rule : actionRulesFor(effectiveRole)) {
            if (rule.matches(normalizedMessage)) {
                return Optional.of(toResponse(rule, effectiveRole, message));
            }
        }
        return Optional.empty();
    }

    private static List<ActionRule> actionRulesFor(AiAgentRole role) {
        List<ActionRule> rules = new ArrayList<>();
        if (role == AiAgentRole.SUPER_ADMIN) {
            rules.addAll(SUPER_ADMIN_RULES);
            rules.addAll(ADMIN_RULES);
            return rules;
        }
        if (role == AiAgentRole.ADMIN) {
            rules.addAll(ADMIN_RULES);
            return rules;
        }
        rules.addAll(DRIVER_RULES);
        return rules;
    }

    private static ChatActionResponse toResponse(ActionRule rule, AiAgentRole role, String message) {
        ChatAction action = new ChatAction(
                "NAVIGATE",
                rule.label(),
                rule.target(),
                encodeValue(role, message)
        );
        return new ChatActionResponse(rule.answer(), List.of(action), false);
    }

    private static String encodeValue(AiAgentRole role, String message) {
        Map<String, Object> value = new LinkedHashMap<>();
        value.put("source", "chat_action_rule");
        value.put("role", role.policyFileName());
        value.put("prefill", extractPrefill(message));
        try {
            return OBJECT_MAPPER.writeValueAsString(value);
        } catch (JsonProcessingException ex) {
            return "{}";
        }
    }

    private static Map<String, String> extractPrefill(String message) {
        Map<String, String> prefill = new LinkedHashMap<>();
        addFirstMatch(prefill, "licensePlate", LICENSE_PLATE_PATTERN, message);
        addFirstMatch(prefill, "phone", PHONE_PATTERN, message);
        addFirstMatch(prefill, "idCard", ID_CARD_PATTERN, message);
        return prefill;
    }

    private static void addFirstMatch(Map<String, String> target, String key, Pattern pattern, String message) {
        Matcher matcher = pattern.matcher(message);
        if (matcher.find()) {
            target.put(key, matcher.group().toUpperCase(Locale.ROOT));
        }
    }

    private static String normalize(String value) {
        return value.toLowerCase(Locale.ROOT).replaceAll("\\s+", "");
    }

    private record ActionRule(List<String> keywords, String answer, String label, String target) {
        private boolean matches(String normalizedMessage) {
            return keywords.stream()
                    .map(ChatActionRuleEngine::normalize)
                    .anyMatch(normalizedMessage::contains);
        }
    }
}
