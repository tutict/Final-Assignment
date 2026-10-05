import { useMemo } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';
import { listEntities } from '../../api/entities';
import { getCurrentProfile } from '../../api/profile';
import { API_PATHS } from '../../constants/apiPaths';
import { useAgentPrefill, hasBusinessPrefill } from '../../hooks/useAgentPrefill';
import type { EntityConfig } from '../../config/entityTypes';

/**
 * 用户罚款信息页，对齐 Flutter FineInformationPage。
 * 若由 AI 聊天动作跳转并携带业务编号，按编号过滤罚款。
 */
export default function FineInformationPage() {
  const navigate = useNavigate();
  const [, setParams] = useSearchParams();
  const prefill = useAgentPrefill();
  const businessNumber = hasBusinessPrefill(prefill) ? prefill.businessNumber : '';

  const config: EntityConfig = useMemo(
    () => ({
      ...entityConfigs.fines,
      layout: 'cards',
      hideCreate: true,
      label: '罚款信息',
      list: async () => {
        const profile = await getCurrentProfile();
        if (!profile.driverId) return [];
        const data = await listEntities<Record<string, unknown>[]>(
          API_PATHS.FINES_BY_DRIVER(profile.driverId),
          { page: 1, size: 100 }
        );
        let mine = Array.isArray(data) ? data : [];
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
    [businessNumber]
  );

  return (
    <>
      <div className="page-actions">
        <button type="button" className="primary" onClick={() => navigate('/mainScan')}>
          出示缴费码
        </button>
        <button type="button" className="ghost" onClick={() => setParams({ guide: 'payment' })}>
          缴费说明
        </button>
      </div>
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
