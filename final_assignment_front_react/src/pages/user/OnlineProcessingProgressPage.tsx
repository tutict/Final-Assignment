import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function OnlineProcessingProgressPage() {
  return <CrudPage config={{ ...entityConfigs.progress, label: '在线处理进度' }} />;
}
