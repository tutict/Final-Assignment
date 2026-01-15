import React from 'react';
import CrudPage from '../shared/CrudPage.jsx';
import { entityConfigs } from '../../config/entities.js';
import { listEntities } from '../../api/entities.js';
import { useAuth } from '../../auth/AuthContext.jsx';

export default function UserOffenseListPage() {
  const { auth } = useAuth();
  const config = {
    ...entityConfigs.offenses,
    label: '我的违法记录',
    list: async () => {
      const data = await listEntities(entityConfigs.offenses.basePath);
      if (!auth?.userId) return data;
      return data.filter((item) => String(item.driverId || '') === String(auth.userId));
    },
  };
  return <CrudPage config={config} />;
}
