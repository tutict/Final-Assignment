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
  return (
    <span
      className={clsx('status-pill', {
        success: SUCCESS_STATUSES.has(status),
        warning: WARNING_STATUSES.has(status),
        danger: DANGER_STATUSES.has(status),
      })}
    >
      {getStatusLabel(value)}
    </span>
  );
}
