import { Outlet } from "react-router-dom";
import { Sidebar } from "@/components/Sidebar";
import { TopBar } from "@/components/TopBar";
import { ThemeProvider } from "@/components/theme-provider";

export function AdminLayout() {
  return (
    <ThemeProvider defaultTheme="dark" storageKey="scamguard-theme">
      <div className="min-h-screen bg-background font-sans text-foreground flex flex-col md:flex-row">
        <Sidebar />
        <div className="flex flex-col flex-1">
          <TopBar />
          <main className="flex-1 p-6 md:ml-[260px] overflow-auto">
            <Outlet />
          </main>
        </div>
      </div>
    </ThemeProvider>
  );
}
