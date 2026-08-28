import clsx from 'clsx';

interface ModalProps {
  isOpen: boolean;
  title: string;
  onClose: () => void;
  children?: React.ReactNode;
  footerActions?: React.ReactNode;
  wide?: boolean;
}

export default function Modal({
  isOpen,
  title,
  onClose,
  children,
  footerActions,
  wide,
}: ModalProps) {
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
