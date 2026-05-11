import React from 'react';
import CrudPage from '../shared/CrudPage.jsx';
import { useAuth } from '../../auth/AuthContext.jsx';
import { entityConfigs } from '../../config/entities.js';
import { useUserAppeals } from '../../hooks/useUserAppeals.js';

export default function UserAppealPage() {
  const { auth } = useAuth();
  const appealsQuery = useUserAppeals(auth?.userId);
  const config = {
    ...entityConfigs.appeals,
    label: '我的申诉',
    queryResult: appealsQuery,
  };

  return <CrudPage config={config} />;
}
