package agent

import (
	"regexp"
	"strings"
)

var draftIDPattern = regexp.MustCompile(`([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})`)

func IsConfirm(message string) bool {
	normalized := strings.ReplaceAll(message, " ", "")
	return strings.Contains(normalized, "确认办理") ||
		normalized == "确认" ||
		normalized == "确定" ||
		strings.HasPrefix(normalized, "确认") ||
		strings.HasPrefix(strings.ToLower(normalized), "confirm")
}

func ExtractDraftID(message string) string {
	match := draftIDPattern.FindStringSubmatch(message)
	if len(match) > 1 {
		return match[1]
	}
	return ""
}

func Route(message, role string) []Call {
	if strings.TrimSpace(message) == "" || isExplicitOpen(message) {
		return nil
	}
	text := strings.ToLower(message)
	effective := role
	if effective == "" {
		effective = "DRIVER"
	}
	var calls []Call
	if containsAny(text, "违法", "违章", "处罚记录", "offense") {
		name := "query_offenses"
		if effective == "DRIVER" || effective == "USER" {
			name = "query_my_offenses"
		}
		calls = append(calls, Call{ID: "intent-" + name, Name: name})
	}
	if containsAny(text, "罚款", "缴款", "fine") {
		name := "query_fines"
		if effective == "DRIVER" || effective == "USER" {
			name = "query_my_fines"
		}
		calls = append(calls, Call{ID: "intent-" + name, Name: name})
	}
	if containsAny(text, "申诉", "appeal") {
		if containsAny(text, "提交", "申请", "我要申诉", "起草") {
			calls = append(calls, Call{ID: "intent-prepare_appeal", Name: "prepare_appeal"})
		} else if effective != "DRIVER" && effective != "USER" && containsAny(text, "审批", "审核") {
			calls = append(calls, Call{ID: "intent-query_appeals", Name: "query_appeals"})
		} else if effective == "DRIVER" || effective == "USER" {
			calls = append(calls, Call{ID: "intent-query_my_appeals", Name: "query_my_appeals"})
		} else {
			calls = append(calls, Call{ID: "intent-query_appeals", Name: "query_appeals"})
		}
	}
	if containsAny(text, "备份", "恢复") && containsAny(text, "打开", "进入", "系统") {
		calls = append(calls, Call{ID: "intent-navigate_backup", Name: "navigate_backup"})
	}
	return calls
}

func isExplicitOpen(message string) bool {
	return strings.Contains(message, "打开") || strings.Contains(message, "前往") || strings.Contains(message, "跳转到") || strings.Contains(message, "进入")
}

func containsAny(text string, parts ...string) bool {
	for _, part := range parts {
		if strings.Contains(text, strings.ToLower(part)) {
			return true
		}
	}
	return false
}
