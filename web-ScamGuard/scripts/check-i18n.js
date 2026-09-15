#!/usr/bin/env node
// check-i18n.js — key-coverage check between data-i18n* keys in HTML and the I18N dict.
// RED state (Loop 2): no dict file exists yet -> exit 1.
// GREEN state (Loop 3): dict at web-ScamGuard/assets/js/i18n.js defines I18N = {key: {th, en}}.
// Exit 0 + "keys OK" only when both directions match.
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const DICT_CANDIDATES = [path.join(ROOT, "assets", "js", "i18n.js")];

function htmlFiles(dir) {
  return fs
    .readdirSync(dir)
    .filter((f) => f.endsWith(".html") && fs.statSync(path.join(dir, f)).isFile())
    .map((f) => path.join(dir, f));
}

function keysInHtml(files) {
  const keys = new Set();
  const re = /data-i18n(?:-[a-zA-Z]+)?="([^"]+)"/g;
  for (const f of files) {
    const src = fs.readFileSync(f, "utf8");
    let m;
    while ((m = re.exec(src)) !== null) keys.add(m[1]);
  }
  return keys;
}

function loadDict() {
  for (const p of DICT_CANDIDATES) {
    if (!fs.existsSync(p)) continue;
    const src = fs.readFileSync(p, "utf8");
    const m = src.match(/I18N\s*=\s*(\{[\s\S]*\})\s*;/);
    if (!m) {
      console.error(`i18n dict found at ${p} but no "I18N = {...};" assignment`);
      process.exit(1);
    }
    try {
      // Dict is a plain object literal with string keys; evaluate safely-ish via Function.
      const obj = new Function(`return (${m[1]});`)();
      return { file: p, keys: new Set(Object.keys(obj)) };
    } catch (e) {
      console.error(`cannot parse I18N dict in ${p}: ${e.message}`);
      process.exit(1);
    }
  }
  return null;
}

(function main() {
  const files = htmlFiles(ROOT);
  const used = keysInHtml(files);
  const dict = loadDict();
  if (!dict) {
    console.error(
      `no I18N dict found (looked in ${DICT_CANDIDATES.join(", ")}); ` +
        `${used.size} data-i18n key(s) used in ${files.length} HTML file(s) — exit 1`
    );
    process.exit(1);
  }
  const missing = [...used].filter((k) => !dict.keys.has(k));
  const unused = [...dict.keys].filter((k) => !used.has(k));
  if (missing.length || unused.length) {
    for (const k of missing) console.error(`missing in dict: ${k}`);
    for (const k of unused) console.error(`unused dict key: ${k}`);
    process.exit(1);
  }
  console.log(`keys OK (${used.size} keys, dict ${dict.file})`);
})();
