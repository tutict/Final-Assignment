package handler

import (
	"encoding/json"
	"net/http"
	"regexp"
	"strings"
	"unicode"

	"github.com/gin-gonic/gin"
)

type chatAction struct {
	Type   string `json:"type"`
	Label  string `json:"label"`
	Target string `json:"target"`
	Value  string `json:"value"`
}

type chatActionResponse struct {
	Answer      string       `json:"answer"`
	Actions     []chatAction `json:"actions"`
	NeedConfirm bool         `json:"needConfirm"`
	IsFallback  bool         `json:"isFallback"`
}

type chatActionValue struct {
	Source  string            `json:"source"`
	Role    string            `json:"role"`
	Prefill map[string]string `json:"prefill"`
}

type chatActionResult struct {
	Answer string
	Label  string
	Target string
}

type chatActionRule struct {
	keywords []string
	result   chatActionResult
}

var driverChatActionRules = []chatActionRule{
	{
		keywords: []string{"违法详情", "违法记录", "违法处理", "交通违法", "查看违法", "offense detail", "violation detail"},
		result:   chatActionResult{Answer: "已定位到违法详情页面，可查看个人违法记录、状态和关联车辆信息。", Label: "查看违法详情", Target: "/userOffenseListPage"},
	},
	{
		keywords: []string{"罚款缴纳", "缴纳罚款", "交罚款", "罚款支付", "fine payment", "pay fine"},
		result:   chatActionResult{Answer: "已定位到罚款缴纳页面，可继续核对缴款信息并办理支付。", Label: "办理罚款缴纳", Target: "/fineInformation"},
	},
	{
		keywords: []string{"用户申诉", "提交申诉", "我要申诉", "申诉材料", "申诉办理", "submit appeal", "my appeal"},
		result:   chatActionResult{Answer: "已定位到用户申诉页面，可提交材料并跟踪处理进度。", Label: "提交用户申诉", Target: "/userAppeal"},
	},
	{
		keywords: []string{"车辆登记", "登记车辆", "绑定车辆", "我的车辆", "vehicle registration", "register vehicle"},
		result:   chatActionResult{Answer: "已定位到车辆登记管理页面，可补充或维护车辆信息。", Label: "维护车辆登记", Target: "/vehicleManagement"},
	},
	{
		keywords: []string{"办理进度", "进度消息", "处理进度", "消息进度", "progress message", "case progress"},
		result:   chatActionResult{Answer: "已定位到进度消息页面，可查看业务处理进展。", Label: "查看进度消息", Target: "/onlineProcessingProgress"},
	},
	{
		keywords: []string{"个人资料", "个人信息", "驾驶证信息", "身份证信息", "profile", "personal info"},
		result:   chatActionResult{Answer: "已定位到个人资料页面，可补全身份信息和驾驶证信息。", Label: "维护个人资料", Target: "/personalMain"},
	},
	{
		keywords: []string{"地图", "附近", "网点", "导航", "map", "nearby"},
		result:   chatActionResult{Answer: "已定位到地图页面，可查看周边服务位置。", Label: "打开地图", Target: "/admin/map"},
	},
}

var adminChatActionRules = []chatActionRule{
	{
		keywords: []string{"rag", "知识库", "资料录入", "文档录入", "向量", "检索资料"},
		result:   chatActionResult{Answer: "已定位到 RAG 资料管理页面，可录入文档、表格并维护检索资料。", Label: "打开 RAG 资料管理", Target: "/ragManagement"},
	},
	{
		keywords: []string{"申诉审批", "申诉管理", "审核申诉", "申诉办理", "appeal management", "appeal approval"},
		result:   chatActionResult{Answer: "已定位到申诉审批管理页面，可处理驾驶员提交的申诉。", Label: "打开申诉审批", Target: "/appealManagement"},
	},
	{
		keywords: []string{"扣分管理", "扣分处理", "deduction management"},
		result:   chatActionResult{Answer: "已定位到扣分管理页面，可维护违法扣分记录。", Label: "打开扣分管理", Target: "/deductionManagement"},
	},
	{
		keywords: []string{"罚款管理", "缴款管理", "fine management"},
		result:   chatActionResult{Answer: "已定位到罚款管理页面，可查询和处理罚款记录。", Label: "打开罚款管理", Target: "/fineList"},
	},
	{
		keywords: []string{"司机管理", "驾驶员管理", "driver management"},
		result:   chatActionResult{Answer: "已定位到司机管理页面，可查询和维护司机档案。", Label: "打开司机管理", Target: "/driverList"},
	},
	{
		keywords: []string{"车辆管理", "vehicle management"},
		result:   chatActionResult{Answer: "已定位到车辆管理页面，可查询和维护车辆档案。", Label: "打开车辆管理", Target: "/vehicleList"},
	},
	{
		keywords: []string{"违法行为管理", "违法管理", "违法处理", "交通违法", "offense management", "violation management"},
		result:   chatActionResult{Answer: "已定位到违法行为管理页面，可处理违法记录。", Label: "打开违法管理", Target: "/offenseList"},
	},
	{
		keywords: []string{"进度管理", "业务进度", "progress management"},
		result:   chatActionResult{Answer: "已定位到进度管理页面，可跟踪业务办理状态。", Label: "打开进度管理", Target: "/progressManagement"},
	},
}

var superAdminChatActionRules = []chatActionRule{
	{
		keywords: []string{"日志审查", "操作日志", "登录日志", "审计日志", "operation log", "login log"},
		result:   chatActionResult{Answer: "已定位到日志审查页面，可查看登录和操作审计记录。", Label: "打开日志审查", Target: "/admin/logManagement"},
	},
	{
		keywords: []string{"用户权限", "角色权限", "权限管理", "用户管理", "role permission", "user management"},
		result:   chatActionResult{Answer: "已定位到用户权限管理页面，可维护用户、角色和权限。", Label: "打开用户权限管理", Target: "/admin/userManagementPage"},
	},
	{
		keywords: []string{"系统治理", "系统配置", "治理", "system governance"},
		result:   chatActionResult{Answer: "已定位到系统治理页面，可查看治理规则和运行状态。", Label: "打开系统治理", Target: "/admin/systemGovernance"},
	},
}

const unsupportedChatActionAnswer = "未找到可跳转的页面，请直接描述要办理的业务，例如「违法详情」「罚款缴纳」或「申诉审批」。"

var (
	chatActionLicensePlatePattern = regexp.MustCompile(`(?i)[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领][A-Z][A-Z0-9]{5,6}`)
	chatActionPhonePattern        = regexp.MustCompile(`(?:^|[^0-9])(1[3-9][0-9]{9})(?:[^0-9]|$)`)
	chatActionIDCardPattern       = regexp.MustCompile(`(?:^|[^0-9])([0-9]{17}[0-9Xx])(?:[^0-9]|$)`)
)

// GetChatActions handles GET /api/ai/chat/actions.
// 规则命中时直接返回导航动作，未命中时给出引导答案，不调用模型，避免压测下的生成抖动。
func (h *AiChatHandler) GetChatActions(c *gin.Context) {
	message := strings.TrimSpace(c.Query("message"))
	if message == "" {
		message = strings.TrimSpace(c.Query("massage"))
	}
	if message == "" {
		c.JSON(http.StatusBadRequest, apiError("INVALID_MESSAGE", "message must not be blank"))
		return
	}

	role := chatActionRole(c)
	response := chatActionResponse{
		Answer:  unsupportedChatActionAnswer,
		Actions: []chatAction{},
	}
	if rule, ok := matchChatActionRule(message, role); ok {
		response.Answer = rule.Answer
		response.Actions = []chatAction{{
			Type:   "NAVIGATE",
			Label:  rule.Label,
			Target: rule.Target,
			Value:  chatActionValueJSON(role, message),
		}}
	}
	c.JSON(http.StatusOK, apiOK(response))
}

func chatActionRole(c *gin.Context) string {
	if memberOfRole(c, "SUPER_ADMIN") {
		return "super_admin"
	}
	if memberOfRole(c, "ADMIN") {
		return "admin"
	}
	return "driver"
}

func matchChatActionRule(message string, role string) (chatActionResult, bool) {
	rules := driverChatActionRules
	switch role {
	case "super_admin":
		rules = append(append([]chatActionRule{}, superAdminChatActionRules...), adminChatActionRules...)
	case "admin":
		rules = adminChatActionRules
	}
	normalized := normalizeChatActionMessage(message)
	for _, rule := range rules {
		for _, keyword := range rule.keywords {
			if strings.Contains(normalized, normalizeChatActionMessage(keyword)) {
				return rule.result, true
			}
		}
	}
	return chatActionResult{}, false
}

func normalizeChatActionMessage(value string) string {
	return strings.Map(func(r rune) rune {
		if unicode.IsSpace(r) {
			return -1
		}
		return unicode.ToLower(r)
	}, value)
}

func chatActionValueJSON(role string, message string) string {
	value := chatActionValue{
		Source:  "chat_action_rule",
		Role:    role,
		Prefill: extractChatActionPrefill(message),
	}
	raw, err := json.Marshal(value)
	if err != nil {
		return "{}"
	}
	return string(raw)
}

func extractChatActionPrefill(message string) map[string]string {
	prefill := map[string]string{}
	if match := chatActionLicensePlatePattern.FindString(message); match != "" {
		prefill["licensePlate"] = strings.ToUpper(match)
	}
	if match := chatActionPhonePattern.FindStringSubmatch(message); len(match) > 1 {
		prefill["phone"] = match[1]
	}
	if match := chatActionIDCardPattern.FindStringSubmatch(message); len(match) > 1 {
		prefill["idCard"] = strings.ToUpper(match[1])
	}
	return prefill
}
