import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function BackupRestorePage() {
  return <CrudPage config={entityConfigs.backups} />;
}
