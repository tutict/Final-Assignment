/**
 * @hook useModalState
 * @description 管理通用弹窗打开状态和当前操作行，适用于详情、编辑、删除确认等实体弹窗。
 *
 * @returns {{
 *   isOpen: boolean,  // 弹窗是否打开
 *   activeRow: Object|null,  // 当前弹窗关联的任意实体对象；未打开或关闭后为 null
 *   open: (row?: Object|null) => void,  // 打开弹窗并记录 activeRow，未传 row 时 activeRow 为 null
 *   close: () => void,  // 关闭弹窗并清空 activeRow
 * }}
 *
 * @example
 * const { isOpen, activeRow, open, close } = useModalState();
 * open(row);
 *
 * @notes
 * - open(row) 会先保存 activeRow，再将 isOpen 置为 true。
 * - close() 会同时将 isOpen 置为 false，并清空 activeRow。
 * - isOpen 与 activeRow 有联动但不等价：允许打开一个不绑定具体行的弹窗。
 */
import { useState } from 'react';

export function useModalState() {
  const [isOpen, setIsOpen] = useState(false);
  const [activeRow, setActiveRow] = useState(null);

  const open = (row = null) => {
    setActiveRow(row);
    setIsOpen(true);
  };

  const close = () => {
    setIsOpen(false);
    setActiveRow(null);
  };

  return { isOpen, activeRow, open, close };
}
