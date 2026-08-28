/**
 * 读取 AI 聊天动作导航传递的 route state，提取预填字段。
 * 对齐 Flutter _decodeActionArguments：location.state = { agentAction, agentPrefill }
 * agentPrefill 包含 licensePlate / businessNumber / source。
 */
import { useLocation } from 'react-router-dom';

export interface AgentPrefill {
  licensePlate?: string;
  businessNumber?: string;
  source?: string;
}

interface AgentRouteState {
  agentAction?: unknown;
  agentPrefill?: AgentPrefill;
  [key: string]: unknown;
}

/** 读取并消费 route state 中的 agentPrefill（一次性：读取后清除历史 state，避免刷新复现）。 */
export function useAgentPrefill(): AgentPrefill | null {
  const location = useLocation();
  const state = location.state as AgentRouteState | null;
  if (!state || !state.agentPrefill) return null;
  return state.agentPrefill;
}

/** 是否存在车牌预填。 */
export function hasPlatePrefill(prefill: AgentPrefill | null): prefill is AgentPrefill & {
  licensePlate: string;
} {
  return Boolean(prefill?.licensePlate);
}

/** 是否存在业务编号预填。 */
export function hasBusinessPrefill(prefill: AgentPrefill | null): prefill is AgentPrefill & {
  businessNumber: string;
} {
  return Boolean(prefill?.businessNumber);
}
