import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function UserManagementPage() {
  return <CrudPage config={entityConfigs.users} />;
}
