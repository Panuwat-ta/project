import { useState, useEffect } from "react";
import { Search, Filter, Eye } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { PageLoader } from "@/components/PageLoader";
import { fetchReports } from "@/lib/api";

export function ReportsList() {
  const [activeTab, setActiveTab] = useState("All");
  const [isLoading, setIsLoading] = useState(true);
  const [reportsData, setReportsData] = useState([]);
  const [total, setTotal] = useState(0);

  useEffect(() => {
    async function loadReports() {
      setIsLoading(true);
      try {
        const data = await fetchReports(1, 20, activeTab);
        setReportsData(data.items);
        setTotal(data.total);
      } catch (err) {
        console.error("Failed to load reports", err);
      } finally {
        setIsLoading(false);
      }
    }
    loadReports();
  }, [activeTab]);

  return (
    <div className="flex flex-col gap-6">
      <div className="flex justify-between items-center">
        <h2 className="font-heading text-2xl font-bold tracking-tight">Scam Reports</h2>
      </div>

      <Card>
        <CardHeader className="pb-3 border-b border-border">
          <div className="flex flex-col md:flex-row justify-between gap-4">
            <div className="flex bg-muted p-1 rounded-md w-max">
              {['All', 'Pending', 'Reviewing', 'Approved', 'Rejected'].map(tab => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`px-4 py-1.5 text-sm font-medium rounded-sm transition-colors ${
                    activeTab === tab 
                      ? "bg-primary text-primary-foreground shadow-sm" 
                      : "text-muted-foreground hover:text-foreground"
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>
            
            <div className="flex items-center gap-2">
              <Button variant="outline" size="sm" className="h-9 gap-2 text-muted-foreground">
                <Filter className="size-4" />
                <span>Filter</span>
              </Button>
              <div className="relative">
                <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
                <Input
                  type="search"
                  placeholder="Search..."
                  className="h-9 w-[200px] pl-9 bg-muted/50 border-border"
                />
              </div>
            </div>
          </div>
        </CardHeader>
        {isLoading ? (
          <PageLoader text="Loading reports..." />
        ) : (
          <CardContent className="p-0">
          <Table>
            <TableHeader className="bg-elevated">
              <TableRow className="border-border">
                <TableHead className="w-[60px] text-center">#</TableHead>
                <TableHead className="w-[80px]">ภาพ</TableHead>
                <TableHead>หมวดหมู่</TableHead>
                <TableHead>ผู้รายงาน</TableHead>
                <TableHead>คะแนนเสี่ยง</TableHead>
                <TableHead>สถานะ</TableHead>
                <TableHead>วันที่</TableHead>
                <TableHead className="text-right">แอคชัน</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {reportsData.map((report) => (
                <TableRow 
                  key={report.id} 
                  className={`border-border hover:bg-surface-hover ${report.status === 'pending' ? 'border-l-4 border-l-sky-400' : ''}`}
                >
                  <TableCell className="font-mono text-muted-foreground text-center">{report.id}</TableCell>
                  <TableCell>
                    <img src={report.scan?.thumbnail_url || "https://via.placeholder.com/48"} alt="thumbnail" className="size-10 object-cover rounded-md border border-border" />
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline" className="font-normal text-xs bg-muted">{report.category}</Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex flex-col">
                      <span className="font-medium text-sm">{report.user?.full_name || "Unknown"}</span>
                      <span className="text-xs text-muted-foreground">{report.user?.email || "No Email"}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge className={
                      (report.scan?.total_risk_score || 0) >= 80 ? "bg-destructive/15 text-destructive hover:bg-destructive/15 border-none" :
                      (report.scan?.total_risk_score || 0) >= 50 ? "bg-amber-500/15 text-amber-500 hover:bg-amber-500/15 border-none" :
                      "bg-emerald-500/15 text-emerald-500 hover:bg-emerald-500/15 border-none"
                    }>
                      {report.scan?.total_risk_score || 0}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <Badge className={
                      report.status === 'pending' ? "bg-sky-400/15 text-sky-400 border-none capitalize" :
                      report.status === 'reviewing' ? "bg-amber-500/15 text-amber-500 border-none capitalize" :
                      report.status === 'approved' ? "bg-emerald-500/15 text-emerald-500 border-none capitalize" :
                      "bg-destructive/15 text-destructive border-none capitalize"
                    }>
                      {report.status}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-xs text-muted-foreground">{new Date(report.created_at).toLocaleDateString('th-TH')}</TableCell>
                  <TableCell className="text-right">
                    <Button variant="ghost" size="sm" className="text-primary hover:text-primary hover:bg-primary/10">
                      <Eye className="size-4 mr-1.5" />
                      ดู
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          
          <div className="p-4 border-t border-border flex justify-between items-center text-sm text-muted-foreground">
            <span>Showing 1-{reportsData.length} of {total}</span>
            <div className="flex gap-2">
              <Button variant="outline" size="sm" disabled>Previous</Button>
              <Button variant="outline" size="sm">Next</Button>
            </div>
          </div>
        </CardContent>
        )}
      </Card>
    </div>
  );
}
