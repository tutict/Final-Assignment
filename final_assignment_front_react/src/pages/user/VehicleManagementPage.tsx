import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';
import { listEntities } from '../../api/entities';
import { useAuth } from '../../auth/AuthContext';
import type { EntityConfig } from '../../config/entityTypes';

export default function VehicleManagementPage() {
  const { auth } = useAuth();
  const config: EntityConfig = {
    ...entityConfigs.vehicles,
    label: '我的车辆',
    list: async () => {
      const data = await listEntities<Record<string, unknown>[]>(
        entityConfigs.vehicles.basePath
      );
      if (!auth?.userName) return data;
      return data.filter(
        (item) => Boolean(item.ownerName) && String(item.ownerName).includes(auth.userName)
      );
    },
  };
  return <CrudPage config={config} />;
}
