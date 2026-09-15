import fs from 'node:fs/promises';
import path from 'node:path';
import { execFile } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { promisify } from 'node:util';
import matter from 'gray-matter';
import MarkdownIt from 'markdown-it';
import hljs from 'highlight.js';

const execFileAsync = promisify(execFile);
const scriptDir = path.dirname(fileURLToPath(import.meta.url));
export const webRoot = path.resolve(scriptDir, '..');
export const projectRoot = path.resolve(webRoot, '..');
export const wikiRoot = path.join(projectRoot, 'wiki');

const categoryOrder = ['overview', 'requirements', 'architecture', 'concepts', 'entities', 'decisions', 'planning', 'testing', 'guide'];
const categoryLabels = {
  overview: 'ภาพรวม',
  requirements: 'ความต้องการระบบ',
  architecture: 'สถาปัตยกรรม',
  concepts: 'แนวคิดและเทคนิค',
  entities: 'องค์ประกอบระบบ',
  decisions: 'การตัดสินใจ',
  planning: 'การวางแผน',
  testing: 'การทดสอบ',
  guide: 'คู่มือและภาคผนวก'
};

const supportingFiles = [
  'design/server.md',
  'design/architecture.md',
  'design/model.md',
  'design/training.md',
  'Document/server/server.md'
];

export function slugify(value) {
  const slug = String(value)
    .normalize('NFC')
    .toLocaleLowerCase('th')
    .replace(/[\u200B-\u200D\uFEFF]/g, '')
    .replace(/[^\p{Letter}\p{Mark}\p{Number}]+/gu, '-')
    .replace(/^-+|-+$/g, '');
  return slug || 'section';
}

export function splitWikiLink(raw) {
  let escaped = false;
  for (let index = 0; index < raw.length; index += 1) {
    const char = raw[index];
    if (escaped) { escaped = false; continue; }
    if (char === '\\') { escaped = true; continue; }
    if (char === '|') {
      return [raw.slice(0, index).replace(/\\\|/g, '|'), raw.slice(index + 1).replace(/\\\|/g, '|')];
    }
  }
  return [raw.replace(/\\\|/g, '|'), null];
}

export function normalizeDocPath(value) {
  return value.replace(/\\/g, '/').replace(/^\.\//, '').replace(/\.md$/i, '').replace(/^\/+|\/+$/g, '');
}

async function walk(directory, extension = null) {
  const output = [];
  const entries = await fs.readdir(directory, { withFileTypes: true });
  for (const entry of entries.sort((a, b) => a.name.localeCompare(b.name))) {
    if (entry.name === '.obsidian') continue;
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) output.push(...await walk(absolute, extension));
    else if (!extension || entry.name.endsWith(extension)) output.push(absolute);
  }
  return output;
}

function escapeHtml(value = '') {
  return String(value).replace(/[&<>"']/g, (character) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character]);
}

function escapeAttribute(value = '') {
  return escapeHtml(value).replace(/\n/g, '&#10;');
}

function plainText(markdown) {
  return markdown
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/g, '$2 $1')
    .replace(/<[^>]+>/g, ' ')
    .replace(/[#>*_`~\[\](){}|]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function excerpt(markdown, length = 190) {
  const text = plainText(markdown);
  return text.length > length ? `${text.slice(0, length).trim()}…` : text;
}

export function firstParagraph(markdown) {
  const blocks = markdown.replace(/```[\s\S]*?```/g, '').split(/\n\s*\n/u);
  const block = blocks.find((candidate) => {
    const value = candidate.trim();
    return value && !/^(?:#{1,6}\s|---+$|>|[-*+]\s|\d+\.\s|\|)/u.test(value);
  });
  return block ? excerpt(block, 230) : '';
}

export function normalizeDate(value) {
  if (!value) return null;
  if (value instanceof Date && !Number.isNaN(value.valueOf())) return value.toISOString().slice(0, 10);
  const match = String(value).match(/^\d{4}-\d{2}-\d{2}/);
  return match ? match[0] : null;
}

export function inlineTokenText(token) {
  if (!token) return '';
  if (token.children?.length) return token.children.map(inlineTokenText).join('');
  if (['text', 'code_inline', 'html_inline'].includes(token.type)) return token.content.replace(/<[^>]+>/g, '');
  if (token.type === 'image') return token.content || token.attrGet?.('alt') || '';
  return token.content || '';
}

function documentTitle(data, content, sourcePath) {
  if (data.title) return String(data.title);
  const heading = content.match(/^#\s+(.+)$/m);
  return heading ? heading[1].trim() : path.basename(sourcePath, '.md');
}

function documentCategory(data, sourcePath) {
  if (data.category && categoryLabels[data.category]) return data.category;
  const first = normalizeDocPath(sourcePath).split('/')[0];
  if (categoryLabels[first]) return first;
  if (['overview', 'index'].includes(normalizeDocPath(sourcePath))) return 'overview';
  return 'guide';
}

export function wikiLinkPlugin(md) {
  md.inline.ruler.before('link', 'wikilink', (state, silent) => {
    const start = state.pos;
    if (state.src.slice(start, start + 2) !== '[[') return false;
    let end = start + 2;
    let escaped = false;
    while (end < state.posMax - 1) {
      const char = state.src[end];
      if (!escaped && char === ']' && state.src[end + 1] === ']') break;
      if (!escaped && char === '\\') escaped = true; else escaped = false;
      end += 1;
    }
    if (end >= state.posMax - 1) return false;
    if (!silent) {
      const raw = state.src.slice(start + 2, end);
      const [target, alias] = splitWikiLink(raw);
      const open = state.push('link_open', 'a', 1);
      open.attrSet('href', `wiki:${encodeURIComponent(target.trim())}`);
      const label = state.push('text', '', 0);
      label.content = (alias || target).trim();
      state.push('link_close', 'a', -1);
    }
    state.pos = end + 2;
    return true;
  });
}

function preprocessCallouts(source, md, env) {
  const lines = source.replace(/^(#{1,6}\s+)⚙️?\s*/gmu, '$1').split('\n');
  const result = [];
  let inFence = false;
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (/^\s*```/.test(line)) inFence = !inFence;
    const match = !inFence && line.match(/^>\s*\[!(NOTE|INFO|TIP|IMPORTANT|WARNING|CAUTION|DANGER)\]\s*(.*)$/i);
    if (!match) { result.push(line); continue; }
    const type = match[1].toLowerCase();
    const labels = { note: 'หมายเหตุ', info: 'ข้อมูล', tip: 'คำแนะนำ', important: 'สำคัญ', warning: 'คำเตือน', caution: 'ข้อควรระวัง', danger: 'อันตราย' };
    const body = [];
    if (match[2]) body.push(match[2]);
    while (index + 1 < lines.length && /^>/.test(lines[index + 1])) {
      index += 1;
      body.push(lines[index].replace(/^>\s?/, ''));
    }
    const inner = md.render(body.join('\n'), env);
    result.push(`<aside class="callout callout-${type}" aria-label="${labels[type] || labels.note}"><p class="callout-title">${labels[type] || labels.note}</p>${inner}</aside>`);
  }
  return result.join('\n');
}

function relativePrefix(outputPath) {
  const relative = path.relative(path.dirname(path.join(webRoot, outputPath)), webRoot).replace(/\\/g, '/');
  return relative ? `${relative}/` : './';
}

function linkTo(fromOutput, toOutput) {
  const relative = path.relative(path.dirname(path.join(webRoot, fromOutput)), path.join(webRoot, toOutput)).replace(/\\/g, '/');
  return relative || './';
}

function icon(name) {
  const paths = {
    shield: '<path d="M12 3 5.5 5.7v5.8c0 4.2 2.7 7.7 6.5 9.5 3.8-1.8 6.5-5.3 6.5-9.5V5.7L12 3Z"/><path d="m9.2 12 1.8 1.8 3.9-4.2"/>',
    search: '<circle cx="11" cy="11" r="6.5"/><path d="m16 16 4 4"/>',
    theme: '<path d="M12 3a9 9 0 1 0 9 9c0-.5 0-1-.1-1.5A7 7 0 0 1 12 3Z"/>',
    menu: '<path d="M4 7h16M4 12h16M4 17h16"/>',
    close: '<path d="m6 6 12 12M18 6 6 18"/>'
  };
  return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths[name]}</svg>`;
}

function navigation(docs, current, outputPath) {
  const groups = categoryOrder.map((category) => {
    const items = docs.filter((doc) => doc.category === category);
    if (!items.length) return '';
    const open = current?.category === category || !current;
    return `<details class="sidebar-group" ${open ? 'open' : ''}><summary>${categoryLabels[category]}</summary><ul class="sidebar-list">${items.map((doc) => `<li><a href="${linkTo(outputPath, doc.outputPath)}" ${current?.sourcePath === doc.sourcePath ? 'aria-current="page"' : ''}>${escapeHtml(doc.shortTitle)}</a></li>`).join('')}</ul></details>`;
  }).join('');
  return `<aside class="sidebar" data-docs-nav data-open="false" aria-label="หมวดเอกสาร"><button class="control nav-close" type="button" data-nav-close>ปิดเมนู ${icon('close')}</button><p class="sidebar-title">เอกสารทั้งหมด</p>${groups}</aside><div class="nav-backdrop" data-nav-backdrop></div>`;
}

function masthead(prefix) {
  return `<header class="masthead"><div class="masthead-inner"><button class="control nav-toggle" type="button" data-nav-toggle aria-expanded="false" aria-label="เปิดเมนูเอกสาร">${icon('menu')}</button><a class="brand" href="${prefix}index.html">${icon('shield')}<span>ScamGuard <small>Documentation</small></span></a><div class="masthead-actions"><button class="control" type="button" data-search-open>${icon('search')}<span>ค้นหา</span><span class="search-shortcut">Ctrl K</span></button><button class="control" type="button" data-theme-toggle aria-label="เปลี่ยนเป็นโหมดมืด">${icon('theme')}<span class="theme-label" data-theme-label>โหมดมืด</span></button></div></div></header>`;
}

function searchDialog() {
  return `<dialog class="search-dialog" data-search-dialog aria-labelledby="search-title"><div class="search-dialog-head"><label class="visually-hidden" id="search-title" for="docs-search">ค้นหาเอกสาร</label><input id="docs-search" type="search" placeholder="ค้นหาในเอกสารทั้งหมด…" autocomplete="off" data-search-input><button class="control" type="button" data-search-close aria-label="ปิดการค้นหา">${icon('close')}</button></div><div class="search-results" data-search-results aria-live="polite"></div></dialog>`;
}

function tocMarkup(toc) {
  if (!toc.length) return '<p class="toc-empty">หน้านี้ไม่มีหัวข้อย่อย</p>';
  return `<ol class="toc">${toc.map((item) => `<li class="toc-level-${item.level}"><a href="#${encodeURIComponent(item.id)}">${escapeHtml(item.title)}</a></li>`).join('')}</ol>`;
}

function layout({ title, description, prefix, docs, current, outputPath, article, toc = [], bodyClass = '' }) {
  return `<!doctype html>
<html lang="th" data-theme="light">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="${escapeAttribute(description)}">
  <meta name="color-scheme" content="light dark">
  <title>${escapeHtml(title)} | ScamGuard Documentation</title>
  <link rel="stylesheet" href="${prefix}assets/css/site.css">
  <script>document.documentElement.dataset.theme=(()=>{try{return localStorage.getItem('scamguard-docs-theme')||'light'}catch(e){return'light'}})();window.SC_DOCS_ROOT='${prefix}';</script>
</head>
<body class="${bodyClass}">
  <a class="skip-link" href="#main-content">ข้ามไปยังเนื้อหา</a>
  ${masthead(prefix)}
  <div class="docs-shell">
    ${navigation(docs, current, outputPath)}
    <main class="article" id="main-content">${article}</main>
    <aside class="toc-wrap" aria-label="สารบัญในหน้านี้"><p class="toc-title">ในหน้านี้</p>${tocMarkup(toc)}</aside>
  </div>
  ${searchDialog()}
  <script src="${prefix}assets/js/search-index.js"></script>
  <script src="${prefix}assets/js/site.js"></script>
</body>
</html>`;
}

function createMarkdownRenderer(context) {
  const md = new MarkdownIt({
    html: true,
    linkify: true,
    typographer: false,
    highlight(code, language) {
      const highlighted = language && hljs.getLanguage(language)
        ? hljs.highlight(code, { language }).value
        : escapeHtml(code);
      const label = language ? `<span class="visually-hidden">ภาษา ${escapeHtml(language)}</span>` : '';
      return `<div class="code-frame">${label}<button class="copy-button" type="button" data-copy>คัดลอก</button><pre><code class="hljs language-${escapeAttribute(language || 'text')}">${highlighted}</code></pre></div>`;
    }
  });
  wikiLinkPlugin(md);

  const defaultFence = md.renderer.rules.fence;
  md.renderer.rules.fence = (tokens, index, options, env, self) => {
    const token = tokens[index];
    if (token.info.trim().toLowerCase() !== 'mermaid') return defaultFence(tokens, index, options, env, self);
    const diagramIndex = env.diagrams.length + 1;
    const diagramId = `${env.doc.slug.replace(/\//g, '-')}-${diagramIndex}`;
    env.diagrams.push({ id: diagramId, source: token.content, sourcePath: env.doc.sourcePath });
    const src = `${env.prefix}assets/diagrams/${diagramId}.svg`;
    return `<figure class="diagram-frame"><div class="diagram-toolbar"><span>แผนภาพ ${diagramIndex}</span><button class="control" type="button" data-diagram-expand>ดูขนาดใหญ่</button></div><img src="${src}" alt="แผนภาพจาก ${escapeAttribute(env.doc.title)}" loading="lazy"><details class="diagram-source"><summary>ดู Mermaid source</summary><pre><code>${escapeHtml(token.content)}</code></pre></details><dialog aria-label="แผนภาพขนาดใหญ่"><div class="diagram-expanded-head"><button class="control" type="button" data-diagram-zoom="out">ย่อ</button><span class="zoom-status" data-zoom-status>100%</span><button class="control" type="button" data-diagram-zoom="in">ขยาย</button><button class="control" type="button" data-diagram-close>ปิด</button></div><div class="diagram-pan" data-diagram-pan data-zoom="1" tabindex="0" aria-label="พื้นที่แผนภาพ เลื่อนได้ทั้งแนวตั้งและแนวนอน"><img src="${src}" alt="แผนภาพจาก ${escapeAttribute(env.doc.title)}"></div></dialog></figure>`;
  };

  const defaultHeadingOpen = md.renderer.rules.heading_open || ((tokens, index, options, env, self) => self.renderToken(tokens, index, options));
  md.renderer.rules.heading_open = (tokens, index, options, env, self) => {
    const token = tokens[index];
    const inline = tokens[index + 1];
    const text = inlineTokenText(inline).trim() || 'section';
    const base = slugify(text);
    const count = env.headingIds.get(base) || 0;
    env.headingIds.set(base, count + 1);
    const id = count ? `${base}-${count + 1}` : base;
    token.attrSet('id', id);
    const level = Number(token.tag.slice(1));
    if (level === 2 || level === 3) env.toc.push({ level, id, title: text });
    return defaultHeadingOpen(tokens, index, options, env, self);
  };

  const defaultLinkOpen = md.renderer.rules.link_open || ((tokens, index, options, env, self) => self.renderToken(tokens, index, options));
  md.renderer.rules.link_open = (tokens, index, options, env, self) => {
    const token = tokens[index];
    const hrefIndex = token.attrIndex('href');
    if (hrefIndex >= 0) {
      const href = token.attrs[hrefIndex][1];
      const resolved = context.resolveLink(env.doc, href);
      token.attrs[hrefIndex][1] = resolved.href;
      if (resolved.external) token.attrSet('rel', 'noreferrer');
      if (resolved.unresolved) token.attrSet('class', 'unresolved-link');
    }
    return defaultLinkOpen(tokens, index, options, env, self);
  };

  const defaultTableOpen = md.renderer.rules.table_open || (() => '<table>');
  md.renderer.rules.table_open = (...args) => `<div class="table-wrap" role="region" aria-label="ตาราง เลื่อนแนวนอนได้" tabindex="0">${defaultTableOpen(...args)}`;
  md.renderer.rules.table_close = () => '</table></div>';
  return md;
}

async function renderDiagram(diagram, temporaryDirectory) {
  const input = path.join(temporaryDirectory, `${diagram.id}.mmd`);
  const output = path.join(webRoot, 'assets', 'diagrams', `${diagram.id}.svg`);
  await fs.writeFile(input, diagram.source, 'utf8');
  const executable = path.join(webRoot, 'node_modules', '.bin', 'mmdc');
  const puppeteerConfig = path.join(webRoot, 'scripts', 'puppeteer-config.json');
  await execFileAsync(executable, ['-p', puppeteerConfig, '-i', input, '-o', output, '-t', 'neutral', '-b', 'transparent'], { cwd: webRoot, maxBuffer: 1024 * 1024 * 8 });
}

async function copySourceMaterials() {
  const wikiFiles = await walk(wikiRoot);
  for (const source of wikiFiles) {
    const relative = path.relative(wikiRoot, source);
    const destination = path.join(webRoot, 'sources', 'wiki', relative);
    await fs.mkdir(path.dirname(destination), { recursive: true });
    await fs.copyFile(source, destination);
  }
  for (const relative of supportingFiles) {
    const source = path.join(projectRoot, relative);
    try {
      await fs.access(source);
      const destination = path.join(webRoot, 'sources', 'supporting', relative);
      await fs.mkdir(path.dirname(destination), { recursive: true });
      await fs.copyFile(source, destination);
    } catch (_) { }
  }
}

function sourceLinks(doc) {
  const links = [`<li><a href="${doc.prefix}sources/wiki/${escapeAttribute(doc.sourcePath)}">Markdown ต้นฉบับ: ${escapeHtml(doc.sourcePath)}</a></li>`];
  for (const source of doc.sources) links.push(`<li>${escapeHtml(String(source))}</li>`);
  return `<footer class="source-panel"><strong>แหล่งข้อมูลของหน้านี้</strong><ul>${links.join('')}</ul></footer>`;
}

function shortTitle(title) {
  return title.replace(/\s*[—–-]\s*Scam Image Detection\s*$/i, '').replace(/\s*\([^)]{28,}\)\s*$/u, '').trim();
}

export async function build() {
  const markdownFiles = await walk(wikiRoot, '.md');
  const rawDocs = [];
  for (const absolute of markdownFiles) {
    const sourcePath = path.relative(wikiRoot, absolute).replace(/\\/g, '/');
    const raw = await fs.readFile(absolute, 'utf8');
    const parsed = matter(raw);
    const slug = normalizeDocPath(sourcePath);
    const title = documentTitle(parsed.data, parsed.content, sourcePath);
    rawDocs.push({
      absolute,
      sourcePath,
      slug,
      outputPath: `pages/${slug}.html`,
      title,
      shortTitle: shortTitle(title),
      category: documentCategory(parsed.data, sourcePath),
      tags: Array.isArray(parsed.data.tags) ? parsed.data.tags.map(String) : [],
      sources: Array.isArray(parsed.data.sources) ? parsed.data.sources : [],
      updated: normalizeDate(parsed.data.updated),
      content: parsed.content
    });
  }

  rawDocs.sort((a, b) => categoryOrder.indexOf(a.category) - categoryOrder.indexOf(b.category) || a.title.localeCompare(b.title, 'th'));
  const bySlug = new Map(rawDocs.map((doc) => [doc.slug, doc]));
  const byBasename = new Map();
  for (const doc of rawDocs) {
    const base = path.posix.basename(doc.slug);
    const existing = byBasename.get(base);
    byBasename.set(base, existing ? null : doc);
  }
  const unresolvedLinks = [];
  const supportingMap = new Map(supportingFiles.map((relative) => [path.resolve(projectRoot, relative), `sources/supporting/${relative}`]));

  function resolveWikiTarget(doc, target) {
    const [filePart, anchor] = target.split('#');
    let normalized = normalizeDocPath(filePart || doc.slug);
    let destination = bySlug.get(normalized);
    if (!destination && filePart && !filePart.includes('/')) destination = byBasename.get(normalized);
    if (!destination && filePart) {
      const fromDir = path.posix.dirname(doc.sourcePath);
      normalized = normalizeDocPath(path.posix.normalize(path.posix.join(fromDir, filePart)));
      destination = bySlug.get(normalized);
    }
    if (!destination) return null;
    return { destination, anchor: anchor ? `#${slugify(anchor)}` : '' };
  }

  const context = {
    resolveLink(doc, href) {
      if (/^(https?:|mailto:|tel:)/i.test(href)) return { href, external: true };
      if (href.startsWith('#')) return { href: `#${slugify(decodeURIComponent(href.slice(1)))}` };
      if (href.startsWith('wiki:')) {
        const raw = decodeURIComponent(href.slice(5));
        const match = resolveWikiTarget(doc, raw);
        if (match) return { href: `${linkTo(doc.outputPath, match.destination.outputPath)}${match.anchor}` };
        unresolvedLinks.push({ source: doc.sourcePath, target: raw, type: 'wikilink' });
        return { href: '#', unresolved: true };
      }
      const [pathname, anchor = ''] = href.split('#');
      if (/\.md$/i.test(pathname)) {
        const absolute = path.resolve(path.dirname(doc.absolute), decodeURIComponent(pathname));
        const insideWiki = path.relative(wikiRoot, absolute);
        if (!insideWiki.startsWith('..')) {
          const target = bySlug.get(normalizeDocPath(insideWiki));
          if (target) return { href: `${linkTo(doc.outputPath, target.outputPath)}${anchor ? `#${slugify(anchor)}` : ''}` };
        }
        const supporting = supportingMap.get(absolute);
        if (supporting) return { href: `${linkTo(doc.outputPath, supporting)}${anchor ? `#${slugify(anchor)}` : ''}` };
        unresolvedLinks.push({ source: doc.sourcePath, target: href, type: 'markdown' });
        return { href: '#', unresolved: true };
      }
      return { href };
    }
  };

  const generatedPaths = ['pages', 'assets', 'sources'];
  for (const generated of generatedPaths) await fs.rm(path.join(webRoot, generated), { recursive: true, force: true });
  await fs.rm(path.join(webRoot, 'index.html'), { force: true });
  await fs.rm(path.join(webRoot, 'build-report.json'), { force: true });
  await fs.mkdir(path.join(webRoot, 'assets', 'css'), { recursive: true });
  await fs.mkdir(path.join(webRoot, 'assets', 'js'), { recursive: true });
  await fs.mkdir(path.join(webRoot, 'assets', 'fonts'), { recursive: true });
  await fs.mkdir(path.join(webRoot, 'assets', 'diagrams'), { recursive: true });
  await fs.copyFile(path.join(webRoot, 'src', 'site.css'), path.join(webRoot, 'assets', 'css', 'site.css'));
  await fs.copyFile(path.join(webRoot, 'src', 'site.js'), path.join(webRoot, 'assets', 'js', 'site.js'));
  for (const weight of [400, 600, 700, 800]) {
    for (const subset of ['thai', 'latin']) {
      const filename = `sarabun-${subset}-${weight}-normal.woff2`;
      await fs.copyFile(path.join(webRoot, 'node_modules', '@fontsource', 'sarabun', 'files', filename), path.join(webRoot, 'assets', 'fonts', filename));
    }
  }
  await copySourceMaterials();

  const md = createMarkdownRenderer(context);
  const diagrams = [];
  const renderedDocs = [];
  for (const doc of rawDocs) {
    const prefix = relativePrefix(doc.outputPath);
    const env = { doc, prefix, diagrams, toc: [], headingIds: new Map() };
    const prepared = preprocessCallouts(doc.content, md, env);
    const rendered = md.render(prepared, env);
    const lead = firstParagraph(doc.content);
    const article = `<nav class="breadcrumbs" aria-label="เส้นทางเอกสาร"><a href="${prefix}index.html">หน้าแรก</a><span aria-hidden="true">/</span><span>${categoryLabels[doc.category]}</span></nav><header class="article-header"><h1>${escapeHtml(doc.title)}</h1>${lead ? `<p class="article-lead">${escapeHtml(lead)}</p>` : ''}<div class="meta"><span>หมวด ${categoryLabels[doc.category]}</span>${doc.updated ? `<time datetime="${doc.updated}">อัปเดต ${doc.updated}</time>` : ''}<span>ต้นฉบับ ${escapeHtml(doc.sourcePath)}</span></div>${doc.tags.length ? `<div class="tags">${doc.tags.map((tag) => `<span class="tag">${escapeHtml(tag)}</span>`).join('')}</div>` : ''}</header><div class="prose">${rendered}</div>${sourceLinks({ ...doc, prefix })}`;
    const html = layout({ title: doc.title, description: excerpt(doc.content), prefix, docs: rawDocs, current: doc, outputPath: doc.outputPath, article, toc: env.toc });
    const output = path.join(webRoot, doc.outputPath);
    await fs.mkdir(path.dirname(output), { recursive: true });
    await fs.writeFile(output, html, 'utf8');
    renderedDocs.push({ source: doc.sourcePath, output: doc.outputPath, title: doc.title, category: doc.category, headings: env.toc.length });
  }

  const temporaryDirectory = await fs.mkdtemp(path.join('/tmp', 'scamguard-mermaid-'));
  const diagramFailures = [];
  try {
    for (const diagram of diagrams) {
      try { await renderDiagram(diagram, temporaryDirectory); }
      catch (error) { diagramFailures.push({ id: diagram.id, source: diagram.sourcePath, error: error.stderr || error.message }); }
    }
  } finally {
    await fs.rm(temporaryDirectory, { recursive: true, force: true });
  }

  const groups = categoryOrder.map((category) => ({ category, label: categoryLabels[category], docs: rawDocs.filter((doc) => doc.category === category) })).filter((group) => group.docs.length);
  const startPaths = ['overview', 'architecture/system-architecture', 'concepts/multi-layer-analysis', 'testing/test-cases'].map((slug) => bySlug.get(slug)).filter(Boolean);
  const homeToc = [{ level: 2, id: 'เริ่มอ่าน', title: 'เริ่มอ่าน' }, { level: 2, id: 'คลังเอกสาร', title: 'คลังเอกสาร' }];
  const homeArticle = `<section class="home-hero"><h1>หลักฐานทางเทคนิคของ ScamGuard ในที่เดียว</h1><p>เอกสารสำหรับทำความเข้าใจระบบตรวจจับภาพหลอกลวง ตั้งแต่ความต้องการ สถาปัตยกรรม การวิเคราะห์ด้วย AI ไปจนถึงแนวทางการทดสอบ โดยจัดทำจาก Wiki ของโครงการโดยตรง</p></section><section class="evidence-strip" aria-label="สรุปคลังเอกสาร"><div><strong>${rawDocs.length}</strong><span>หน้าเอกสาร</span></div><div><strong>${diagrams.length}</strong><span>แผนภาพระบบ</span></div><div><strong>${groups.length}</strong><span>หมวดความรู้</span></div></section><section class="start-path" id="เริ่มอ่าน"><h2>เริ่มอ่าน</h2><ol class="path-list">${startPaths.map((doc) => `<li><a href="${doc.outputPath}">${escapeHtml(doc.shortTitle)}</a><span>${categoryLabels[doc.category]}</span></li>`).join('')}</ol></section><section class="catalog" id="คลังเอกสาร"><h2>คลังเอกสารทั้งหมด</h2>${groups.map((group) => `<section class="catalog-group"><h3>${group.label} <span class="tag">${group.docs.length}</span></h3><ul class="catalog-list">${group.docs.map((doc) => `<li><a href="${doc.outputPath}">${escapeHtml(doc.shortTitle)}</a></li>`).join('')}</ul></section>`).join('')}</section>`;
  await fs.writeFile(path.join(webRoot, 'index.html'), layout({ title: 'หน้าแรก', description: 'เว็บไซต์เอกสารทางเทคนิคของโครงการ ScamGuard', prefix: './', docs: rawDocs, current: null, outputPath: 'index.html', article: homeArticle, toc: homeToc, bodyClass: 'home' }), 'utf8');

  const searchIndex = rawDocs.map((doc) => ({
    title: doc.title,
    category: doc.category,
    categoryLabel: categoryLabels[doc.category],
    tags: doc.tags,
    text: plainText(doc.content),
    excerpt: excerpt(doc.content),
    url: doc.outputPath
  }));
  await fs.writeFile(path.join(webRoot, 'assets', 'js', 'search-index.js'), `window.SC_SEARCH_INDEX=${JSON.stringify(searchIndex).replace(/<\//g, '<\\/')};\n`, 'utf8');

  const report = {
    generatedAt: new Date().toISOString(),
    sourceMarkdownCount: markdownFiles.length,
    renderedPageCount: renderedDocs.length,
    mermaidSourceCount: diagrams.length,
    mermaidRenderedCount: diagrams.length - diagramFailures.length,
    unresolvedLinks,
    diagramFailures,
    pages: renderedDocs
  };
  await fs.writeFile(path.join(webRoot, 'build-report.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
  console.log(`Built ${renderedDocs.length} pages and ${report.mermaidRenderedCount}/${diagrams.length} Mermaid diagrams.`);
  if (unresolvedLinks.length) console.warn(`Found ${unresolvedLinks.length} unresolved links. Run npm run check for details.`);
  if (diagramFailures.length) throw new Error(`Failed to render ${diagramFailures.length} Mermaid diagrams.`);
}

const invoked = process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href;
if (invoked) build().catch((error) => { console.error(error); process.exitCode = 1; });
