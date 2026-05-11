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
