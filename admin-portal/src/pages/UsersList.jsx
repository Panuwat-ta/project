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
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { PageLoader } from "@/components/PageLoader";
import { Users as UsersIcon, ShieldAlert, ShieldCheck } from "lucide-react";

export function UsersList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadUsers = async () => {
    try {
      const token = localStorage.getItem("token");
      const res = await fetch("/api/v1/admin/users", {
        headers: {
          "Authorization": `Bearer ${token}`
        }
      });
      if (res.ok) {
        const data = await res.json();
        setUsers(data.items || []);
      }
    } catch (error) {
      console.error("Failed to fetch users", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  const toggleUserStatus = async (userId, currentStatus) => {
    try {
      const token = localStorage.getItem("token");
      const res = await fetch(`/api/v1/admin/users/${userId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${token}`
        },
        body: JSON.stringify({ is_active: !currentStatus })
      });
      if (res.ok) {
        loadUsers();
      }
    } catch (error) {
      console.error("Failed to update user", error);
    }
  };

  if (loading) return <PageLoader text="กำลังโหลดข้อมูลผู้ใช้..." />;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">Manage Users</h2>
        <p className="text-muted-foreground mt-2">
          จัดการบัญชีผู้ใช้งานระบบ ScamGuard, ตั้งค่าสิทธิ์ และจัดการการแบนบัญชี
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <UsersIcon className="h-5 w-5 text-primary" />
            ผู้ใช้งานทั้งหมด
          </CardTitle>
          <CardDescription>แสดงรายชื่อผู้ใช้งานทั้งหมดในระบบ เรียงตามวันที่สมัคร</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border border-border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>ID</TableHead>
                  <TableHead>Email / ชื่อ</TableHead>
                  <TableHead>สิทธิ์ (Role)</TableHead>
                  <TableHead>สถานะ</TableHead>
                  <TableHead className="text-right">จัดการ</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="h-24 text-center text-muted-foreground">
                      ไม่พบข้อมูลผู้ใช้
                    </TableCell>
                  </TableRow>
                ) : (
                  users.map((user) => (
                    <TableRow key={user.id}>
                      <TableCell className="font-medium">#{user.id}</TableCell>
                      <TableCell>
                        <div className="flex flex-col">
                          <span className="font-medium text-foreground">{user.email}</span>
                          {user.full_name && (
                            <span className="text-xs text-muted-foreground">{user.full_name}</span>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant={user.role === 'admin' ? 'default' : 'secondary'}>
                          {user.role}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {user.is_active ? (
                          <Badge variant="outline" className="bg-emerald-500/10 text-emerald-500 border-emerald-500/20">
                            Active
                          </Badge>
                        ) : (
                          <Badge variant="outline" className="bg-destructive/10 text-destructive border-destructive/20">
                            Banned
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-right">
                        {user.is_active ? (
                          <Button 
                            variant="destructive" 
                            size="sm"
                            onClick={() => toggleUserStatus(user.id, user.is_active)}
                            disabled={user.role === 'admin'}
                          >
                            <ShieldAlert className="h-4 w-4 mr-1" /> แบนผู้ใช้
                          </Button>
                        ) : (
                          <Button 
                            variant="outline" 
                            size="sm"
                            className="text-emerald-500 hover:text-emerald-600 hover:bg-emerald-50"
                            onClick={() => toggleUserStatus(user.id, user.is_active)}
                          >
                            <ShieldCheck className="h-4 w-4 mr-1" /> ปลดแบน
                          </Button>
                        )}
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
