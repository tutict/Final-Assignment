import { useSearchParams } from 'react-router-dom';
import { findGuide, guideArticles } from '../config/guides';

export default function HelpDrawer() {
  const [params, setParams] = useSearchParams();
  const guideId = params.get('guide');
  if (!guideId) return null;
  const article = findGuide(guideId);

  const select = (id: string) => {
    const next = new URLSearchParams(params);
    next.set('guide', id);
    setParams(next, { replace: true });
  };

  const close = () => {
    const next = new URLSearchParams(params);
    next.delete('guide');
    setParams(next, { replace: true });
  };

  return (
    <aside className="help-drawer" aria-label="办事指引">
      <div className="page-header">
        <h2>{article?.title || '办事指引'}</h2>
        <button type="button" className="ghost" onClick={close}>
          关闭
        </button>
      </div>
      <div className="guide-list">
        {guideArticles.map((item) => (
          <button key={item.id} type="button" onClick={() => select(item.id)}>
            {item.title}
          </button>
        ))}
      </div>
      {article ? (
        <div className="reading-wrap">
          {article.sections.map((section) => (
            <section key={section.heading}>
              <h3>{section.heading}</h3>
              <p>{section.content}</p>
            </section>
          ))}
        </div>
      ) : (
        <p>没有找到对应指引。请从列表中选择一篇。</p>
      )}
    </aside>
  );
}
