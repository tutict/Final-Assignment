import { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import clsx from 'clsx';
import { useAuth } from '../auth/AuthContext';
import { decodeActionValue } from '../api/businessChatAgent';
import { useAiChatStream, type ChatMessage } from '../hooks/useAiChatStream';
import { useOptionalAgentWindow } from '../layouts/AgentWindowContext';

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

export interface AiChatPanelProps {
  compact?: boolean;
  onNavigate?: () => void;
}

type ChatSession = ReturnType<typeof useAiChatStream>;

export default function AiChatPanel(props: AiChatPanelProps) {
  const context = useOptionalAgentWindow();
  if (context) {
    return <AiChatPanelView chat={context.chat} {...props} />;
  }
  return <AiChatPanelWithLocalSession {...props} />;
}

function AiChatPanelWithLocalSession(props: AiChatPanelProps) {
  const chat = useAiChatStream();
  return <AiChatPanelView chat={chat} {...props} />;
}

interface AiChatPanelViewProps extends AiChatPanelProps {
  chat: ChatSession;
}

function AiChatPanelView({ compact = false, onNavigate, chat }: AiChatPanelViewProps) {
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
  } = chat;
  const { auth } = useAuth();
  const navigate = useNavigate();
  const role = (auth?.userRole || 'USER').toUpperCase();
  const emptyState = buildEmptyState(role);
  const predefined = role === 'USER' ? USER_PREDEFINED : MANAGER_PREDEFINED;
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, searchResults]);

  const handleExecuteAction = (
    action: { type?: string; label?: string; target?: string; value?: string },
    needConfirm?: boolean
  ) => {
    const run = () => {
      const target = action.target;
      if (!target) return;
      const decoded = decodeActionValue(action.value);
      navigate(target, { state: decoded });
      onNavigate?.();
    };
    if (needConfirm && !window.confirm('AI 给出了可执行动作，是否继续？')) {
      return;
    }
    run();
  };

  const isEmpty = messages.length === 0 && !error;

  return (
    <div className={clsx('chat-panel', compact && 'is-embedded')}>
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
          messages.map((msg, index) => (
            <ChatBubble
              key={msg.isThinkingPlaceholder ? `thinking-${index}` : `msg-${index}`}
              message={msg}
              index={index}
              onExecuteAction={handleExecuteAction}
              onConfirmDraft={(draftId) => sendMessage(`确认办理 ${draftId}`)}
              confirming={streaming}
            />
          ))
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
              if (event.key === 'Enter' && !event.shiftKey) {
                event.preventDefault();
                sendMessage();
              }
            }}
          />
          {streaming ? (
            <button type="button" className="ghost" onClick={stopStream}>
              停止
            </button>
          ) : (
            <button type="button" className="primary" onClick={() => sendMessage()} disabled={!input.trim()}>
              发送
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function ChatBubble({
  message,
  index,
  onExecuteAction,
  onConfirmDraft,
  confirming,
}: {
  message: ChatMessage;
  index: number;
  onExecuteAction: (
    action: { type?: string; label?: string; target?: string; value?: string },
    needConfirm?: boolean
  ) => void;
  onConfirmDraft?: (draftId: string) => void;
  confirming?: boolean;
}) {
  if (message.isThinkingPlaceholder) {
    return (
      <div className="chat-bubble assistant thinking">
        <span className="chat-thinking-spinner" aria-hidden="true" />
        <span>思考中...</span>
      </div>
    );
  }

  const roleClass = message.isSystem ? 'system' : message.role;
  const showDivider = Boolean(message.thinkContent && message.formalContent);

  return (
    <div className={`chat-bubble ${roleClass}`}>
      {message.thinkContent ? <span className="chat-think">{message.thinkContent}</span> : null}
      {showDivider ? <span className="chat-divider" /> : null}
      {message.formalContent ? <span className="chat-formal">{message.formalContent}</span> : null}
      {message.toolStatus ? <div className="chat-tool-status">{message.toolStatus}</div> : null}
      {message.results && message.results.length > 0 ? (
        <div className="chat-result-list">
          {message.results.map((result, resultIndex) => (
            <div key={`result-${index}-${resultIndex}`} className="chat-result-card">
              <div className="chat-result-summary">{result.summary}</div>
              {result.items && result.items.length > 0 ? (
                <ul>
                  {result.items.slice(0, 5).map((item, itemIndex) => (
                    <li key={`item-${resultIndex}-${itemIndex}`}>
                      {String(item.number || item.plate || item.title || item.id || JSON.stringify(item))}
                    </li>
                  ))}
                </ul>
              ) : null}
            </div>
          ))}
        </div>
      ) : null}
      {message.draft ? (
        <div className="chat-draft-card">
          <div className="chat-draft-title">待确认办理</div>
          <div>{message.draft.summary}</div>
          {message.draft.serviceName ? <div className="chat-draft-meta">将调用 {message.draft.serviceName}</div> : null}
          {message.draft.risk ? <div className="chat-draft-meta">风险：{message.draft.risk}</div> : null}
          <button
            type="button"
            className="primary"
            disabled={confirming || !message.draft.draftId}
            onClick={() => message.draft?.draftId && onConfirmDraft?.(message.draft.draftId)}
          >
            确认办理
          </button>
        </div>
      ) : null}
      {message.actions && message.actions.length > 0 ? (
        <div className="chat-actions">
          {message.actions.map((action, actionIndex) => (
            <button
              key={`action-${index}-${actionIndex}`}
              type="button"
              className="chip chat-action"
              onClick={() => onExecuteAction(action, false)}
            >
              {action.label || '打开页面'}
            </button>
          ))}
        </div>
      ) : null}
    </div>
  );
}
