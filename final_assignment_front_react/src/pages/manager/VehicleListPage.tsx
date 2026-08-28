import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function VehicleListPage() {
  return <CrudPage config={entityConfigs.vehicles} />;
}
