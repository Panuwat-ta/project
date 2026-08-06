import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Users, Zap, Flag, Activity } from "lucide-react";
import { Area, AreaChart, ResponsiveContainer, Tooltip, XAxis, YAxis, Pie, PieChart, Cell, Bar, BarChart, CartesianGrid } from "recharts";
import { PageLoader } from "@/components/PageLoader";
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";

const chartConfig = {
  count: { label: "Scans", color: "var(--chart-1)" },
  value: { label: "จำนวน", color: "var(--chart-1)" },
};

const scanTrendData = [
  { name: '1 Aug', count: 120 },
  { name: '2 Aug', count: 135 },
  { name: '3 Aug', count: 110 },
  { name: '4 Aug', count: 180 },
  { name: '5 Aug', count: 140 },
  { name: '6 Aug', count: 156 },
];

const riskData = [
  { name: 'Low', value: 400, color: 'var(--risk-low)' },
  { name: 'Medium', value: 300, color: 'var(--risk-medium)' },
  { name: 'High', value: 156, color: 'var(--risk-high)' },
];

const categoryData = [
  { name: 'สลิปปลอม', value: 45 },
  { name: 'ซื้อขายออนไลน์', value: 32 },
  { name: 'หลอกลวงความรัก', value: 20 },
  { name: 'ลงทุน', value: 15 },
  { name: 'ปลอมแปลงตัวตน', value: 12 },
  { name: 'AI/Deepfake', value: 8 },
  { name: 'อื่นๆ', value: 24 },
];

export function Dashboard() {
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Simulate fetching data
    const timer = setTimeout(() => setIsLoading(false), 800);
    return () => clearTimeout(timer);
  }, []);

  if (isLoading) {
    return <PageLoader text="Loading dashboard data..." />;
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex justify-between items-center">
        <h2 className="font-heading text-2xl font-bold tracking-tight">Dashboard</h2>
        <p className="text-sm text-muted-foreground">{new Date().toLocaleDateString('th-TH', { dateStyle: 'full' })}</p>
      </div>

      {/* KPI Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">ผู้ใช้ทั้งหมด</CardTitle>
            <div className="size-8 rounded-full bg-primary/10 flex items-center justify-center">
              <Users className="size-4 text-primary" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-heading">1,250</div>
            <p className="text-xm text-muted-foreground mt-1">+12% จากสัปดาห์ที่แล้ว</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">สแกนทั้งหมด</CardTitle>
            <div className="size-8 rounded-full bg-primary/10 flex items-center justify-center">
              <Activity className="size-4 text-primary" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-heading">8,432</div>
            <p className="text-xm text-muted-foreground mt-1">+5.4% จากสัปดาห์ที่แล้ว</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">สแกนวันนี้</CardTitle>
            <div className="size-8 rounded-full bg-primary/10 flex items-center justify-center">
              <Zap className="size-4 text-primary" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-heading">156</div>
            <p className="text-xm text-[var(--risk-low)] font-medium mt-1">+2% จากเมื่อวาน</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">รายงาน Pending</CardTitle>
            <div className="size-8 rounded-full bg-primary/10 flex items-center justify-center">
              <Flag className="size-4 text-primary" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-heading">28</div>
            <p className="text-xm text-[var(--risk-high)] font-medium mt-1">ต้องการตรวจสอบด่วน 5 รายการ</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        {/* Trend Chart */}
        <Card className="lg:col-span-4">
          <CardHeader>
            <CardTitle>แนวโน้มการสแกน (7 วันย้อนหลัง)</CardTitle>
          </CardHeader>
          <CardContent className="h-[300px]">
            <ChartContainer config={chartConfig} className="h-full w-full">
              <AreaChart data={scanTrendData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorCount" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--chart-1)" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="var(--chart-1)" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="name" stroke="var(--muted-foreground)" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis stroke="var(--muted-foreground)" fontSize={12} tickLine={false} axisLine={false} />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Area type="monotone" dataKey="count" stroke="var(--chart-1)" strokeWidth={2} fillOpacity={1} fill="url(#colorCount)" />
              </AreaChart>
            </ChartContainer>
          </CardContent>
        </Card>

        {/* Risk Distribution */}
        <Card className="lg:col-span-3">
          <CardHeader>
            <CardTitle>สัดส่วนความเสี่ยง (Risk Distribution)</CardTitle>
          </CardHeader>
          <CardContent className="h-[300px] flex flex-col items-center justify-center relative">
            <ChartContainer config={chartConfig} className="h-full w-full">
              <PieChart>
                <Pie
                  data={riskData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {riskData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <ChartTooltip content={<ChartTooltipContent />} />
              </PieChart>
            </ChartContainer>
            <div className="absolute flex flex-col items-center justify-center text-center pointer-events-none">
              <span className="text-3xl font-bold font-heading">856</span>
              <span className="text-xm text-muted-foreground">Total Scans</span>
            </div>
            <div className="flex gap-4 justify-center mt-2">
              {riskData.map(entry => (
                <div key={entry.name} className="flex items-center gap-1.5 text-xm text-muted-foreground">
                  <div className="size-3 rounded-full" style={{ backgroundColor: entry.color }} />
                  {entry.name}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        {/* Category Breakdown */}
        <Card className="lg:col-span-4">
          <CardHeader>
            <CardTitle>หมวดหมู่รายงานสแกม (Report Categories)</CardTitle>
          </CardHeader>
          <CardContent className="h-[300px]">
            <ChartContainer config={chartConfig} className="h-full w-full">
              <BarChart data={categoryData} layout="vertical" margin={{ top: 0, right: 30, left: 30, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="var(--border)" />
                <XAxis type="number" stroke="var(--muted-foreground)" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis dataKey="name" type="category" stroke="var(--muted-foreground)" fontSize={12} tickLine={false} axisLine={false} width={100} />
                <ChartTooltip
                  cursor={{ fill: 'var(--muted)' }}
                  content={<ChartTooltipContent />}
                />
                <Bar dataKey="value" fill="var(--chart-1)" radius={[0, 4, 4, 0]} barSize={20}>
                  {categoryData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={index % 2 === 0 ? "var(--chart-1)" : "var(--chart-2)"} />
                  ))}
                </Bar>
              </BarChart>
            </ChartContainer>
          </CardContent>
        </Card>

        {/* AI Model Status */}
        <Card className="lg:col-span-3 bg-gradient-to-br from-surface to-primary/5 border-primary/20 shadow-[0_0_20px_rgba(0,229,255,0.05)]">
          <CardHeader>
            <CardTitle>AI Model Status</CardTitle>
            <CardDescription>SegFormer v2.1.0 is currently active</CardDescription>
          </CardHeader>
          <CardContent className="flex flex-col gap-4">
            <div className="flex justify-between items-center p-3 bg-muted rounded-md border border-border">
              <div className="flex flex-col">
                <span className="text-sm font-semibold text-primary">v2.1.0</span>
                <span className="text-xm text-muted-foreground">Deployed: 2026-08-01</span>
              </div>
              <Badge className="bg-[var(--risk-low)]/15 text-[var(--risk-low)] hover:bg-[var(--risk-low)]/15 border-none">ACTIVE</Badge>
            </div>

            <div className="flex justify-between items-center p-3 rounded-md">
              <div className="flex flex-col">
                <span className="text-sm font-medium">v2.0.0</span>
                <span className="text-xm text-muted-foreground">Deployed: 2026-07-15</span>
              </div>
              <Badge variant="outline" className="text-muted-foreground">INACTIVE</Badge>
            </div>

            <Button variant="outline" className="w-full mt-2 text-primary border-primary/50 hover:bg-primary/10 hover:text-primary">
              Manage Models
            </Button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
