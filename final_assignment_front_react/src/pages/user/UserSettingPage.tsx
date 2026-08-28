import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTheme } from '../../theme/ThemeContext';
import { useAuth } from '../../auth/AuthContext';
import { clearStoredAuth } from '../../api/client';
import PageLayout from '../../components/PageLayout';

/**
 * 用户设置页：对齐 Flutter `SettingPage`。
 * 提供主题切换、清缓存、保存设置、反馈入口、退出登录。
 */
export default function UserSettingPage() {
  const { theme, setTheme } = useTheme();
  const { logout } = useAuth();
  const navigate = useNavigate();
  const [cleared, setCleared] = useState(false);
  const [saved, setSaved] = useState(false);

  const handleClearCache = () => {
    // 浏览器端清缓存：清理非鉴权类 localStorage/ sessionStorage 业务缓存键
    const keep = new Set([
      'authToken',
      'refreshToken',
      'userRole',
      'userName',
      'userEmail',
      'driverName',
      'userId',
      'appTheme',
    ]);
    Object.keys(localStorage).forEach((key) => {
      if (!keep.has(key)) localStorage.removeItem(key);
    });
    try {
      sessionStorage.clear();
    } catch {
      /* 忽略 */
    }
    setCleared(true);
    window.setTimeout(() => setCleared(false), 2000);
  };

  // 对齐 Flutter _saveSettings：展示保存成功提示（主题已实时持久化于 ThemeContext）
  const handleSaveSettings = () => {
    setSaved(true);
    window.setTimeout(() => setSaved(false), 2000);
  };

  // 对齐 Flutter 反馈入口，跳转到咨询反馈页
  const handleFeedback = () => navigate('/consultation');

  const handleLogout = async () => {
    await logout();
    clearStoredAuth();
  };

  return (
    <PageLayout title="用户设置" subtitle="通知、隐私与偏好">
      <div className="panel">
        <h3>界面主题</h3>
        <div className="setting-row">
          <span>当前主题</span>
          <select value={theme} onChange={(event) => setTheme(event.target.value as 'light' | 'dark')}>
            <option value="light">明亮模式</option>
            <option value="dark">暗黑模式</option>
          </select>
        </div>
        <div className="setting-row">
          <span>保存设置</span>
          <button type="button" className="ghost" onClick={handleSaveSettings}>
            保存设置
          </button>
        </div>
        {saved ? <div className="form-success">设置已保存</div> : null}
      </div>
      <div className="panel">
        <h3>缓存与数据</h3>
        <div className="setting-row">
          <span>清除本地缓存（保留登录信息）</span>
          <button type="button" className="ghost" onClick={handleClearCache}>
            清除缓存
          </button>
        </div>
        {cleared ? <div className="form-success">本地缓存已清除</div> : null}
      </div>
      <div className="panel">
        <h3>反馈</h3>
        <div className="setting-row">
          <span>意见与咨询反馈</span>
          <button type="button" className="ghost" onClick={handleFeedback}>
            前往反馈
          </button>
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
