import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react';
import { useAiChatStream } from '../hooks/useAiChatStream';

type ChatSession = ReturnType<typeof useAiChatStream>;

interface AgentWindowContextValue {
  open: boolean;
  toggle: () => void;
  close: () => void;
  chat: ChatSession;
}

const AgentWindowContext = createContext<AgentWindowContextValue | null>(null);

export function AgentWindowProvider({ children }: { children: ReactNode }) {
  const [open, setOpen] = useState(false);
  const chat = useAiChatStream();
  const toggle = useCallback(() => setOpen((value) => !value), []);
  const close = useCallback(() => setOpen(false), []);
  const value = useMemo(
    () => ({ open, toggle, close, chat }),
    [open, toggle, close, chat]
  );

  return (
    <AgentWindowContext.Provider value={value}>
      {children}
    </AgentWindowContext.Provider>
  );
}

export function useAgentWindow(): AgentWindowContextValue {
  const context = useContext(AgentWindowContext);
  if (!context) {
    throw new Error('useAgentWindow must be used within AgentWindowProvider');
  }
  return context;
}

export function useOptionalAgentWindow(): AgentWindowContextValue | null {
  return useContext(AgentWindowContext);
}
