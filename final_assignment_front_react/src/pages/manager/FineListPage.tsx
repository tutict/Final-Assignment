import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function FineListPage() {
  return <CrudPage config={entityConfigs.fines} />;
}
