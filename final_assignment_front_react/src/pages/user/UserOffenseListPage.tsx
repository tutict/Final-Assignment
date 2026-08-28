import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';
import { listEntities } from '../../api/entities';
import { useAuth } from '../../auth/AuthContext';
import type { EntityConfig } from '../../config/entityTypes';

export default function UserOffenseListPage() {
  const { auth } = useAuth();
  const config: EntityConfig = {
    ...entityConfigs.offenses,
    label: '我的违法记录',
    list: async () => {
      const data = await listEntities<Record<string, unknown>[]>(
        entityConfigs.offenses.basePath
      );
      if (!auth?.userId) return data;
      return data.filter(
        (item) => String(item.driverId || '') === String(auth.userId)
      );
    },
  };
  return <CrudPage config={config} />;
}
