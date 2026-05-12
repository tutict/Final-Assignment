export default function ErrorStateView({ message, onRetry }) {
  return (
    <div className="error-state" role="alert">
      <span>{message}</span>
      {onRetry ? (
        <button type="button" className="ghost" onClick={() => onRetry()}>
          重试
        </button>
      ) : null}
    </div>
  );
}
