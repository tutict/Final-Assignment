import React from 'react';
import clsx from 'clsx';
import { STATUS, getStatusLabel } from '../utils/statusLabels.js';

const SUCCESS_STATUSES = new Set([STATUS.SUCCESS, STATUS.APPROVED, STATUS.PAID]);
const WARNING_STATUSES = new Set([STATUS.PENDING, STATUS.PROCESSING]);
const DANGER_STATUSES = new Set([STATUS.FAILED, STATUS.REJECTED, STATUS.UNPAID]);

export default function StatusPill({ value }) {
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
