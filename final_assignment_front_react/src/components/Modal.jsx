import React from 'react';
import clsx from 'clsx';

/**
 * @component Modal
 * @description 通用模态框容器，控制显示状态、标题、关闭按钮和底部操作区。
 *
 * @param {{
 *   isOpen: boolean,
 *   title: string,
 *   onClose: () => void,
 *   children: React.ReactNode,
 *   footerActions?: React.ReactNode,
 *   wide?: boolean,
 * }} props - 显示状态、标题、关闭回调、内容和底部操作区。
 *
 * @notes
 * - 当前底部操作区命名为 footerActions，不是 actions。
 * - size prop 当前未实现，宽版由 wide 控制。
 */
export default function Modal({ isOpen, title, onClose, children, footerActions, wide }) {
  if (!isOpen) return null;
  return (
    <div className="modal-backdrop" role="dialog" aria-modal="true">
      <div className={clsx('modal', wide && 'modal-wide')}>
        <div className="modal-header">
          <h3>{title}</h3>
          <button type="button" className="icon-button" onClick={onClose}>
            ×
          </button>
        </div>
        <div className="modal-body">{children}</div>
        {footerActions ? <div className="modal-footer">{footerActions}</div> : null}
      </div>
    </div>
  );
}

