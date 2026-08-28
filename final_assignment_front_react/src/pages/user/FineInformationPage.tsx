import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function FineInformationPage() {
  return <CrudPage config={{ ...entityConfigs.fines, label: '罚款信息' }} />;
}
