/**
 * AI 聊天流式接口（POST + SSE），对齐 Flutter AiChatApi / ChatControllerApi。
 *
 * 关键点：
 * - 使用 fetch + ReadableStream 而非 EventSource，因为后端是 POST 且需要带
 *   Authorization 头与 JSON body（EventSource 仅支持 GET 且无法自定义请求头）。
 * - SSE 事件类型：session / token / done / error / usage / keepalive。
 * - 思考片段（think 块）剥离为独立 think 文本，其余为正式回复，
 *   对齐 Flutter removeMarkdown + _splitThinkAndFormal。
 * - 维护 sessionKey 与会话窗口（最近 10 轮），随请求回传服务端以保持上下文。
 */
import { API_PATHS } from "../constants/apiPaths";
import { getAccessToken } from "../auth/tokens";

const DEFAULT_API_BASE =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:8081";

const SSE_OVERALL_TIMEOUT_MS = 90_000;
const FIRST_TOKEN_TIMEOUT_MS = 45_000;

export type AiStreamEventType =
  | "session"
  | "token"
  | "done"
  | "error"
  | "usage"
  | "keepalive"
  | "unknown";

export interface AiStreamEvent {
  type: AiStreamEventType;
  rawType: string;
  sessionKey?: string;
  messageId?: string;
  token?: string;
  payload?: Record<string, unknown>;
  timestamp?: string;
}

export interface ChatStreamChunk {
  text: string;
  sessionKey?: string;
  messageId?: string;
  isFallback: boolean;
  fallbackReason?: string;
}

export interface ChatStreamHandlers {
  onChunk: (chunk: ChatStreamChunk) => void;
  onError?: (message: string) => void;
  onDone?: () => void;
}

export interface ChatStreamSession {
  cancel: () => void;
}

export interface ConversationTurn {
  role: "user" | "assistant";
  content: string;
}

export interface StreamChatOptions {
  message: string;
  sessionKey?: string;
  webSearch?: boolean;
  conversationWindow?: ConversationTurn[];
  apiBase?: string;
}

interface CancelToken {
  canceled: boolean;
  callbacks: Array<() => void>;
  cancel: () => void;
  onCancel: (fn: () => void) => void;
}

function createCancelToken(): CancelToken {
  const token: CancelToken = {
    canceled: false,
    callbacks: [],
    cancel: () => {
      if (token.canceled) return;
      token.canceled = true;
      token.callbacks.forEach((fn) => {
        try {
          fn();
        } catch {
          /* ignore */
        }
      });
      token.callbacks = [];
    },
    onCancel: (fn: () => void) => {
      if (token.canceled) {
        fn();
      } else {
        token.callbacks.push(fn);
      }
    },
  };
  return token;
}

const WIRE_TO_TYPE: Record<string, AiStreamEventType> = {
  session: "session",
  token: "token",
  done: "done",
  error: "error",
  usage: "usage",
  keepalive: "keepalive",
};

function lookupType(rawType: string | undefined): AiStreamEventType {
  if (!rawType) return "unknown";
  return WIRE_TO_TYPE[rawType] || "unknown";
}

function parseEvent(rawEvent: string, eventName?: string): AiStreamEvent | null {
  const trimmed = rawEvent.trim();
  if (!trimmed) return null;
  try {
    const data = JSON.parse(trimmed) as Record<string, unknown>;
    const rawType = (data.type as string | undefined) ?? eventName ?? "unknown";
    const payload = data.payload;
    return {
      type: lookupType(rawType),
      rawType,
      sessionKey: data.sessionKey as string | undefined,
      messageId: data.messageId as string | undefined,
      token: data.token as string | undefined,
      payload:
        payload && typeof payload === "object"
          ? (payload as Record<string, unknown>)
          : undefined,
      timestamp: data.timestamp as string | undefined,
    };
  } catch {
    return null;
  }
}

const THINK_OPEN = "<" + "think" + ">";
const THINK_CLOSE = "</" + "think" + ">";
const THINK_TAG_RE = /<\/?think>/g;

/**
 * 剥离 Markdown 与思考推理标记，对齐 Flutter removeMarkdown。
 * 思考块被替换为 [THINK]...[/THINK]，随后由调用方拆分为 think / formal。
 */
export function cleanAiText(text: string): string {
  const thinkBlockRe = new RegExp(
    THINK_OPEN.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") +
      "([\\s\\S]*?)" +
      THINK_CLOSE.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"),
    "g"
  );
  let out = text.replace(thinkBlockRe, (_m, inner: string) =>
    "[THINK]" + inner + "[/THINK]"
  );
  out = out.replace(THINK_TAG_RE, "");
  out = out.replace(/\*\*(.*?)\*\*/g, "$1");
  out = out.replace(/\*(.*?)\*/g, "$1");
  out = out.replace(/##(.*?)##/g, "$1");
  out = out.replace(/_(.*?)_/g, "$1");
  out = out.replace(/-(.*?)-/g, "$1");
  out = out.replace(/###(.*?)###/g, "$1");
  return out.trim();
}

/** 将一段文本拆分为 [thinkPart, formalPart]，对齐 Flutter _splitThinkAndFormal。 */
export function splitThinkAndFormal(text: string): [string, string] {
  let think = "";
  let formal = text;
  const thinkRegex = /\[THINK\]([\s\S]*?)\[\/THINK\]/g;
  const matches = text.matchAll(thinkRegex);
  for (const match of matches) {
    think += (match[1] || "").trim();
  }
  formal = text.replace(/\[THINK\]([\s\S]*?)\[\/THINK\]/g, "").trim();
  return [think, formal];
}

function isFallback(event: AiStreamEvent): boolean {
  return Boolean(event.payload?.isFallback || event.payload?.fallback);
}

function fallbackReason(event: AiStreamEvent): string | undefined {
  const payload = event.payload;
  if (!payload) return undefined;
  return (
    (payload.reason as string | undefined) ??
    (payload.fallback_reason as string | undefined)
  );
}

function eventMessage(event: AiStreamEvent): string {
  const payload = event.payload;
  return (payload?.message as string | undefined) ?? "AI stream failed";
}

interface SseBuffer {
  dataLines: string[];
  eventName: string | undefined;
}

/** 从流式文本增量中切分 SSE 帧（支持跨 chunk 的帧拆分）。 */
function appendSseChunk(
  buffer: { leftover: string },
  chunk: string,
  onEvent: (rawData: string, eventName: string | undefined) => void
): void {
  buffer.leftover += chunk;
  let frame: SseBuffer = { dataLines: [], eventName: undefined };
  let idx = buffer.leftover.indexOf("\n");
  while (idx !== -1) {
    const line = buffer.leftover.slice(0, idx).replace(/\r$/, "");
    buffer.leftover = buffer.leftover.slice(idx + 1);
    if (line === "") {
      if (frame.dataLines.length > 0) {
        onEvent(frame.dataLines.join("\n"), frame.eventName);
      }
      frame = { dataLines: [], eventName: undefined };
    } else if (line.startsWith(":")) {
      // SSE 注释，忽略
    } else if (line.startsWith("event:")) {
      frame.eventName = line.slice(6).trim();
    } else if (line.startsWith("data:")) {
      frame.dataLines.push(line.slice(5).replace(/^\s/, ""));
    } else if (line.startsWith("data")) {
      frame.dataLines.push(line.slice(4).replace(/^\s/, ""));
    }
    idx = buffer.leftover.indexOf("\n");
  }
}

export function streamChat(
  options: StreamChatOptions,
  handlers: ChatStreamHandlers
): ChatStreamSession {
  const cancelToken = createCancelToken();
  const apiBase = options.apiBase ?? DEFAULT_API_BASE;
  let aborted = false;
  let firstTokenReceived = false;
  const controller = new AbortController();
  cancelToken.onCancel(() => {
    if (aborted) return;
    aborted = true;
    try {
      controller.abort();
    } catch {
      /* ignore */
    }
  });

  const overallTimer = window.setTimeout(() => {
    if (!firstTokenReceived && !cancelToken.canceled) {
      cancelToken.cancel();
      handlers.onError?.("AI 服务响应超时，请稍后重试");
    }
  }, SSE_OVERALL_TIMEOUT_MS);

  const firstTokenTimer = window.setTimeout(() => {
    if (!firstTokenReceived && !cancelToken.canceled) {
      cancelToken.cancel();
      handlers.onError?.("AI 服务返回了无效的流格式");
    }
  }, FIRST_TOKEN_TIMEOUT_MS);

  (async () => {
    const body = {
      message: options.message,
      ...(options.sessionKey ? { sessionKey: options.sessionKey } : {}),
      metadata: {
        ...(options.webSearch ? { webSearchRequested: true } : {}),
        ...(options.conversationWindow
          ? { conversationWindow: options.conversationWindow }
          : {}),
      },
    };
    const token = getAccessToken();
    let response: Response;
    try {
      response = await fetch(`${apiBase}${API_PATHS.AI_CHAT_STREAM}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          Accept: "text/event-stream",
          "Cache-Control": "no-cache",
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify(body),
        signal: controller.signal,
      });
    } catch (error) {
      window.clearTimeout(overallTimer);
      window.clearTimeout(firstTokenTimer);
      if (cancelToken.canceled) return;
      handlers.onError?.((error as Error)?.message || "AI 流式请求失败");
      return;
    }

    if (!response.ok || !response.body) {
      window.clearTimeout(overallTimer);
      window.clearTimeout(firstTokenTimer);
      if (cancelToken.canceled) return;
      let message = `AI 流式请求失败：${response.status}`;
      try {
        const text = await response.text();
        const data = text ? JSON.parse(text) : null;
        const msg = data?.message ?? data?.error;
        if (msg) message = String(msg);
      } catch {
        /* ignore */
      }
      handlers.onError?.(message);
      return;
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder("utf-8");
    const buffer = { leftover: "" };
    try {
      while (true) {
        if (cancelToken.canceled) break;
        const { done, value } = await reader.read();
        if (done) break;
        const text = decoder.decode(value, { stream: true });
        appendSseChunk(buffer, text, (rawData, eventName) => {
          const event = parseEvent(rawData, eventName);
          if (!event) return;
          switch (event.type) {
            case "token": {
              const raw = event.token ?? "";
              const cleaned = cleanAiText(raw);
              if (!cleaned) break;
              firstTokenReceived = true;
              window.clearTimeout(firstTokenTimer);
              handlers.onChunk({
                text: cleaned,
                sessionKey: event.sessionKey,
                messageId: event.messageId,
                isFallback: isFallback(event),
                fallbackReason: fallbackReason(event),
              });
              break;
            }
            case "done": {
              window.clearTimeout(overallTimer);
              window.clearTimeout(firstTokenTimer);
              handlers.onDone?.();
              aborted = true;
              try {
                controller.abort();
              } catch {
                /* ignore */
              }
              break;
            }
            case "error": {
              window.clearTimeout(overallTimer);
              window.clearTimeout(firstTokenTimer);
              handlers.onError?.(eventMessage(event));
              aborted = true;
              try {
                controller.abort();
              } catch {
                /* ignore */
              }
              break;
            }
            case "session":
            case "usage":
            case "keepalive":
            case "unknown":
            default:
              break;
          }
        });
      }
    } catch (error) {
      if (!cancelToken.canceled) {
        handlers.onError?.((error as Error)?.message || "AI 流式读取失败");
      }
    } finally {
      window.clearTimeout(overallTimer);
      window.clearTimeout(firstTokenTimer);
      if (!aborted) handlers.onDone?.();
    }
  })();

  return { cancel: cancelToken.cancel };
}

/** GET /api/ai/chat/actions —— 获取结构化动作建议（对齐 Flutter getChatActions）。 */
export interface ChatAction {
  type?: string;
  label?: string;
  target?: string;
  value?: string;
}

export interface ChatActionResponse {
  answer?: string;
  actions?: ChatAction[];
  needConfirm?: boolean;
}

/**
 * GET /api/ai/chat/actions?message=&webSearch=
 * 注意：Flutter 实际 UI 使用本地 BusinessChatAgent 解析动作，此端点已定义但未被
 * ChatController.sendMessage 调用。保留以备服务端驱动的动作建议。
 */
export async function getChatActions(
  message: string,
  webSearch = false
): Promise<ChatActionResponse | null> {
  const token = getAccessToken();
  let response: Response;
  try {
    response = await fetch(
      `${DEFAULT_API_BASE}${API_PATHS.AI_CHAT_ACTIONS}?message=${encodeURIComponent(message)}&webSearch=${webSearch}`,
      {
        method: "GET",
        headers: {
          Accept: "application/json",
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
      }
    );
  } catch {
    return null;
  }
  if (response.status === 204 || response.status === 404) return null;
  if (!response.ok) return null;
  try {
    const data = (await response.json()) as ChatActionResponse;
    return {
      answer: data.answer,
      actions: Array.isArray(data.actions) ? data.actions : [],
      needConfirm: data.needConfirm === true,
    };
  } catch {
    return null;
  }
}
