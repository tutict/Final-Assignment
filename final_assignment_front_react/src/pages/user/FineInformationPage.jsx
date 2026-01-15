import React from 'react';
import CrudPage from '../shared/CrudPage.jsx';
import { entityConfigs } from '../../config/entities.js';

export default function FineInformationPage() {
  return <CrudPage config={{ ...entityConfigs.fines, label: '罚款信息' }} />;
}
