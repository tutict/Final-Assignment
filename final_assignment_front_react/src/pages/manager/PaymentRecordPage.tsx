import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';

export default function PaymentRecordPage() {
  return <CrudPage config={entityConfigs.payments} />;
}
