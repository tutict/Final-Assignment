import React from 'react';
import CrudPage from '../shared/CrudPage.jsx';
import { entityConfigs } from '../../config/entities.js';
import { listEntities } from '../../api/entities.js';
import { useAuth } from '../../auth/AuthContext.jsx';

async function fetchUserAppeals(userId) {
  const offenses = await listEntities(entityConfigs.offenses.basePath);
  const mine = userId
    ? offenses.filter((item) => String(item.driverId || '') === String(userId))
    : offenses;
  const results = [];
  for (const offense of mine.slice(0, 20)) {
    if (!offense.offenseId) continue;
    try {
      const appealList = await listEntities(entityConfigs.appeals.basePath, {
        offenseId: offense.offenseId,
        page: 1,
        size: 50,
      });
      results.push(...appealList);
    } catch (error) {
      // ignore per-offense errors to keep list going
    }
  }
  return results;
}

export default function UserAppealPage() {
  const { auth } = useAuth();
  const config = {
    ...entityConfigs.appeals,
    label: '我的申诉',
    list: () => fetchUserAppeals(auth?.userId),
  };
  return <CrudPage config={config} />;
}
