import React from 'react';
import PageLayout from '../../components/PageLayout.jsx';
import { useAiChatStream } from '../../hooks/useAiChatStream.js';

export default function AiChatPage() {
  const {
    messages,
    input,
    setInput,
    webSearch,
    setWebSearch,
    streaming,
    send: sendMessage,
    stop: stopStream,
  } = useAiChatStream();

  const handleSend = () => sendMessage();
  const handleStop = () => stopStream();

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
