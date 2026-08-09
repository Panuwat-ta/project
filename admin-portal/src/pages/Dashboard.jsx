import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Users, Zap, Flag, Activity, RefreshCw, AlertCircle, Database, Server, DatabaseBackup, Gauge } from "lucide-react";
import { Area, AreaChart, ResponsiveContainer, Tooltip, XAxis, YAxis, Pie, PieChart, Cell, Bar, BarChart, CartesianGrid } from "recharts";

import { fetchDashboard, fetchHealth, getAccessToken } from "@/lib/api";

const COLORS = {
  primary: "#4f46e5", // indigo-600
  secondary: "#c7d2fe", // indigo-200
  low: "#22c55e", // green-500
  medium: "#eab308", // yellow-500
  high: "#ef4444", // red-500
};

export function Dashboard() {
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [data, setData] = useState(null);
  const [health, setHealth] = useState(null);
  const [error, setError] = useState(null);
  const [lastRefresh, setLastRefresh] = useState(null);
  const navigate = useNavigate();

  const loadData = async (isRefresh = false) => {
    try {
      if (isRefresh) setIsRefreshing(true);
      else setIsLoading(true);
      setError(null);
      
      const [dashData, healthData] = await Promise.all([
        fetchDashboard(),
        fetchHealth()
      ]);
      
      setData(dashData);
      setHealth(healthData);
      setLastRefresh(new Date());
    } catch (err) {
      console.error("Failed to load dashboard data", err);
      setError(err.message || "เกิดข้อผิดพลาดในการโหลดข้อมูล");
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();

    // Establish WebSocket connection for real-time updates
    const token = getAccessToken();
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    // Use host from current window to support local and network IP access
    const wsUrl = `${protocol}//${window.location.host}/api/v1/ws/admin/dashboard?token=${token}`;
    
    let ws;
    try {
      ws = new WebSocket(wsUrl);
      
      ws.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data);
          if (message.type === 'refresh_dashboard') {
            loadData(true);
          }
        } catch (e) {
          console.error("Failed to parse websocket message", e);
        }
      };

      ws.onerror = (error) => {
        console.error("WebSocket error:", error);
      };
    } catch (e) {
      console.error("Failed to connect to WebSocket", e);
    }

    return () => {
      if (ws) {
        ws.close();
      }
    };
  }, []);

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-4 pt-20">
        <div className="size-16 bg-red-50 dark:bg-red-900/20 rounded-full flex items-center justify-center">
          <AlertCircle className="size-8 text-red-500" />
        </div>
        <h2 className="text-xl font-semibold text-slate-900 dark:text-slate-100">ไม่สามารถโหลดข้อมูลได้</h2>
        <p className="text-sm text-slate-500 dark:text-slate-400">{error}</p>
        <button 
          onClick={() => loadData(true)}
          className="mt-4 px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 flex items-center gap-2"
        >
          <RefreshCw className="size-4" /> ลองใหม่อีกครั้ง
        </button>
      </div>
    );
  }

  if (isLoading || !data) {
    return (
      <div className="flex flex-col gap-6 font-sans">
        <div className="flex justify-between items-center">
          <div className="h-8 bg-slate-200 dark:bg-slate-800 rounded-md w-48 animate-pulse"></div>
          <div className="h-5 bg-slate-100 dark:bg-slate-800/50 rounded-md w-32 animate-pulse"></div>
        </div>

        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm p-5 h-[116px] flex flex-col justify-between">
              <div className="flex justify-between items-center">
                <div className="h-4 bg-slate-200 dark:bg-slate-800 rounded-md w-24 animate-pulse"></div>
                <div className="size-8 rounded-md bg-slate-100 dark:bg-slate-800/50 animate-pulse"></div>
              </div>
              <div>
                <div className="h-8 bg-slate-200 dark:bg-slate-800 rounded-md w-16 mb-2 animate-pulse"></div>
                <div className="h-3 bg-slate-100 dark:bg-slate-800/50 rounded-md w-24 animate-pulse"></div>
              </div>
            </div>
          ))}
        </div>

        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm lg:col-span-4 h-[385px] p-6 flex flex-col gap-4">
            <div className="h-6 bg-slate-200 dark:bg-slate-800 rounded-md w-1/3 animate-pulse mb-2"></div>
            <div className="flex-1 bg-slate-100 dark:bg-slate-800/50 rounded-lg animate-pulse"></div>
          </div>
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm lg:col-span-3 h-[385px] p-6 flex flex-col gap-4">
            <div className="h-6 bg-slate-200 dark:bg-slate-800 rounded-md w-1/3 animate-pulse mb-2"></div>
            <div className="flex-1 bg-slate-100 dark:bg-slate-800/50 rounded-full mx-auto aspect-square max-h-48 animate-pulse"></div>
            <div className="h-4 bg-slate-100 dark:bg-slate-800/50 rounded-md w-1/2 mx-auto animate-pulse mt-4"></div>
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm lg:col-span-4 h-[385px] p-6 flex flex-col gap-4">
            <div className="h-6 bg-slate-200 dark:bg-slate-800 rounded-md w-1/3 animate-pulse mb-2"></div>
            <div className="flex-1 bg-slate-100 dark:bg-slate-800/50 rounded-lg animate-pulse"></div>
          </div>
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm lg:col-span-3 h-[385px] p-6 flex flex-col gap-4">
            <div className="h-6 bg-slate-200 dark:bg-slate-800 rounded-md w-1/2 animate-pulse mb-2"></div>
            <div className="h-16 bg-slate-100 dark:bg-slate-800/50 rounded-lg animate-pulse"></div>
            <div className="h-16 bg-slate-100 dark:bg-slate-800/50 rounded-lg animate-pulse"></div>
            <div className="h-10 bg-slate-200 dark:bg-slate-800 rounded-md mt-auto animate-pulse"></div>
          </div>
        </div>
      </div>
    );
  }

  // Format Risk Data for Recharts
  const riskData = [
    { name: 'Low', value: data.risk_distribution.low, color: COLORS.low },
    { name: 'Medium', value: data.risk_distribution.medium, color: COLORS.medium },
    { name: 'High', value: data.risk_distribution.high, color: COLORS.high },
  ];

  // Format Category Data for Recharts
  const categoryData = Object.entries(data.category_breakdown).map(([key, val]) => ({
    name: key, value: val
  }));

  const scanTrendData = data.scan_trend;

  return (
    <div className="flex flex-col gap-6 font-sans">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100 flex items-center gap-3">
            Dashboard
            {isRefreshing && <RefreshCw className="size-5 animate-spin text-indigo-500" />}
          </h2>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            {new Date().toLocaleDateString('th-TH', { dateStyle: 'full' })} 
            {lastRefresh && ` • อัปเดตล่าสุด: ${lastRefresh.toLocaleTimeString('th-TH')}`}
          </p>
        </div>
        <button 
          onClick={() => loadData(true)}
          disabled={isRefreshing}
          className="px-3 py-1.5 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-300 rounded-md text-sm font-medium hover:bg-slate-50 dark:hover:bg-slate-700 flex items-center gap-2 transition-colors disabled:opacity-50"
        >
          <RefreshCw className={`size-4 ${isRefreshing ? 'animate-spin' : ''}`} /> รีเฟรชข้อมูล
        </button>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {/* KPI Card 1 */}
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm p-5">
          <div className="flex justify-between items-center pb-2">
            <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400">ผู้ใช้ทั้งหมด</h3>
            <div className="size-8 rounded-md bg-indigo-50 dark:bg-indigo-500/10 flex items-center justify-center">
              <Users className="size-4 text-indigo-600 dark:text-indigo-400" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-bold text-slate-900 dark:text-slate-100">{data.overview.total_users.toLocaleString()}</div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">{data.overview.active_users_today} ใช้งานวันนี้</p>
          </div>
        </div>

        {/* KPI Card 2 */}
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm p-5">
          <div className="flex justify-between items-center pb-2">
            <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400">สแกนทั้งหมด</h3>
            <div className="size-8 rounded-md bg-indigo-50 dark:bg-indigo-500/10 flex items-center justify-center">
              <Activity className="size-4 text-indigo-600 dark:text-indigo-400" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-bold text-slate-900 dark:text-slate-100">{data.overview.total_scans.toLocaleString()}</div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">จากทั้งหมดในระบบ</p>
          </div>
        </div>

        {/* KPI Card 3 */}
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm p-5">
          <div className="flex justify-between items-center pb-2">
            <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400">สแกนวันนี้</h3>
            <div className="size-8 rounded-md bg-indigo-50 dark:bg-indigo-500/10 flex items-center justify-center">
              <Zap className="size-4 text-indigo-600 dark:text-indigo-400" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-bold text-slate-900 dark:text-slate-100">{data.overview.scans_today.toLocaleString()}</div>
            <p className="text-xs text-emerald-600 dark:text-emerald-400 font-medium mt-1">อัปเดตวันนี้</p>
          </div>
        </div>

        {/* KPI Card 4 */}
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm p-5">
          <div className="flex justify-between items-center pb-2">
            <h3 className="text-sm font-medium text-slate-500 dark:text-slate-400">รายงาน Pending</h3>
            <div className="size-8 rounded-md bg-indigo-50 dark:bg-indigo-500/10 flex items-center justify-center">
              <Flag className="size-4 text-indigo-600 dark:text-indigo-400" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-bold text-slate-900 dark:text-slate-100">{data.reports.pending.toLocaleString()}</div>
            <p className="text-xs text-red-600 dark:text-red-400 font-medium mt-1">รอการตรวจสอบ</p>
          </div>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        {/* Trend Chart */}
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm lg:col-span-4 flex flex-col">
          <div className="px-6 py-5 border-b border-slate-100 dark:border-slate-800">
            <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">แนวโน้มการสแกน (7 วันย้อนหลัง)</h3>
          </div>
          <div className="p-6 h-[320px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={scanTrendData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorCount" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor={COLORS.primary} stopOpacity={0.2} />
                    <stop offset="95%" stopColor={COLORS.primary} stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="date" stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} dy={10} />
                <YAxis stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} dx={-10} />
                <Tooltip 
                  contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)', backgroundColor: 'var(--tw-colors-slate-800, #1e293b)', color: '#f8fafc' }}
                  itemStyle={{ color: '#f8fafc' }}
                  cursor={{ stroke: '#94a3b8', strokeWidth: 1, strokeDasharray: '3 3' }}
                />
                <Area type="monotone" dataKey="count" stroke={COLORS.primary} strokeWidth={2} fillOpacity={1} fill="url(#colorCount)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Risk Distribution */}
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm lg:col-span-3 flex flex-col">
          <div className="px-6 py-5 border-b border-slate-100 dark:border-slate-800">
            <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">สัดส่วนความเสี่ยง</h3>
          </div>
          <div className="p-6 h-[320px] flex flex-col items-center justify-center relative">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={riskData}
                  cx="50%"
                  cy="50%"
                  innerRadius={70}
                  outerRadius={90}
                  paddingAngle={2}
                  dataKey="value"
                  stroke="none"
                >
                  {riskData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip 
                  contentStyle={{ borderRadius: '8px', border: 'none', backgroundColor: '#1e293b', color: '#f8fafc' }} 
                  itemStyle={{ color: '#f8fafc' }}
                />
              </PieChart>
            </ResponsiveContainer>
            <div className="absolute flex flex-col items-center justify-center text-center pointer-events-none">
              <span className="text-3xl font-bold text-slate-900 dark:text-slate-100">{data.overview.total_scans.toLocaleString()}</span>
              <span className="text-xs text-slate-500 dark:text-slate-400">Total</span>
            </div>
            <div className="flex gap-4 justify-center mt-4">
              {riskData.map(entry => (
                <div key={entry.name} className="flex items-center gap-1.5 text-xs font-medium text-slate-600 dark:text-slate-400">
                  <div className="size-2.5 rounded-full" style={{ backgroundColor: entry.color }} />
                  {entry.name}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        {/* Category Breakdown */}
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm lg:col-span-4 flex flex-col">
          <div className="px-6 py-5 border-b border-slate-100 dark:border-slate-800">
            <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">หมวดหมู่รายงานสแกม</h3>
          </div>
          <div className="p-6 h-[320px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={categoryData} layout="vertical" margin={{ top: 0, right: 30, left: 20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#334155" />
                <XAxis type="number" stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis dataKey="name" type="category" stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} width={120} />
                <Tooltip 
                  cursor={{ fill: '#334155', opacity: 0.2 }}
                  contentStyle={{ borderRadius: '8px', border: 'none', backgroundColor: '#1e293b', color: '#f8fafc' }}
                  itemStyle={{ color: '#f8fafc' }}
                />
                <Bar dataKey="value" fill={COLORS.primary} radius={[0, 4, 4, 0]} barSize={24}>
                  {categoryData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={index % 2 === 0 ? COLORS.primary : COLORS.secondary} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* AI Model Status & Health */}
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm lg:col-span-3 flex flex-col">
          <div className="px-6 py-5 border-b border-slate-100 dark:border-slate-800">
            <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">AI Model & System Health</h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">{data.model.active_version ? `Version ${data.model.active_version} is currently active` : 'No active model'}</p>
          </div>
          <div className="p-6 flex flex-col gap-4 overflow-y-auto">
            {/* System Health Summary */}
            {health && (
              <div className="grid grid-cols-2 gap-3 mb-2">
                <div className={`flex flex-col p-3 rounded-lg border ${health.database === 'ok' ? 'bg-emerald-50 border-emerald-200 dark:bg-emerald-900/10 dark:border-emerald-800/50' : 'bg-red-50 border-red-200 dark:bg-red-900/10 dark:border-red-800/50'}`}>
                  <div className="flex items-center justify-between mb-1">
                    <Database className={`size-4 ${health.database === 'ok' ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400'}`} />
                    <div className={`size-2 rounded-full ${health.database === 'ok' ? 'bg-emerald-500' : 'bg-red-500 animate-pulse'}`} />
                  </div>
                  <span className="text-xs font-medium text-slate-500 dark:text-slate-400">Database</span>
                  <span className={`text-sm font-semibold capitalize ${health.database === 'ok' ? 'text-emerald-700 dark:text-emerald-400' : 'text-red-700 dark:text-red-400'}`}>{health.database}</span>
                </div>
                <div className={`flex flex-col p-3 rounded-lg border ${health.storage === 'ok' ? 'bg-emerald-50 border-emerald-200 dark:bg-emerald-900/10 dark:border-emerald-800/50' : 'bg-red-50 border-red-200 dark:bg-red-900/10 dark:border-red-800/50'}`}>
                  <div className="flex items-center justify-between mb-1">
                    <DatabaseBackup className={`size-4 ${health.storage === 'ok' ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400'}`} />
                    <div className={`size-2 rounded-full ${health.storage === 'ok' ? 'bg-emerald-500' : 'bg-red-500 animate-pulse'}`} />
                  </div>
                  <span className="text-xs font-medium text-slate-500 dark:text-slate-400">Storage</span>
                  <span className={`text-sm font-semibold capitalize ${health.storage === 'ok' ? 'text-emerald-700 dark:text-emerald-400' : 'text-red-700 dark:text-red-400'}`}>{health.storage}</span>
                </div>
              </div>
            )}

            {/* Model Info */}
            <div className="flex justify-between items-center p-4 bg-slate-50 dark:bg-slate-800/50 rounded-lg border border-slate-200 dark:border-slate-800">
              <div className="flex flex-col">
                <span className="text-sm font-semibold text-slate-900 dark:text-slate-100">{data.model.active_version || 'N/A'}</span>
                <span className="text-xs text-slate-500 dark:text-slate-400 mt-1">Deployed: {data.model.deployed_at ? new Date(data.model.deployed_at).toLocaleDateString('th-TH') : 'N/A'}</span>
              </div>
              <span className="px-2.5 py-1 text-[10px] font-bold tracking-wide uppercase bg-emerald-100 dark:bg-emerald-500/20 text-emerald-700 dark:text-emerald-400 rounded-full">Active</span>
            </div>

            {/* Metrics */}
            <div className="grid grid-cols-2 gap-2">
              <div className="flex flex-col items-center justify-center p-2 rounded-lg bg-slate-50 dark:bg-slate-800/30 border border-slate-100 dark:border-slate-800 text-center">
                <span className="text-[10px] text-slate-500 dark:text-slate-400 uppercase tracking-wider font-semibold mb-1">Pixel Acc (aAcc)</span>
                <span className="text-sm font-bold text-slate-900 dark:text-slate-100">{data.model.a_acc ? `${(data.model.a_acc * 100).toFixed(1)}%` : '-'}</span>
              </div>
              <div className="flex flex-col items-center justify-center p-2 rounded-lg bg-slate-50 dark:bg-slate-800/30 border border-slate-100 dark:border-slate-800 text-center">
                <span className="text-[10px] text-slate-500 dark:text-slate-400 uppercase tracking-wider font-semibold mb-1">Mean Acc (mAcc)</span>
                <span className="text-sm font-bold text-slate-900 dark:text-slate-100">{data.model.m_acc ? `${(data.model.m_acc * 100).toFixed(1)}%` : '-'}</span>
              </div>
              <div className="flex flex-col items-center justify-center p-2 rounded-lg bg-slate-50 dark:bg-slate-800/30 border border-slate-100 dark:border-slate-800 text-center">
                <span className="text-[10px] text-slate-500 dark:text-slate-400 uppercase tracking-wider font-semibold mb-1">Mean IoU (mIoU)</span>
                <span className="text-sm font-bold text-slate-900 dark:text-slate-100">{data.model.m_iou ? `${(data.model.m_iou * 100).toFixed(1)}%` : '-'}</span>
              </div>
              <div className="flex flex-col items-center justify-center p-2 rounded-lg bg-slate-50 dark:bg-slate-800/30 border border-slate-100 dark:border-slate-800 text-center">
                <span className="text-[10px] text-slate-500 dark:text-slate-400 uppercase tracking-wider font-semibold mb-1">Mean Dice (F1)</span>
                <span className="text-sm font-bold text-slate-900 dark:text-slate-100">{data.model.m_dice ? `${(data.model.m_dice * 100).toFixed(1)}%` : '-'}</span>
              </div>
            </div>

            <button
              onClick={() => navigate("/admin/models")}
              className="w-full mt-auto px-4 py-2 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-300 rounded-md text-sm font-medium hover:bg-slate-50 dark:hover:bg-slate-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 dark:focus:ring-offset-slate-900 transition-colors"
            >
              Manage Models
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
