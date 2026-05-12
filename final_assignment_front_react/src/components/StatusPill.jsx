import React from 'react';
import clsx from 'clsx';
import { STATUSES } from '../constants/statuses.js';
import { STATUS, getStatusLabel } from '../utils/statusLabels.js';

// 状态颜色映射：Pending → yellow, Approved → green, Rejected → red
// 枚举值参见 src/constants/statuses.js
const SUCCESS_STATUSES = new Set([STATUS.SUCCESS, STATUSES.APPROVED, STATUS.PAID]);
const WARNING_STATUSES = new Set([STATUSES.PENDING, STATUS.PROCESSING]);
const DANGER_STATUSES = new Set([STATUS.FAILED, STATUSES.REJECTED, STATUS.UNPAID]);

/**
 * @component StatusPill
 * @description 根据状态值渲染带颜色的状态标签，适用于流程状态和支付状态的紧凑展示。
 *
 * @param {{ value: string }} props - 状态字符串；枚举值参见 src/constants/statuses.js。
 *
 * @notes
 * - 当前组件使用 value prop，不是 status prop；调用处如需统一命名需同步修改。
 */
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
