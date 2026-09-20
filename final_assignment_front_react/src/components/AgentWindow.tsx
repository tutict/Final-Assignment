import { useEffect, useRef } from 'react';
import { useLocation } from 'react-router-dom';
import { FiStar, FiX } from 'react-icons/fi';
import clsx from 'clsx';
import { useAgentWindow } from '../layouts/AgentWindowContext';
import AiChatPanel from './AiChatPanel';

const NARROW_QUERY = '(max-width: 1024px)';

export default function AgentWindow() {
  const { open, close, chat } = useAgentWindow();
  const location = useLocation();
  const panelRef = useRef<HTMLElement>(null);
  const isChatPage = location.pathname.endsWith('/aiChat');
  const visible = open && !isChatPage;

  useEffect(() => {
    const node = panelRef.current;
    if (!node) return;
    if (visible) node.removeAttribute('inert');
    else node.setAttribute('inert', '');
  }, [visible]);

  useEffect(() => {
    if (!visible) return undefined;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') close();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [visible, close]);

  const handleNavigate = () => {
    if (window.matchMedia(NARROW_QUERY).matches) {
      close();
    }
  };

  return (
    <>
      <button
        type="button"
        className={clsx('agent-backdrop', visible && 'is-open')}
        aria-label="关闭 AI 助手"
        tabIndex={visible ? 0 : -1}
        onClick={close}
      />
      <aside
        ref={panelRef}
        className={clsx('agent-window', visible ? 'is-open' : 'is-closed')}
        aria-hidden={!visible}
        aria-label="AI 助手"
      >
        <header className="agent-window-header">
          <div className="agent-window-brand">
            <span className="agent-window-icon" aria-hidden="true">
              <FiStar />
            </span>
            <div>
              <div className="agent-window-title">AI 助手</div>
              <div className="agent-window-subtitle">业务咨询与快捷办理</div>
            </div>
          </div>
          <div className="agent-window-actions">
            <button
              type="button"
              className="ghost"
              onClick={chat.newConversation}
              disabled={chat.streaming}
            >
              新对话
            </button>
            <button
              type="button"
              className="icon-button"
              onClick={close}
              aria-label="关闭 AI 助手"
              title="关闭 AI 助手"
            >
              <FiX />
            </button>
          </div>
        </header>
        <div className="agent-window-body">
          <AiChatPanel compact onNavigate={handleNavigate} />
        </div>
      </aside>
    </>
  );
}
