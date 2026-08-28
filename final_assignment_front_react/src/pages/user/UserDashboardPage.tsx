import { useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import PageLayout from '../../components/PageLayout';
import StatCard from '../../components/StatCard';
import UserCarousel from '../../components/UserCarousel';
import { useAuth } from '../../auth/AuthContext';
import { useUserDashboardMetrics } from '../../hooks/useUserDashboard';
import { useUserAppeals } from '../../hooks/useUserAppeals';

/**
 * 用户首页，对齐 Flutter user_dashboard。
 * 顶部安全驾驶轮播 + 个人 KPI + 快速入口。
 */
const QUICK_LINKS = [
  { label: '违法记录', path: '/userOffenseListPage', desc: '查看我的违法行为' },
  { label: '车辆管理', path: '/vehicleManagement', desc: '管理已绑定车辆' },
  { label: '罚款信息', path: '/fineInformation', desc: '在线缴纳罚款' },
  { label: '业务进度', path: '/businessProgress', desc: '跟踪办理进度' },
];

export default function UserDashboardPage() {
  const { auth } = useAuth();
  const navigate = useNavigate();
  const driverId = auth?.userId;
  const { metrics, isLoading, refresh } = useUserDashboardMetrics(driverId);
  const appealsQuery = useUserAppeals(driverId);
  const activeAppeals = useMemo(() => {
    const list = (appealsQuery.data || []) as Array<{ status?: string; appealStatus?: string }>;
    return list.filter((item) => {
      const status = (item.appealStatus || item.status || '').toUpperCase();
      return status && !['APPROVED', 'REJECTED', 'CLOSED'].includes(status);
    }).length;
  }, [appealsQuery.data]);

  return (
    <PageLayout title="用户首页" subtitle="查看违法记录与业务进度">
      <UserCarousel />

      <div className="stat-grid">
        <StatCard
          title="待处理违法"
          value={isLoading ? '-' : metrics.pendingOffenses}
          description="待处理违法记录"
        />
        <StatCard
          title="待缴罚款"
          value={isLoading ? '-' : metrics.unpaidFines}
          description="可在线缴纳"
        />
        <StatCard
          title="处理中申诉"
          value={activeAppeals}
          description="等待审核"
        />
        <StatCard
          title="车辆信息"
          value={metrics.vehicleCount || '-'}
          description="已绑定车辆"
        />
      </div>

      <div className="panel">
        <h3>快速入口</h3>
        <div className="grid-two">
          {QUICK_LINKS.map((link) => (
            <button
              key={link.path}
              type="button"
              className="quick-link"
              onClick={() => navigate(link.path)}
            >
              <span className="quick-link-title">{link.label}</span>
              <span className="quick-link-desc">{link.desc}</span>
            </button>
          ))}
        </div>
        <div style={{ marginTop: 16 }}>
          <button type="button" className="ghost" onClick={refresh} disabled={isLoading}>
            {isLoading ? '刷新中...' : '刷新数据'}
          </button>
        </div>
      </div>
    </PageLayout>
  );
}
