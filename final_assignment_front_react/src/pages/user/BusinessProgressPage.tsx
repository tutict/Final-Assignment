import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function BusinessProgressPage() {
  return <CrudPage config={{ ...entityConfigs.progress, label: '业务办理进度' }} />;
}
