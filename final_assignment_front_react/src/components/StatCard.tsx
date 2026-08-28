interface StatCardProps {
  title: string;
  value: React.ReactNode;
  trend?: React.ReactNode;
  description?: React.ReactNode;
}

export default function StatCard({ title, value, trend, description }: StatCardProps) {
  return (
    <div className="stat-card">
      <div className="stat-header">
        <span>{title}</span>
        {trend ? <span className="stat-trend">{trend}</span> : null}
      </div>
      <div className="stat-value">{value}</div>
      {description ? <div className="stat-description">{description}</div> : null}
    </div>
  );
}
