import { useMemo } from 'react';
import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';
import { listEntities } from '../../api/entities';
import { useAuth } from '../../auth/AuthContext';
import { useAgentPrefill, hasPlatePrefill } from '../../hooks/useAgentPrefill';
import type { EntityConfig } from '../../config/entityTypes';

/**
 * 用户车辆管理页，对齐 Flutter VehicleManagementPage。
 * 若由 AI 聊天动作跳转并携带车牌，提示定位该车牌车辆。
 */
export default function VehicleManagementPage() {
  const { auth } = useAuth();
  const prefill = useAgentPrefill();
  const plate = hasPlatePrefill(prefill) ? prefill.licensePlate : '';

  const config: EntityConfig = useMemo(
    () => ({
      ...entityConfigs.vehicles,
      label: '我的车辆',
      list: async () => {
        const data = await listEntities<Record<string, unknown>[]>(
          entityConfigs.vehicles.basePath
        );
        let mine = auth?.userName
          ? data.filter(
              (item) => Boolean(item.ownerName) && String(item.ownerName).includes(auth.userName)
            )
          : data;
        if (plate) {
          mine = mine.filter((item) =>
            String(item.licensePlate || '').toUpperCase().includes(plate)
          );
        }
        return mine;
      },
    }),
    [auth?.userName, plate]
  );

  return (
    <>
      {plate ? (
        <div className="panel" role="status">
          <h3>AI 助手已为您定位车牌</h3>
          <p>车牌号：<strong>{plate}</strong>，已按该车牌过滤车辆。</p>
        </div>
      ) : null}
      <CrudPage config={config} />
    </>
  );
}
