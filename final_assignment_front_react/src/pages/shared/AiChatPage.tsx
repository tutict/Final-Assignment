import { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import PageLayout from '../../components/PageLayout';
import { useAiChatStream } from '../../hooks/useAiChatStream';
import { useAuth } from '../../auth/AuthContext';
import { decodeActionValue } from '../../api/businessChatAgent';

interface PredefinedQuestion {
  label: string;
  text: string;
}

const USER_PREDEFINED: PredefinedQuestion[] = [
  { label: '查询我的违法记录', text: '如何查询我的交通违法记录？' },
  { label: '罚款缴纳流程', text: '罚款缴纳流程是什么？' },
  { label: '申诉材料', text: '交通违法申诉需要哪些材料？' },
  { label: '罚款到期时间', text: '我的罚款什么时候到期？' },
  { label: '处理超速违法', text: '如何处理超速违法？' },
];

const MANAGER_PREDEFINED: PredefinedQuestion[] = [
  { label: '待办定位', text: '今天有哪些待办处理？' },
  { label: '申诉审批', text: '如何审核用户申诉？' },
  { label: '数据统计', text: '近期违法数据统计如何？' },
  { label: '业务管理', text: '如何处理驾驶员违法？' },
];

const USER_CAPABILITY_CHIPS = ['违法查询', '罚款缴纳', '申诉指引', '事故快处'];
const ADMIN_CAPABILITY_CHIPS = ['待办定位', '申诉审核', '数据统计', '业务管理'];
const SUPER_ADMIN_CAPABILITY_CHIPS = ['日志审查', 'RAG 资料', '异常链路', '系统治理'];

interface EmptyStateContent {
  title: string;
  subtitle: string;
  chips: string[];
}

function buildEmptyState(role: string): EmptyStateContent {
  if (role === 'SUPER_ADMIN') {
    return {
      title: '超级管理员助手',
      subtitle: '审查操作日志、维护 RAG 资料、分析异常链路和系统治理事项。',
      chips: SUPER_ADMIN_CAPABILITY_CHIPS,
    };
  }
  if (role === 'ADMIN') {
    return {
      title: '管理员业务助手',
      subtitle: '定位待办、查看处理进度、梳理申诉审批和数据管理口径。',
      chips: ADMIN_CAPABILITY_CHIPS,
    };
  }
  return {
    title: '驾驶员业务助手',
    subtitle: '查询违法、缴纳罚款、准备申诉材料并了解事故快处流程。',
    chips: USER_CAPABILITY_CHIPS,
  };
}

export default function AiChatPage() {
  const {
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
    newConversation,
  } = useAiChatStream();
  const { auth } = useAuth();
  const navigate = useNavigate();
  const role = (auth?.userRole || 'USER').toUpperCase();
  const emptyState = buildEmptyState(role);
  const predefined = role === 'USER' ? USER_PREDEFINED : MANAGER_PREDEFINED;

  const messagesEndRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, searchResults]);

  const handleSend = () => sendMessage();
  const handleStop = () => stopStream();

  const handleExecuteAction = (
    action: { type?: string; label?: string; target?: string; value?: string },
    needConfirm?: boolean
  ) => {
    const run = () => {
      const target = action.target;
      if (!target) return;
      const decoded = decodeActionValue(action.value);
      navigate(target, { state: decoded });
    };
    if (needConfirm) {
      if (window.confirm('AI 给出了可执行动作，是否继续？')) run();
      return;
    }
    run();
  };

  const isEmpty = messages.length === 0 && !error;

  return (
    <PageLayout
      title="AI 智能助手"
      subtitle="在线咨询 · 违法处理建议 · 业务指引"
      headerActions={
        <button
          type="button"
          className="ghost"
          onClick={newConversation}
          disabled={streaming}
        >
          新对话
        </button>
      }
    >
      <div className="chat-panel">
        {searchResults.length > 0 ? (
          <div className="chat-search-strip">
            <div className="chat-search-strip-title">联网搜索结果</div>
            <div className="chat-search-strip-list">
              {searchResults.map((result, index) => (
                <div key={`${index}-${result.slice(0, 16)}`} className="chat-search-item">
                  {result}
                </div>
              ))}
            </div>
          </div>
        ) : null}

        <div className="chat-messages">
          {isEmpty ? (
            <div className="chat-empty-state">
              <h3 className="chat-empty-title">{emptyState.title}</h3>
              <p className="chat-empty-subtitle">{emptyState.subtitle}</p>
              <div className="chat-empty-chips">
                {emptyState.chips.map((chip) => (
                  <span key={chip} className="chip">{chip}</span>
                ))}
              </div>
            </div>
          ) : (
            messages.map((msg, index) => {
              if (msg.isThinkingPlaceholder) {
                return (
                  <div key={`thinking-${index}`} className="chat-bubble assistant thinking">
                    <span className="chat-thinking-spinner" aria-hidden="true" />
                    <span>思考中...</span>
                  </div>
                );
              }
              const roleClass = msg.isSystem ? 'system' : msg.role;
              const showDivider = Boolean(msg.thinkContent && msg.formalContent);
              return (
                <div key={`msg-${index}`} className={`chat-bubble ${roleClass}`}>
                  {msg.thinkContent ? (
                    <span className="chat-think">{msg.thinkContent}</span>
                  ) : null}
                  {showDivider ? <span className="chat-divider" /> : null}
                  {msg.formalContent ? <span className="chat-formal">{msg.formalContent}</span> : null}
                  {msg.actions && msg.actions.length > 0 ? (
                    <div className="chat-actions">
                      {msg.actions.map((action, actionIndex) => (
                        <button
                          key={`action-${actionIndex}`}
                          type="button"
                          className="chip chat-action"
                          onClick={() => handleExecuteAction(action, msg.needConfirm)}
                        >
                          {action.label || '打开页面'}
                        </button>
                      ))}
                    </div>
                  ) : null}
                </div>
              );
            })
          )}
          <div ref={messagesEndRef} />
        </div>

        {!streaming ? (
          <div className="chat-predefined">
            {predefined.map((question) => (
              <button
                key={question.label}
                type="button"
                className="chip"
                onClick={() => {
                  setInput(question.text);
                  sendMessage(question.text);
                }}
              >
                {question.label}
              </button>
            ))}
          </div>
        ) : null}

        {error ? <div className="form-error chat-error">{error}</div> : null}

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
              placeholder="输入问题，按 Enter 发送"
              onKeyDown={(event) => {
                if (event.key === 'Enter') handleSend();
              }}
            />
            {streaming ? (
              <button type="button" className="ghost" onClick={handleStop}>
                停止
              </button>
            ) : (
              <button type="button" className="primary" onClick={handleSend} disabled={!input.trim()}>
                发送
              </button>
            )}
          </div>
        </div>
      </div>
    </PageLayout>
  );
}
