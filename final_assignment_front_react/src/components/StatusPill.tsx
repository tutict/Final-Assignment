import clsx from 'clsx';
import { STATUSES } from '../constants/statuses';
import { STATUS, getStatusLabel } from '../utils/statusLabels';

const SUCCESS_STATUSES = new Set<string>([STATUS.SUCCESS, STATUSES.APPROVED, STATUS.PAID]);
const WARNING_STATUSES = new Set<string>([STATUSES.PENDING, STATUS.PROCESSING]);
const DANGER_STATUSES = new Set<string>([STATUS.FAILED, STATUSES.REJECTED, STATUS.UNPAID]);

interface StatusPillProps {
  value: unknown;
}

export default function StatusPill({ value }: StatusPillProps) {
  const status = String(value || '');
  const tone = SUCCESS_STATUSES.has(status) ? 'success' : WARNING_STATUSES.has(status) ? 'warning' : DANGER_STATUSES.has(status) ? 'danger' : 'info';
  const mark = tone === 'success' ? '✓' : tone === 'warning' ? '!' : tone === 'danger' ? '×' : 'i';
  return (
    <span className={clsx('status-pill', tone)}>
      <span aria-hidden="true">{mark}</span>
      {getStatusLabel(value)}
    </span>
  );
}
