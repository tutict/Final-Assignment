import React from 'react';
import CrudPage from '../shared/CrudPage.jsx';
import { entityConfigs } from '../../config/entities.js';

export default function UserManagementPage() {
  return <CrudPage config={entityConfigs.users} />;
}

