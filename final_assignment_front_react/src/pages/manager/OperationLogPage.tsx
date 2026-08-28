import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function OperationLogPage() {
  return <CrudPage config={entityConfigs.operationLogs} />;
}
