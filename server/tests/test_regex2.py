import re

text = """
ระบบไม่พึ่งพาวิธีตรวจจับเดียว แต่รันการวิเคราะห์ 3 ชั้นพร้อมกันและรวมผลเป็น **Weighted Risk Score** เดียว ดูรายละเอียดที่ [[concepts/multi-layer-analysis]]

คะแนนรวมอยู่ระหว่าง 0–100 ดูเกณฑ์การตัดสินที่ [[concepts/risk-scoring]]

ดูสถาปัตยกรรมเต็มที่ [[architecture/system-architecture]]

ดูรายละเอียดที่ [[entities/tech-stack]] และ [[decisions/technology-choices]]

Heatmap เป็นหัวใจของการออกแบบ **Explainable AI (XAI)** ดูที่ [[concepts/explainable-ai]]

ถอนได้ ดูที่ [[requirements/non-functional-requirements]]

## หน้าที่เกี่ยวข้อง

- [[concepts/multi-layer-analysis]]
- [[concepts/risk-scoring]]
- [[concepts/explainable-ai]]
- [[architecture/system-architecture]]
- [[requirements/objectives-kpis]]
- [[planning/project-scope]]
- [[planning/team]]
- [[entities/tech-stack]]
"""

text = re.sub(r'\s*(ดูรายละเอียดที่|ดูเกณฑ์การตัดสินที่|ดูสถาปัตยกรรมเต็มที่|ดูที่)\s*\[\[.*?\]\](?:\s*และ\s*\[\[.*?\]\])*', '', text)
text = re.sub(r'## หน้าที่เกี่ยวข้อง\n+(?:-\s*\[\[.*?\]\]\n*)*', '', text)
text = re.sub(r'\[\[.*?\]\]', '', text)

print(text)
