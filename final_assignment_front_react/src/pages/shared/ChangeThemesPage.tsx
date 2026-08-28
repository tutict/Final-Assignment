import { useTheme, type ThemeMode } from '../../theme/ThemeContext';
import PageLayout from '../../components/PageLayout';

const themeOptions: Array<{ mode: ThemeMode; label: string; description: string }> = [
  { mode: 'light', label: '明亮模式', description: '默认浅色界面，适合白天与高亮度环境' },
  { mode: 'dark', label: '暗黑模式', description: '低亮度护眼界面，适合夜间与弱光环境' },
];

export default function ChangeThemesPage() {
  const { theme, setTheme } = useTheme();

  return (
    <PageLayout title="主题切换" subtitle="切换界面风格与强调色">
      <div className="grid-two">
        {themeOptions.map((option) => (
          <button
            key={option.mode}
            type="button"
            className={`panel theme-card ${theme === option.mode ? 'is-active' : ''}`}
            onClick={() => setTheme(option.mode)}
          >
            <h3>{option.label}</h3>
            <p>{option.description}</p>
            <span className="theme-tag">{theme === option.mode ? '当前' : '点击启用'}</span>
          </button>
        ))}
      </div>
    </PageLayout>
  );
}
