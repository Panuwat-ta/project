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
import { useAdminQuery } from "@/lib/use-admin-query";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import { CardSkeleton } from "@/components/ui/Skeleton";
import { formatNumber } from "@/lib/utils";

const RISK_PALETTE = {
  low: "var(--chart-risk-low)",
  medium: "var(--chart-risk-medium)",
  high: "var(--chart-risk-high)",
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
  const navigate = useNavigate();
  const { setIsWsConnected } = useOutletContext() || {};
  const {
    data,
    isLoading,
    isRefreshing,
    error,
    lastUpdated,
    reload: loadData,
  } = useAdminQuery(
    async () => {
      const [dash, hlth] = await Promise.all([fetchDashboard(), fetchHealth()]);
      return { dashboard: dash, health: hlth };
    },
    {
      resetOnError: false,
      successMessage: "อัปเดตข้อมูลสถิติล่าสุดเรียบร้อยแล้ว",
      errorMessage: "เกิดข้อผิดพลาดในการโหลดข้อมูล",
      logPrefix: "Dashboard data load error:",
      onStatusChange: (ok) => {
        if (setIsWsConnected) setIsWsConnected(ok);
      },
    }
  );
  const dash = data?.dashboard;
  const health = data?.health;

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
  const riskTotal = (dash.risk_distribution.low || 0) + (dash.risk_distribution.medium || 0) + (dash.risk_distribution.high || 0);
  const riskDonut = [
    { name: "ต่ำ", value: dash.risk_distribution.low || 0, color: RISK_PALETTE.low },
    { name: "กลาง", value: dash.risk_distribution.medium || 0, color: RISK_PALETTE.medium },
    { name: "สูง", value: dash.risk_distribution.high || 0, color: RISK_PALETTE.high },
  ];

  // Category breakdown formatted
  const categoryData = Object.entries(dash.category_breakdown || {}).map(([key, val]) => ({
    name: CATEGORY_LABELS[key] || key,
    count: val,
  }));

  const highRiskRatio = riskTotal > 0 ? Math.round(((dash.risk_distribution.high || 0) / riskTotal) * 100) : 0;

  return (
    <div className="space-y-6">
      {/* Top Header & Telemetry Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
           <h2 className="text-xl font-bold tracking-tight text-foreground">
            ภาพรวมระบบ
          </h2>
          <p className="text-xs text-muted-foreground mt-1.5 leading-relaxed">
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
            รีเฟรช
          </Button>
        </div>
      </div>

      {/* System status summary */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 p-3 rounded-xl bg-muted/40 border border-border text-[13px]">
        <div className="flex items-center gap-2">
          <Database className="size-4 text-primary shrink-0" />
          <span className="text-muted-foreground font-medium">ฐานข้อมูล</span>
          <span className="font-semibold text-success">ปกติ</span>
        </div>
        <div className="flex items-center gap-2">
          <Cpu className="size-4 text-primary shrink-0" />
          <span className="text-muted-foreground font-medium">โมเดล AI</span>
          <span className="font-semibold text-success">พร้อมใช้งาน</span>
        </div>
        <div className="flex items-center gap-2">
          <ShieldCheck className="size-4 text-primary shrink-0" />
          <span className="text-muted-foreground font-medium">โมเดลที่ใช้งาน</span>
          <span className="font-semibold font-mono text-foreground truncate">
            {dash?.model?.active_version ? `SegFormer ${dash.model.active_version}` : (health?.models ? "SegFormer v1.0.0" : "SegFormer-B2")}
          </span>
        </div>
      </div>

      {/* Primary KPI Instruments */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* KPI 1: Scan Velocity Today */}
        <Card className="hover:border-primary-border transition-all">
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-[13px] text-muted-foreground font-medium">
              <span>สแกนวันนี้</span>
              <Zap className="size-4 text-primary" />
            </div>
            <div className="text-2xl font-bold font-mono text-foreground tracking-tight">
              {formatNumber(dash.overview.scans_today)}
            </div>
            <div className="flex items-center justify-between text-xs text-muted-foreground pt-1 border-t border-border-subtle font-medium">
              <span>สะสมทั้งหมด</span>
              <span className="font-bold text-foreground"><span className="font-mono">{formatNumber(dash.overview.total_scans)}</span> ครั้ง</span>
            </div>
          </CardContent>
        </Card>

        {/* KPI 2: Pending Scam Reports */}
        <Card
          className={
            dash.reports.pending > 0
              ? "border-danger-border/40 bg-danger-subtle/30 cursor-pointer hover:border-danger-border transition-all"
              : "hover:border-border transition-all cursor-pointer"
          }
          onClick={() => navigate("/admin/reports?status=pending")}
        >
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-[13px] text-muted-foreground font-medium">
              <span>รอตรวจ</span>
              <Flag className="size-4 text-danger" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-danger tracking-tight">
                {formatNumber(dash.reports.pending)}
              </span>
              <span className="text-xs text-muted-foreground font-medium">
                / <span className="font-mono">{formatNumber(dash.reports.reviewing)}</span> กำลังตรวจ
              </span>
            </div>
            <div className="flex items-center justify-between text-[13px] text-danger font-semibold pt-1 border-t border-border-subtle">
              <span>เปิดรายการรอตรวจ</span>
              <ArrowUpRight className="size-3.5" />
            </div>
          </CardContent>
        </Card>

        {/* KPI 3: High Risk Anomaly Ratio */}
        <Card className="hover:border-warning-border transition-all">
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-[13px] text-muted-foreground font-medium">
              <span>ภาพความเสี่ยงสูง</span>
              <Activity className="size-4 text-warning" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-warning tracking-tight">
                {highRiskRatio}%
              </span>
              <span className="text-xs text-muted-foreground font-medium">
                (<span className="font-mono">{formatNumber(dash.risk_distribution.high)}</span> ภาพ)
              </span>
            </div>
            <div className="flex items-center justify-between text-xs text-muted-foreground pt-1 border-t border-border-subtle font-medium">
              <span>สัดส่วนความเสี่ยง</span>
              <span className="font-bold text-foreground">
                L:{dash.risk_distribution.low} M:{dash.risk_distribution.medium} H:{dash.risk_distribution.high}
              </span>
            </div>
          </CardContent>
        </Card>

        {/* KPI 4: Active Registered Users */}
        <Card className="hover:border-primary-border transition-all">
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-[13px] text-muted-foreground font-medium">
              <span>ผู้ใช้งานวันนี้</span>
              <Users className="size-4 text-primary" />
            </div>
            <div className="text-2xl font-bold font-mono text-foreground tracking-tight">
              {formatNumber(dash.overview.active_users_today)}
            </div>
            <div className="flex items-center justify-between text-xs text-muted-foreground pt-1 border-t border-border-subtle font-medium">
              <span>บัญชีทั้งหมด</span>
              <span className="font-bold text-foreground"><span className="font-mono">{formatNumber(dash.overview.total_users)}</span> บัญชี</span>
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
                <span>แนวโน้มการสแกน</span>
              </CardTitle>
              <p className="text-xs text-muted-foreground mt-0.5">
                จำนวนการสแกนรายวัน
              </p>
            </div>
          </CardHeader>
          <CardContent className="p-4 pt-2">
            <div className="h-64 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart
                  data={dash.scan_trend || []}
                  margin={{ top: 10, right: 10, left: -20, bottom: 0 }}
                >
                  <defs>
                    <linearGradient id="scanGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="var(--chart-primary)" stopOpacity={0.4} />
                      <stop offset="95%" stopColor="var(--chart-primary)" stopOpacity={0.0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--chart-grid)" opacity={0.7} />
                  <XAxis
                    dataKey="date"
                    tick={{ fontSize: 12, fill: "var(--chart-axis)" }}
                    tickLine={false}
                    axisLine={{ stroke: "var(--chart-axis-line)" }}
                  />
                  <YAxis
                    tick={{ fontSize: 12, fill: "var(--chart-axis)" }}
                    tickLine={false}
                    axisLine={{ stroke: "var(--chart-axis-line)" }}
                  />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: "var(--chart-tooltip-bg)",
                      borderColor: "var(--chart-tooltip-border)",
                      borderRadius: "0.5rem",
                      fontSize: "13px",
                      color: "var(--foreground)",
                      boxShadow: "var(--chart-tooltip-shadow)",
                    }}
                  />
                  <Area
                    type="monotone"
                    dataKey="count"
                    name="จำนวนสแกน"
                    stroke="var(--chart-primary)"
                    strokeWidth={2}
                    fillOpacity={1}
                    fill="url(#scanGradient)"
                    isAnimationActive={false}
                    dot={{ r: 3, fill: "var(--chart-primary)" }}
                    activeDot={{ r: 5, fill: "var(--chart-primary)" }}
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
              <CardTitle>ระดับความเสี่ยง</CardTitle>
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
                        fontSize: "13px",
                        color: "var(--foreground)",
                        boxShadow: "var(--chart-tooltip-shadow)",
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                  <span className="text-xl font-bold font-mono text-foreground">
                    {formatNumber(riskTotal)}
                  </span>
                  <span className="text-xs text-muted-foreground font-medium">ทั้งหมด</span>
                </div>
              </div>

              {/* Level bars */}
              <div className="flex-1 w-full space-y-3">
                {[
                  { label: "สูง", value: dash.risk_distribution.high || 0, color: RISK_PALETTE.high },
                  { label: "กลาง", value: dash.risk_distribution.medium || 0, color: RISK_PALETTE.medium },
                  { label: "ต่ำ", value: dash.risk_distribution.low || 0, color: RISK_PALETTE.low },
                ].map((row) => (
                  <div key={row.label} className="flex items-center gap-3">
                    <span className="w-10 shrink-0 text-[13px] text-muted-foreground font-sans">{row.label}</span>
                    <div className="flex-1 h-2.5 rounded-full bg-muted overflow-hidden">
                      <div
                        className="h-full rounded-full"
                        style={{
                          width: `${riskTotal > 0 ? Math.max((row.value / riskTotal) * 100, row.value > 0 ? 4 : 0) : 0}%`,
                          backgroundColor: row.color,
                        }}
                      />
                    </div>
                    <span className="w-8 shrink-0 text-right text-sm font-mono font-bold text-foreground">
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
            <CardTitle>ประเภทการหลอกลวง</CardTitle>
            <p className="text-xs text-muted-foreground mt-0.5">
              จำนวนรายการในแต่ละประเภท
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
                <CartesianGrid strokeDasharray="3 3" stroke="var(--chart-grid)" opacity={0.7} />
                <XAxis
                  dataKey="name"
                  tick={{ fontSize: 12, fill: "var(--chart-axis)" }}
                  interval={0}
                  angle={-15}
                  textAnchor="end"
                />
                <YAxis tick={{ fontSize: 12, fill: "var(--chart-axis)" }} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "var(--chart-tooltip-bg)",
                    borderColor: "var(--chart-tooltip-border)",
                    borderRadius: "0.5rem",
                    fontSize: "13px",
                    color: "var(--foreground)",
                    boxShadow: "var(--chart-tooltip-shadow)",
                  }}
                />
                <Bar dataKey="count" name="จำนวนคดี" fill="var(--chart-secondary)" radius={[4, 4, 0, 0]} isAnimationActive={false} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
