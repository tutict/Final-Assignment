import { useEffect, useState } from 'react';
import { useTheme } from '../../theme/ThemeContext';
import PageLayout from '../../components/PageLayout';

/**
 * 管理员设置页：对齐 Flutter `ManagerSettingPage`。
 * 提供主题切换、通知开关（本地占位）、退出登录。
 */
export default function ManagerSettingPage() {
  const { theme, setTheme, palette, setPalette } = useTheme();
  const appearance = new URLSearchParams(window.location.search).get('section') === 'appearance';
  useEffect(() => {
    if (!appearance) return;
    document.getElementById('appearance')?.scrollIntoView({ block: 'center' });
  }, [appearance]);
  const [notifyEnabled, setNotifyEnabled] = useState(true);

  return (
    <PageLayout title="管理员设置" subtitle="系统安全与告警策略" reading>
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
    </PageLayout>
  );
}
