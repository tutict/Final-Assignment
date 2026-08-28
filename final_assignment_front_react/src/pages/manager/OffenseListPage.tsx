import { useCallback, useMemo, useState } from 'react';
import CrudPage from '../shared/CrudPage';
import { entityConfigs } from '../../config/entities';
import { useQueryClient } from '@tanstack/react-query';
import OffenseDetailModal from '../../components/OffenseDetailModal';
import { deleteEntity } from '../../api/entities';
import { getErrorMessage } from '../../utils/errorMessages';

/**
 * 管理员违法记录列表，对齐 Flutter OffenseList + OffenseDetailPage。
 * 在通用 CrudPage 之上接 config.onView：点击「详情」弹出现场字段网格，
 * 并提供删除违法信息按钮（管理员可删除）。
 */
export default function OffenseListPage() {
  const queryClient = useQueryClient();
  const [detail, setDetail] = useState<Record<string, unknown> | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState('');

  const config = useMemo(
    () => ({
      ...entityConfigs.offenses,
      onView: (row: Record<string, unknown>) => {
        setError('');
        setDetail(row);
      },
    }),
    []
  );

  const handleDelete = useCallback(
    async (offense: Record<string, unknown>) => {
      const id = offense.offenseId as string | number | undefined;
      if (id == null) return;
      if (!window.confirm('确定删除该违法信息吗？此操作不可撤销。')) return;
      setDeleting(true);
      setError('');
      try {
        await deleteEntity(entityConfigs.offenses.basePath, id);
        setDetail(null);
        await queryClient.invalidateQueries({ queryKey: ['offenses'] });
      } catch (e) {
        setError(getErrorMessage(e));
      } finally {
        setDeleting(false);
      }
    },
    [queryClient]
  );

  return (
    <>
      {error ? <div className="form-error">{error}</div> : null}
      <CrudPage config={config} />
      <OffenseDetailModal
        offense={detail}
        isOpen={detail !== null}
        onClose={() => setDetail(null)}
        canDelete
        onDelete={handleDelete}
        deleting={deleting}
      />
    </>
  );
}
