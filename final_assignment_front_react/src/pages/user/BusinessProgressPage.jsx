import React from 'react';
import CrudPage from '../shared/CrudPage.jsx';
import { entityConfigs } from '../../config/entities.js';

export default function BusinessProgressPage() {
  return <CrudPage config={{ ...entityConfigs.progress, label: '业务办理进度' }} />;
}
