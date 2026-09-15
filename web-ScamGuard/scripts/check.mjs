import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

async function walk(directory, extension) {
  const output = [];
  for (const entry of await fs.readdir(directory, { withFileTypes: true })) {
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) output.push(...await walk(absolute, extension));
    else if (!extension || absolute.endsWith(extension)) output.push(absolute);
  }
  return output;
}

async function exists(target) {
  try { await fs.access(target); return true; } catch (_) { return false; }
}

const report = JSON.parse(await fs.readFile(path.join(webRoot, 'build-report.json'), 'utf8'));
const wikiFiles = await walk(path.resolve(webRoot, '..', 'wiki'), '.md');
const htmlFiles = [path.join(webRoot, 'index.html'), ...await walk(path.join(webRoot, 'pages'), '.html')];
const errors = [];

if (report.sourceMarkdownCount !== wikiFiles.length) errors.push(`รายงานต้นฉบับ ${report.sourceMarkdownCount} หน้า แต่พบจริง ${wikiFiles.length} หน้า`);
if (report.renderedPageCount !== wikiFiles.length) errors.push(`สร้างเอกสาร ${report.renderedPageCount}/${wikiFiles.length} หน้า`);
if (report.mermaidRenderedCount !== report.mermaidSourceCount) errors.push(`สร้าง Mermaid ${report.mermaidRenderedCount}/${report.mermaidSourceCount} แผนภาพ`);
if (report.diagramFailures.length) errors.push(`Mermaid ล้มเหลว ${report.diagramFailures.length} รายการ`);
if (report.unresolvedLinks.length) errors.push(`ลิงก์หาเป้าหมายไม่ได้ ${report.unresolvedLinks.length} รายการ: ${report.unresolvedLinks.map((item) => `${item.source} -> ${item.target}`).join(', ')}`);

for (const htmlPath of htmlFiles) {
  const html = await fs.readFile(htmlPath, 'utf8');
  const relative = path.relative(webRoot, htmlPath);
  if (!/<title>[^<]+<\/title>/.test(html)) errors.push(`${relative}: ไม่มี title`);
  if (!/href="#main-content"/.test(html)) errors.push(`${relative}: ไม่มี skip link`);
  if (/\b(?:src|href)="https?:\/\//i.test(html.replace(/<a\b[^>]*href="https?:\/\/[^>]*>/gi, '<a>'))) errors.push(`${relative}: มี runtime asset จากภายนอก`);
  for (const match of html.matchAll(/(?:href|src)="([^"#][^"]*)"/g)) {
    const value = match[1].split('#')[0].split('?')[0];
    if (/^(https?:|mailto:|tel:|data:|javascript:)/i.test(value)) continue;
    const target = path.resolve(path.dirname(htmlPath), decodeURIComponent(value));
    if (!await exists(target)) errors.push(`${relative}: ไม่พบไฟล์ ${value}`);
  }
}

const siteJs = await fs.readFile(path.join(webRoot, 'assets', 'js', 'site.js'), 'utf8');
if (/\bfetch\s*\(/.test(siteJs)) errors.push('site.js ใช้ fetch ซึ่งไม่รับประกันการทำงานผ่าน file://');
if (!await exists(path.resolve(webRoot, '..', 'index.html'))) errors.push('ไม่มี index.html ที่ root ของโปรเจค');

if (errors.length) {
  console.error(`CHECK FAILED (${errors.length})`);
  errors.forEach((error) => console.error(`- ${error}`));
  process.exitCode = 1;
} else {
  console.log(`CHECK PASSED: ${report.renderedPageCount} pages, ${report.mermaidRenderedCount} diagrams, ${htmlFiles.length} HTML files, no broken local links.`);
}
