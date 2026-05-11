import { useCallback, useEffect, useRef, useState } from 'react';
import { API_PATHS } from '../constants/apiPaths.js';

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
