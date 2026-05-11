import { useParams } from 'react-router-dom';
import PlaceholderPage from './PlaceholderPage.jsx';

export default function ProgressDetailPage() {
  const { id } = useParams();

  return <PlaceholderPage title="进度详情" description={`记录编号：${id || '-'}`} />;
}
