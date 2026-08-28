import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function SystemSettingsPage() {
  return <CrudPage config={entityConfigs.systemSettings} />;
}
