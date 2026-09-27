import { useEffect, useState } from 'react';
import { Outlet } from 'react-router-dom';
import Sidebar from '../components/Sidebar';
import Header from '../components/Header';
import AgentWindow from '../components/AgentWindow';
import HelpDrawer from '../components/HelpDrawer';

function useViewportWidth() {
  const [width, setWidth] = useState(() => window.innerWidth);
  useEffect(() => {
    const onResize = () => setWidth(window.innerWidth);
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);
  return width;
}

export default function AppShell() {
  const width = useViewportWidth();
  const mobile = width < 700;
  const desktop = width >= 1100;
  const [collapsed, setCollapsed] = useState(!desktop);
  const [navOpen, setNavOpen] = useState(false);
  const [widthBand, setWidthBand] = useState(desktop ? 'desktop' : 'narrow');

  useEffect(() => {
    const band = desktop ? 'desktop' : 'narrow';
    if (band !== widthBand) {
      setWidthBand(band);
      setCollapsed(!desktop);
      if (!mobile) setNavOpen(false);
    }
  }, [desktop, mobile, widthBand]);

  return (
    <>
      <a className="skip-link" href="#main-content">
        跳到内容
      </a>
      <div className={`app-shell${collapsed && !mobile ? ' is-collapsed' : ''}${mobile ? ' is-mobile' : ''}${navOpen ? ' nav-open' : ''}`}>
        {mobile && navOpen ? (
          <button className="nav-backdrop" type="button" aria-label="关闭导航" onClick={() => setNavOpen(false)} />
        ) : null}
        <Sidebar
          collapsed={!mobile && collapsed}
          mobile={mobile}
          onNavigate={() => {
            if (mobile) setNavOpen(false);
          }}
        />
        <div className="app-main">
          <Header showMenu={mobile || !desktop} onOpenNav={() => (mobile ? setNavOpen(true) : setCollapsed((value) => !value))} />
          <div className="app-body">
            <main id="main-content" className="app-content">
              <Outlet />
            </main>
            <AgentWindow />
            <HelpDrawer />
          </div>
        </div>
      </div>
    </>
  );
}
