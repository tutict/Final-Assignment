package finalassignmentbackend.ai.agent;

import finalassignmentbackend.entity.AppealRecord;
import finalassignmentbackend.entity.FineRecord;
import finalassignmentbackend.entity.OffenseRecord;
import finalassignmentbackend.service.appeal.AppealManagementService;
import finalassignmentbackend.service.offense.FineRecordService;
import finalassignmentbackend.service.offense.OffenseRecordService;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@ApplicationScoped
public class AgentRuntime {

    private static final Pattern DRAFT_ID = Pattern.compile("([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})");

    @Inject OffenseRecordService offenseRecordService;
    @Inject FineRecordService fineRecordService;
    @Inject AppealManagementService appealManagementService;
    @Inject InMemoryDraftStore draftStore;

    public List<Map<String, Object>> execute(String message, AgentModels.Context context) {
        List<String> calls = route(message, context.role());
        List<Map<String, Object>> events = new ArrayList<>();
        for (String name : calls) {
            events.add(event("tool", context.sessionKey(), Map.of("phase", "start", "name", name)));
            Map<String, Object> args = new LinkedHashMap<>();
            Matcher matcher = DRAFT_ID.matcher(message == null ? "" : message);
            if (matcher.find()) args.put("draftId", matcher.group(1));
            AgentModels.Result result = invoke(name, context, args);
            events.addAll(toEvents(result, context, name));
            events.add(event("tool", context.sessionKey(), Map.of("phase", "end", "name", name, "ok", result.ok())));
        }
        return events;
    }

    public boolean bindSession(String userKey, String sessionKey) {
        return draftStore.bindSession(userKey, sessionKey);
    }

    private AgentModels.Result invoke(String name, AgentModels.Context context, Map<String, Object> args) {
        try {
            return switch (name) {
                case "query_my_offenses" -> queryOffenses(context, true);
                case "query_offenses" -> queryOffenses(context, false);
                case "query_my_fines" -> queryFines(context, true);
                case "query_fines" -> queryFines(context, false);
                case "query_my_appeals" -> queryAppeals(context, true);
                case "query_appeals" -> queryAppeals(context, false);
                case "prepare_appeal" -> prepareAppeal(context, args);
                case "prepare_offense_create" -> prepareOffense(context, args);
                case "confirm_draft" -> confirm(context, args, messageDraftId(args));
                case "navigate_backup" -> AgentModels.Result.action("备份恢复需要在系统页面人工确认，助手不会自动执行。", AgentModels.navigate("打开备份与恢复", "/admin/backupAndRestore"));
                default -> AgentModels.Result.error("未知工具: " + name);
            };
        } catch (RuntimeException ex) {
            return AgentModels.Result.error(ex.getMessage() == null ? "工具执行失败" : ex.getMessage());
        }
    }

    private AgentModels.Result queryOffenses(AgentModels.Context context, boolean self) {
        if (self && context.driverId() == null) return AgentModels.Result.error("当前账号尚未绑定驾驶员档案，无法查询违法记录。");
        if (self && !Set.of("DRIVER", "USER").contains(context.role()) && !"USER".equals(context.role())) {
            // still allow driver role
        }
        if (self) {
            List<OffenseRecord> records = offenseRecordService.findByDriverId(context.driverId(), 0, 10);
            return AgentModels.Result.result(records.isEmpty() ? "没有查询到您的违法记录。" : "共找到 " + records.size() + " 条违法记录。", summarizeOffenses(records), AgentModels.navigate("查看违法详情", "/userOffenseListPage"));
        }
        if (!isAdmin(context.role())) return AgentModels.Result.error("当前角色无权使用工具 query_offenses");
        List<OffenseRecord> records = offenseRecordService.findPage(0, 10).getRecords();
        return AgentModels.Result.result(records.isEmpty() ? "没有查询到违法记录。" : "共找到 " + records.size() + " 条违法记录。", summarizeOffenses(records), AgentModels.navigate("打开违法管理", "/offenseList"));
    }

    private AgentModels.Result queryFines(AgentModels.Context context, boolean self) {
        if (self && context.driverId() == null) return AgentModels.Result.error("当前账号尚未绑定驾驶员档案，无法查询罚款。");
        if (self) {
            List<FineRecord> records = fineRecordService.findByDriverId(context.driverId(), 0, 10);
            return AgentModels.Result.result(records.isEmpty() ? "没有查询到您的罚款记录。" : "共找到 " + records.size() + " 条罚款记录。", summarizeFines(records), AgentModels.navigate("查看罚款信息", "/fineInformation"));
        }
        if (!isAdmin(context.role())) return AgentModels.Result.error("当前角色无权使用工具 query_fines");
        List<FineRecord> records = fineRecordService.findAll();
        return AgentModels.Result.result(records.isEmpty() ? "没有查询到罚款记录。" : "共找到 " + records.size() + " 条罚款记录。", summarizeFines(records), AgentModels.navigate("打开罚款管理", "/fineInformation"));
    }

    private AgentModels.Result queryAppeals(AgentModels.Context context, boolean self) {
        if (self && context.driverId() == null) return AgentModels.Result.error("当前账号尚未绑定驾驶员档案，无法查询申诉。");
        if (self) {
            List<AppealRecord> records = appealManagementService.findByDriverId(context.driverId(), 0, 10);
            return AgentModels.Result.result(records.isEmpty() ? "没有查询到您的申诉记录。" : "共找到 " + records.size() + " 条申诉记录。", summarizeAppeals(records), AgentModels.navigate("查看我的申诉", "/userAppeal"));
        }
        if (!isAdmin(context.role())) return AgentModels.Result.error("当前角色无权使用工具 query_appeals");
        List<AppealRecord> records = appealManagementService.findByDriverId(context.driverId() == null ? -1L : context.driverId(), 0, 10);
        return AgentModels.Result.result(records.isEmpty() ? "没有查询到申诉记录。" : "共找到 " + records.size() + " 条申诉记录。", summarizeAppeals(records), AgentModels.navigate("打开申诉管理", "/appealManagement"));
    }

    private AgentModels.Result prepareAppeal(AgentModels.Context context, Map<String, Object> args) {
        if (!context.confirmed()) {
            AgentModels.Draft draft = new AgentModels.Draft(UUID.randomUUID().toString(), context.userKey(), context.sessionKey(),
                    "prepare_appeal", "即将提交申诉，请确认后办理。", "high", args, args, Instant.now().plus(Duration.ofMinutes(10)));
            draftStore.save(draft);
            return AgentModels.Result.draft(draft);
        }
        AppealRecord record = new AppealRecord();
        Object offenseId = args.get("offenseId");
        if (offenseId instanceof Number number) record.setOffenseId(number.longValue());
        AppealRecord saved = appealManagementService.createAppeal(record);
        return AgentModels.Result.result("申诉已提交，ID " + saved.getAppealId() + "。", List.of(Map.of("appealId", saved.getAppealId())), AgentModels.navigate("查看我的申诉", "/userAppeal"));
    }

    private AgentModels.Result prepareOffense(AgentModels.Context context, Map<String, Object> args) {
        if (!isAdmin(context.role())) return AgentModels.Result.error("当前角色无权使用工具 prepare_offense_create");
        if (!context.confirmed()) {
            AgentModels.Draft draft = new AgentModels.Draft(UUID.randomUUID().toString(), context.userKey(), context.sessionKey(),
                    "prepare_offense_create", "即将录入违法记录，请确认后办理。", "high", args, args, Instant.now().plus(Duration.ofMinutes(10)));
            draftStore.save(draft);
            return AgentModels.Result.draft(draft);
        }
        OffenseRecord record = new OffenseRecord();
        OffenseRecord saved = offenseRecordService.createOffenseRecord(record);
        return AgentModels.Result.result("违法记录已录入，ID " + saved.getOffenseId() + "。", List.of(Map.of("offenseId", saved.getOffenseId())), AgentModels.navigate("打开违法管理", "/offenseList"));
    }

    private AgentModels.Result confirm(AgentModels.Context context, Map<String, Object> args, String draftId) {
        if (draftId == null || draftId.isBlank()) {
            draftId = draftStore.lastDraftId(context.userKey(), context.sessionKey()).orElse(null);
        }
        AgentModels.Draft draft = draftStore.find(draftId).orElse(null);
        if (draft == null) return AgentModels.Result.error("没有待确认的办理草稿，或草稿已过期。");
        if (!context.userKey().equals(draft.userId())) return AgentModels.Result.error("不能确认其他用户的办理草稿。");
        AgentModels.Context confirmed = new AgentModels.Context(context.role(), context.sessionKey(), context.username(), context.userKey(), context.driverId(), true);
        AgentModels.Result result = invoke(draft.toolName(), confirmed, draft.payload() == null ? Map.of() : draft.payload());
        if (result.ok()) draftStore.delete(draft.draftId());
        return result;
    }

    private List<String> route(String message, String role) {
        if (message == null || message.isBlank()) return List.of();
        String compact = message.replaceAll("\\s+", "");
        if (compact.contains("确认办理") || compact.equals("确认") || compact.toLowerCase(Locale.ROOT).startsWith("confirm")) {
            return List.of("confirm_draft");
        }
        String text = message.toLowerCase(Locale.ROOT);
        boolean driver = "DRIVER".equals(role) || "USER".equals(role);
        List<String> calls = new ArrayList<>();
        if (contains(text, "违法", "违章", "offense")) calls.add(driver ? "query_my_offenses" : "query_offenses");
        if (contains(text, "罚款", "fine")) calls.add(driver ? "query_my_fines" : "query_fines");
        if (contains(text, "申诉", "appeal")) {
            if (contains(text, "提交", "申请", "起草")) calls.add("prepare_appeal");
            else calls.add(driver ? "query_my_appeals" : "query_appeals");
        }
        if (contains(text, "备份", "恢复") && contains(text, "打开", "进入", "系统")) calls.add("navigate_backup");
        return calls;
    }

    private static boolean contains(String text, String... parts) {
        for (String part : parts) if (text.contains(part.toLowerCase(Locale.ROOT))) return true;
        return false;
    }

    private static boolean isAdmin(String role) {
        return "ADMIN".equals(role) || "SUPER_ADMIN".equals(role);
    }

    private static String messageDraftId(Map<String, Object> args) {
        Object value = args.get("draftId");
        return value == null ? null : String.valueOf(value);
    }

    private List<Map<String, Object>> toEvents(AgentModels.Result result, AgentModels.Context context, String name) {
        List<Map<String, Object>> events = new ArrayList<>();
        if ("draft".equals(result.kind()) && result.draft() != null) {
            AgentModels.Draft draft = result.draft();
            events.add(event("draft", context.sessionKey(), Map.of(
                    "draftId", draft.draftId(), "summary", draft.summary(), "risk", draft.risk(),
                    "preview", draft.preview() == null ? Map.of() : draft.preview(),
                    "expiresAt", draft.expiresAt() == null ? "" : draft.expiresAt().toString())));
            return events;
        }
        if ("action".equals(result.kind()) && result.navigate() != null) {
            Map<String, Object> payload = new LinkedHashMap<>(result.navigate());
            payload.put("summary", result.summary());
            events.add(event("action", context.sessionKey(), payload));
            return events;
        }
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("name", name);
        payload.put("summary", result.summary());
        payload.put("ok", result.ok());
        payload.put("items", result.items());
        events.add(event("result", context.sessionKey(), payload));
        if (result.navigate() != null) {
            Map<String, Object> nav = new LinkedHashMap<>(result.navigate());
            nav.put("summary", result.summary());
            events.add(event("action", context.sessionKey(), nav));
        }
        return events;
    }

    private static Map<String, Object> event(String type, String sessionKey, Object payload) {
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("type", type);
        event.put("sessionKey", sessionKey);
        event.put("payload", payload);
        event.put("timestamp", Instant.now().toString());
        return event;
    }

    private static List<Map<String, Object>> summarizeOffenses(List<OffenseRecord> records) {
        List<Map<String, Object>> items = new ArrayList<>();
        for (OffenseRecord record : records) {
            items.add(Map.of("id", record.getOffenseId(), "number", n(record.getOffenseNumber()), "status", n(record.getProcessStatus())));
        }
        return items;
    }

    private static List<Map<String, Object>> summarizeFines(List<FineRecord> records) {
        List<Map<String, Object>> items = new ArrayList<>();
        for (FineRecord record : records) {
            items.add(Map.of("id", record.getFineId(), "amount", n(record.getFineAmount()), "status", n(record.getPaymentStatus())));
        }
        return items;
    }

    private static List<Map<String, Object>> summarizeAppeals(List<AppealRecord> records) {
        List<Map<String, Object>> items = new ArrayList<>();
        for (AppealRecord record : records) {
            items.add(Map.of("id", record.getAppealId(), "status", n(record.getProcessStatus())));
        }
        return items;
    }

    private static Object n(Object value) { return value == null ? "" : value; }
}
