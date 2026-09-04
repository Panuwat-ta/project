import { useState, useEffect, useCallback } from "react";
import { useNavigate, useOutletContext } from "react-router-dom";
import {
  Activity,
  Zap,
  Flag,
  Users,
  RefreshCw,
  AlertCircle,
  Database,
  Cpu,
  ShieldCheck,
  CheckCircle2,
  ArrowUpRight,
  TrendingUp,
} from "lucide-react";
import {
  AreaChart,
  Area,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  CartesianGrid,
} from "recharts";
import { fetchDashboard, fetchHealth, getAccessToken, getWebSocketUrl } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";
import { CardSkeleton } from "@/components/ui/Skeleton";
import { useToast } from "@/components/ui/ToastContext";
import { useTheme } from "@/components/theme-provider";
import { formatNumber } from "@/lib/utils";

const RISK_PALETTE = {
  low: "#10b981",    // Emerald
  medium: "#f59e0b", // Amber
  high: "#f43f5e",   // Rose
};

const CATEGORY_LABELS = {
  romance_scam: "หลอกลวงความรัก",
  online_shopping: "ซื้อขายออนไลน์",
  fake_slip: "สลิปโอนเงินปลอม",
  investment: "ลงทุนผลตอบแทนสูง",
  identity_theft: "ปลอมแปลงตัวตน",
  ai_deepfake: "ภาพ AI / Deepfake",
  other: "อื่น ๆ",
};

export function Dashboard() {
  const [data, setData] = useState(null);
  const [health, setHealth] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);
  const navigate = useNavigate();
  const toast = useToast();
  const { setIsWsConnected } = useOutletContext() || {};
  const { theme } = useTheme();

  const isDark =
    theme === "dark" ||
    (theme === "system" &&
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-color-scheme: dark)").matches);

  const loadData = useCallback(async (manual = false) => {
    try {
      if (manual) setIsRefreshing(true);
      else setIsLoading(true);
      setError(null);

      const [dash, hlth] = await Promise.all([fetchDashboard(), fetchHealth()]);
      setData(dash);
      setHealth(hlth);
      setLastUpdated(new Date());

      if (manual) {
        toast.success("อัปเดตข้อมูลสถิติล่าสุดเรียบร้อยแล้ว");
      }
    } catch (err) {
      console.error("Dashboard data load error:", err);
      setError(err.message || "ไม่สามารถเรียกข้อมูลแดชบอร์ดได้");
      toast.error("เกิดข้อผิดพลาดในการโหลดข้อมูล: " + err.message);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [toast]);

  // WebSocket Live Updates
  useEffect(() => {
    loadData();

    const token = getAccessToken();
    const wsUrl = getWebSocketUrl("/admin/dashboard", token);

    let ws;
    try {
      ws = new WebSocket(wsUrl);

      ws.onopen = () => {
        if (setIsWsConnected) setIsWsConnected(true);
      };

      ws.onmessage = (event) => {
        try {
          const msg = JSON.parse(event.data);
          if (msg.type === "refresh_dashboard") {
            loadData(false);
          }
        } catch (e) {
          console.error("WS Parse error", e);
        }
      };

      ws.onerror = () => {
        if (setIsWsConnected) setIsWsConnected(false);
      };

      ws.onclose = () => {
        if (setIsWsConnected) setIsWsConnected(false);
      };
    } catch {
      if (setIsWsConnected) setIsWsConnected(false);
    }

    return () => {
      if (ws) ws.close();
    };
  }, [loadData, setIsWsConnected]);

  if (error && !data) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] gap-4">
        <div className="size-14 rounded-full bg-rose-500/10 border border-rose-500/30 flex items-center justify-center text-rose-500">
          <AlertCircle className="size-7" />
        </div>
        <div className="text-center space-y-1">
          <h2 className="text-base font-semibold text-slate-900 dark:text-slate-100">
            ไม่สามารถโหลดข้อมูลสถิติได้
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400 max-w-sm">{error}</p>
        </div>
        <Button
          variant="primary"
          size="sm"
          icon={RefreshCw}
          onClick={() => loadData(true)}
          isLoading={isRefreshing}
        >
          ลองใหม่อีกครั้ง
        </Button>
      </div>
    );
  }

  if (isLoading || !data) {
    return (
      <div className="space-y-6">
        <div className="h-10 bg-slate-200 dark:bg-slate-800 rounded-lg animate-pulse w-72" />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 h-80 bg-slate-200 dark:bg-slate-800 rounded-xl animate-pulse" />
          <div className="h-80 bg-slate-200 dark:bg-slate-800 rounded-xl animate-pulse" />
        </div>
      </div>
    );
  }

  // Risk Donut Data
  const riskTotal = (data.risk_distribution.low || 0) + (data.risk_distribution.medium || 0) + (data.risk_distribution.high || 0);
  const riskDonut = [
    { name: "Low Risk", value: data.risk_distribution.low || 0, color: RISK_PALETTE.low },
    { name: "Medium Risk", value: data.risk_distribution.medium || 0, color: RISK_PALETTE.medium },
    { name: "High Risk", value: data.risk_distribution.high || 0, color: RISK_PALETTE.high },
  ];

  // Category breakdown formatted
  const categoryData = Object.entries(data.category_breakdown || {}).map(([key, val]) => ({
    name: CATEGORY_LABELS[key] || key,
    count: val,
  }));

  const highRiskRatio = riskTotal > 0 ? Math.round(((data.risk_distribution.high || 0) / riskTotal) * 100) : 0;

  return (
    <div className="space-y-6">
      {/* Top Header & Telemetry Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-slate-900 dark:text-slate-100 flex items-center gap-2.5">
            <span>ศูนย์ควบคุมและตรวจจับการหลอกลวง</span>
            <Badge variant="primary" size="sm" withDot>
              Real-time
            </Badge>
          </h2>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-1 font-mono">
            {lastUpdated ? `อัปเดตล่าสุด: ${lastUpdated.toLocaleTimeString("th-TH")}` : ""}
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            icon={RefreshCw}
            isLoading={isRefreshing}
            onClick={() => loadData(true)}
          >
            รีเฟรชสถิติ
          </Button>
        </div>
      </div>

      {/* System Infrastructure Telemetry Bar */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 p-3 rounded-xl bg-slate-100 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800/80 text-xs font-mono">
        <div className="flex items-center gap-2">
          <Database className="size-4 text-cyan-600 dark:text-cyan-500 shrink-0" />
          <span className="text-slate-700 dark:text-slate-400 font-semibold">Database:</span>
          <span className="font-bold text-emerald-700 dark:text-emerald-400">Connected</span>
        </div>
        <div className="flex items-center gap-2">
          <Cpu className="size-4 text-cyan-600 dark:text-cyan-500 shrink-0" />
          <span className="text-slate-700 dark:text-slate-400 font-semibold">AI Node:</span>
          <span className="font-bold text-emerald-700 dark:text-emerald-400">Ready (SegFormer)</span>
        </div>
        <div className="flex items-center gap-2">
          <ShieldCheck className="size-4 text-cyan-600 dark:text-cyan-500 shrink-0" />
          <span className="text-slate-700 dark:text-slate-400 font-semibold">Model:</span>
          <span className="font-bold text-slate-900 dark:text-slate-200 truncate">
            {health?.active_model || data?.model_status?.active_version || "SegFormer-B2"}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <CheckCircle2 className="size-4 text-emerald-600 dark:text-emerald-500 shrink-0" />
          <span className="text-slate-700 dark:text-slate-400 font-semibold">Status:</span>
          <span className="font-bold text-emerald-700 dark:text-emerald-400">All Operational</span>
        </div>
      </div>

      {/* Primary KPI Instruments */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* KPI 1: Scan Velocity Today */}
        <Card className="hover:border-cyan-500/30 transition-all">
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-xs text-slate-600 dark:text-slate-400 font-medium">
              <span>สแกนวันนี้ (24h Velocity)</span>
              <Zap className="size-4 text-cyan-600 dark:text-cyan-400" />
            </div>
            <div className="text-2xl font-bold font-mono text-slate-900 dark:text-slate-100 tracking-tight">
              {formatNumber(data.overview.scans_today)}
            </div>
            <div className="flex items-center justify-between text-[11px] text-slate-600 dark:text-slate-400 pt-1 border-t border-slate-100 dark:border-slate-800/60 font-mono font-medium">
              <span>สะสมทั้งหมด</span>
              <span className="font-bold text-slate-900 dark:text-slate-200">
                {formatNumber(data.overview.total_scans)} ครั้ง
              </span>
            </div>
          </CardContent>
        </Card>

        {/* KPI 2: Pending Scam Reports */}
        <Card
          className={
            data.reports.pending > 0
              ? "border-rose-500/40 bg-rose-500/5 cursor-pointer hover:border-rose-500/60 transition-all"
              : "hover:border-slate-700 transition-all cursor-pointer"
          }
          onClick={() => navigate("/admin/reports?status=pending")}
        >
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-xs text-slate-600 dark:text-slate-400 font-medium">
              <span>ค้างการตรวจสอบ (Pending Queue)</span>
              <Flag className="size-4 text-rose-600 dark:text-rose-500" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-rose-600 dark:text-rose-500 tracking-tight">
                {formatNumber(data.reports.pending)}
              </span>
              <span className="text-xs text-slate-600 dark:text-slate-400 font-mono font-medium">
                / {formatNumber(data.reports.reviewing)} กำลังตรวจ
              </span>
            </div>
            <div className="flex items-center justify-between text-[11px] text-rose-700 dark:text-rose-400 font-semibold pt-1 border-t border-slate-100 dark:border-slate-800/60">
              <span>คลิกเพื่อเปิดคิวตรวจทันที</span>
              <ArrowUpRight className="size-3.5" />
            </div>
          </CardContent>
        </Card>

        {/* KPI 3: High Risk Anomaly Ratio */}
        <Card className="hover:border-amber-500/30 transition-all">
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-xs text-slate-600 dark:text-slate-400 font-medium">
              <span>อัตราภาพเสี่ยงสูง (High Risk)</span>
              <Activity className="size-4 text-amber-600 dark:text-amber-500" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-amber-700 dark:text-amber-500 tracking-tight">
                {highRiskRatio}%
              </span>
              <span className="text-xs text-slate-600 dark:text-slate-400 font-mono font-medium">
                ({formatNumber(data.risk_distribution.high)} ภาพ)
              </span>
            </div>
            <div className="flex items-center justify-between text-[11px] text-slate-600 dark:text-slate-400 pt-1 border-t border-slate-100 dark:border-slate-800/60 font-mono font-medium">
              <span>สัดส่วนความเสี่ยง</span>
              <span className="font-bold text-slate-900 dark:text-slate-200">
                L:{data.risk_distribution.low} M:{data.risk_distribution.medium} H:{data.risk_distribution.high}
              </span>
            </div>
          </CardContent>
        </Card>

        {/* KPI 4: Active Registered Users */}
        <Card className="hover:border-cyan-500/30 transition-all">
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-xs text-slate-600 dark:text-slate-400 font-medium">
              <span>ผู้ใช้งานวันนี้ (Active Users)</span>
              <Users className="size-4 text-cyan-600 dark:text-cyan-400" />
            </div>
            <div className="text-2xl font-bold font-mono text-slate-900 dark:text-slate-100 tracking-tight">
              {formatNumber(data.overview.active_users_today)}
            </div>
            <div className="flex items-center justify-between text-[11px] text-slate-600 dark:text-slate-400 pt-1 border-t border-slate-100 dark:border-slate-800/60 font-mono font-medium">
              <span>บัญชีทั้งหมด</span>
              <span className="font-bold text-slate-900 dark:text-slate-200">
                {formatNumber(data.overview.total_users)} บัญชี
              </span>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Visual Analytics Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Trend Chart (Span 2) */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <div>
              <CardTitle className="flex items-center gap-2">
                <TrendingUp className="size-4 text-cyan-600 dark:text-cyan-400" />
                <span>แนวโน้มปริมาณการสแกนรูปภาพ (Scan Trend)</span>
              </CardTitle>
              <p className="text-xs text-slate-600 dark:text-slate-400 mt-0.5">
                สถิติการส่งรูปภาพตรวจจับความผิดปกติรายวัน
              </p>
            </div>
          </CardHeader>
          <CardContent className="p-4 pt-2">
            <div className="h-64 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart
                  data={data.scan_trend || []}
                  margin={{ top: 10, right: 10, left: -20, bottom: 0 }}
                >
                  <defs>
                    <linearGradient id="scanGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor={isDark ? "#00e5ff" : "#0891b2"} stopOpacity={0.4} />
                      <stop offset="95%" stopColor={isDark ? "#00e5ff" : "#0891b2"} stopOpacity={0.0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke={isDark ? "#1e293b" : "#e2e8f0"} opacity={0.7} />
                  <XAxis
                    dataKey="date"
                    tick={{ fontSize: 11, fill: isDark ? "#94a3b8" : "#475569" }}
                    tickLine={false}
                    axisLine={{ stroke: isDark ? "#334155" : "#cbd5e1" }}
                  />
                  <YAxis
                    tick={{ fontSize: 11, fill: isDark ? "#94a3b8" : "#475569" }}
                    tickLine={false}
                    axisLine={{ stroke: isDark ? "#334155" : "#cbd5e1" }}
                  />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: isDark ? "#0f172a" : "#ffffff",
                      borderColor: isDark ? "#334155" : "#cbd5e1",
                      borderRadius: "0.5rem",
                      fontSize: "12px",
                      color: isDark ? "#f8fafc" : "#0f172a",
                      boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)",
                      fontFamily: "monospace",
                    }}
                  />
                  <Area
                    type="monotone"
                    dataKey="count"
                    name="จำนวนสแกน"
                    stroke={isDark ? "#00e5ff" : "#0891b2"}
                    strokeWidth={2}
                    fillOpacity={1}
                    fill="url(#scanGradient)"
                    isAnimationActive={false}
                    dot={{ r: 3, fill: isDark ? "#00e5ff" : "#0891b2" }}
                    activeDot={{ r: 5, fill: isDark ? "#00e5ff" : "#0891b2" }}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        {/* Severity Distribution Donut */}
        <Card>
          <CardHeader>
            <div>
              <CardTitle>การกระจายระดับความเสี่ยง (Risk Tiers)</CardTitle>
              <p className="text-xs text-slate-600 dark:text-slate-400 mt-0.5">
                เกณฑ์ 3 ระดับ: ต่ำ, ปานกลาง, สูง
              </p>
            </div>
          </CardHeader>
          <CardContent className="p-4 pt-0 flex flex-col items-center">
            <div className="h-52 w-full flex items-center justify-center relative">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={riskDonut}
                    cx="50%"
                    cy="50%"
                    innerRadius={55}
                    outerRadius={80}
                    paddingAngle={3}
                    dataKey="value"
                    isAnimationActive={false}
                  >
                    {riskDonut.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip
                    contentStyle={{
                      backgroundColor: isDark ? "#0f172a" : "#ffffff",
                      borderColor: isDark ? "#334155" : "#cbd5e1",
                      borderRadius: "0.5rem",
                      fontSize: "12px",
                      color: isDark ? "#f8fafc" : "#0f172a",
                      boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)",
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-xl font-bold font-mono text-slate-900 dark:text-slate-100">
                  {formatNumber(riskTotal)}
                </span>
                <span className="text-[10px] text-slate-600 dark:text-slate-400 uppercase tracking-wider font-semibold">ทั้งหมด</span>
              </div>
            </div>

            {/* Legend */}
            <div className="w-full grid grid-cols-3 gap-2 mt-2 pt-3 border-t border-slate-100 dark:border-slate-800 text-center font-mono">
              <div className="space-y-0.5">
                <div className="flex items-center justify-center gap-1 text-[11px] text-emerald-700 dark:text-emerald-400 font-semibold">
                  <span className="size-2 rounded-full bg-emerald-500" />
                  <span>Low</span>
                </div>
                <div className="text-xs font-bold text-slate-900 dark:text-slate-100">
                  {formatNumber(data.risk_distribution.low)}
                </div>
              </div>

              <div className="space-y-0.5">
                <div className="flex items-center justify-center gap-1 text-[11px] text-amber-800 dark:text-amber-400 font-semibold">
                  <span className="size-2 rounded-full bg-amber-500" />
                  <span>Med</span>
                </div>
                <div className="text-xs font-bold text-slate-900 dark:text-slate-100">
                  {formatNumber(data.risk_distribution.medium)}
                </div>
              </div>

              <div className="space-y-0.5">
                <div className="flex items-center justify-center gap-1 text-[11px] text-rose-700 dark:text-rose-400 font-semibold">
                  <span className="size-2 rounded-full bg-rose-500" />
                  <span>High</span>
                </div>
                <div className="text-xs font-bold text-slate-900 dark:text-slate-100">
                  {formatNumber(data.risk_distribution.high)}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Scam Category Breakdown */}
      <Card>
        <CardHeader action={
          <Button
            variant="ghost"
            size="xs"
            onClick={() => navigate("/admin/reports")}
            className="text-cyan-700 dark:text-cyan-400 font-semibold hover:text-cyan-800"
          >
            ดูรายงานทั้งหมด →
          </Button>
        }>
          <div>
            <CardTitle>จำแนกตามประเภทการหลอกลวง (Scam Categories)</CardTitle>
            <p className="text-xs text-slate-600 dark:text-slate-400 mt-0.5">
              การกระจายตัวของภาพหลอกลวงที่ตรวจพบในระบบ
            </p>
          </div>
        </CardHeader>
        <CardContent className="p-4">
          <div className="h-56 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart
                data={categoryData}
                margin={{ top: 10, right: 10, left: -20, bottom: 20 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke={isDark ? "#1e293b" : "#e2e8f0"} opacity={0.7} />
                <XAxis
                  dataKey="name"
                  tick={{ fontSize: 11, fill: isDark ? "#94a3b8" : "#475569" }}
                  interval={0}
                  angle={-15}
                  textAnchor="end"
                />
                <YAxis tick={{ fontSize: 11, fill: isDark ? "#94a3b8" : "#475569" }} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: isDark ? "#0f172a" : "#ffffff",
                    borderColor: isDark ? "#334155" : "#cbd5e1",
                    borderRadius: "0.5rem",
                    fontSize: "12px",
                    color: isDark ? "#f8fafc" : "#0f172a",
                    boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)",
                  }}
                />
                <Bar dataKey="count" name="จำนวนคดี" fill={isDark ? "#0ea5e9" : "#0284c7"} radius={[4, 4, 0, 0]} isAnimationActive={false} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
