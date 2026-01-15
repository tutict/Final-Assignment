import React from 'react';
import CrudPage from '../shared/CrudPage.jsx';
import { entityConfigs } from '../../config/entities.js';

export default function OnlineProcessingProgressPage() {
  return <CrudPage config={{ ...entityConfigs.progress, label: '在线处理进度' }} />;
}
