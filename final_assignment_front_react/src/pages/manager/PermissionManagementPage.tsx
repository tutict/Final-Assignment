import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function PermissionManagementPage() {
  return <CrudPage config={entityConfigs.permissions} />;
}
