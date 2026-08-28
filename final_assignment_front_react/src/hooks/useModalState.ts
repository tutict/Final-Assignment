import { useState } from 'react';

export interface ModalState {
  isOpen: boolean;
  activeRow: Record<string, unknown> | null;
  open: (row?: Record<string, unknown> | null) => void;
  close: () => void;
}

export function useModalState(): ModalState {
  const [isOpen, setIsOpen] = useState(false);
  const [activeRow, setActiveRow] = useState<Record<string, unknown> | null>(null);

  const open = (row: Record<string, unknown> | null = null) => {
    setActiveRow(row);
    setIsOpen(true);
  };

  const close = () => {
    setIsOpen(false);
    setActiveRow(null);
  };

  return { isOpen, activeRow, open, close };
}
