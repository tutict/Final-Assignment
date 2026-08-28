import type { ReactNode } from 'react';

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
  getRowErrorMessage?: (row: Record<string, unknown>) => string | null | undefined;
}

export default function DataTable({
  columns,
  rows,
  onEdit,
  onDelete,
  onView,
  getRowErrorMessage,
}: DataTableProps) {
  const hasActions = Boolean(onEdit || onDelete || onView);
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
                暂无数据
              </td>
            </tr>
          ) : (
            rows.map((row, index) => {
              const rowErrorMessage = getRowErrorMessage?.(row);
              const rowKey = (row.id || row.key || row.offenseId || index) as string | number;

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
                <tr key={rowKey}>
                  {columns.map((col) => (
                    <td key={col.key}>
                      {col.render ? col.render(row) : (row[col.key] as React.ReactNode)}
                    </td>
                  ))}
                  {hasActions ? (
                    <td className="table-actions">
                      {onView ? (
                        <button type="button" className="link-button" onClick={() => onView(row)}>
                          详情
                        </button>
                      ) : null}
                      {onEdit ? (
                        <button type="button" className="link-button" onClick={() => onEdit(row)}>
                          编辑
                        </button>
                      ) : null}
                      {onDelete ? (
                        <button type="button" className="link-button danger" onClick={() => onDelete(row)}>
                          删除
                        </button>
                      ) : null}
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
