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
import { Cpu, Zap } from "lucide-react";

export function ModelsList() {
  const [models, setModels] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadModels = async () => {
    try {
      const token = localStorage.getItem("token");
      const res = await fetch("/api/v1/admin/models", {
        headers: {
          "Authorization": `Bearer ${token}`
        }
      });
      if (res.ok) {
        const data = await res.json();
        setModels(data.items || []);
      }
    } catch (error) {
      console.error("Failed to fetch models", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadModels();
  }, []);

  const deployModel = async (modelId) => {
    try {
      const token = localStorage.getItem("token");
      const res = await fetch(`/api/v1/admin/models/${modelId}/deploy`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${token}`
        }
      });
      if (res.ok) {
        loadModels();
      }
    } catch (error) {
      console.error("Failed to deploy model", error);
    }
  };

  if (loading) return <PageLoader text="กำลังโหลดข้อมูลโมเดล..." />;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">AI Models</h2>
        <p className="text-muted-foreground mt-2">
          จัดการเวอร์ชันของโมเดล AI ตรวจจับ Scam Image และสลับใช้งานเวอร์ชันที่ต้องการ
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Cpu className="h-5 w-5 text-primary" />
            Model Versions
          </CardTitle>
          <CardDescription>แสดงรายการโมเดล AI ทั้งหมดที่มีอยู่ในระบบ</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border border-border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Version Tag</TableHead>
                  <TableHead>File Path</TableHead>
                  <TableHead>Deploy Date</TableHead>
                  <TableHead>สถานะ</TableHead>
                  <TableHead className="text-right">จัดการ</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {models.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="h-24 text-center text-muted-foreground">
                      ไม่พบข้อมูลโมเดล
                    </TableCell>
                  </TableRow>
                ) : (
                  models.map((model) => (
                    <TableRow key={model.id}>
                      <TableCell className="font-medium">{model.version_tag}</TableCell>
                      <TableCell className="text-muted-foreground font-mono text-xs">
                        {model.file_path}
                      </TableCell>
                      <TableCell className="text-muted-foreground">
                        {model.deployed_at ? new Date(model.deployed_at).toLocaleString('th-TH') : '-'}
                      </TableCell>
                      <TableCell>
                        {model.is_active ? (
                          <Badge variant="default" className="bg-primary text-primary-foreground">
                            Active
                          </Badge>
                        ) : (
                          <Badge variant="outline" className="text-muted-foreground">
                            Inactive
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-right">
                        {!model.is_active && (
                          <Button 
                            variant="default" 
                            size="sm"
                            className="bg-emerald-600 hover:bg-emerald-700 text-white"
                            onClick={() => deployModel(model.id)}
                          >
                            <Zap className="h-4 w-4 mr-1" /> Deploy
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
