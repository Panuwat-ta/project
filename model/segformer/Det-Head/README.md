# Det-Head workspace

โฟลเดอร์นี้รวม source code, tools, reports และ candidate artifacts ที่เกี่ยวกับ SegFormer image-level Det Head.

## Source files
- `det_head.py` — Det1–Det4 heads และ SegFormer wrapper
- `det5_local.py` — Det5 patch/local heads
- `train_det.py` — training สำหรับ pooled feature heads
- `train_det5.py` — training สำหรับ patch/local heads
- `precompute_det_features.py` — GAP 1024-D cache
- `precompute_det_features_gapgmp.py` — GAP+GMP 2048-D cache
- `precompute_det5_local.py` — 4x4 local-token cache
- `eval_det_cache.py` / `hard_mine_det.py` — evaluation และ hard-example mining
- `build_det_cache_manifests.py` — สร้าง Train/Val manifests
- `build_train_manifest_from_audit.py` — สร้าง manifest หลัง Label Audit
- `export_onnx_dynamic.py` / `export_onnx.sh` — ONNX export

ให้รันคำสั่งจาก `/home/panuwat/project/model/segformer` เพื่อให้ relative paths ของ `configs/`, `work_dirs/` และ `venv/` ตรงกัน

## Version comparison (Det-Head รายเวอร์ชัน)

- `eval_det_diagnostics.py` — รันทุก head พร้อมกันบนภาพชุดเดียวกัน (camera9, chatshot2, pilot11, testcases) ได้ `diagnostics.json` + CSV รายเซ็ต เป็นวิธีเปรียบเทียบเวอร์ชันที่ทำซ้ำได้
- `plot_det_versions.py` — สร้างกราฟเปรียบเทียบทุกเวอร์ชันจาก `diagnostics.json` ที่มีอยู่แล้ว (ไม่รัน inference ใหม่) ได้กราฟ PNG, `report.html` แบบฝังภาพในไฟล์เดียว และ `charts_data.json`
- `test_plot_det_versions.py` — unit test ของ pipeline สรุปข้อมูลกราฟ
- `diagnostics_det_versions_2026-10-02/` — ผลรันเปรียบเทียบ 20 heads (det1–det7b) บน Test-Cases 176 ภาพ พร้อมกราฟใน `charts/`
