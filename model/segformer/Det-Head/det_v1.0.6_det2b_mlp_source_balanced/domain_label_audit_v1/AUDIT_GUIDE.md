# Label Audit v2

เป้าหมาย: ตรวจว่า image-level label สอดคล้องกับความหมายที่ ScamGuard ต้องการจริงหรือไม่ โดยไม่แก้ label ต้นฉบับอัตโนมัติ

## หลักการ
- `label` คือ dataset label เดิมและถือเป็น immutable evidence
- `verified_label` กรอกเฉพาะเมื่อมีหลักฐานเพียงพอหลัง review
- ห้ามใช้ det_score หรือ TruFor score เป็น ground truth เพียงอย่างเดียว
- การ review ต้องแยก provenance, visual evidence และ dataset semantics ออกจากกัน
- 11 real-camera images และ pilot 11 ไม่ถูกนำเข้าคิว Train นี้

## review_decision
- `keep` = label เดิมเหมาะกับ image-level task
- `relabel` = มีหลักฐานว่าคลาสเดิมผิดสำหรับ image-level task
- `exclude` = semantics/provenance ไม่ชัดหรือไม่เหมาะกับโจทย์
- `uncertain` = ยังตัดสินไม่ได้ ต้องหาหลักฐานเพิ่ม
