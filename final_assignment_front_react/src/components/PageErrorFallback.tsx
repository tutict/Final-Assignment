interface PageErrorFallbackProps {
  pageName?: string;
}

export default function PageErrorFallback({ pageName = '当前页面' }: PageErrorFallbackProps) {
  return (
    <div className="error-fallback">
      <p>{pageName}加载失败，请刷新页面或联系管理员。</p>
      <button type="button" onClick={() => window.location.reload()}>
        刷新页面
      </button>
    </div>
  );
}
