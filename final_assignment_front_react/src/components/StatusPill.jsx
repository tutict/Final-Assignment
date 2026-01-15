import React from 'react';
import clsx from 'clsx';

export default function StatusPill({ value }) {
  const normalized = String(value || '').toLowerCase();
  return (
    <span
      className={clsx('status-pill', {
        success: normalized.includes('success') || normalized.includes('approved') || normalized.includes('paid'),
        warning: normalized.includes('pending') || normalized.includes('processing'),
        danger: normalized.includes('fail') || normalized.includes('rejected') || normalized.includes('unpaid'),
      })}
    >
      {value || '未知'}
    </span>
  );
}

