import { useMemo, useState, useEffect } from 'react';
import { useBusinessEventInvalidator } from '../../hooks/useBusinessEventInvalidator';
import PageLayout from '../../components/PageLayout';
import StatCard from '../../components/StatCard';
import SimpleBarChart from '../../components/SimpleBarChart';
import TrendChart from '../../components/TrendChart';
import PieChart from '../../components/PieChart';
import ErrorStateView from '../../components/ErrorStateView';
import { useOffenseDashboard } from '../../hooks/useOffenseDashboard';

/**
 * 管理总览页，对齐 Flutter manager_dashboard_screen + OffenseScreen。
 * 数据源 GET /api/offenses 客户端聚合；刷新按钮 + 业务事件触发自动刷新。
 */
export default function ManagerDashboardPage() {
  const { metrics, isLoading, isError, error, refresh } = useOffenseDashboard();
  const invalidate = useBusinessEventInvalidator();
  const [lastUpdated, setLastUpdated] = useState<string>('');

  useEffect(() => {
    if (!isLoading) {
      setLastUpdated(new Date().toLocaleTimeString('zh-CN'));
    }
  }, [isLoading, metrics.total]);

  // 业务事件（申诉/缴费状态变化）触发刷新，对齐 Flutter 实时联动
  useEffect(() => {
    invalidate([['offenses']]);
  }, [invalidate, metrics.total]);

  const offenseTypeData = useMemo(
    () => metrics.offenseTypes.slice(0, 6).map((item) => ({ label: item.label, value: item.value })),
    [metrics.offenseTypes]
  );
  const appealReasonData = useMemo(
    () => metrics.appealReasons.slice(0, 5),
    [metrics.appealReasons]
  );
  const pendingQueue = useMemo(() => {
    // 暂以聚合指标替代明细队列（明细需额外接口），展示分布前 5
    return metrics.offenseTypes.slice(0, 5);
  }, [metrics.offenseTypes]);

  return (
    <PageLayout
      title="管理总览"
      subtitle="实时掌控违法、罚款与申诉进度"
      headerActions={
        <button type="button" className="ghost" onClick={refresh} disabled={isLoading}>
          {isLoading ? '刷新中...' : '刷新数据'}
        </button>
      }
    >
      {lastUpdated ? <div className="dashboard-updated">最近更新：{lastUpdated}</div> : null}
      {isError ? (
        <ErrorStateView message="加载违法数据失败，请重试" onRetry={refresh} />
      ) : null}

      <div className="stat-grid">
        <StatCard title="今日新增" value={metrics.todayAdded} description="今日新增违法记录" />
        <StatCard title="待处理" value={metrics.pending} description="需人工审核/缴费" />
        <StatCard title="已办结" value={metrics.processed} description="已缴/已结记录" />
        <StatCard title="罚款合计" value={`¥${metrics.finesTotal}`} description="近 30 天罚款金额" />
      </div>

      <div className="grid-two">
        <div className="panel">
          <h3>违法类型分布</h3>
          {isLoading ? <div className="placeholder">加载中...</div> : <SimpleBarChart data={offenseTypeData} />}
        </div>
        <div className="panel">
          <h3>罚款与扣分趋势（近 30 天）</h3>
          {isLoading ? <div className="placeholder">加载中...</div> : <TrendChart data={metrics.timeSeries} />}
        </div>
      </div>

      <div className="grid-two">
        <div className="panel">
          <h3>申诉理由分布</h3>
          {isLoading ? <div className="placeholder">加载中...</div> : <PieChart data={appealReasonData} centerLabel="申诉" />}
        </div>
        <div className="panel">
          <h3>罚款支付状态</h3>
          {isLoading ? <div className="placeholder">加载中...</div> : <PieChart data={metrics.paymentStatus} centerLabel="总数" />}
        </div>
      </div>

      <div className="panel">
        <h3>待办分布</h3>
        <SimpleBarChart data={pendingQueue} horizontal unit="件" />
      </div>
    </PageLayout>
  );
}
