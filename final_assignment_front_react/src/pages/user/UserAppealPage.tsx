import CrudPage from '../shared/CrudPage';
import { useAuth } from '../../auth/AuthContext';
import { entityConfigs } from '../../config/entities';
import { useUserAppeals } from '../../hooks/useUserAppeals';
import { useAgentPrefill, hasBusinessPrefill } from '../../hooks/useAgentPrefill';
import type { EntityConfig } from '../../config/entityTypes';

/**
 * 用户申诉页，对齐 Flutter UserAppealPage。
 * 若由 AI 聊天动作跳转并携带 businessNumber（违法编号），预填查询并提示。
 */
export default function UserAppealPage() {
  const { auth } = useAuth();
  const appealsQuery = useUserAppeals(auth?.userId);
  const prefill = useAgentPrefill();
  const prefillHint = hasBusinessPrefill(prefill) ? prefill.businessNumber : null;

  const config: EntityConfig = {
    ...entityConfigs.appeals,
    label: '我的申诉',
    queryResult: appealsQuery,
    errorRowMessage: (row) =>
      (row as { __fetchError?: boolean })?.__fetchError
        ? '申诉信息加载失败，请刷新重试'
        : null,
  };

  return (
    <>
      {prefillHint ? (
        <div className="panel" role="status">
          <h3>AI 助手已为您定位</h3>
          <p>关联业务编号：<strong>{prefillHint}</strong>，请在申诉表单中引用该编号。</p>
        </div>
      ) : null}
      <CrudPage config={config} />
    </>
  );
}
