/**
 * 违法详情弹窗，对齐 Flutter OffenseDetailPage（管理员）/ UserOffenseDetailPage（用户）。
 * 两者仅渲染同一组字段（违法ID/车牌/驾驶员/类型/代码/时间/地点/扣分/罚款/状态/结果），
 * 区别在于管理员可删除——由 canDelete + onDelete 控制。
 *
 * 由各违法列表页通过 CrudPage 的 config.onView 触发，传入当前行。
 */
import Modal from './Modal';
import { formatDateTime } from '../utils/format';

export interface OffenseDetailModalProps {
  offense: Record<string, unknown> | null;
  isOpen: boolean;
  onClose: () => void;
  /** 管理员可删除：展示删除按钮并调用该回调 */
  canDelete?: boolean;
  onDelete?: (offense: Record<string, unknown>) => void;
  deleting?: boolean;
}

interface Row {
  label: string;
  value: string;
}

function buildRows(offense: Record<string, unknown>): Row[] {
  const str = (v: unknown): string => {
    if (v === null || v === undefined || v === '') return '无';
    return String(v);
  };
  return [
    { label: '违法ID', value: str(offense.offenseId) },
    { label: '车牌号', value: str(offense.licensePlate) },
    { label: '驾驶员姓名', value: str(offense.driverName) },
    { label: '违法类型', value: str(offense.offenseType) },
    { label: '违法代码', value: str(offense.offenseCode) },
    { label: '违法时间', value: offense.offenseTime ? formatDateTime(offense.offenseTime) : '无' },
    { label: '违法地点', value: str(offense.offenseLocation) },
    { label: '扣分', value: offense.deductedPoints != null ? `${offense.deductedPoints} 分` : '无' },
    { label: '罚款金额', value: offense.fineAmount != null ? `${offense.fineAmount} 元` : '无' },
    { label: '处理状态', value: str(offense.processStatus) },
    { label: '处理结果', value: str(offense.processResult) },
  ];
}

export default function OffenseDetailModal({
  offense,
  isOpen,
  onClose,
  canDelete,
  onDelete,
  deleting,
}: OffenseDetailModalProps) {
  const rows = offense ? buildRows(offense) : [];
  return (
    <Modal
      isOpen={isOpen}
      title="违法行为详情"
      onClose={onClose}
      footerActions={
        <div className="modal-actions">
          {canDelete && onDelete && offense ? (
            <button
              type="button"
              className="danger"
              onClick={() => onDelete(offense)}
              disabled={deleting}
            >
              {deleting ? '删除中...' : '删除违法信息'}
            </button>
          ) : null}
          <button type="button" className="ghost" onClick={onClose}>
            关闭
          </button>
        </div>
      }
    >
      <div className="detail-grid">
        {rows.map((row) => (
          <div className="profile-tile" key={row.label}>
            <span className="profile-tile-label">{row.label}</span>
            <span className="profile-tile-value">{row.value}</span>
          </div>
        ))}
      </div>
    </Modal>
  );
}
