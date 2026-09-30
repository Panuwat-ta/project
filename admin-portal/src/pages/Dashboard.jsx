import { Link, useNavigate } from "react-router-dom";
import {
  Activity,
  Zap,
  Flag,
  Users,
  RefreshCw,
  AlertCircle,
  Database,
  HardDrive,
  ListChecks,
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
import { OperationalStatusBadge } from "@/components/ui/Badge";
import { formatNumber } from "@/lib/utils";
import { formatOptionalDate, formatOptionalMetric, toFiniteNumber } from "@/lib/display-state";

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
  const {
    data,
    isLoading,
    isRefreshing,
    error,
    lastUpdated,
    reload: loadData,
  } = useAdminQuery(
    async () => {
      const dash = await fetchDashboard();
      let hlth = null;
      try {
        hlth = await fetchHealth();
      } catch {
        // Dashboard metrics remain useful even when health telemetry is unavailable.
      }
      return { dashboard: dash, health: hlth };
    },
    {
      resetOnError: false,
      successMessage: "อัปเดตข้อมูลสถิติล่าสุดเรียบร้อยแล้ว",
      errorMessage: "เกิดข้อผิดพลาดในการโหลดข้อมูล",
      logPrefix: "Dashboard data load error:",
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

  const overview = dash?.overview || {};
  const reports = dash?.reports || {};
  const riskDistribution = dash?.risk_distribution || {};
  const modelStatus = dash?.model || {};
  const riskValues = ["low", "medium", "high"].map((key) => toFiniteNumber(riskDistribution[key]));
  const hasRiskDistribution = riskValues.every((value) => value !== null);
  const riskTotal = hasRiskDistribution ? riskValues.reduce((sum, value) => sum + value, 0) : null;
  const riskDonut = hasRiskDistribution
    ? [
        { name: "ต่ำ", value: riskValues[0], color: RISK_PALETTE.low },
        { name: "กลาง", value: riskValues[1], color: RISK_PALETTE.medium },
        { name: "สูง", value: riskValues[2], color: RISK_PALETTE.high },
      ]
    : [];

  const categoryData = Object.entries(dash?.category_breakdown || {}).map(([key, val]) => ({
    name: CATEGORY_LABELS[key] || key,
    count: val,
  }));

  const highRiskRatio = hasRiskDistribution && riskTotal > 0
    ? Math.round((riskValues[2] / riskTotal) * 100)
    : hasRiskDistribution && riskTotal === 0
      ? 0
      : null;

  return (
    <div className="space-y-6">
      {/* Top Header & Telemetry Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
           <h2 className="text-xl font-bold tracking-tight text-foreground">
            ภาพรวมระบบ
          </h2>
          <p className="text-[13px] text-muted-foreground mt-1.5 leading-relaxed">
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

      {/* Operational health comes from /admin/health. Missing data stays unknown. */}
      <div className="rounded-xl bg-muted/40 border border-border p-3 space-y-3">
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-[repeat(4,minmax(150px,1fr))_minmax(240px,1.4fr)] gap-3 text-[13px]">
          {[
            { label: "ฐานข้อมูล", icon: Database, value: health?.database },
            { label: "พื้นที่จัดเก็บ", icon: HardDrive, value: health?.storage },
            { label: "โมเดล AI", icon: Cpu, value: health?.models },
            { label: "คิวงาน", icon: ListChecks, value: health?.queue },
          ].map(({ label, icon: Icon, value }) => (
            <div key={label} className="flex items-center gap-2 min-w-0">
              <Icon className="size-4 text-primary shrink-0" />
              <span className="text-muted-foreground font-medium">{label}</span>
              <OperationalStatusBadge status={value} />
            </div>
          ))}
          <div className="flex items-center gap-2 min-w-0">
            <ShieldCheck className="size-4 text-primary shrink-0" />
            <span className="text-muted-foreground font-medium whitespace-nowrap">โมเดลที่ใช้งาน</span>
            <span className="font-semibold font-mono text-foreground truncate">
              {modelStatus.active_version ? `SegFormer ${modelStatus.active_version}` : "ไม่ทราบ"}
            </span>
          </div>
        </div>
        <p className="text-xs text-muted-foreground">
          ตรวจสถานะระบบล่าสุด: {formatOptionalDate(health?.last_check)}
        </p>
      </div>

      {/* Primary KPI Instruments */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* KPI 1: Scan Velocity Today */}
        <Card className="hover:border-primary-border transition-colors">
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-[13px] text-muted-foreground font-medium">
              <span>สแกนวันนี้</span>
              <Zap className="size-4 text-primary" />
            </div>
            <div className="text-2xl font-bold font-mono text-foreground tracking-tight">
              {formatOptionalMetric(overview.scans_today, { fallback: "—" })}
            </div>
            <div className="flex items-center justify-between text-xs text-muted-foreground pt-1 border-t border-border-subtle font-medium">
              <span>สะสมทั้งหมด</span>
              <span className="font-bold text-foreground"><span className="font-mono">{formatOptionalMetric(overview.total_scans, { fallback: "—" })}</span> ครั้ง</span>
            </div>
          </CardContent>
        </Card>

        {/* KPI 2: Pending Scam Reports */}
        <Link
          to="/admin/reports?status=pending"
          className="block rounded-xl focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
          aria-label="เปิดรายการรายงานที่รอตรวจ"
        >
          <Card
            className={
              reports.pending > 0
                ? "h-full border-danger-border/40 bg-danger-subtle/30 hover:border-danger-border transition-colors"
                : "h-full hover:border-border transition-colors"
            }
          >
            <CardContent className="p-4 space-y-2">
              <div className="flex items-center justify-between text-[13px] text-muted-foreground font-medium">
                <span>รอตรวจ</span>
                <Flag className="size-4 text-danger" />
              </div>
              <div className="flex items-baseline gap-2">
                <span className="text-2xl font-bold font-mono text-danger tracking-tight">
                  {formatOptionalMetric(reports.pending, { fallback: "—" })}
                </span>
                <span className="text-xs text-muted-foreground font-medium">
                  / <span className="font-mono">{formatOptionalMetric(reports.reviewing, { fallback: "—" })}</span> กำลังตรวจ
                </span>
              </div>
              <div className="flex items-center justify-between text-[13px] text-danger font-semibold pt-1 border-t border-border-subtle">
                <span>เปิดรายการรอตรวจ</span>
                <ArrowUpRight className="size-3.5" />
              </div>
            </CardContent>
          </Card>
        </Link>

        {/* KPI 3: High Risk Anomaly Ratio */}
        <Card className="hover:border-danger-border transition-colors">
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-[13px] text-muted-foreground font-medium">
              <span>ภาพความเสี่ยงสูง</span>
              <Activity className="size-4 text-danger" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-danger tracking-tight">
                {formatOptionalMetric(highRiskRatio, { suffix: "%", fallback: "—" })}
              </span>
              <span className="text-xs text-muted-foreground font-medium">
                (<span className="font-mono">{formatOptionalMetric(riskDistribution.high, { fallback: "—" })}</span> ภาพ)
              </span>
            </div>
            <div className="flex items-center justify-between text-xs text-muted-foreground pt-1 border-t border-border-subtle font-medium">
              <span>สัดส่วนความเสี่ยง</span>
              <span className="font-bold text-foreground">
                L:{formatOptionalMetric(riskDistribution.low, { fallback: "—" })} M:{formatOptionalMetric(riskDistribution.medium, { fallback: "—" })} H:{formatOptionalMetric(riskDistribution.high, { fallback: "—" })}
              </span>
            </div>
          </CardContent>
        </Card>

        {/* KPI 4: Active Registered Users */}
        <Card className="hover:border-primary-border transition-colors">
          <CardContent className="p-4 space-y-2">
            <div className="flex items-center justify-between text-[13px] text-muted-foreground font-medium">
              <span>ผู้ใช้งานวันนี้</span>
              <Users className="size-4 text-primary" />
            </div>
            <div className="text-2xl font-bold font-mono text-foreground tracking-tight">
              {formatOptionalMetric(overview.active_users_today, { fallback: "—" })}
            </div>
            <div className="flex items-center justify-between text-xs text-muted-foreground pt-1 border-t border-border-subtle font-medium">
              <span>บัญชีทั้งหมด</span>
              <span className="font-bold text-foreground"><span className="font-mono">{formatOptionalMetric(overview.total_users, { fallback: "—" })}</span> บัญชี</span>
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
              <p className="text-[13px] text-muted-foreground mt-0.5">
                จำนวนการสแกนรายวัน
              </p>
            </div>
          </CardHeader>
          <CardContent className="p-4 pt-2">
            <div className="h-64 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart
                  data={dash?.scan_trend || []}
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
              <p className="text-[13px] text-muted-foreground mt-0.5">
                เกณฑ์ 3 ระดับ: ต่ำ, ปานกลาง, สูง
              </p>
            </div>
          </CardHeader>
          <CardContent className="p-4 pt-0">
            <div className="flex flex-col sm:flex-row items-center gap-4">
              {hasRiskDistribution ? (
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
              ) : (
                <div className="h-44 w-44 shrink-0 rounded-lg border border-border bg-muted/40 flex items-center justify-center text-center px-4">
                  <span className="text-xs text-muted-foreground">ไม่มีข้อมูลการกระจายความเสี่ยง</span>
                </div>
              )}

              {/* Level bars */}
              <div className="flex-1 w-full space-y-3">
                {[
                  { label: "สูง", value: hasRiskDistribution ? riskValues[2] : null, color: RISK_PALETTE.high },
                  { label: "กลาง", value: hasRiskDistribution ? riskValues[1] : null, color: RISK_PALETTE.medium },
                  { label: "ต่ำ", value: hasRiskDistribution ? riskValues[0] : null, color: RISK_PALETTE.low },
                ].map((row) => (
                  <div key={row.label} className="flex items-center gap-3">
                    <span className="w-10 shrink-0 text-[13px] text-muted-foreground font-sans">{row.label}</span>
                    <div className="flex-1 h-2.5 rounded-full bg-muted overflow-hidden">
                      <div
                        className="h-full rounded-full"
                        style={{
                          width: `${hasRiskDistribution && riskTotal > 0 ? Math.max((row.value / riskTotal) * 100, row.value > 0 ? 4 : 0) : 0}%`,
                          backgroundColor: row.color,
                        }}
                      />
                    </div>
                    <span className="w-8 shrink-0 text-right text-sm font-mono font-bold text-foreground">
                      {formatOptionalMetric(row.value, { fallback: "—" })}
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
            <p className="text-[13px] text-muted-foreground mt-0.5">
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
