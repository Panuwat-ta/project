## 2026-09-02 04:40 +07

- Feature: การแสดงรูปและ heatmap ในหน้ารายละเอียดประวัติ
- Type: Manual Review + Lint
- Command: `/home/panuwat/develop/flutter/bin/cache/dart-sdk/bin/dart analyze`
- Result: Pass
- Notes: แก้ `history_detail_screen.dart:449` ที่ต่อ URL ผิดเป็น 2 ชั้น (`baseUrl + heatmapUrl` ที่ `parseUrl()` ทำเป็น full URL แล้ว) เป็น `(result.heatmapUrl ?? result.imageUrl)!`, เปลี่ยน `Image.network` เป็น `CachedNetworkImage` พร้อม `placeholder`/`errorWidget` เพื่อรองรับ offline, `dart analyze` ไม่พบ error
