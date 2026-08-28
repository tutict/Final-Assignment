import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function ProgressManagementPage() {
  return <CrudPage config={entityConfigs.progress} />;
}
