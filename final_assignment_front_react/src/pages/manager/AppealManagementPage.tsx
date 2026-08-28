import { useMemo, useState } from 'react';
import PageLayout from '../../components/PageLayout';
import DataTable from '../../components/DataTable';
import SearchBar from '../../components/SearchBar';
import Modal from '../../components/Modal';
import { useAppealManagement } from '../../hooks/useAppealManagement';
import { useConfirm } from '../../hooks/useConfirm';
import { useModalState } from '../../hooks/useModalState';
import { buildColumns } from '../../utils/buildColumns';
import { getErrorMessage } from '../../utils/errorMessages';
import { normalizeText } from '../../utils/format';
import { canApprove, canReject } from '../../utils/workflowPermissions';
import { getStatusLabel } from '../../utils/statusLabels';
import type { EntityField } from '../../config/entityTypes';

const appealColumnFields: Array<EntityField & { key?: string }> = [
  { name: 'appealId', key: 'appealId', label: '申诉ID' },
  { name: 'offenseId', key: 'offenseId', label: '违法记录ID' },
  { name: 'appellantName', key: 'appellantName', label: '申诉人' },
  { name: 'appealReason', key: 'appealReason', label: '申诉原因' },
  { name: 'appealTime', key: 'appealTime', label: '申诉时间', type: 'DateTime' },
  { name: 'processStatus', key: 'processStatus', label: '处理状态' },
];

type AppealRow = Record<string, unknown> & {
  __fetchError?: boolean;
  appealId?: string | number;
  offenseId?: string | number;
  appellantName?: string;
  appealReason?: string;
  processStatus?: string;
  processResult?: string;
  appellantContact?: string;
};

export default function AppealManagementPage() {
  const [search, setSearch] = useState('');
  const [rejectReason, setRejectReason] = useState('');
  const [actionError, setActionError] = useState('');
  const {
    isOpen: isDetailOpen,
    activeRow: activeAppeal,
    open,
    close,
  } = useModalState();

  const { data, isLoading, isError, error, approve, reject, isUpdating } = useAppealManagement();

  const handleCloseDetail = () => {
    setRejectReason('');
    setActionError('');
    close();
  };

  const handleOpenDetail = (row: Record<string, unknown>) => {
    if ((row as AppealRow)?.__fetchError) return;
    setRejectReason('');
    setActionError('');
    open(row);
  };

  const rows: AppealRow[] = Array.isArray(data) ? (data as AppealRow[]) : [];

  const filteredRows = useMemo(() => {
    if (!search.trim()) return rows;
    const query = normalizeText(search);
    return rows.filter((row) =>
      row.__fetchError ||
      [row.appealReason, row.appellantName, row.processStatus].some((value) =>
        normalizeText(value).includes(query)
      )
    );
  }, [rows, search]);

  const columns = useMemo(() => buildColumns(appealColumnFields), []);

  const activeAppealRow = activeAppeal as AppealRow | null;

  const { confirm: handleConfirmApprove, loading: approving } = useConfirm(
    async () => {
      if (!activeAppealRow?.appealId) return;
      setActionError('');
      await approve(activeAppealRow);
    },
    {
      onSuccess: handleCloseDetail,
      onError: (err) => {
        setActionError(getErrorMessage(err));
      },
    }
  );

  const { confirm: handleConfirmReject, loading: rejecting } = useConfirm(
    async () => {
      if (!activeAppealRow?.appealId) return;
      setActionError('');
      await reject(activeAppealRow);
    },
    {
      onSuccess: handleCloseDetail,
      onError: (err) => {
        setActionError(getErrorMessage(err));
      },
    }
  );

  const updating = isUpdating || approving || rejecting;

  return (
    <PageLayout title="申诉管理" subtitle="申诉审核与处理结果确认">
      <SearchBar value={search} onChange={setSearch} placeholder="搜索申诉原因/申诉人/处理状态" />
      {isLoading ? <div className="placeholder">加载中...</div> : null}
      {isError ? <div className="form-error">{getErrorMessage(error)}</div> : null}
      <DataTable
        columns={columns}
        rows={filteredRows}
        onView={handleOpenDetail}
        getRowErrorMessage={(row) =>
          (row as AppealRow)?.__fetchError ? '申诉信息加载失败，请刷新重试' : null
        }
      />
      <Modal
        isOpen={isDetailOpen}
        title="申诉详情"
        onClose={handleCloseDetail}
        footerActions={
          <div className="modal-actions">
            <button type="button" className="ghost" onClick={handleCloseDetail}>
              关闭
            </button>
            <button
              type="button"
              className="primary"
              onClick={handleConfirmApprove}
              disabled={updating || !canApprove(activeAppealRow?.processStatus)}
            >
              通过
            </button>
            <button
              type="button"
              className="danger"
              onClick={handleConfirmReject}
              disabled={updating || !canReject(activeAppealRow?.processStatus)}
            >
              驳回
            </button>
          </div>
        }
      >
        {actionError ? <div className="form-error">{actionError}</div> : null}
        {activeAppealRow ? (
          <div className="detail-grid">
            <div><strong>申诉ID：</strong>{activeAppealRow.appealId}</div>
            <div><strong>违法记录ID：</strong>{activeAppealRow.offenseId}</div>
            <div><strong>申诉人：</strong>{activeAppealRow.appellantName}</div>
            <div><strong>联系方式：</strong>{activeAppealRow.appellantContact}</div>
            <div><strong>申诉原因：</strong>{activeAppealRow.appealReason}</div>
            <div><strong>处理状态：</strong>{getStatusLabel(activeAppealRow.processStatus)}</div>
            <div><strong>处理结果：</strong>{activeAppealRow.processResult}</div>
            <label className="form-field full">
              <span>驳回原因</span>
              <textarea value={rejectReason} onChange={(event) => setRejectReason(event.target.value)} rows={3} />
            </label>
          </div>
        ) : null}
      </Modal>
    </PageLayout>
  );
}
