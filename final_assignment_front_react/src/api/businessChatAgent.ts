/**
 * 本地业务动作解析器，对齐 Flutter BusinessChatAgent。
 * 在发起 AI 流式请求前，根据关键词命中把消息解析为一条可执行动作
 * （跳转到对应业务页面并携带预填信息）。未命中关键词时返回 null，
 * 由调用方继续走真正的 AI 流式回答。
 *
 * 路由名对齐 Flutter Routes.* 与 React 路由表（见 App.tsx）。
 * 预填字段：licensePlate（车牌）、businessNumber（业务编号）。
 */
import type { ChatAction, ChatActionResponse } from "../api/aiChat";

type Role = "USER" | "ADMIN" | "SUPER_ADMIN";

interface Prefill {
  licensePlate?: string;
  businessNumber?: string;
  source: "ai_chat";
}

const PLATE_RE =
  /[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼][A-Z][A-Z0-9]{5,6}/g;
const BUSINESS_NO_RE =
  /(?:违法|违章|处罚|申诉|业务|编号|单号|记录)[:\s#-]*([A-Za-z0-9]{5,})/g;

function extractPrefill(message: string): Prefill {
  const prefill: Prefill = { source: "ai_chat" };
  const plateMatch = message.toUpperCase().match(PLATE_RE);
  if (plateMatch && plateMatch.length > 0) {
    prefill.licensePlate = plateMatch[0];
  }
  const businessMatch = BUSINESS_NO_RE.exec(message);
  if (businessMatch && businessMatch[1]) {
    prefill.businessNumber = businessMatch[1];
  }
  return prefill;
}

function containsAny(text: string, keywords: string[]): boolean {
  return keywords.some((keyword) => text.includes(keyword));
}

interface ActionSpec {
  label: string;
  target: string;
  keywords: string[];
}

const DRIVER_ACTIONS: ActionSpec[] = [
  {
    label: "打开我的申诉",
    target: "/userAppeal",
    keywords: ["申诉", "异议", "复议", "撤销处罚"],
  },
  {
    label: "打开罚款缴纳",
    target: "/fineInformation",
    keywords: ["罚款", "缴费", "缴款", "缴纳", "支付"],
  },
  {
    label: "打开违法记录",
    target: "/userOffenseListPage",
    keywords: ["违法", "违章", "扣分", "记分", "处罚"],
  },
  {
    label: "打开车辆管理",
    target: "/vehicleManagement",
    keywords: ["车辆", "车牌", "登记", "绑定", "行驶证"],
  },
  {
    label: "打开进度消息",
    target: "/onlineProcessingProgress",
    keywords: ["进度", "消息", "办理状态", "处理结果"],
  },
  {
    label: "打开个人资料",
    target: "/personalMain",
    keywords: ["资料", "个人信息", "身份证", "驾驶证", "手机号"],
  },
  {
    label: "打开服务地图",
    // 对齐 Flutter Routes.map = /admin/map（仅注册在 AdminLayout 下）
    target: "/admin/map",
    keywords: ["地图", "位置", "附近", "导航"],
  },
];

const ADMIN_EXTRA: ActionSpec[] = [
  {
    label: "打开申诉审批",
    target: "/appealManagement",
    keywords: ["申诉", "审批", "审核", "复核"],
  },
  {
    label: "打开扣分管理",
    target: "/deductionManagement",
    keywords: ["扣分", "记分"],
  },
  {
    label: "打开罚款管理",
    target: "/fineList",
    keywords: ["罚款", "缴费", "缴款", "缴纳"],
  },
  {
    label: "打开驾驶员管理",
    target: "/driverList",
    keywords: ["司机", "驾驶员", "驾驶证"],
  },
  {
    label: "打开车辆管理",
    target: "/vehicleList",
    keywords: ["车辆", "车牌", "车架", "发动机"],
  },
  {
    label: "打开违法管理",
    target: "/offenseList",
    keywords: ["违法", "违章", "处罚", "违法行为"],
  },
  {
    label: "打开业务进度",
    target: "/progressManagement",
    keywords: ["进度", "消息", "处理状态", "办理状态"],
  },
];

const SUPER_ADMIN_EXTRA: ActionSpec[] = [
  {
    label: "打开 RAG 资料管理",
    target: "/admin/ragManagement",
    keywords: ["rag", "知识库", "知识", "资料录入", "向量"],
  },
  {
    label: "打开日志审查",
    target: "/admin/logManagement",
    keywords: ["日志", "审计", "操作记录", "登录记录"],
  },
  {
    label: "打开用户与权限",
    target: "/admin/userManagementPage",
    keywords: ["用户", "账号", "账户", "权限", "角色"],
  },
  {
    label: "打开系统治理",
    target: "/admin/systemGovernance",
    keywords: ["系统治理", "治理", "异常链路", "运维"],
  },
];

function resolveFromSpecs(
  message: string,
  specs: ActionSpec[]
): ChatActionResponse | null {
  for (const spec of specs) {
    if (containsAny(message, spec.keywords)) {
      const prefill = extractPrefill(message);
      const action: ChatAction = {
        type: "NAVIGATE",
        label: spec.label,
        target: spec.target,
        value: JSON.stringify({ agentPrefill: prefill, source: "ai_chat" }),
      };
      return {
        answer: "已识别到可执行业务动作，请点击下方按钮继续。",
        actions: [action],
        needConfirm: false,
      };
    }
  }
  return null;
}

/**
 * 解析用户消息为业务动作。对齐 Flutter BusinessChatAgent.resolve：
 * - SUPER_ADMIN 优先尝试超级管理员动作，再退回管理员动作；
 * - ADMIN 使用管理员动作；
 * - 其余使用驾驶员动作。
 * 未命中返回 null。
 */
export function resolveBusinessAction(
  message: string,
  role: Role
): ChatActionResponse | null {
  const normalized = message.trim().toLowerCase();
  if (!normalized) return null;

  if (role === "SUPER_ADMIN") {
    return (
      resolveFromSpecs(normalized, SUPER_ADMIN_EXTRA) ||
      resolveFromSpecs(normalized, ADMIN_EXTRA) ||
      resolveFromSpecs(normalized, DRIVER_ACTIONS)
    );
  }
  if (role === "ADMIN") {
    return resolveFromSpecs(normalized, ADMIN_EXTRA);
  }
  return resolveFromSpecs(normalized, DRIVER_ACTIONS);
}

/** 解析动作 value JSON，提取预填字段，对齐 Flutter _decodeActionArguments。 */
export function decodeActionValue(
  value: string | undefined
): { agentPrefill: Record<string, unknown>; [key: string]: unknown } {
  if (!value) return { agentPrefill: {} };
  try {
    const decoded = JSON.parse(value) as Record<string, unknown>;
    if (decoded && typeof decoded === "object") {
      return {
        agentPrefill:
          (decoded.agentPrefill as Record<string, unknown>) || {},
        ...decoded,
      };
    }
  } catch {
    /* ignore */
  }
  return { agentPrefill: { value } };
}
