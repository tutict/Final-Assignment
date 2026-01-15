import React from 'react';
import CrudPage from '../shared/CrudPage.jsx';
import { entityConfigs } from '../../config/entities.js';
import { listEntities } from '../../api/entities.js';
import { useAuth } from '../../auth/AuthContext.jsx';

export default function VehicleManagementPage() {
  const { auth } = useAuth();
  const config = {
    ...entityConfigs.vehicles,
    label: '我的车辆',
    list: async () => {
      const data = await listEntities(entityConfigs.vehicles.basePath);
      if (!auth?.userName) return data;
      return data.filter((item) => item.ownerName && item.ownerName.includes(auth.userName));
    },
  };
  return <CrudPage config={config} />;
}
