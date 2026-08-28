import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function RoleManagementPage() {
  return <CrudPage config={entityConfigs.roles} />;
}
