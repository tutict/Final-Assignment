/**
 * 安全驾驶横幅轮播，对齐 Flutter UserScreenSwiper。
 * 3 张静态安全提示幻灯片，自动播放（4.2s）、过渡 650ms、矩形指示点。
 * 幻灯片内容完全静态，对齐 Flutter _UserSafetySlide.slides。
 */
import { useCallback, useEffect, useRef, useState } from 'react';

interface Slide {
  title: string;
  subtitle: string;
  tag: string;
  accent: string;
  gradient: string;
}

const SLIDES: Slide[] = [
  {
    title: '安全驾驶，文明出行',
    subtitle: '出发前确认状态，行驶中保持车距和注意力。',
    tag: '安全提醒',
    accent: '#2F80ED',
    gradient: 'linear-gradient(135deg, rgba(47,128,237,0.85), rgba(20,40,80,0.92))',
  },
  {
    title: '遵守交规，平安回家',
    subtitle: '红灯停、礼让行人，减少每一次不必要的风险。',
    tag: '文明通行',
    accent: '#25A7A0',
    gradient: 'linear-gradient(135deg, rgba(37,167,160,0.85), rgba(15,60,60,0.92))',
  },
  {
    title: '减速慢行，生命至上',
    subtitle: '夜间、雨雪和拥堵路段主动降速，预留反应空间。',
    tag: '风险预警',
    accent: '#E5A33A',
    gradient: 'linear-gradient(135deg, rgba(229,163,58,0.85), rgba(80,50,10,0.92))',
  },
];

const AUTOPLAY_MS = 4200;

export default function UserCarousel() {
  const [index, setIndex] = useState(0);
  const [paused, setPaused] = useState(false);
  const timerRef = useRef<number | null>(null);

  const go = useCallback(
    (next: number) => {
      setIndex(((next % SLIDES.length) + SLIDES.length) % SLIDES.length);
    },
    []
  );

  useEffect(() => {
    if (paused) return;
    timerRef.current = window.setTimeout(() => {
      setIndex((prev) => (prev + 1) % SLIDES.length);
    }, AUTOPLAY_MS);
    return () => {
      if (timerRef.current !== null) {
        window.clearTimeout(timerRef.current);
        timerRef.current = null;
      }
    };
  }, [index, paused]);

  return (
    <div
      className="user-carousel"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      role="region"
      aria-label="安全驾驶提示"
    >
      <div className="user-carousel-track">
        {SLIDES.map((slide, i) => (
          <div
            key={slide.title}
            className="user-carousel-slide"
            style={{
              background: slide.gradient,
              opacity: i === index ? 1 : 0,
              transform: i === index ? 'scale(1)' : 'scale(0.94)',
              pointerEvents: i === index ? 'auto' : 'none',
            }}
            aria-hidden={i !== index}
          >
            <span className="user-carousel-tag" style={{ background: slide.accent }}>
              {slide.tag}
            </span>
            <div className="user-carousel-text">
              <h3>{slide.title}</h3>
              <p>{slide.subtitle}</p>
            </div>
          </div>
        ))}
      </div>

      <div className="user-carousel-dots">
        {SLIDES.map((_, i) => (
          <button
            key={i}
            type="button"
            className={`user-carousel-dot ${i === index ? 'active' : ''}`}
            aria-label={`切换到第 ${i + 1} 张`}
            onClick={() => go(i)}
          />
        ))}
      </div>

      <button
        type="button"
        className="user-carousel-arrow prev"
        aria-label="上一张"
        onClick={() => go(index - 1)}
      >
        ‹
      </button>
      <button
        type="button"
        className="user-carousel-arrow next"
        aria-label="下一张"
        onClick={() => go(index + 1)}
      >
        ›
      </button>
    </div>
  );
}
