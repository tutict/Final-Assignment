import React from 'react';
import CrudPage from '../shared/CrudPage.jsx';
import { entityConfigs } from '../../config/entities.js';

export default function ManagerBusinessProcessingPage() {
  return <CrudPage config={{ ...entityConfigs.progress, label: '业务处理中心' }} />;
}
