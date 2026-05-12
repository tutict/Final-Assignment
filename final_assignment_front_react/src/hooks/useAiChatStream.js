/**
 * @hook useAiChatStream
 * @description AI 聊天 SSE 流式 Hook，管理输入框状态、联网搜索开关、消息列表和 EventSource 生命周期。
 *
 * @param {{ apiBase?: string }} [options] - 可选 API base URL；默认使用 VITE_API_BASE_URL，开发环境回退到本地后端地址。
 *
 * @returns {{
 *   messages: Array<{ role: 'user'|'assistant', content: string }>,  // 聊天消息数组，assistant 消息会随 SSE chunk 增量覆盖最后一条内容
 *   input: string,  // 当前输入框内容
 *   setInput: import('react').Dispatch<import('react').SetStateAction<string>>,  // 更新输入框内容
 *   webSearch: boolean,  // 是否请求后端启用联网搜索
 *   setWebSearch: import('react').Dispatch<import('react').SetStateAction<boolean>>,  // 更新联网搜索开关
 *   streaming: boolean,  // SSE 是否正在接收数据
 *   send: (message?: string) => void,  // 发送消息；默认使用 input，空白消息会被忽略
 *   stop: () => void,  // 关闭当前 SSE 连接并结束 streaming 状态
 * }}
 *
 * @example
 * const { messages, input, setInput, streaming, send, stop } = useAiChatStream();
 * send('查询最近的处理进度');
 *
 * @notes
 * - send(message) 会先追加 user 消息，然后关闭旧 EventSource 并建立新的 SSE 连接。
 * - EventSource 在 send 时建立，在 stop、组件卸载、下一次 send 或 onerror 时关闭。
 * - EventSource 断连/报错时会关闭连接、停止 streaming，并清空 input。
 * - Hook 不维护独立 error 状态；调用方如需错误 UI，需要基于 streaming 或额外封装处理。
 */
import { useCallback, useEffect, useRef, useState } from 'react';
import { API_PATHS } from '../constants/apiPaths.js';

// @devFallback 开发环境 fallback，生产环境应由环境变量 VITE_API_URL 覆盖
const DEFAULT_API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8081';

function readChunk(eventData) {
  try {
    const data = JSON.parse(eventData);
    return data?.result?.output?.content || data?.message || eventData;
  } catch (error) {
    return eventData;
  }
}

export function useAiChatStream({ apiBase = DEFAULT_API_BASE } = {}) {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [webSearch, setWebSearch] = useState(false);
  const [streaming, setStreaming] = useState(false);
  const eventSourceRef = useRef(null);

  const closeStream = useCallback(() => {
    if (eventSourceRef.current) {
      eventSourceRef.current.close();
      eventSourceRef.current = null;
    }
  }, []);

  useEffect(() => closeStream, [closeStream]);

  const appendMessage = useCallback((role, content) => {
    setMessages((prev) => [...prev, { role, content }]);
  }, []);

  const send = useCallback(
    (message = input) => {
      const trimmedMessage = message.trim();
      if (!trimmedMessage) return;

      appendMessage('user', trimmedMessage);
      setStreaming(true);
      closeStream();

      const params = new URLSearchParams({
        message: trimmedMessage,
        webSearch: webSearch ? 'true' : 'false',
      });

      const eventSource = new EventSource(`${apiBase}${API_PATHS.AI_CHAT_STREAM}?${params.toString()}`);
      eventSourceRef.current = eventSource;
      let buffer = '';

      eventSource.onmessage = (event) => {
        buffer += readChunk(event.data);
        setMessages((prev) => {
          const next = [...prev];
          const last = next[next.length - 1];
          if (!last || last.role !== 'assistant') {
            next.push({ role: 'assistant', content: buffer });
          } else {
            next[next.length - 1] = { ...last, content: buffer };
          }
          return next;
        });
      };

      eventSource.onerror = () => {
        closeStream();
        setStreaming(false);
        setInput('');
      };
    },
    [apiBase, appendMessage, closeStream, input, webSearch]
  );

  const stop = useCallback(() => {
    closeStream();
    setStreaming(false);
  }, [closeStream]);

  return {
    messages,
    input,
    setInput,
    webSearch,
    setWebSearch,
    streaming,
    send,
    stop,
  };
}
