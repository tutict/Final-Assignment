import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function DriverListPage() {
  return <CrudPage config={entityConfigs.drivers} />;
}
