/**
 * 主题控制器：四套调色板（Basic / Traffic / Ionic / Material）× 明暗。
 * 持久化键与 Flutter 对齐：selectedStyle、isDarkMode。
 */
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';

export type ThemeMode = 'light' | 'dark';
export type PaletteId = 'Basic' | 'Traffic' | 'Ionic' | 'Material';

export const PALETTES: PaletteId[] = ['Basic', 'Traffic', 'Ionic', 'Material'];

const STYLE_KEY = 'selectedStyle';
const MODE_KEY = 'isDarkMode';

function readPalette(): PaletteId {
  const stored = localStorage.getItem(STYLE_KEY);
  if (stored === 'Basic' || stored === 'Traffic' || stored === 'Ionic' || stored === 'Material') {
    return stored;
  }
  return 'Basic';
}

function readMode(): ThemeMode {
  const stored = localStorage.getItem(MODE_KEY);
  if (stored === 'true' || stored === 'Dark') return 'dark';
  if (stored === 'false' || stored === 'Light') return 'light';
  const legacy = localStorage.getItem('appTheme');
  if (legacy === 'dark' || legacy === 'light') return legacy;
  if (typeof window !== 'undefined' && window.matchMedia?.('(prefers-color-scheme: dark)').matches) {
    return 'dark';
  }
  return 'light';
}

interface ThemeContextValue {
  theme: ThemeMode;
  palette: PaletteId;
  toggleTheme: () => void;
  setTheme: (mode: ThemeMode) => void;
  setPalette: (palette: PaletteId) => void;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setThemeState] = useState<ThemeMode>(() => readMode());
  const [palette, setPaletteState] = useState<PaletteId>(() => readPalette());

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    document.documentElement.setAttribute('data-palette', palette.toLowerCase());
    localStorage.setItem(MODE_KEY, theme === 'dark' ? 'true' : 'false');
    localStorage.setItem(STYLE_KEY, palette);
    localStorage.setItem('appTheme', theme);
  }, [theme, palette]);

  const setTheme = useCallback((mode: ThemeMode) => setThemeState(mode), []);
  const setPalette = useCallback((next: PaletteId) => setPaletteState(next), []);
  const toggleTheme = useCallback(
    () => setThemeState((prev) => (prev === 'dark' ? 'light' : 'dark')),
    []
  );

  const value = useMemo<ThemeContextValue>(
    () => ({ theme, palette, toggleTheme, setTheme, setPalette }),
    [theme, palette, toggleTheme, setTheme, setPalette]
  );

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  const ctx = useContext(ThemeContext);
  if (!ctx) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return ctx;
}
