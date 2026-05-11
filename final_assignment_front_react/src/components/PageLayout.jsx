import React from 'react';

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

