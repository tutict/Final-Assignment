import type { ReactNode } from 'react';

const IDENTITY_FIELDS = ['paymentId', 'appealId', 'deductionId', 'reviewId', 'fineId', 'offenseId', 'driverId', 'vehicleId', 'userId', 'id', 'key'];

function identityForRow(row: Record<string, unknown>, index: number): string {
  for (const field of IDENTITY_FIELDS) {
    const value = row[field];
    if (value !== undefined && value !== null && value !== '') {
      return field + ':' + String(value);
    }
  }
  return 'row:' + String(index);
}


export interface DataTableColumn {
  key: string;
  label: string;
  render?: (row: Record<string, unknown>) => ReactNode;
}

interface DataTableProps {
  columns: DataTableColumn[];
  rows: Array<Record<string, unknown>>;
  onEdit?: (row: Record<string, unknown>) => void;
  onDelete?: (row: Record<string, unknown>) => void;
  onView?: (row: Record<string, unknown>) => void;
  onRowClick?: (row: Record<string, unknown>) => void;
  emptyMessage?: string;
  getRowErrorMessage?: (row: Record<string, unknown>) => string | null | undefined;
}

export default function DataTable({
  columns,
  rows,
  onEdit,
  onDelete,
  onView,
  onRowClick,
  emptyMessage = '暂无记录。可以调整筛选，或使用页面上的主操作新增。',
  getRowErrorMessage,
}: DataTableProps) {
  const actionCount = [onEdit, onDelete, onView].filter(Boolean).length;
  const hasActions = actionCount > 0;
  const useMenu = actionCount > 2;
  const colSpan = columns.length + (hasActions ? 1 : 0);

  return (
    <div className="table-card">
      <table>
        <thead>
          <tr>
            {columns.map((col) => (
              <th key={col.key}>{col.label}</th>
            ))}
            {hasActions ? <th>操作</th> : null}
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 ? (
            <tr>
              <td colSpan={colSpan} className="table-empty">
                {emptyMessage}
              </td>
            </tr>
          ) : (
            rows.map((row, index) => {
              const rowErrorMessage = getRowErrorMessage?.(row);
              const rowKey = identityForRow(row, index);

              if (rowErrorMessage) {
                return (
                  <tr key={rowKey}>
                    <td colSpan={colSpan} className="table-empty form-error">
                      {rowErrorMessage}
                    </td>
                  </tr>
                );
              }

              return (
                <tr key={rowKey} onClick={onRowClick ? () => onRowClick(row) : undefined} style={onRowClick ? { cursor: 'pointer' } : undefined}>
                  {columns.map((col) => (
                    <td key={col.key}>
                      {col.render ? col.render(row) : (row[col.key] as React.ReactNode)}
                    </td>
                  ))}
                  {hasActions ? (
                    <td className="table-actions" onClick={(event) => event.stopPropagation()}>
                      {useMenu ? (
                        <details className="row-menu">
                          <summary>操作</summary>
                          {onView ? <button type="button" className="link-button" onClick={() => onView(row)}>详情</button> : null}
                          {onEdit ? <button type="button" className="link-button" onClick={() => onEdit(row)}>编辑</button> : null}
                          {onDelete ? <button type="button" className="link-button danger" onClick={() => onDelete(row)}>删除</button> : null}
                        </details>
                      ) : (
                        <>
                          {onView ? <button type="button" className="link-button" onClick={() => onView(row)}>详情</button> : null}
                          {onEdit ? <button type="button" className="link-button" onClick={() => onEdit(row)}>编辑</button> : null}
                          {onDelete ? <button type="button" className="link-button danger" onClick={() => onDelete(row)}>删除</button> : null}
                        </>
                      )}
                    </td>
                  ) : null}
                </tr>
              );
            })
          )}
        </tbody>
      </table>
    </div>
  );
}
