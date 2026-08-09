import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Users, Zap, Flag, Activity } from "lucide-react";
import { Area, AreaChart, ResponsiveContainer, Tooltip, XAxis, YAxis, Pie, PieChart, Cell, Bar, BarChart, CartesianGrid } from "recharts";

import { fetchDashboard } from "@/lib/api";

const COLORS = {
  primary: "#4f46e5", // indigo-600
  secondary: "#c7d2fe", // indigo-200
  low: "#22c55e", // green-500
  medium: "#eab308", // yellow-500
  high: "#ef4444", // red-500
};

export function Dashboard() {
  const [isLoading, setIsLoading] = useState(true);
  const [data, setData] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    async function loadData() {
      try {
        const result = await fetchDashboard();
        setData(result);
      } catch (err) {
        console.error("Failed to load dashboard data", err);
      } finally {
        setIsLoading(false);
      }
    }
    loadData();
  }, []);

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
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Dashboard</h2>
        <p className="text-sm text-slate-500 dark:text-slate-400">{new Date().toLocaleDateString('th-TH', { dateStyle: 'full' })}</p>
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
                <XAxis dataKey="name" stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} dy={10} />
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

        {/* AI Model Status */}
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm lg:col-span-3 flex flex-col">
          <div className="px-6 py-5 border-b border-slate-100 dark:border-slate-800">
            <h3 className="text-base font-semibold text-slate-900 dark:text-slate-100">AI Model Status</h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">{data.model.active_version ? `Version ${data.model.active_version} is currently active` : 'No active model'}</p>
          </div>
          <div className="p-6 flex flex-col gap-4">
            <div className="flex justify-between items-center p-4 bg-slate-50 dark:bg-slate-800/50 rounded-lg border border-slate-200 dark:border-slate-800">
              <div className="flex flex-col">
                <span className="text-sm font-semibold text-slate-900 dark:text-slate-100">{data.model.active_version || 'N/A'}</span>
                <span className="text-xs text-slate-500 dark:text-slate-400 mt-1">Deployed: {data.model.deployed_at ? new Date(data.model.deployed_at).toLocaleDateString('th-TH') : 'N/A'}</span>
              </div>
              <span className="px-2.5 py-1 text-[10px] font-bold tracking-wide uppercase bg-emerald-100 dark:bg-emerald-500/20 text-emerald-700 dark:text-emerald-400 rounded-full">Active</span>
            </div>

            <div className="flex justify-between items-center p-4 rounded-lg border border-transparent">
              <div className="flex flex-col">
                <span className="text-sm font-medium text-slate-700 dark:text-slate-300">Total Versions</span>
                <span className="text-xs text-slate-500 dark:text-slate-400 mt-1">{data.model.total_versions} versions in system</span>
              </div>
              <span className="px-2.5 py-1 text-[10px] font-bold tracking-wide uppercase bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 rounded-full">Info</span>
            </div>

            <button
              onClick={() => navigate("/admin/models")}
              className="w-full mt-4 px-4 py-2 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-300 rounded-md text-sm font-medium hover:bg-slate-50 dark:hover:bg-slate-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 dark:focus:ring-offset-slate-900 transition-colors"
            >
              Manage Models
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
