import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import puppeteer from 'puppeteer';

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const projectRoot = path.resolve(webRoot, '..');
const reviewRoot = path.join(projectRoot, '.impeccable', 'review');
await fs.mkdir(reviewRoot, { recursive: true });

const browser = await puppeteer.launch({
  executablePath: '/usr/bin/google-chrome',
  headless: true,
  args: ['--no-sandbox', '--disable-setuid-sandbox']
});

const assertions = [];
function assert(condition, message) {
  if (!condition) throw new Error(message);
  assertions.push(message);
}

async function openPage(url, viewport, theme, screenshot) {
  const page = await browser.newPage();
  await page.setViewport(viewport);
  const remoteRequests = [];
  page.on('request', (request) => {
    if (/^https?:/i.test(request.url())) remoteRequests.push(request.url());
  });
  await page.evaluateOnNewDocument((selectedTheme) => localStorage.setItem('scamguard-docs-theme', selectedTheme), theme);
  await page.goto(url, { waitUntil: 'networkidle0' });
  assert(remoteRequests.length === 0, `${screenshot}: ไม่มี network request ภายนอก`);
  assert(await page.$('#main-content'), `${screenshot}: มี main content`);
  const dimensions = await page.evaluate(() => ({ scrollWidth: document.documentElement.scrollWidth, clientWidth: document.documentElement.clientWidth }));
  assert(dimensions.scrollWidth <= dimensions.clientWidth + 1, `${screenshot}: ไม่มี page overflow แนวนอน`);
  await page.screenshot({ path: path.join(reviewRoot, screenshot), fullPage: true });
  return page;
}

try {
  const rootUrl = pathToFileURL(path.join(projectRoot, 'index.html')).href;
  const homeUrl = pathToFileURL(path.join(webRoot, 'index.html')).href;
  const architectureUrl = pathToFileURL(path.join(webRoot, 'pages', 'architecture', 'flowchart.html')).href;

  const rootPage = await browser.newPage();
  await rootPage.goto(rootUrl, { waitUntil: 'networkidle0' });
  assert(rootPage.url().endsWith('/web-ScamGuard/index.html'), 'root index ส่งต่อไปหน้าเอกสาร');
  await rootPage.close();

  const desktopLight = await openPage(homeUrl, { width: 1440, height: 1000, deviceScaleFactor: 1 }, 'light', 'desktop-light.png');
  assert(await desktopLight.evaluate(() => {
    const sidebar = document.querySelector('.sidebar').getBoundingClientRect();
    const toc = document.querySelector('.toc-wrap').getBoundingClientRect();
    return Math.abs(sidebar.left) < 1 && Math.abs(sidebar.width - 282) < 1 && Math.abs(toc.right - innerWidth) < 1;
  }), 'desktop ใช้ sidebar เต็มความสูง 282px และสารบัญชิดขอบขวา');
  await desktopLight.click('[data-search-open]');
  await desktopLight.type('[data-search-input]', 'ONNX');
  await desktopLight.waitForSelector('.search-result');
  assert(await desktopLight.$$eval('.search-result', (items) => items.length > 0), 'ค้นหา ONNX พบเอกสาร');
  await desktopLight.click('[data-search-close]');
  await desktopLight.click('[data-theme-option="dark"]');
  assert(await desktopLight.evaluate(() => document.documentElement.dataset.theme === 'dark' && document.documentElement.dataset.themeMode === 'dark'), 'เลือกโหมดมืดได้');
  assert(await desktopLight.$eval('[data-theme-option="dark"]', (button) => button.getAttribute('aria-pressed') === 'true'), 'ปุ่มโหมดมืดแสดงสถานะ active');
  await desktopLight.click('[data-theme-option="system"]');
  assert(await desktopLight.evaluate(() => document.documentElement.dataset.themeMode === 'system'), 'เลือกธีมตามระบบได้');
  await desktopLight.close();

  const desktopDark = await openPage(architectureUrl, { width: 1920, height: 1000, deviceScaleFactor: 1 }, 'dark', 'desktop-dark.png');
  assert(await desktopDark.$('.diagram-frame img'), 'บทความสถาปัตยกรรมแสดง Mermaid SVG');
  assert(await desktopDark.$('.toc a'), 'บทความมีสารบัญหัวข้อ');
  assert(await desktopDark.$eval('.article-header h1', (heading) => parseFloat(getComputedStyle(heading).fontSize) <= 44), 'หัวข้อบทความ desktop ไม่เกิน 44px');
  await desktopDark.close();

  const mobileLight = await openPage(homeUrl, { width: 390, height: 844, deviceScaleFactor: 1 }, 'light', 'mobile-light.png');
  assert(await mobileLight.$eval('.docs-shell', (shell) => getComputedStyle(shell).paddingLeft === '10px' && getComputedStyle(shell).paddingRight === '10px'), 'กรอบ mobile ห่างขอบด้านละ 10px');
  assert(await mobileLight.evaluate(() => document.querySelector('[data-docs-nav]').inert && document.querySelector('[data-docs-nav]').getAttribute('aria-hidden') === 'true'), 'เมนูมือถือที่ปิดไม่อยู่ใน focus หรือ accessibility tree');
  await mobileLight.click('[data-nav-toggle]');
  assert(await mobileLight.evaluate(() => document.querySelector('[data-docs-nav]').dataset.open === 'true'), 'เมนูมือถือเปิดได้');
  await new Promise((resolve) => setTimeout(resolve, 260));
  await mobileLight.keyboard.down('Shift');
  await mobileLight.keyboard.press('Tab');
  await mobileLight.keyboard.up('Shift');
  assert(await mobileLight.evaluate(() => document.querySelector('[data-docs-nav]').contains(document.activeElement)), 'focus trap ใช้เฉพาะ controls ที่มองเห็นในเมนู');
  await mobileLight.keyboard.press('Escape');
  assert(await mobileLight.evaluate(() => document.activeElement === document.querySelector('[data-nav-toggle]')), 'Escape ปิดเมนูและคืน focus');
  await mobileLight.click('[data-nav-toggle]');
  await mobileLight.setViewport({ width: 900, height: 844, deviceScaleFactor: 1 });
  await new Promise((resolve) => setTimeout(resolve, 120));
  assert(await mobileLight.evaluate(() => {
    const nav = document.querySelector('[data-docs-nav]');
    const trigger = document.querySelector('[data-nav-toggle]');
    return nav.dataset.open === 'false' && trigger.getAttribute('aria-expanded') === 'false' && !document.body.classList.contains('nav-open') && !nav.inert;
  }), 'เปลี่ยน breakpoint แล้วล้างสถานะเมนูและเปิด navigation สำหรับ desktop');
  await mobileLight.close();

  const mobileDark = await openPage(architectureUrl, { width: 390, height: 844, deviceScaleFactor: 1 }, 'dark', 'mobile-dark.png');
  await mobileDark.click('[data-nav-toggle]');
  await new Promise((resolve) => setTimeout(resolve, 260));
  assert(await mobileDark.$$eval('[data-docs-nav] summary', (items) => items.every((item) => item.getClientRects().length > 0 && item.tabIndex >= 0)), 'summary ของทุกหมวดมองเห็นและใช้คีย์บอร์ดได้');
  await mobileDark.keyboard.press('Escape');
  await mobileDark.click('[data-diagram-expand]');
  await mobileDark.click('[data-diagram-zoom="in"]');
  assert(await mobileDark.$eval('[data-zoom-status]', (status) => status.textContent === '125%'), 'แผนภาพขนาดใหญ่ปรับ zoom ได้');
  assert(await mobileDark.$eval('[data-diagram-pan]', (viewport) => viewport.scrollWidth > viewport.clientWidth), 'แผนภาพขนาดใหญ่เลื่อนดูรายละเอียดแนวนอนได้');
  await mobileDark.close();

  const noJs = await browser.newPage();
  await noJs.setJavaScriptEnabled(false);
  await noJs.setViewport({ width: 1280, height: 800 });
  await noJs.goto(architectureUrl, { waitUntil: 'load' });
  assert(await noJs.$('#main-content .prose'), 'ปิด JavaScript แล้วยังอ่านบทความได้');
  assert(await noJs.$('.sidebar a'), 'ปิด JavaScript แล้วยังใช้ลิงก์นำทางได้');
  await noJs.close();

  console.log(`VISUAL CHECK PASSED: ${assertions.length} assertions; screenshots saved to ${reviewRoot}`);
} finally {
  await browser.close();
}
