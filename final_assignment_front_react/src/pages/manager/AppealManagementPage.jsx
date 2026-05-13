import React, { useMemo, useState } from 'react';
import PageLayout from '../../components/PageLayout.jsx';
import DataTable from '../../components/DataTable.jsx';
import SearchBar from '../../components/SearchBar.jsx';
import Modal from '../../components/Modal.jsx';
import { useAppealManagement } from '../../hooks/useAppealManagement.js';
import { useConfirm } from '../../hooks/useConfirm.js';
import { useModalState } from '../../hooks/useModalState.js';
import { buildColumns } from '../../utils/buildColumns.js';
import { getErrorMessage } from '../../utils/errorMessages.js';
import { normalizeText } from '../../utils/format.js';
import { canApprove, canReject } from '../../utils/workflowPermissions.js';
import { getStatusLabel } from '../../utils/statusLabels.js';

const appealColumnFields = [
  { key: 'appealId', label: '申诉ID' },
  { key: 'offenseId', label: '违法记录ID' },
  { key: 'appellantName', label: '申诉人' },
  { key: 'appealReason', label: '申诉原因' },
  { key: 'appealTime', label: '申诉时间', type: 'DateTime' },
  { key: 'processStatus', label: '处理状态' },
];

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

  const handleOpenDetail = (row) => {
    if (row?.__fetchError) return;
    setRejectReason('');
    setActionError('');
    open(row);
  };

  const rows = Array.isArray(data) ? data : [];

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

  const { confirm: handleConfirmApprove, loading: approving } = useConfirm(
    async () => {
      if (!activeAppeal?.appealId) return;
      setActionError('');
      await approve(activeAppeal);
    },
    {
      onSuccess: handleCloseDetail,
      onError: (error) => {
        setActionError(getErrorMessage(error));
      },
    }
  );

  const { confirm: handleConfirmReject, loading: rejecting } = useConfirm(
    async () => {
      if (!activeAppeal?.appealId) return;
      setActionError('');
      await reject(activeAppeal);
    },
    {
      onSuccess: handleCloseDetail,
      onError: (error) => {
        setActionError(getErrorMessage(error));
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
          row?.__fetchError ? '申诉信息加载失败，请刷新重试' : null
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
              disabled={updating || !canApprove(activeAppeal?.processStatus)}
            >
              通过
            </button>
            <button
              type="button"
              className="danger"
              onClick={handleConfirmReject}
              disabled={updating || !canReject(activeAppeal?.processStatus)}
            >
              驳回
            </button>
          </div>
        }
      >
        {actionError ? <div className="form-error">{actionError}</div> : null}
        {activeAppeal ? (
          <div className="detail-grid">
            <div><strong>申诉ID：</strong>{activeAppeal.appealId}</div>
            <div><strong>违法记录ID：</strong>{activeAppeal.offenseId}</div>
            <div><strong>申诉人：</strong>{activeAppeal.appellantName}</div>
            <div><strong>联系方式：</strong>{activeAppeal.appellantContact}</div>
            <div><strong>申诉原因：</strong>{activeAppeal.appealReason}</div>
            <div><strong>处理状态：</strong>{getStatusLabel(activeAppeal.processStatus)}</div>
            <div><strong>处理结果：</strong>{activeAppeal.processResult}</div>
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
