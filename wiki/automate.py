import os
import time
import re
import json
import markdown
import shutil

WIKI_DIR = "/home/panuwat/project/wiki"
OUT_DIR = "/home/panuwat/project/web-ScamGuard"
INDEX_HTML = "/home/panuwat/project/index.html"

CATEGORIES = [
    {"id": "overview", "phase": "เนื้อหา · OVERVIEW", "title": "Overview"},
    {"id": "architecture", "phase": "เนื้อหา · ARCHITECTURE", "title": "Architecture"},
    {"id": "concepts", "phase": "เนื้อหา · CONCEPTS", "title": "Concepts"},
    {"id": "requirements", "phase": "เนื้อหา · REQUIREMENTS", "title": "Requirements"},
    {"id": "entities", "phase": "เนื้อหา · ENTITIES", "title": "Entities"},
    {"id": "planning", "phase": "เนื้อหา · PLANNING", "title": "Planning"},
    {"id": "decisions", "phase": "เนื้อหา · DECISIONS", "title": "Decisions"},
]

HTML_TEMPLATE = """<!doctype html>
<html lang="th">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title} - ScamGuard</title>
  <link
    href="https://fonts.googleapis.com/css2?family=Taviraj:wght@500;600;700&family=Sarabun:wght@300;400;500;600;700&family=IBM+Plex+Mono:wght@400;500;600&display=swap"
    rel="stylesheet">
  <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" rel="stylesheet">
  <link rel="stylesheet" href="{css_path}">
</head>

<body>
  <main class="document">
{content}
  </main>

  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-python.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-bash.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-json.min.js"></script>
  <script>
    mermaid.initialize({{ startOnLoad: true, theme: 'base', themeVariables: {{ primaryColor: '#EFE9DA', primaryTextColor: '#1B1F2B', primaryBorderColor: '#3D4B94', lineColor: '#3D4B94', secondaryColor: '#F6F4EE', tertiaryColor: '#F6F4EE' }} }});
  </script>
  <script>
    MathJax = {{
      tex: {{
        inlineMath: [['$', '$'], ['\\(', '\\)']],
        displayMath: [['$$', '$$'], ['\\[', '\\]']]
      }}
    }};
  </script>
  <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>

  <script src="https://cdn.jsdelivr.net/npm/svg-pan-zoom@3.6.1/dist/svg-pan-zoom.min.js"></script>
  <script>
    document.addEventListener("DOMContentLoaded", () => {{
      document.querySelectorAll('.mermaid-container').forEach(container => {{
        const btn = document.createElement('button');
        btn.className = 'btn-expand-mermaid';
        btn.innerHTML = '🔍 Fullscreen';

        btn.onclick = () => {{
          const originalSvg = container.querySelector('svg');
          if (!originalSvg) return;

          const overlay = document.createElement('div');
          overlay.style.position = 'fixed';
          overlay.style.top = '0';
          overlay.style.left = '0';
          overlay.style.width = '100vw';
          overlay.style.height = '100vh';
          overlay.style.backgroundColor = 'var(--paper, #F6F4EE)';
          overlay.style.zIndex = '999999';
          overlay.style.display = 'flex';
          overlay.style.alignItems = 'center';
          overlay.style.justifyContent = 'center';

          const closeBtn = document.createElement('button');
          closeBtn.innerHTML = '✖ Close';
          closeBtn.style.position = 'absolute';
          closeBtn.style.top = '20px';
          closeBtn.style.right = '20px';
          closeBtn.style.padding = '8px 16px';
          closeBtn.style.fontSize = '1rem';
          closeBtn.style.fontWeight = 'bold';
          closeBtn.style.cursor = 'pointer';
          closeBtn.style.backgroundColor = '#ff4d4d';
          closeBtn.style.color = '#fff';
          closeBtn.style.border = 'none';
          closeBtn.style.borderRadius = '8px';
          closeBtn.style.zIndex = '1000000';
          closeBtn.style.boxShadow = '0 4px 12px rgba(0,0,0,0.2)';

          closeBtn.onmouseover = () => closeBtn.style.backgroundColor = '#e60000';
          closeBtn.onmouseout = () => closeBtn.style.backgroundColor = '#ff4d4d';

          const clonedSvg = originalSvg.cloneNode(true);
          clonedSvg.style.width = '100%';
          clonedSvg.style.height = '100%';
          clonedSvg.style.maxWidth = '100vw';
          clonedSvg.style.maxHeight = '100vh';

          overlay.appendChild(clonedSvg);
          overlay.appendChild(closeBtn);
          document.body.appendChild(overlay);

          const oldOverflow = document.body.style.overflow;
          document.body.style.overflow = 'hidden';

          const panZoomInstance = svgPanZoom(clonedSvg, {{
            zoomEnabled: true,
            controlIconsEnabled: true,
            fit: true,
            center: true,
            minZoom: 0.5,
            maxZoom: 10,
            mouseWheelZoomEnabled: true
          }});

          closeBtn.onclick = () => {{
            panZoomInstance.destroy();
            document.body.removeChild(overlay);
            document.body.style.overflow = oldOverflow;
          }};
        }};
        container.appendChild(btn);
      }});
    }});
  </script>
</body>
</html>"""

def parse_frontmatter(text):
    if not text.startswith("---"):
        return {}, text
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}, text
    
    fm_text = parts[1]
    content = parts[2].strip()
    
    fm = {}
    for line in fm_text.splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            fm[k.strip()] = v.strip().strip('"').strip("'")
            
    return fm, content

import html as html_lib

def convert_markdown_to_html(md_content):
    # Remove wikilinks and related text
    md_content = re.sub(r'(?:---\n+)?## หน้าที่เกี่ยวข้อง\n+(?:-\s*\[\[.*?\]\]\n*)*', '', md_content)
    md_content = re.sub(r'\s*(ดูรายละเอียดที่|ดูเกณฑ์การตัดสินที่|ดูสถาปัตยกรรมเต็มที่|ดูที่)\s*\[\[.*?\]\](?:\s*และ\s*\[\[.*?\]\])*', '', md_content)
    md_content = re.sub(r'\[\[.*?\]\]', '', md_content)

    # Pre-process alerts
    md_content = re.sub(r'> \[!(\w+)\]\n', r'> **\1:**<br />\n', md_content)
    
    html = markdown.markdown(md_content, extensions=['fenced_code', 'tables', 'mdx_math'])
    
    # Post-process html structure for the theme
    html = html.replace('<hr />', '<div class="divider"></div>')
    html = re.sub(r'</h1>\s*<p>', '</h1>\n    <p class="lede">', html)
    
    # Process mermaid blocks
    def replace_mermaid(match):
        code = html_lib.unescape(match.group(1))
        return f'<div class="mermaid-container"><div class="mermaid">{code}</div></div>'
        
    html = re.sub(
        r'<pre><code class="language-mermaid">(.*?)</code></pre>',
        replace_mermaid,
        html,
        flags=re.DOTALL
    )
    
    # Indent content properly
    html = '\n'.join('    ' + line for line in html.splitlines())
    return html

def build():
    print("Building documentation...")
    documents_data = []
    
    # Map category id to category info
    cat_map = {c['id']: c for c in CATEGORIES}
    
    # Collect files by category
    category_files = {c['id']: [] for c in CATEGORIES}
    
    for root, dirs, files in os.walk(WIKI_DIR):
        if '.obsidian' in root:
            continue
        for file in files:
            if file.endswith('.md'):
                filepath = os.path.join(root, file)
                rel_path = os.path.relpath(filepath, WIKI_DIR)
                
                with open(filepath, 'r', encoding='utf-8') as f:
                    fm, content = parse_frontmatter(f.read())
                
                cat = fm.get('category')
                if cat in category_files:
                    category_files[cat].append({
                        'title': fm.get('title', file),
                        'src_rel': rel_path,
                        'content': content
                    })
                    
    # Generate HTML files and documents data
    for i, cat_info in enumerate(CATEGORIES):
        cat_id = cat_info['id']
        files = category_files[cat_id]
        if not files:
            continue
            
        doc_entry = {
            "phase": cat_info["phase"],
            "title": cat_info["title"],
            "sub_titles": []
        }
        
        # Sort files to ensure overview is first if it's the overview category, or sort alphabetically
        files.sort(key=lambda x: x['title'])
        
        for file_info in files:
            src_rel = file_info['src_rel']
            html_rel = src_rel[:-3] + '.html'
            
            # calculate depth for css
            depth = html_rel.count(os.sep)
            css_path = "../" * depth + "shared-theme.css"
            if depth == 0:
                css_path = "shared-theme.css"
                
            html_content = convert_markdown_to_html(file_info['content'])
            final_html = HTML_TEMPLATE.format(
                title=file_info['title'],
                css_path=css_path,
                content=html_content
            )
            
            out_file = os.path.join(OUT_DIR, html_rel)
            os.makedirs(os.path.dirname(out_file), exist_ok=True)
            with open(out_file, 'w', encoding='utf-8') as f:
                f.write(final_html)
                
            # Web-ScamGuard relative path for index.html
            portal_path = "web-ScamGuard/" + html_rel.replace(os.sep, '/')
            doc_entry["sub_titles"].append({
                "title": file_info['title'],
                "path": portal_path
            })
            
        documents_data.append(doc_entry)
        
    # Generate Sidebar HTML
    nav_list_html = '<ul class="nav-list">\n'
    for i, doc in enumerate(documents_data):
        nav_list_html += f'''            <li>
              <button class="nav-item category-toggle" type="button" data-cat="{i}">
                <span class="stamp">0{i+1}</span>
                <span class="nav-copy">
                  <span class="nav-phase">{doc["title"]}</span>
                </span>
              </button>
              <div id="cat-{i}" class="sub-menu-container">'''
        for j, sub in enumerate(doc["sub_titles"]):
            nav_list_html += f'\n                <button class="sub-item" data-cat="{i}" data-sub="{j}">&bull; {sub["title"]}</button>'
        nav_list_html += '''
              </div>
            </li>\n'''
    nav_list_html += '          </ul>'
    
    # Update index.html
    with open(INDEX_HTML, 'r', encoding='utf-8') as f:
        index_content = f.read()
        
    # Replace nav-list
    index_content = re.sub(r'<ul class="nav-list">.*?</ul>', nav_list_html, index_content, flags=re.DOTALL)
    
    # Replace documents json
    index_content = re.sub(
        r'const documents = \[.*?\];', 
        f'const documents = {json.dumps(documents_data, ensure_ascii=False)};', 
        index_content, 
        flags=re.DOTALL
    )
    
    with open(INDEX_HTML, 'w', encoding='utf-8') as f:
        f.write(index_content)
        
    print("Build complete!")

def get_mtime():
    mtime = 0
    for root, dirs, files in os.walk(WIKI_DIR):
        if '.obsidian' in root:
            continue
        for file in files:
            if file.endswith('.md'):
                t = os.path.getmtime(os.path.join(root, file))
                mtime = max(mtime, t)
    return mtime

def watch():
    print("Watching for changes...")
    last_mtime = get_mtime()
    try:
        while True:
            time.sleep(2)
            current_mtime = get_mtime()
            if current_mtime > last_mtime:
                print("Changes detected!")
                build()
                last_mtime = current_mtime
    except KeyboardInterrupt:
        print("Stopped watching.")

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "--build":
        build()
    else:
        build() # build once first
        watch()
