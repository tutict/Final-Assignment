import React, { useMemo, useState } from 'react';
import { useMutation, useQuery } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout.jsx';
import DataTable from '../../components/DataTable.jsx';
import SearchBar from '../../components/SearchBar.jsx';
import Modal from '../../components/Modal.jsx';
import StatusPill from '../../components/StatusPill.jsx';
import { entityConfigs } from '../../config/entities.js';
import { listEntities, postWithIdempotency } from '../../api/entities.js';
import { formatDateTime, normalizeText } from '../../utils/format.js';
import {
  APPEAL_PROCESS_EVENT,
  canApprove,
  canReject,
} from '../../utils/workflowPermissions.js';
import { getStatusLabel } from '../../utils/statusLabels.js';

async function fetchAppeals() {
  const offenses = await listEntities(entityConfigs.offenses.basePath);
  const results = [];
  for (const offense of offenses.slice(0, 20)) {
    if (!offense.offenseId) continue;
    try {
      const appealList = await listEntities(entityConfigs.appeals.basePath, {
        offenseId: offense.offenseId,
        page: 1,
        size: 50,
      });
      results.push(...appealList);
    } catch (error) {
      // ignore per-offense errors
    }
  }
  return results;
}

export default function AppealManagementPage() {
  const [search, setSearch] = useState('');
  const [activeAppeal, setActiveAppeal] = useState(null);
  const [rejectReason, setRejectReason] = useState('');

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['appeals'],
    queryFn: fetchAppeals,
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, event }) =>
      postWithIdempotency(`/api/workflow/appeals/${id}/events/${event}`, {}),
    onSuccess: () => refetch(),
  });

  const rows = Array.isArray(data) ? data : [];

  const filteredRows = useMemo(() => {
    if (!search.trim()) return rows;
    const query = normalizeText(search);
    return rows.filter((row) =>
      [row.appealReason, row.appellantName, row.processStatus]
        .some((value) => normalizeText(value).includes(query))
    );
  }, [rows, search]);

  const columns = [
    { key: 'appealId', label: '申诉ID' },
    { key: 'offenseId', label: '违法记录ID' },
    { key: 'appellantName', label: '申诉人' },
    { key: 'appealReason', label: '申诉原因' },
    { key: 'appealTime', label: '申诉时间', render: (row) => formatDateTime(row.appealTime) },
    { key: 'processStatus', label: '处理状态', render: (row) => <StatusPill value={row.processStatus} /> },
  ];

  const handleApprove = async () => {
    if (!activeAppeal?.appealId) return;
    await updateMutation.mutateAsync({
      id: activeAppeal.appealId,
      event: APPEAL_PROCESS_EVENT.approve,
    });
    setActiveAppeal(null);
  };

  const handleReject = async () => {
    if (!activeAppeal?.appealId) return;
    await updateMutation.mutateAsync({
      id: activeAppeal.appealId,
      event: APPEAL_PROCESS_EVENT.reject,
    });
    setRejectReason('');
    setActiveAppeal(null);
  };

  return (
    <PageLayout title="申诉管理" subtitle="申诉审核与处理结果确认">
      <SearchBar value={search} onChange={setSearch} placeholder="搜索申诉原因/申诉人/处理状态" />
      {isLoading ? <div className="placeholder">加载中...</div> : null}
      {error ? <div className="form-error">加载失败，请检查后端服务。</div> : null}
      <DataTable
        columns={columns}
        rows={filteredRows}
        onView={(row) => {
          setRejectReason('');
          setActiveAppeal(row);
        }}
      />
      <Modal
        open={Boolean(activeAppeal)}
        title="申诉详情"
        onClose={() => setActiveAppeal(null)}
        footer={
          <div className="modal-actions">
            <button type="button" className="ghost" onClick={() => setActiveAppeal(null)}>
              关闭
            </button>
            <button
              type="button"
              className="primary"
              onClick={handleApprove}
              disabled={!canApprove(activeAppeal?.processStatus)}
            >
              通过
            </button>
            <button
              type="button"
              className="danger"
              onClick={handleReject}
              disabled={!canReject(activeAppeal?.processStatus)}
            >
              驳回
            </button>
          </div>
        }
      >
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
