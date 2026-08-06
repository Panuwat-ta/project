import { useState, useEffect } from "react";
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { PageLoader } from "@/components/PageLoader";
import { FileText, Clock } from "lucide-react";

export function AuditLogsList() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadLogs = async () => {
    try {
      const token = localStorage.getItem("token");
      const res = await fetch("/api/v1/admin/audit-logs", {
        headers: {
          "Authorization": `Bearer ${token}`
        }
      });
      if (res.ok) {
        const data = await res.json();
        setLogs(data.items || []);
      }
    } catch (error) {
      console.error("Failed to fetch audit logs", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadLogs();
  }, []);

  if (loading) return <PageLoader text="กำลังโหลดข้อมูลประวัติ..." />;

  const getActionColor = (action) => {
    if (action.includes("report_approved")) return "bg-emerald-500/10 text-emerald-500 border-emerald-500/20";
    if (action.includes("report_rejected")) return "bg-destructive/10 text-destructive border-destructive/20";
    if (action.includes("user_banned")) return "bg-destructive/10 text-destructive border-destructive/20";
    if (action.includes("user_unbanned")) return "bg-emerald-500/10 text-emerald-500 border-emerald-500/20";
    if (action.includes("model_deployed")) return "bg-blue-500/10 text-blue-500 border-blue-500/20";
    return "bg-secondary text-secondary-foreground";
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">Audit Logs</h2>
        <p className="text-muted-foreground mt-2">
          บันทึกประวัติการทำรายการที่สำคัญโดยผู้ดูแลระบบ
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5 text-primary" />
            System Audit Logs
          </CardTitle>
          <CardDescription>แสดงรายการประวัติการดำเนินการ 50 รายการล่าสุด</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border border-border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Log ID</TableHead>
                  <TableHead>Admin ID</TableHead>
                  <TableHead>การดำเนินการ (Action)</TableHead>
                  <TableHead>รายละเอียด</TableHead>
                  <TableHead className="text-right">เวลา</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {logs.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="h-24 text-center text-muted-foreground">
                      ไม่พบประวัติการทำรายการ
                    </TableCell>
                  </TableRow>
                ) : (
                  logs.map((log) => (
                    <TableRow key={log.id}>
                      <TableCell className="font-medium text-muted-foreground">#{log.id}</TableCell>
                      <TableCell>Admin #{log.admin_id}</TableCell>
                      <TableCell>
                        <Badge variant="outline" className={getActionColor(log.action)}>
                          {log.action}
                        </Badge>
                      </TableCell>
                      <TableCell className="max-w-[300px] truncate">
                        {log.details}
                      </TableCell>
                      <TableCell className="text-right text-muted-foreground flex items-center justify-end gap-1">
                        <Clock className="h-3 w-3" />
                        {new Date(log.created_at).toLocaleString('th-TH')}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
