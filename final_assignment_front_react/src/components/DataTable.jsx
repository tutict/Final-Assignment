import React from 'react';

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

