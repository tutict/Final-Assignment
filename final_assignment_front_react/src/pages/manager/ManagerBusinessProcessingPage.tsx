import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function ManagerBusinessProcessingPage() {
  return <CrudPage config={{ ...entityConfigs.progress, label: '业务处理中心' }} />;
}
