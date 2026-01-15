import React, { useEffect, useRef, useState } from 'react';
import PageLayout from '../../components/PageLayout.jsx';

export default function AiChatPage() {
  const apiBase = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8081';
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [webSearch, setWebSearch] = useState(false);
  const [streaming, setStreaming] = useState(false);
  const eventSourceRef = useRef(null);

  useEffect(() => {
    return () => {
      if (eventSourceRef.current) {
        eventSourceRef.current.close();
      }
    };
  }, []);

  const appendMessage = (role, content) => {
    setMessages((prev) => [...prev, { role, content }]);
  };

  const handleSend = () => {
    if (!input.trim()) return;
    appendMessage('user', input.trim());
    setStreaming(true);

    if (eventSourceRef.current) {
      eventSourceRef.current.close();
    }

    const params = new URLSearchParams({
      message: input.trim(),
      webSearch: webSearch ? 'true' : 'false',
    });

    const url = `${apiBase}/api/ai/chat?${params.toString()}`;
    const eventSource = new EventSource(url);
    eventSourceRef.current = eventSource;

    let buffer = '';

    eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        const chunk = data?.result?.output?.content || data?.message || event.data;
        buffer += chunk;
      } catch (error) {
        buffer += event.data;
      }
      setMessages((prev) => {
        const next = [...prev];
        const last = next[next.length - 1];
        if (!last || last.role !== 'assistant') {
          next.push({ role: 'assistant', content: buffer });
        } else {
          last.content = buffer;
        }
        return [...next];
      });
    };

    eventSource.onerror = () => {
      eventSource.close();
      eventSourceRef.current = null;
      setStreaming(false);
      setInput('');
    };
  };

  const handleStop = () => {
    if (eventSourceRef.current) {
      eventSourceRef.current.close();
      eventSourceRef.current = null;
    }
    setStreaming(false);
  };

  return (
    <PageLayout title="AI 智能助手" subtitle="在线咨询 · 违法处理建议 · 业务指引">
      <div className="chat-panel">
        <div className="chat-messages">
          {messages.length === 0 ? (
            <div className="chat-empty">输入问题开始对话</div>
          ) : (
            messages.map((msg, index) => (
              <div key={`${msg.role}-${index}`} className={`chat-bubble ${msg.role}`}>
                <span>{msg.content}</span>
              </div>
            ))
          )}
        </div>
        <div className="chat-controls">
          <label className="toggle">
            <input
              type="checkbox"
              checked={webSearch}
              onChange={(event) => setWebSearch(event.target.checked)}
            />
            联网检索
          </label>
          <div className="chat-input">
            <input
              type="text"
              value={input}
              onChange={(event) => setInput(event.target.value)}
              placeholder="请输入问题，例如：如何处理超速罚单？"
              onKeyDown={(event) => {
                if (event.key === 'Enter') handleSend();
              }}
            />
            <button type="button" className="primary" onClick={handleSend} disabled={streaming}>
              发送
            </button>
            {streaming ? (
              <button type="button" className="ghost" onClick={handleStop}>
                停止
              </button>
            ) : null}
          </div>
        </div>
      </div>
    </PageLayout>
  );
}
