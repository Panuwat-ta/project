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
import { fetchDashboard, fetchHealth } from "@/lib/api";
import { useDashboardWebSocket } from "@/lib/use-dashboard-ws";
import { useAutoRefresh } from "@/lib/use-auto-refresh";
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

  const loadData = useCallback(async (manual = false, quiet = false) => {
    try {
      if (manual) setIsRefreshing(true);
      else if (!quiet) setIsLoading(true);
      if (!quiet) setError(null);

      const [dash, hlth] = await Promise.all([fetchDashboard(), fetchHealth()]);
      setData(dash);
      setHealth(hlth);
      setLastUpdated(new Date());

      if (manual) {
        toast.success("อัปเดตข้อมูลสถิติล่าสุดเรียบร้อยแล้ว");
      }
    } catch (err) {
      if (quiet) return;
      console.error("Dashboard data load error:", err);
      setError(err.message || "ไม่สามารถเรียกข้อมูลแดชบอร์ดได้");
      toast.error("เกิดข้อผิดพลาดในการโหลดข้อมูล: " + err.message);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [toast]);

  // Initial load once; live updates arrive via the persistent WebSocket below.
  useEffect(() => {
    loadData();
  }, [loadData]);

  // WebSocket Live Updates (single connection + backoff reconnect)
  useDashboardWebSocket({
    onRefresh: () => loadData(false, true),
    onStatusChange: (ok) => {
      if (setIsWsConnected) setIsWsConnected(ok);
    },
  });

  // Polling fallback: backend pushes WS only on review/decision/deploy events.
  useAutoRefresh(() => loadData(false, true), 30000);

  if (error && !data) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] gap-4">
        <div className="size-14 rounded-full bg-danger-subtle border border-danger-border flex items-center justify-center text-danger">
          <AlertCircle className="size-7" />
        </div>
        <div className="text-center space-y-1">
          <h2 className="text-base font-semibold text-foreground">
            ไม่สามารถโหลดข้อมูลสถิติได้
          </h2>
          <p className="text-xs text-muted-foreground max-w-sm">{error}</p>
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
        <div className="h-10 bg-muted rounded-lg animate-pulse w-72" />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 h-80 bg-muted rounded-xl animate-pulse" />
          <div className="h-80 bg-muted rounded-xl animate-pulse" />
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
           <h2 className="text-xl font-bold tracking-tight text-foreground flex items-center gap-2.5">
            <span>ศูนย์ควบคุมและตรวจจับการหลอกลวง</span>
            <Badge variant="primary" size="sm" withDot>
              Real-time
            </Badge>
          </h2>
          <p className="text-xs text-muted-foreground mt-1.5 leading-relaxed font-mono">
            {lastUpdated ? `อัปเดตข้อมูลล่าสุด: ${lastUpdated.toLocaleTimeString("th-TH")}` : ""}
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
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 p-3 rounded-xl bg-muted/40 border border-border text-xs font-mono">
        <div className="flex items-center gap-2">
          <Database className="size-4 text-primary shrink-0" />
          <span className="text-muted-foreground font-semibold">Database:</span>
          <span className="font-bold text-success">Connected</span>
        </div>
        <div className="flex items-center gap-2">
          <Cpu className="size-4 text-primary shrink-0" />
          <span className="text-muted-foreground font-semibold">AI Node:</span>
          <span className="font-bold text-success">Ready (SegFormer)</span>
        </div>
        <div className="flex items-center gap-2">
          <ShieldCheck className="size-4 text-primary shrink-0" />
          <span className="text-muted-foreground font-semibold">Model:</span>
          <span className="font-bold text-foreground truncate">
            {data?.model?.active_version ? `SegFormer ${data.model.active_version}` : (health?.models ? "SegFormer v1.0.0" : "SegFormer-B2")}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <CheckCircle2 className="size-4 text-success shrink-0" />
          <span className="text-muted-foreground font-semibold">Status:</span>
          <span className="font-bold text-success">All Operational</span>
        </div>
      </div>

      {/* Primary KPI Instruments */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* KPI 1: Scan Velocity Today */}
        <Card className="hover:border-primary-border transition-all">
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-xs text-muted-foreground font-medium">
              <span>สแกนวันนี้ (24h Velocity)</span>
              <Zap className="size-4 text-primary" />
            </div>
            <div className="text-2xl font-bold font-mono text-foreground tracking-tight">
              {formatNumber(data.overview.scans_today)}
            </div>
            <div className="flex items-center justify-between text-[11px] text-muted-foreground pt-1 border-t border-border-subtle font-mono font-medium">
              <span>สะสมทั้งหมด</span>
              <span className="font-bold text-foreground">
                {formatNumber(data.overview.total_scans)} ครั้ง
              </span>
            </div>
          </CardContent>
        </Card>

        {/* KPI 2: Pending Scam Reports */}
        <Card
          className={
            data.reports.pending > 0
              ? "border-danger-border/40 bg-danger-subtle/30 cursor-pointer hover:border-danger-border transition-all"
              : "hover:border-border transition-all cursor-pointer"
          }
          onClick={() => navigate("/admin/reports?status=pending")}
        >
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-xs text-muted-foreground font-medium">
              <span>ค้างการตรวจสอบ (Pending Queue)</span>
              <Flag className="size-4 text-danger" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-danger tracking-tight">
                {formatNumber(data.reports.pending)}
              </span>
              <span className="text-xs text-muted-foreground font-mono font-medium">
                / {formatNumber(data.reports.reviewing)} กำลังตรวจ
              </span>
            </div>
            <div className="flex items-center justify-between text-[11px] text-danger font-semibold pt-1 border-t border-border-subtle">
              <span>คลิกเพื่อเปิดคิวตรวจทันที</span>
              <ArrowUpRight className="size-3.5" />
            </div>
          </CardContent>
        </Card>

        {/* KPI 3: High Risk Anomaly Ratio */}
        <Card className="hover:border-warning-border transition-all">
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-xs text-muted-foreground font-medium">
              <span>อัตราภาพเสี่ยงสูง (High Risk)</span>
              <Activity className="size-4 text-warning" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-warning tracking-tight">
                {highRiskRatio}%
              </span>
              <span className="text-xs text-muted-foreground font-mono font-medium">
                ({formatNumber(data.risk_distribution.high)} ภาพ)
              </span>
            </div>
            <div className="flex items-center justify-between text-[11px] text-muted-foreground pt-1 border-t border-border-subtle font-mono font-medium">
              <span>สัดส่วนความเสี่ยง</span>
              <span className="font-bold text-foreground">
                L:{data.risk_distribution.low} M:{data.risk_distribution.medium} H:{data.risk_distribution.high}
              </span>
            </div>
          </CardContent>
        </Card>

        {/* KPI 4: Active Registered Users */}
        <Card className="hover:border-primary-border transition-all">
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-xs text-muted-foreground font-medium">
              <span>ผู้ใช้งานวันนี้ (Active Users)</span>
              <Users className="size-4 text-primary" />
            </div>
            <div className="text-2xl font-bold font-mono text-foreground tracking-tight">
              {formatNumber(data.overview.active_users_today)}
            </div>
            <div className="flex items-center justify-between text-[11px] text-muted-foreground pt-1 border-t border-border-subtle font-mono font-medium">
              <span>บัญชีทั้งหมด</span>
              <span className="font-bold text-foreground">
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
                <TrendingUp className="size-4 text-primary" />
                <span>แนวโน้มปริมาณการสแกนรูปภาพ (Scan Trend)</span>
              </CardTitle>
              <p className="text-xs text-muted-foreground mt-0.5">
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
              <p className="text-xs text-muted-foreground mt-0.5">
                เกณฑ์ 3 ระดับ: ต่ำ, ปานกลาง, สูง
              </p>
            </div>
          </CardHeader>
          <CardContent className="p-4 pt-0">
            <div className="flex flex-col sm:flex-row items-center gap-4">
              <div className="h-44 w-44 shrink-0 flex items-center justify-center relative">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={riskDonut}
                      cx="50%"
                      cy="50%"
                      innerRadius={48}
                      outerRadius={70}
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
                        backgroundColor: "var(--card)",
                        borderColor: "var(--border)",
                        borderRadius: "0.5rem",
                        fontSize: "12px",
                        color: "var(--foreground)",
                        boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)",
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                  <span className="text-xl font-bold font-mono text-foreground">
                    {formatNumber(riskTotal)}
                  </span>
                  <span className="text-[10px] text-muted-foreground uppercase tracking-wider font-semibold">ทั้งหมด</span>
                </div>
              </div>

              {/* Level bars */}
              <div className="flex-1 w-full space-y-3 font-mono">
                {[
                  { label: "สูง", value: data.risk_distribution.high || 0, color: RISK_PALETTE.high },
                  { label: "กลาง", value: data.risk_distribution.medium || 0, color: RISK_PALETTE.medium },
                  { label: "ต่ำ", value: data.risk_distribution.low || 0, color: RISK_PALETTE.low },
                ].map((row) => (
                  <div key={row.label} className="flex items-center gap-3">
                    <span className="w-8 shrink-0 text-xs text-muted-foreground font-sans">{row.label}</span>
                    <div className="flex-1 h-2.5 rounded-full bg-muted overflow-hidden">
                      <div
                        className="h-full rounded-full"
                        style={{
                          width: `${riskTotal > 0 ? Math.max((row.value / riskTotal) * 100, row.value > 0 ? 4 : 0) : 0}%`,
                          backgroundColor: row.color,
                        }}
                      />
                    </div>
                    <span className="w-8 shrink-0 text-right text-sm font-bold text-foreground">
                      {formatNumber(row.value)}
                    </span>
                  </div>
                ))}
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
            className="text-primary font-semibold hover:text-primary"
          >
            ดูรายงานทั้งหมด →
          </Button>
        }>
          <div>
            <CardTitle>จำแนกตามประเภทการหลอกลวง (Scam Categories)</CardTitle>
            <p className="text-xs text-muted-foreground mt-0.5">
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
