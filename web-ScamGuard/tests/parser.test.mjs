import test from 'node:test';
import assert from 'node:assert/strict';
import MarkdownIt from 'markdown-it';
import { firstParagraph, inlineTokenText, normalizeDate, normalizeDocPath, slugify, splitWikiLink, wikiLinkPlugin } from '../scripts/build.mjs';

test('slugify รองรับหัวข้อภาษาไทยและตัดสัญลักษณ์', () => {
  assert.equal(slugify('คะแนนความเสี่ยง (Risk Score)'), 'คะแนนความเสี่ยง-risk-score');
});

test('slugify คืน fallback สำหรับหัวข้อที่ไม่มีตัวอักษร', () => {
  assert.equal(slugify('---'), 'section');
});

test('splitWikiLink แยก alias และรองรับ escaped pipe', () => {
  assert.deepEqual(splitWikiLink('concepts/risk-scoring|Risk Score'), ['concepts/risk-scoring', 'Risk Score']);
  assert.deepEqual(splitWikiLink('semantic-segmentation\\|notation'), ['semantic-segmentation|notation', null]);
});

test('normalizeDocPath ทำให้พาธ Markdown อยู่ในรูป canonical', () => {
  assert.equal(normalizeDocPath('./architecture/system-architecture.md'), 'architecture/system-architecture');
});

test('wikilink parser ไม่แก้ตัวอย่างภายใน code fence', () => {
  const md = new MarkdownIt();
  wikiLinkPlugin(md);
  const html = md.render('[[overview|ภาพรวม]]\n\n```md\n[[page-name|ตัวอย่าง]]\n```');
  assert.match(html, /href="wiki:overview"/);
  assert.match(html, /\[\[page-name\|ตัวอย่าง\]\]/);
  assert.doesNotMatch(html, /href="wiki:page-name"/);
});

test('heading slug คงที่เมื่อใช้ข้อมูลผสมไทยและอังกฤษ', () => {
  assert.equal(slugify('ONNX และการนำไปใช้จริง'), 'onnx-และการนำไปใช้จริง');
});

test('firstParagraph เลือกย่อหน้าเนื้อหาและไม่รวม heading', () => {
  assert.equal(firstParagraph('# ชื่อหน้า\n\nย่อหน้าแรกที่อธิบายเนื้อหา\n\n## หัวข้อถัดไป'), 'ย่อหน้าแรกที่อธิบายเนื้อหา');
  assert.equal(firstParagraph('# ชื่อหน้า\n\n## แผนภาพ\n\n1. ขั้นตอนแรก'), '');
});

test('inlineTokenText อ่านเฉพาะ label ของ Markdown link', () => {
  const md = new MarkdownIt();
  const tokens = md.parseInline('[Diagram Link](https://example.com)', {})[0];
  assert.equal(inlineTokenText(tokens), 'Diagram Link');
});

test('normalizeDate รองรับ Date จาก YAML โดยคงรูป YYYY-MM-DD', () => {
  assert.equal(normalizeDate(new Date('2026-08-04T00:00:00.000Z')), '2026-08-04');
  assert.equal(normalizeDate('2026-09-15'), '2026-09-15');
});
