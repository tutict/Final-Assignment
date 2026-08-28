import CrudPage from '../shared/CrudPage';
import { useAuth } from '../../auth/AuthContext';
import { entityConfigs } from '../../config/entities';
import { useUserAppeals } from '../../hooks/useUserAppeals';
import type { EntityConfig } from '../../config/entityTypes';

export default function UserAppealPage() {
  const { auth } = useAuth();
  const appealsQuery = useUserAppeals(auth?.userId);
  const config: EntityConfig = {
    ...entityConfigs.appeals,
    label: '我的申诉',
    queryResult: appealsQuery,
    errorRowMessage: (row) =>
      (row as { __fetchError?: boolean })?.__fetchError
        ? '申诉信息加载失败，请刷新重试'
        : null,
  };

  return <CrudPage config={config} />;
}
