import React from 'react';
import CrudPage from '../shared/CrudPage.jsx';
import { entityConfigs } from '../../config/entities.js';

export default function OffenseTypePage() {
  return <CrudPage config={entityConfigs.offenseTypes} />;
}

