import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { Search, Loader2, ArrowRight, Flag, Users, Cpu, Database, FileText, LayoutDashboard, Settings } from "lucide-react";
import { searchGlobal } from "@/lib/api";
import { cn } from "@/lib/utils";

const NAV_SHORTCUTS = [
  { title: "Dashboard", subtitle: "ภาพรวมระบบและสถิติ", url: "/admin/dashboard", icon: LayoutDashboard },
  { title: "Scam Reports", subtitle: "คิวตรวจสอบรายงานภาพหลอกลวง", url: "/admin/reports", icon: Flag },
  { title: "User Management", subtitle: "จัดการบัญชีผู้ใช้งาน", url: "/admin/users", icon: Users },
  { title: "AI Models", subtitle: "โมเดล SegFormer & Surya OCR", url: "/admin/models", icon: Cpu },
  { title: "Dataset Export", subtitle: "ส่งออกชุดข้อมูลสำหรับงานวิจัย", url: "/admin/dataset", icon: Database },
  { title: "Audit Log", subtitle: "ประวัติการตรวจสอบย้อนหลัง", url: "/admin/audit-log", icon: FileText },
  { title: "Profile Settings", subtitle: "ตั้งค่าบัญชีและเซสชัน", url: "/admin/profile", icon: Settings },
];

export function CommandPalette({ isOpen, onClose }) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState([]);
  const [isSearching, setIsSearching] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = useRef(null);
  const navigate = useNavigate();

  useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 50);
      setQuery("");
      setResults([]);
      setSelectedIndex(0);
    }
  }, [isOpen]);

  useEffect(() => {
    if (!query.trim() || query.length < 2) {
      setResults([]);
      setIsSearching(false);
      return;
    }

    const timer = setTimeout(async () => {
      setIsSearching(true);
      try {
        const res = await searchGlobal(query.trim());
        setResults(res.items || []);
        setSelectedIndex(0);
      } catch (err) {
        console.error("Command palette search failed", err);
        setResults([]);
      } finally {
        setIsSearching(false);
      }
    }, 250);

    return () => clearTimeout(timer);
  }, [query]);

  // Combined items: either search results or default shortcuts
  const items = query.length >= 2 ? results : NAV_SHORTCUTS;

  const handleSelect = (item) => {
    if (!item?.url) return;
    onClose();
    navigate(item.url);
  };

  const handleKeyDown = (e) => {
    if (e.key === "Escape") {
      onClose();
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      setSelectedIndex((prev) => (prev + 1) % Math.max(1, items.length));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setSelectedIndex((prev) => (prev - 1 + items.length) % Math.max(1, items.length));
    } else if (e.key === "Enter" && items[selectedIndex]) {
      e.preventDefault();
      handleSelect(items[selectedIndex]);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-20 px-4">
      <div
        className="fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity animate-in fade-in duration-150"
        onClick={onClose}
      />

      <div
        className="relative z-10 w-full max-w-xl rounded-xl bg-card border border-border shadow-2xl overflow-hidden transition-all animate-in zoom-in-95 duration-150"
        onKeyDown={handleKeyDown}
      >
        {/* Search Bar */}
        <div className="flex items-center px-4 border-b border-border">
          <Search className="size-5 text-muted-foreground shrink-0" />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="ค้นหารายงาน, ผู้ใช้, รหัสสแกน, หรือหน้าเมนู..."
            className="w-full bg-transparent px-3 py-3.5 text-sm text-foreground placeholder:text-muted-foreground outline-none"
          />
          {isSearching && <Loader2 className="size-4 animate-spin text-primary shrink-0" />}
          <kbd className="hidden sm:inline-block px-2 py-0.5 text-[10px] font-mono font-semibold text-muted-foreground bg-muted border border-border rounded">
            ESC
          </kbd>
        </div>

        {/* Results List */}
        <div className="max-h-80 overflow-y-auto p-2">
          {items.length === 0 ? (
            <div className="p-8 text-center text-sm font-medium text-muted-foreground">
              ไม่พบผลลัพธ์ที่ตรงกับคำค้นหา
            </div>
          ) : (
            <div className="space-y-1">
              <div className="px-3 py-1 text-[11px] font-bold uppercase tracking-wider text-muted-foreground">
                {query.length >= 2 ? "ผลการค้นหา" : "เมนูลัด (Navigation)"}
              </div>
              {items.map((item, idx) => {
                const isSelected = idx === selectedIndex;
                const Icon = item.icon || ArrowRight;

                return (
                  <button
                    key={item.id || item.url || idx}
                    type="button"
                    onClick={() => handleSelect(item)}
                    onMouseEnter={() => setSelectedIndex(idx)}
                    className={cn(
                      "w-full flex items-center justify-between p-2.5 rounded-lg text-left text-sm transition-colors",
                      isSelected
                        ? "bg-primary-subtle text-primary font-semibold"
                        : "text-foreground hover:bg-muted"
                    )}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div
                        className={cn(
                          "size-8 rounded-md flex items-center justify-center shrink-0",
                          isSelected
                            ? "bg-primary/20 text-primary"
                            : "bg-muted text-muted-foreground"
                        )}
                      >
                        <Icon className="size-4" />
                      </div>
                      <div className="min-w-0">
                        <div className="truncate font-semibold text-foreground">{item.title}</div>
                        {item.subtitle && (
                          <div className="text-xs text-muted-foreground truncate font-normal">
                            {item.subtitle}
                          </div>
                        )}
                      </div>
                    </div>

                    <ArrowRight className="size-4 opacity-50 shrink-0 ml-2 text-muted-foreground" />
                  </button>
                );
              })}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between px-4 py-2 border-t border-border-subtle bg-muted/40 text-[11px] font-medium text-muted-foreground">
          <span>ใช้ลูกศรขึ้น/ลง เพื่อเลือก</span>
          <span>กด Enter เพื่อเปิด</span>
        </div>
      </div>
    </div>
  );
}
