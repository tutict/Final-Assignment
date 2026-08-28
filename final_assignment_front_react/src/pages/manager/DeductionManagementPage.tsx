import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function DeductionManagementPage() {
  return <CrudPage config={entityConfigs.deductions} />;
}
