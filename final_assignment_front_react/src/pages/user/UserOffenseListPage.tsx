import { useMemo, useState } from 'react';
import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';
import { listEntities } from '../../api/entities';
import { useAuth } from '../../auth/AuthContext';
import { useAgentPrefill, hasPlatePrefill } from '../../hooks/useAgentPrefill';
import OffenseDetailModal from '../../components/OffenseDetailModal';
import type { EntityConfig } from '../../config/entityTypes';

/**
 * 用户违法记录页，对齐 Flutter UserOffenseListPage + UserOffenseDetailPage。
 * 若由 AI 聊天动作跳转并携带车牌，按车牌过滤；点击「详情」弹出只读违法详情。
 */
export default function UserOffenseListPage() {
  const { auth } = useAuth();
  const prefill = useAgentPrefill();
  const plate = hasPlatePrefill(prefill) ? prefill.licensePlate : '';
  const [detail, setDetail] = useState<Record<string, unknown> | null>(null);

  const config: EntityConfig = useMemo(() => {
    return {
      ...entityConfigs.offenses,
      label: '我的违法记录',
      list: async () => {
        const data = await listEntities<Record<string, unknown>[]>(
          entityConfigs.offenses.basePath
        );
        let mine = auth?.userId
          ? data.filter((item) => String(item.driverId || '') === String(auth.userId))
          : data;
        if (plate) {
          mine = mine.filter((item) => String(item.licensePlate || '').toUpperCase().includes(plate));
        }
        return mine;
      },
      onView: (row: Record<string, unknown>) => setDetail(row),
    };
  }, [auth?.userId, plate]);

  return (
    <>
      {plate ? (
        <div className="panel" role="status">
          <h3>AI 助手已为您定位车牌</h3>
          <p>车牌号：<strong>{plate}</strong>，已按该车牌过滤违法记录。</p>
        </div>
      ) : null}
      <CrudPage config={config} />
      <OffenseDetailModal
        offense={detail}
        isOpen={detail !== null}
        onClose={() => setDetail(null)}
      />
    </>
  );
}
