import PageLayout from '../../components/PageLayout';
import AiChatPanel from '../../components/AiChatPanel';
import { useOptionalAgentWindow } from '../../layouts/AgentWindowContext';

export default function AiChatPage() {
  const agentWindow = useOptionalAgentWindow();

  return (
    <PageLayout
      title="AI 智能助手"
      subtitle="在线咨询 · 违法处理建议 · 业务指引"
      headerActions={
        <button
          type="button"
          className="ghost"
          onClick={agentWindow?.chat.newConversation}
          disabled={!agentWindow || agentWindow.chat.streaming}
        >
          新对话
        </button>
      }
    >
      <AiChatPanel />
    </PageLayout>
  );
}
