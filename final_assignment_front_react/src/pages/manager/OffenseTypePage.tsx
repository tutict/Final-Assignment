import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function OffenseTypePage() {
  return <CrudPage config={entityConfigs.offenseTypes} />;
}
