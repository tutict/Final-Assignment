import React from 'react';

export default function PageLayout({ title, subtitle, actions, children }) {
  return (
    <section className="page">
      <div className="page-header">
        <div>
          <h1>{title}</h1>
          {subtitle ? <p>{subtitle}</p> : null}
        </div>
        {actions ? <div className="page-actions">{actions}</div> : null}
      </div>
      <div className="page-body">{children}</div>
    </section>
  );
}

