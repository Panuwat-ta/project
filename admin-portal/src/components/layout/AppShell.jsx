import { useCallback, useEffect, useState } from 'react';
import { Outlet } from 'react-router-dom';
import Drawer from '../ui/Drawer.jsx';
import CommandPalette from '../navigation/CommandPalette.jsx';
import Sidebar, { SidebarNav } from './Sidebar.jsx';
import TopBar from './TopBar.jsx';
import { useDashboardSocket } from '../../features/dashboard/useDashboardSocket.js';

export default function AppShell() {
  const [navOpen, setNavOpen] = useState(false);
  const [paletteOpen, setPaletteOpen] = useState(false);
  const liveState = useDashboardSocket();

  const openPalette = useCallback(() => setPaletteOpen(true), []);

  useEffect(() => {
    const keyHandler = (event) => {
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault();
        setPaletteOpen((prev) => !prev);
      }
    };
    document.addEventListener('keydown', keyHandler);
    return () => document.removeEventListener('keydown', keyHandler);
  }, []);

  return (
    <div className="flex min-h-screen bg-app text-ink">
      <a
        href="#main-content"
        className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-[70] focus:rounded-lg focus:bg-surface focus:px-4 focus:py-2 focus:font-semibold"
      >
        ข้ามไปยังเนื้อหาหลัก
      </a>
      <Sidebar />
      <div className="flex min-w-0 flex-1 flex-col">
        <TopBar onMenu={() => setNavOpen(true)} onSearch={openPalette} liveState={liveState} />
        <main id="main-content" className="mx-auto w-full max-w-[1600px] flex-1 px-4 py-4 sm:px-5 md:px-7 md:py-7">
          <Outlet />
        </main>
      </div>
      <Drawer open={navOpen} onClose={() => setNavOpen(false)} title="เมนูนำทาง" side="left">
        <div className="flex items-center gap-2.5 px-1 pb-4">
          <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-action text-sm font-bold text-white" aria-hidden="true">
            SG
          </span>
          <span className="text-[15px] font-bold">ScamGuard</span>
        </div>
        <SidebarNav onNavigate={() => setNavOpen(false)} />
      </Drawer>
      <CommandPalette open={paletteOpen} onClose={() => setPaletteOpen(false)} />
    </div>
  );
}
