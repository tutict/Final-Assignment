import { useMemo } from 'react';
import PageLayout from '../../components/PageLayout';
import SimpleBarChart from '../../components/SimpleBarChart';
import TrendChart from '../../components/TrendChart';
import PieChart from '../../components/PieChart';
import ErrorStateView from '../../components/ErrorStateView';
import { useOffenseDashboard } from '../../hooks/useOffenseDashboard';

/**
 * 交通违法概览页，对齐 Flutter OffenseScreen。
 * 四张图：违法类型分布 / 罚款扣分趋势 / 申诉理由分布 / 罚款支付状态。
 */
export default function TrafficViolationScreenPage() {
  const { metrics, isLoading, isError, refresh } = useOffenseDashboard();

  const offenseTypeData = useMemo(
    () => metrics.offenseTypes.slice(0, 6).map((item) => ({ label: item.label, value: item.value })),
    [metrics.offenseTypes]
  );
  const appealReasonData = useMemo(
    () => metrics.appealReasons.slice(0, 5).map((item) => ({ label: item.label, value: item.value })),
    [metrics.appealReasons]
  );

  return (
    <PageLayout
      title="交通违法概览"
      subtitle="图表化分析近期违法趋势"
      headerActions={
        <button type="button" className="ghost" onClick={refresh} disabled={isLoading}>
          {isLoading ? '刷新中...' : '刷新'}
        </button>
      }
    >
      {isError ? (
        <ErrorStateView message="加载违法数据失败，请重试" onRetry={refresh} />
      ) : null}

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
    </PageLayout>
  );
}
