import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTheme } from '../../theme/ThemeContext';
import PageLayout from '../../components/PageLayout';

/**
 * 用户设置页：对齐 Flutter `SettingPage`。
 * 提供主题切换、清缓存、保存设置、反馈入口、退出登录。
 */
export default function UserSettingPage() {
  const { theme, setTheme, palette, setPalette } = useTheme();
  const appearance = new URLSearchParams(window.location.search).get('section') === 'appearance';
  useEffect(() => {
    if (!appearance) return;
    document.getElementById('appearance')?.scrollIntoView({ block: 'center' });
  }, [appearance]);
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

  return (
    <PageLayout title="用户设置" subtitle="通知、隐私与偏好" reading>
      <div className="panel">
        <h3>界面主题</h3>
        <div id="appearance" className={appearance ? "setting-row is-target" : "setting-row"}>
          <span>明暗</span>
          <select value={theme} onChange={(event) => setTheme(event.target.value as 'light' | 'dark')}>
            <option value="light">浅色</option>
            <option value="dark">深色</option>
          </select>
        </div>
        <div className="palette-grid" role="group" aria-label="调色板">
          {(['Basic', 'Traffic', 'Ionic', 'Material'] as const).map((item) => (
            <button
              key={item}
              type="button"
              className={palette === item ? 'ghost is-selected' : 'ghost'}
              onClick={() => setPalette(item)}
            >
              {item}
            </button>
          ))}
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
          <span>返回首页</span>
          <button type="button" className="ghost" onClick={() => navigate('/userDashboard')}>
            返回首页
          </button>
        </div>
      </div>
    </PageLayout>
  );
}
