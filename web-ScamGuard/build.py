#!/usr/bin/env python3
"""Stdlib wiki-to-HTML pipeline (Loops 2-3).

Converts the allowlisted wiki pages (all wiki/**/*.md minus scratch/
and AGENTS.md) into flat web-ScamGuard/*.html files inside the
t01-sidebar shell, sidebar injected from
web-ScamGuard/templates/t01-sidebar/index.html (<aside class="side">).

Usage:
    python3 web-ScamGuard/build.py           # build
    python3 web-ScamGuard/build.py --check   # verify, prints BUILD OK
"""
import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent  # web-ScamGuard/
REPO = ROOT.parent
TEMPLATE = ROOT / "templates" / "t01-sidebar" / "index.html"

EXCLUDE_DIR_PARTS = {"scratch"}
EXCLUDE_FILES = {"AGENTS.md"}


def discover_pages() -> list[tuple[str, str]]:
    """Allowlist: all wiki/**/*.md minus scratch/ and AGENTS.md.

    Destinations are flattened (basename stem + .html); stems are unique
    across wiki/ so no collisions. Returns sorted (src_rel, dest_name).
    """
    pages = []
    for md in sorted((REPO / "wiki").rglob("*.md")):
        rel = md.relative_to(REPO)
        if EXCLUDE_DIR_PARTS & set(rel.parts):
            continue
        if md.name in EXCLUDE_FILES:
            continue
        pages.append((rel.as_posix(), md.stem + ".html"))
    return pages


PAGES = discover_pages()


def _excluded_dests() -> set[str]:
    """Dest names of wiki sources dropped by the allowlist (scratch/, AGENTS.md).

    Links pointing at these have no built page; render them as plain labels
    so the output contains no dead hrefs.
    """
    out = set()
    for md in (REPO / "wiki").rglob("*.md"):
        rel = md.relative_to(REPO)
        if (EXCLUDE_DIR_PARTS & set(rel.parts)) or md.name in EXCLUDE_FILES:
            out.add(md.stem + ".html")
    return out


EXCLUDED_DESTS = _excluded_dests()

# --- Output sanitizers (offline self-contained rule + ADR-001) ----------------
# No external URLs, no jira/atlassian tokens, no emoji in built HTML.
AUTOLINK_RE = re.compile(r"<https?://[^>\s]+>")
BARE_URL_RE = re.compile(r"https?://\S+")
MD_HTTP_LINK_RE = re.compile(r"\[([^\]]+)\]\(https?://[^)]+\)")
EXCLUDED_TOKEN_RE = re.compile(r"atlassian|jira", re.I)
EMOJI_RE = re.compile(
    "[\u2600-\u27bf\u2b00-\u2bff\ufe00-\ufe0f"
    "\U0001f000-\U0001faff\U0001fc00-\U0001ffff]"
)
EXTERNAL_PLACEHOLDER = "[ลิงก์ภายนอก]"
NEUTRAL_BOARD = "task-board"


def sanitize(md_text: str) -> str:
    text = AUTOLINK_RE.sub(EXTERNAL_PLACEHOLDER, md_text)
    text = MD_HTTP_LINK_RE.sub(r"\1", text)  # [label](http...) -> label
    text = BARE_URL_RE.sub(EXTERNAL_PLACEHOLDER, text)
    text = EXCLUDED_TOKEN_RE.sub(NEUTRAL_BOARD, text)
    text = EMOJI_RE.sub("", text)
    return text

CALLOUT_RE = re.compile(r"^\s*\[!(NOTE|IMPORTANT|WARNING|TIP)\]\s*(.*)$", re.I)
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
FENCE_RE = re.compile(r"^(`{3,})(\w*)\s*$")
TABLE_SEP_RE = re.compile(r"^\s*\|?[\s:\-|]+\|?\s*$")
WIKILINK_RE = re.compile(r"\[\[([^\]|]+)(?:\|([^\]]+))?\]\]")
MD_LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
BULLET_RE = re.compile(r"^[-*]\s+")
ORDERED_RE = re.compile(r"^\d+[.)]\s+")
BOLD_RE = re.compile(r"\*\*([^*]+)\*\*")
INLINE_CODE_RE = re.compile(r"`([^`]+)`")


def strip_frontmatter(text: str) -> str:
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            rest = text[end + 4 :]
            return rest.lstrip("\n") if rest.startswith("\n") else rest
    return text


def inline(md: str) -> str:
    """Inline markup: escape, then code, bold, md links, wikilinks."""
    parts = []
    # Protect inline code spans first.
    codes = []

    def stash(m):
        codes.append(m.group(1))
        return f"\x00CODE{len(codes) - 1}\x00"

    md = INLINE_CODE_RE.sub(stash, md)
    md = html.escape(md)
    md = BOLD_RE.sub(r"<strong>\1</strong>", md)

    def md_link(m):
        target = m.group(2).strip()
        if target.startswith("http://") or target.startswith("https://"):
            return m.group(1)  # external links: keep label only (offline rule)
        if target.endswith(".md") or ".md#" in target or ".md?" in target:
            base = re.split(r"[#?]", target)[0]
            stem = Path(base).stem + ".html"
            if stem in EXCLUDED_DESTS:
                return m.group(1)  # allowlist-excluded source: label only, no dead href
            suffix = target[len(base):]
            return f'<a href="{html.escape(stem + suffix)}">{m.group(1)}</a>'
        return f'<a href="{html.escape(m.group(2))}">{m.group(1)}</a>'

    md = MD_LINK_RE.sub(md_link, md)

    def wiki_link(m):
        target = m.group(1).strip()
        label = (m.group(2) or target).strip()
        if "#" in target:
            base, anchor = target.split("#", 1)
            anchor = "#" + anchor
        else:
            base, anchor = target, ""
        base = base.strip()
        if base.endswith(".md"):
            base = base[:-3]
        stem = base.split("/")[-1]  # flatten: [[dir/page]] -> page.html
        if stem + ".html" in EXCLUDED_DESTS:
            return html.escape(label)  # allowlist-excluded source: label only
        href = stem + ".html" + anchor
        return f'<a href="{html.escape(href)}">{html.escape(label)}</a>'

    md = WIKILINK_RE.sub(wiki_link, md)
    for i, code in enumerate(codes):
        md = md.replace(f"\x00CODE{i}\x00", f"<code>{html.escape(code)}</code>")
    return md


def md_to_html(md_text: str) -> str:
    text = sanitize(strip_frontmatter(md_text))
    lines = text.split("\n")
    out: list[str] = []
    in_fence = False
    fence_lang = ""
    fence_buf: list[str] = []
    in_ul = False
    in_ol = False
    para: list[str] = []

    def flush_para():
        if para:
            out.append(f"<p>{inline(' '.join(para))}</p>")
            para.clear()

    def close_lists():
        nonlocal in_ul, in_ol
        if in_ul:
            out.append("</ul>")
            in_ul = False
        if in_ol:
            out.append("</ol>")
            in_ol = False

    i = 0
    while i < len(lines):
        line = lines[i]
        fence = FENCE_RE.match(line)
        if fence:
            if not in_fence:
                flush_para()
                close_lists()
                in_fence = True
                fence_lang = fence.group(2)
                fence_buf = []
            else:
                lang = f' class="language-{html.escape(fence_lang)}"' if fence_lang else ""
                out.append(f"<pre><code{lang}>{html.escape(chr(10).join(fence_buf))}</code></pre>")
                in_fence = False
            i += 1
            continue
        if in_fence:
            fence_buf.append(line)
            i += 1
            continue
        s = line.strip()
        if not s:
            flush_para()
            close_lists()
            i += 1
            continue
        if s == "---":
            flush_para()
            close_lists()
            out.append("<hr>")
            i += 1
            continue
        h = HEADING_RE.match(s)
        if h:
            flush_para()
            close_lists()
            level = len(h.group(1))
            out.append(f"<h{level}>{inline(h.group(2))}</h{level}>")
            i += 1
            continue
        # Table: header row + separator row + body rows.
        if s.startswith("|") and i + 1 < len(lines) and TABLE_SEP_RE.match(lines[i + 1]):
            flush_para()
            close_lists()
            header = [c.strip() for c in s.strip("|").split("|")]
            out.append("<table>")
            out.append(
                "<thead><tr>"
                + "".join(f"<th>{inline(c)}</th>" for c in header)
                + "</tr></thead><tbody>"
            )
            i += 2
            while i < len(lines) and lines[i].strip().startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                out.append(
                    "<tr>" + "".join(f"<td>{inline(c)}</td>" for c in cells) + "</tr>"
                )
                i += 1
            out.append("</tbody></table>")
            continue
        # Blockquote / callout.
        if s.startswith(">"):
            flush_para()
            close_lists()
            quote_lines = []
            while i < len(lines) and lines[i].strip().startswith(">"):
                quote_lines.append(lines[i].strip()[1:].strip())
                i += 1
            body = " ".join(quote_lines)
            cm = CALLOUT_RE.match(body)
            if cm:
                kind = cm.group(1).upper()
                out.append(
                    f'<aside class="callout callout-{kind.lower()}">'
                    f"<strong>{kind}</strong> {inline(cm.group(2))}</aside>"
                )
            else:
                out.append(f"<blockquote><p>{inline(body)}</p></blockquote>")
            continue
        # Lists.
        if re.match(r"^[-*]\s+", s):
            flush_para()
            if in_ol:
                out.append("</ol>")
                in_ol = False
            if not in_ul:
                out.append("<ul>")
                in_ul = True
            item = BULLET_RE.sub("", s)
            out.append("<li>" + inline(item) + "</li>")
            i += 1
            continue
        if re.match(r"^\d+[.)]\s+", s):
            flush_para()
            if in_ul:
                out.append("</ul>")
                in_ul = False
            if not in_ol:
                out.append("<ol>")
                in_ol = True
            item = ORDERED_RE.sub("", s)
            out.append("<li>" + inline(item) + "</li>")
            i += 1
            continue
        para.append(s)
        i += 1
    flush_para()
    close_lists()
    return "\n".join(out)


def load_sidebar() -> str:
    src = TEMPLATE.read_text(encoding="utf-8")
    m = re.search(r'<aside class="side".*?</aside>', src, re.S)
    if not m:
        raise SystemExit(f"sidebar <aside> not found in {TEMPLATE}")
    return m.group(0)


def page_title(md_text: str, fallback: str) -> str:
    text = strip_frontmatter(md_text)
    m = re.search(r"^#\s+(.+)$", text, re.M)
    title = m.group(1).strip() if m else fallback
    return sanitize(title).strip() or fallback


SHELL = """<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title} — ScamGuard Docs</title>
<link rel="stylesheet" href="assets/css/site.css">
</head>
<body>
<a class="skip" href="#content">ข้ามไปยังเนื้อหา</a>
<header class="site-head"><div class="wrap"><a class="brand" href="index.html" data-i18n="brand">ScamGuard Docs</a><nav class="nav" aria-label="หลัก"><a href="overview.html" data-i18n="nav_overview">ภาพรวม</a><a href="overview.html#layers" data-i18n="nav_layers">หลายชั้น</a><a href="overview.html#risk" data-i18n="nav_risk">คะแนนเสี่ยง</a><a href="overview.html#arch" data-i18n="nav_arch">สถาปัตยกรรม</a></nav><button id="lang-toggle" data-i18n="lang_toggle" aria-label="switch language">EN</button></div></header>
<div class="wrap layout">
{sidebar}
<main id="content">
<p class="t01-crumb"><a href="index.html" data-i18n="crumb">เทมเพลตทั้งหมด</a> / {title}</p>
<p class="en-wip" data-i18n="en_wip">English body translation in progress — เนื้อหาภาษาอังกฤษอยู่ระหว่างแปล</p>
{body}
</main>
</div>
<footer class="site-foot"><div class="wrap">ScamGuard Docs — ไทยเป็นหลัก</div></footer>
<script src="assets/js/i18n.js" defer></script>
</body>
</html>
"""


def build() -> list[Path]:
    sidebar = load_sidebar()
    written = []
    for src_rel, dest_name in PAGES:
        src = REPO / src_rel
        if not src.exists():
            raise SystemExit(f"source not found: {src}")
        md = src.read_text(encoding="utf-8")
        title = page_title(md, dest_name)
        body = md_to_html(md)
        dest = ROOT / dest_name
        dest.write_text(
            SHELL.format(title=html.escape(title), sidebar=sidebar, body=body),
            encoding="utf-8",
        )
        written.append(dest)
    return written


def check() -> bool:
    """Verify the full Loop 3 build output. Prints BUILD OK on success."""
    errors = []
    expected = [dest for _, dest in PAGES]
    if len(expected) < 35:
        errors.append(f"allowlist only {len(expected)} pages (< 35)")
    for dest_name in expected:
        dest = ROOT / dest_name
        if not dest.exists():
            errors.append(f"missing {dest_name}")
    dest = ROOT / "overview.html"
    if not dest.exists():
        print("BUILD FAIL: overview.html missing")
        return False
    src = dest.read_text(encoding="utf-8")
    for needle, label in [
        ('<aside class="side"', "sidebar"),
        ("<h1>", "converted H1"),
        ("<table>", "converted table"),
        ("callout-", "converted callout"),
        (".html", "converted wikilink"),
        ("en-wip", "EN-WIP notice"),
        ('data-i18n="brand"', "i18n chrome key"),
        ('assets/js/i18n.js', "i18n script"),
    ]:
        if needle not in src:
            errors.append(label)
    # Per-page: every built page carries sidebar + EN-WIP + chrome key.
    for dest_name in expected:
        p = ROOT / dest_name
        if not p.exists():
            continue
        s = p.read_text(encoding="utf-8")
        if '<aside class="side"' not in s:
            errors.append(f"{dest_name}: sidebar")
        if "en-wip" not in s:
            errors.append(f"{dest_name}: EN-WIP")
        if 'data-i18n="brand"' not in s:
            errors.append(f"{dest_name}: chrome")
        if "http://" in s or "https://" in s:
            errors.append(f"{dest_name}: external URL leak")
        if re.search(r"atlassian|jira", s, re.I):
            errors.append(f"{dest_name}: excluded token leak")
        if EMOJI_RE.search(s):
            errors.append(f"{dest_name}: emoji leak")
    # Fixture round-trip: sample.md must convert through the same code path.
    fixture = ROOT / "tests" / "fixtures" / "sample.md"
    if not fixture.exists():
        errors.append("fixture sample.md")
    else:
        fhtml = md_to_html(fixture.read_text(encoding="utf-8"))
        for needle, label in [
            ("<h1>", "fixture H1"),
            (".html", "fixture wikilink"),
            ("<table>", "fixture table"),
            ("<pre><code", "fixture fence"),
        ]:
            if needle not in fhtml:
                errors.append(label)
    if errors:
        print("BUILD FAIL: missing " + ", ".join(errors))
        return False
    print("BUILD OK")
    return True


if __name__ == "__main__":
    if "--check" in sys.argv:
        build()
        sys.exit(0 if check() else 1)
    for p in build():
        print(f"wrote {p}")
