import { useMemo, useState } from 'react';
import { QRCodeCanvas } from 'qrcode.react';
import PageLayout from '../../components/PageLayout';
import { listEntities } from '../../api/entities';
import { entityConfigs } from '../../config/entities';

interface FineLike {
  fineId?: number | string;
  fineAmount?: number;
  payee?: string;
  paymentStatus?: string;
}

const DEFAULT_QR_DATA = '交通违法处理二维码';

export default function MainScanPage() {
  const [fineId, setFineId] = useState('');
  const [fine, setFine] = useState<FineLike | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const qrData = useMemo(() => {
    if (!fine) return DEFAULT_QR_DATA;
    return `Fine ID: ${fine.fineId ?? ''}\nAmount: ${fine.fineAmount ?? 0}\nPayee: ${fine.payee ?? ''}`;
  }, [fine]);

  const handleGenerate = async () => {
    setError('');
    setLoading(true);
    try {
      if (!fineId.trim()) {
        setFine(null);
        setLoading(false);
        return;
      }
      const data = await listEntities<FineLike[]>(entityConfigs.fines.basePath);
      const matched = data.find(
        (item) => String(item.fineId || '') === String(fineId).trim()
      );
      setFine(matched || null);
      if (!matched) {
        setError('未找到对应罚款记录');
      }
    } catch (err) {
      setError('加载罚款数据失败');
      // eslint-disable-next-line no-console
      console.warn('[MainScanPage] load fine failed:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <PageLayout title="扫码服务" subtitle="事故与业务办理快速入口">
      <div className="scanner-panel">
        <div className="scanner-frame">
          <QRCodeCanvas value={qrData} size={240} includeMargin level="M" />
        </div>
        <p>选择罚款记录生成对应二维码，或使用默认业务二维码。</p>
        <div className="scan-input-row">
          <input
            type="text"
            value={fineId}
            onChange={(event) => setFineId(event.target.value)}
            placeholder="输入罚款编号（可选）"
          />
          <button type="button" className="primary" onClick={handleGenerate} disabled={loading}>
            {loading ? '生成中...' : '生成二维码'}
          </button>
        </div>
        {error ? <div className="form-error">{error}</div> : null}
        {fine ? (
          <div className="scan-detail">
            <div><strong>罚款编号：</strong>{fine.fineId}</div>
            <div><strong>罚款金额：</strong>{fine.fineAmount ?? 0} 元</div>
            <div><strong>缴纳对象：</strong>{fine.payee || '--'}</div>
            <div><strong>缴纳状态：</strong>{fine.paymentStatus || '--'}</div>
          </div>
        ) : null}
      </div>
    </PageLayout>
  );
}
