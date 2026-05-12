import React from 'react';

/**
 * @component PageLayout
 * @description 页面骨架容器，提供标题区、说明文本、右侧操作区和内容区。
 *
 * @param {{
 *   title: string,
 *   subtitle?: string,
 *   headerActions?: React.ReactNode,
 *   children: React.ReactNode,
 * }} props - 页面标题、辅助说明、顶部右侧操作区和页面内容。
 *
 * @notes
 * - 当前没有 breadcrumb prop。
 * - 顶部右侧操作区命名为 headerActions，不是 actions。
 */
export default function PageLayout({ title, subtitle, headerActions, children }) {
  return (
    <section className="page">
      <div className="page-header">
        <div>
          <h1>{title}</h1>
          {subtitle ? <p>{subtitle}</p> : null}
        </div>
        {headerActions ? <div className="page-actions">{headerActions}</div> : null}
      </div>
      <div className="page-body">{children}</div>
    </section>
  );
}

