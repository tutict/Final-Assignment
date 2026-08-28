import { useState } from 'react';
import { useTheme } from '../../theme/ThemeContext';
import { useAuth } from '../../auth/AuthContext';
import { clearStoredAuth } from '../../api/client';
import PageLayout from '../../components/PageLayout';

/**
 * 管理员设置页：对齐 Flutter `ManagerSettingPage`。
 * 提供主题切换、通知开关（本地占位）、退出登录。
 */
export default function ManagerSettingPage() {
  const { theme, setTheme } = useTheme();
  const { logout } = useAuth();
  const [notifyEnabled, setNotifyEnabled] = useState(true);

  const handleLogout = async () => {
    await logout();
    clearStoredAuth();
  };

  return (
    <PageLayout title="管理员设置" subtitle="系统安全与告警策略">
      <div className="panel">
        <h3>界面主题</h3>
        <div className="setting-row">
          <span>当前主题</span>
          <select
            value={theme}
            onChange={(event) => setTheme(event.target.value as 'light' | 'dark')}
          >
            <option value="light">明亮模式</option>
            <option value="dark">暗黑模式</option>
          </select>
        </div>
      </div>
      <div className="panel">
        <h3>通知</h3>
        <div className="setting-row">
          <span>启用业务事件通知</span>
          <label className="toggle">
            <input
              type="checkbox"
              checked={notifyEnabled}
              onChange={(event) => setNotifyEnabled(event.target.checked)}
            />
            {notifyEnabled ? '已开启' : '已关闭'}
          </label>
        </div>
      </div>
      <div className="panel">
        <h3>账户</h3>
        <div className="setting-row">
          <span>退出登录并吊销刷新令牌</span>
          <button type="button" className="danger" onClick={handleLogout}>
            退出登录
          </button>
        </div>
      </div>
    </PageLayout>
  );
}
