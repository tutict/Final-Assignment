/**
 * AI 聊天视图模型，对齐 Flutter ChatController + ChatControllerApi。
 *
 * 关键点（对齐 Flutter）：
 * - 先用本地 BusinessChatAgent.resolve 解析消息；命中关键词则推送用户气泡 +
 *   系统(动作)气泡并直接返回，不发起流式请求。
 * - 否则发起 POST + SSE 流式请求（api/aiChat.streamChat），按 token 事件增量
 *   拼接 think/formal 文本，维护会话窗口（最近 10 轮）与 sessionKey。
 * - 思考块剥离为独立 think 文本；正式回复前缀 "DeepSeek: "。
 * - 联网检索开启时，token 中以 [SEARCH] 开头的内容归入搜索结果条而非气泡。
 * - 等待首个 token 时显示 "思考中..."/THINKING 占位气泡，首 token 到达后移除。
 * - fallback token 显示为系统气泡，不加 DeepSeek 前缀、不参与历史窗口。
 */
import { useCallback, useEffect, useRef, useState } from "react";
import {
  streamChat,
  splitThinkAndFormal,
  cleanAiText,
  type ChatStreamChunk,
  type ChatStreamSession,
  type ConversationTurn,
} from "../api/aiChat";
import { resolveBusinessAction } from "../api/businessChatAgent";
import { useAuth } from "../auth/AuthContext";

export type ChatRole = "user" | "assistant" | "system";

export interface ChatMessage {
  role: ChatRole;
  thinkContent: string;
  formalContent: string;
  isSystem: boolean;
  /** THINKING 占位气泡（流式生成中） */
  isThinkingPlaceholder?: boolean;
  /** 预填动作建议（系统气泡） */
  actions?: { type?: string; label?: string; target?: string; value?: string }[];
  needConfirm?: boolean;
}

const MAX_WINDOW = 10;
const DEEPSEEK_PREFIX = "DeepSeek: ";
const LIST_START_RE = /^\s*(\d+\.\s+|[-*]\s+)/m;

/** 判定字符串是否以列表开头（对齐 Flutter finalThinkContent 清空逻辑）。 */
function startsAsList(text: string): boolean {
  return LIST_START_RE.test(text.trim());
}

/** 正式回复前缀 "DeepSeek: "（对齐 Flutter _updateAiMessage）。 */
function withPrefix(text: string): string {
  const trimmed = text.trim();
  return trimmed ? `${DEEPSEEK_PREFIX}${trimmed}` : "";
}

export function useAiChatStream() {
  const { auth } = useAuth();
  const role = (auth?.userRole || "USER").toUpperCase() as
    | "USER"
    | "ADMIN"
    | "SUPER_ADMIN";

  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState("");
  const [webSearch, setWebSearch] = useState(false);
  const [streaming, setStreaming] = useState(false);
  const [searchResults, setSearchResults] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);

  // sessionKey 仅存内存（对齐 Flutter _sessionKey，不持久化）
  const sessionRef = useRef<string | null>(null);
  const sessionHandleRef = useRef<ChatStreamSession | null>(null);
  const messageIndexRef = useRef<number>(-1);
  const thinkBufferRef = useRef<string>("");
  const formalBufferRef = useRef<string>("");

  const closeStream = useCallback(() => {
    sessionHandleRef.current?.cancel();
    sessionHandleRef.current = null;
  }, []);

  useEffect(() => closeStream, [closeStream]);

  const removeThinkingPlaceholders = useCallback(() => {
    setMessages((prev) => prev.filter((msg) => !msg.isThinkingPlaceholder));
  }, []);

  /** 把已积累的 think/formal 文本写回对应索引的气泡。 */
  const flushAiMessage = useCallback((index: number, isFinal: boolean) => {
    const think = thinkBufferRef.current;
    let formal = formalBufferRef.current;
    if (isFinal && startsAsList(formal)) {
      // 对齐 Flutter：正式回复以列表开头时清空思考内容
      setMessages((prev) =>
        prev.map((msg, i) =>
          i === index
            ? {
                ...msg,
                thinkContent: "",
                formalContent: withPrefix(formal),
                isThinkingPlaceholder: false,
              }
            : msg
        )
      );
      return;
    }
    setMessages((prev) =>
      prev.map((msg, i) =>
        i === index
          ? {
              ...msg,
              thinkContent: think.trim(),
              formalContent: withPrefix(formal),
              isThinkingPlaceholder: false,
            }
          : msg
      )
    );
  }, []);

  /** 构造会话窗口（最近 10 轮，排除系统/思考占位/空内容，对齐 Flutter）。 */
  const buildConversationWindow = useCallback(
    (msgs: ChatMessage[]): ConversationTurn[] => {
      const usable = msgs.filter(
        (msg) =>
          !msg.isSystem &&
          !msg.isThinkingPlaceholder &&
          (msg.formalContent || msg.thinkContent)
      );
      const recent = usable.slice(-MAX_WINDOW);
      return recent.map((msg) => {
        let content = msg.formalContent;
        if (msg.role === "assistant" && content.startsWith(DEEPSEEK_PREFIX)) {
          content = content.slice(DEEPSEEK_PREFIX.length);
        }
        return { role: msg.role === "user" ? "user" : "assistant", content: content.trim() };
      });
    },
    []
  );

  const processChunk = useCallback(
    (chunk: ChatStreamChunk) => {
      // 捕获 sessionKey（对齐 Flutter _sessionKey 在首个带 sessionKey 的 token 上记录）
      if (!sessionRef.current && chunk.sessionKey) {
        sessionRef.current = chunk.sessionKey;
      }

      // fallback：显示为系统气泡，不加前缀、不参与历史
      if (chunk.isFallback) {
        removeThinkingPlaceholders();
        setMessages((prev) => [
          ...prev,
          {
            role: "system",
            thinkContent: "",
            formalContent: chunk.text,
            isSystem: true,
          },
        ]);
        return;
      }

      let token = chunk.text;
      // 联网搜索结果以 [SEARCH] 开头时归入搜索结果条
      if (webSearch && token.startsWith("[SEARCH]")) {
        const snippet = token.slice("[SEARCH]".length).trim();
        if (snippet) {
          setSearchResults((prev) => [...prev, snippet]);
        }
        return;
      }

      // 增量清理后拆分为 think / formal，累加到缓冲区
      const cleaned = cleanAiText(token);
      if (!cleaned) return;

      const [thinkPart, formalPart] = splitThinkAndFormal(cleaned);
      if (thinkPart) thinkBufferRef.current += thinkPart;
      if (formalPart) formalBufferRef.current += formalPart;

      const index = messageIndexRef.current;
      if (index >= 0) flushAiMessage(index, false);
    },
    [webSearch, flushAiMessage, removeThinkingPlaceholders]
  );

  const sendMessage = useCallback(
    (messageText?: string) => {
      const message = (messageText ?? input).trim();
      if (!message || streaming) return;
      setInput("");
      setError(null);

      // 1) 先尝试本地业务动作解析（对齐 Flutter BusinessChatAgent）
      const businessAction = resolveBusinessAction(message, role);
      if (businessAction && businessAction.actions?.length) {
        setMessages((prev) => [
          ...prev,
          {
            role: "user",
            thinkContent: "",
            formalContent: message,
            isSystem: false,
          },
          {
            role: "system",
            thinkContent: "",
            formalContent:
              businessAction.answer ||
              "已识别到可执行业务动作，请点击下方按钮继续。",
            isSystem: true,
            actions: businessAction.actions,
            needConfirm: businessAction.needConfirm,
          },
        ]);
        return;
      }

      // 2) 推入用户气泡 + THINKING 占位气泡
      setMessages((prev) => {
        const next = [
          ...prev,
          {
            role: "user" as ChatRole,
            thinkContent: "",
            formalContent: message,
            isSystem: false,
          },
          {
            role: "assistant" as ChatRole,
            thinkContent: "",
            formalContent: "THINKING: " + (webSearch ? "Searching..." : "Thinking..."),
            isSystem: false,
            isThinkingPlaceholder: true,
          },
        ];
        messageIndexRef.current = next.length - 1;
        return next;
      });

      thinkBufferRef.current = "";
      formalBufferRef.current = "";
      setStreaming(true);

      const conversationWindow = buildConversationWindow(
        messages.filter((m) => !m.isThinkingPlaceholder)
      );

      const handle = streamChat(
        {
          message,
          sessionKey: sessionRef.current || undefined,
          webSearch,
          conversationWindow,
        },
        {
          onChunk: processChunk,
          onError: (msg) => {
            removeThinkingPlaceholders();
            setStreaming(false);
            setError(msg);
            setMessages((prev) => [
              ...prev,
              {
                role: "system",
                thinkContent: "",
                formalContent: `Error: ${msg}`,
                isSystem: true,
              },
            ]);
          },
          onDone: () => {
            const index = messageIndexRef.current;
            if (index >= 0) flushAiMessage(index, true);
            setStreaming(false);
          },
        }
      );
      sessionHandleRef.current = handle;
    },
    [
      input,
      streaming,
      role,
      webSearch,
      buildConversationWindow,
      processChunk,
      flushAiMessage,
      removeThinkingPlaceholders,
    ]
  );

  const stopStream = useCallback(() => {
    closeStream();
    removeThinkingPlaceholders();
    setStreaming(false);
  }, [closeStream, removeThinkingPlaceholders]);

  const clearMessages = useCallback(() => {
    closeStream();
    sessionRef.current = null;
    setMessages([]);
    setSearchResults([]);
    setError(null);
    setStreaming(false);
  }, [closeStream]);

  const startNewConversation = useCallback(() => {
    closeStream();
    sessionRef.current = null;
    setMessages([]);
    setSearchResults([]);
    setError(null);
    setStreaming(false);
  }, [closeStream]);

  return {
    messages,
    input,
    setInput,
    webSearch,
    setWebSearch,
    streaming,
    error,
    searchResults,
    send: sendMessage,
    stop: stopStream,
    clear: clearMessages,
    newConversation: startNewConversation,
  };
}
