import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function LoginLogPage() {
  return <CrudPage config={entityConfigs.loginLogs} />;
}
