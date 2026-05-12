import React from 'react';

/**
 * @component DataTable
 * @description 通用表格组件，按 columns 渲染行数据并提供查看、编辑、删除操作。
 *
 * @param {{
 *   columns: Array<{ key: string, label: string, render?: (row: Object) => React.ReactNode }>,
 *   rows: Array<Object>,
 *   onEdit?: (row: Object) => void,
 *   onDelete?: (row: Object) => void,
 *   onView?: (row: Object) => void,
 * }} props - 表格列配置、行数据和行级操作回调。
 *
 * @notes
 * - 当前组件使用 rows 作为数据源，不支持 data/onRowClick/loading/emptyText 这组命名。
 * - 空状态文案固定为“暂无数据”。
 */
export default function DataTable({ columns, rows, onEdit, onDelete, onView }) {
  return (
    <div className="table-card">
      <table>
        <thead>
          <tr>
            {columns.map((col) => (
              <th key={col.key}>{col.label}</th>
            ))}
            {(onEdit || onDelete || onView) ? <th>操作</th> : null}
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 ? (
            <tr>
              <td colSpan={columns.length + 1} className="table-empty">
                暂无数据
              </td>
            </tr>
          ) : (
            rows.map((row, index) => (
              <tr key={row.id || row.key || index}>
                {columns.map((col) => (
                  <td key={col.key}>{col.render ? col.render(row) : row[col.key]}</td>
                ))}
                {(onEdit || onDelete || onView) ? (
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
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}

