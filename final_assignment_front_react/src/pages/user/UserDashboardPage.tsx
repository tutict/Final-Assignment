import { useMemo } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import PageLayout from '../../components/PageLayout';
import StatCard from '../../components/StatCard';
import { useAuth } from '../../auth/AuthContext';
import { useUserDashboardMetrics } from '../../hooks/useUserDashboard';
import { useUserAppeals } from '../../hooks/useUserAppeals';
import { useProgress } from '../../hooks/useProgress';
import { getDriver } from '../../api/profile';

const TASKS = [
  { label: '我的违法', path: '/userOffenseListPage', desc: '查看本人违法记录' },
  { label: '缴费', path: '/fineInformation', desc: '核对并缴纳罚款' },
  { label: '申诉', path: '/userAppeal', desc: '提交或查看申诉' },
  { label: '我的车辆', path: '/vehicleManagement', desc: '管理已登记车辆' },
];

export default function UserDashboardPage() {
  const { auth } = useAuth();
  const navigate = useNavigate();
  const [, setParams] = useSearchParams();
  const driverId = auth?.userId;
  const { metrics, isLoading, isError, refresh } = useUserDashboardMetrics(driverId);
  const appealsQuery = useUserAppeals(driverId);
  const progress = useProgress({ canManage: false });
  const profileNoticeQuery = useProfileNotice(driverId);

  const activeAppeals = useMemo(() => {
    const list = (appealsQuery.data || []) as Array<{ status?: string; appealStatus?: string; processStatus?: string }>;
    return list.filter((item) => {
      const status = (item.processStatus || item.appealStatus || item.status || '').toUpperCase();
      return status && !['APPROVED', 'REJECTED', 'CLOSED', 'COMPLETED', 'ARCHIVED'].includes(status);
    }).length;
  }, [appealsQuery.data]);

  return (
    <PageLayout title="首页" subtitle="待办、消息和办事入口">
      {profileNoticeQuery?.incomplete ? (
        <div className="profile-notice" role="status">
          <span className="profile-notice-text">
            个人资料还不完整（{profileNoticeQuery.missing.join('、')}）。补全后才能继续办理。
          </span>
          <button type="button" className="primary" onClick={() => navigate('/personalMain')}>
            去完善
          </button>
        </div>
      ) : null}

      <div className="stat-grid">
        <StatCard title="待缴费" value={isLoading ? '-' : metrics.unpaidFines} description="可进入缴费页处理" />
        <StatCard title="处理中申诉" value={appealsQuery.isLoading ? '-' : activeAppeals} description="尚未办结的申诉" />
        <StatCard
          title="未读消息"
          value={progress.isLoading ? '-' : progress.items.length}
          description="办理进度与通知"
        />
      </div>

      {isError ? (
        <div className="error-state">
          <p>首页数据没有加载成功。已填内容不受影响，可以重试。</p>
          <button type="button" className="ghost" onClick={refresh}>重试</button>
        </div>
      ) : null}

      <div className="panel">
        <h3>办事</h3>
        <div className="task-grid">
          {TASKS.map((task) => (
            <button key={task.path} type="button" className="task-card" onClick={() => navigate(task.path)}>
              <strong>{task.label}</strong>
              <span>{task.desc}</span>
            </button>
          ))}
        </div>
        <div style={{ marginTop: 16 }}>
          <button
            type="button"
            className={profileNoticeQuery?.incomplete ? 'ghost' : 'primary'}
            onClick={() => setParams({ guide: 'news' })}
          >
            办事指引
          </button>
        </div>
      </div>
    </PageLayout>
  );
}

function useProfileNotice(driverId?: string | number):
  | { incomplete: true; missing: string[] }
  | { incomplete: false; missing: never[] }
  | undefined {
  const query = useQuery({
    queryKey: ['profile', 'driver', driverId],
    queryFn: () => getDriver(driverId as number),
    enabled: Boolean(driverId),
  });
  if (query.isLoading || !query.data) return undefined;
  const missing: string[] = [];
  if (!query.data.idCardNumber) missing.push('身份证号');
  if (!query.data.driverLicenseNumber) missing.push('驾驶证号');
  return missing.length > 0 ? { incomplete: true, missing } : { incomplete: false, missing: [] };
}
