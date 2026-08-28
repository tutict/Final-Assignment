import { useMemo } from 'react';
import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';
import { listEntities } from '../../api/entities';
import { useAuth } from '../../auth/AuthContext';
import { useAgentPrefill, hasBusinessPrefill } from '../../hooks/useAgentPrefill';
import type { EntityConfig } from '../../config/entityTypes';

/**
 * 用户罚款信息页，对齐 Flutter FineInformationPage。
 * 若由 AI 聊天动作跳转并携带业务编号，按编号过滤罚款。
 */
export default function FineInformationPage() {
  const { auth } = useAuth();
  const prefill = useAgentPrefill();
  const businessNumber = hasBusinessPrefill(prefill) ? prefill.businessNumber : '';

  const config: EntityConfig = useMemo(
    () => ({
      ...entityConfigs.fines,
      label: '罚款信息',
      list: async () => {
        const data = await listEntities<Record<string, unknown>[]>(
          entityConfigs.fines.basePath
        );
        let mine = auth?.userId
          ? data.filter((item) => String(item.driverId || '') === String(auth.userId))
          : data;
        if (businessNumber) {
          mine = mine.filter((item) =>
            [item.fineNumber, item.offenseNumber, item.businessNumber]
              .filter(Boolean)
              .some((v) => String(v).includes(businessNumber))
          );
        }
        return mine;
      },
    }),
    [auth?.userId, businessNumber]
  );

  return (
    <>
      {businessNumber ? (
        <div className="panel" role="status">
          <h3>AI 助手已为您定位</h3>
          <p>关联业务编号：<strong>{businessNumber}</strong>，已按该编号过滤罚款记录。</p>
        </div>
      ) : null}
      <CrudPage config={config} />
    </>
  );
}
