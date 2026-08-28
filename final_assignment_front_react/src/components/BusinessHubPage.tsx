import { useNavigate } from 'react-router-dom';
import PageLayout from './PageLayout';

/**
 * 业务枢纽导航页：统一渲染一组带图标/描述/标签的导航瓦片。
 * 对齐 Flutter SystemGovernancePage / ManagerBusinessProcessing / BusinessProgressPage
 * ——三者均为「头部 + 瓦片网格」结构，差异仅在瓦片集合，故抽出复用。
 */
export interface HubOption {
  title: string;
  description: string;
  /** 右上角小标签（Flutter metric/status） */
  badge: string;
  /** react-icons 图标组件 */
  icon: IconComponent;
  /** 跳转目标路由 */
  target: string;
  /** 强调色（CSS 色值），用于图标与悬停描边 */
  accent?: string;
}

type IconComponent = React.ComponentType<{ size?: number; className?: string }>;

interface BusinessHubPageProps {
  title: string;
  subtitle: string;
  headerIcon?: IconComponent;
  headerNote?: string;
  options: HubOption[];
  /** 网格底部提示条文案（对齐 Flutter _BusinessProgressHint） */
  hint?: string;
  /** 右上角徽标文案，如「4 个入口」 */
  countLabel?: string;
}

export default function BusinessHubPage({
  title,
  subtitle,
  headerIcon: HeaderIcon,
  headerNote,
  options,
  hint,
  countLabel,
}: BusinessHubPageProps) {
  const navigate = useNavigate();

  return (
    <PageLayout title={title} subtitle={subtitle}>
      <div className="hub-header">
        {HeaderIcon ? (
          <span className="hub-header-icon">
            <HeaderIcon size={22} />
          </span>
        ) : null}
        <div className="hub-header-text">
          <h3>{title}</h3>
          <p>{headerNote || subtitle}</p>
        </div>
        {countLabel ? <span className="hub-count">{countLabel}</span> : null}
      </div>

      <div className="hub-grid">
        {options.map((option) => {
          const Icon = option.icon;
          const accent = option.accent || 'var(--accent)';
          return (
            <button
              key={option.target}
              type="button"
              className="hub-tile"
              style={{ ['--hub-accent' as string]: accent }}
              onClick={() => navigate(option.target)}
            >
              <span className="hub-tile-icon">
                <Icon size={24} />
              </span>
              <span className="hub-tile-body">
                <span className="hub-tile-top">
                  <span className="hub-tile-title">{option.title}</span>
                  <span className="hub-tile-badge">{option.badge}</span>
                </span>
                <span className="hub-tile-desc">{option.description}</span>
              </span>
              <span className="hub-tile-arrow">→</span>
            </button>
          );
        })}
      </div>

      {hint ? <div className="hub-hint">{hint}</div> : null}
    </PageLayout>
  );
}
