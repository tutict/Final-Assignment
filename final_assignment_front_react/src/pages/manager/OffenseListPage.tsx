import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function OffenseListPage() {
  return <CrudPage config={entityConfigs.offenses} />;
}
