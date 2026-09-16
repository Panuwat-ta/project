(() => {
  const root = document.documentElement;
  const storageKey = 'scamguard-docs-theme';
  const systemTheme = matchMedia('(prefers-color-scheme: dark)');

  function selectedTheme() {
    try {
      const saved = localStorage.getItem(storageKey);
      if (saved === 'system' || saved === 'light' || saved === 'dark') return saved;
    } catch (_) { }
    return 'system';
  }

  function resolveTheme(mode) {
    return mode === 'system' ? (systemTheme.matches ? 'dark' : 'light') : mode;
  }

  function setTheme(mode, persist = true) {
    if (!['system', 'light', 'dark'].includes(mode)) mode = 'system';
    const resolved = resolveTheme(mode);
    root.dataset.themeMode = mode;
    root.dataset.theme = resolved;
    document.querySelectorAll('[data-theme-option]').forEach((button) => {
      const active = button.dataset.themeOption === mode;
      button.classList.toggle('is-active', active);
      button.setAttribute('aria-pressed', String(active));
    });
    if (persist) {
      try { localStorage.setItem(storageKey, mode); } catch (_) { }
    }
  }

  setTheme(selectedTheme(), false);

  document.querySelectorAll('[data-theme-option]').forEach((button) => {
    button.addEventListener('click', () => setTheme(button.dataset.themeOption));
  });

  systemTheme.addEventListener('change', () => {
    if (root.dataset.themeMode === 'system') setTheme('system', false);
  });

  const nav = document.querySelector('[data-docs-nav]');
  const navButton = document.querySelector('[data-nav-toggle]');
  const navClose = document.querySelector('[data-nav-close]');
  const navBackdrop = document.querySelector('[data-nav-backdrop]');
  const mobileNav = matchMedia('(max-width: 760px)');
  let navReturnFocus = null;

  function syncNavAccessibility() {
    if (!nav) return;
    const hidden = mobileNav.matches && nav.dataset.open !== 'true';
    nav.inert = hidden;
    if (hidden) nav.setAttribute('aria-hidden', 'true'); else nav.removeAttribute('aria-hidden');
  }

  function setNav(open) {
    if (!nav || !navButton) return;
    if (open) navReturnFocus = document.activeElement;
    nav.dataset.open = String(open);
    navButton.setAttribute('aria-expanded', String(open));
    document.body.classList.toggle('nav-open', open);
    syncNavAccessibility();
    if (open) requestAnimationFrame(() => nav.querySelector('a, button')?.focus());
    else if (navReturnFocus instanceof HTMLElement) {
      const target = navReturnFocus;
      navReturnFocus = null;
      target.focus();
    }
  }
  navButton?.addEventListener('click', () => setNav(nav?.dataset.open !== 'true'));
  navClose?.addEventListener('click', () => setNav(false));
  navBackdrop?.addEventListener('click', () => setNav(false));
  mobileNav.addEventListener('change', () => {
    nav.dataset.open = 'false';
    navButton?.setAttribute('aria-expanded', 'false');
    document.body.classList.remove('nav-open');
    navReturnFocus = null;
    syncNavAccessibility();
  });
  syncNavAccessibility();

  document.addEventListener('keydown', (event) => {
    if (!mobileNav.matches || nav?.dataset.open !== 'true') return;
    if (event.key === 'Escape') {
      event.preventDefault();
      setNav(false);
      return;
    }
    if (event.key !== 'Tab') return;
    const focusable = [...nav.querySelectorAll('a[href], button:not([disabled]), summary')]
      .filter((node) => node.getClientRects().length > 0 && (node.matches('summary') || !node.closest('details:not([open])')));
    if (!focusable.length) return;
    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
    else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
  });

  document.querySelectorAll('[data-copy]').forEach((button) => {
    button.addEventListener('click', async () => {
      const code = button.closest('.code-frame')?.querySelector('code')?.innerText || '';
      const original = button.textContent;
      try {
        await navigator.clipboard.writeText(code);
        button.textContent = 'คัดลอกแล้ว';
      } catch (_) {
        const range = document.createRange();
        const selection = getSelection();
        range.selectNodeContents(button.closest('.code-frame').querySelector('code'));
        selection.removeAllRanges();
        selection.addRange(range);
        button.textContent = 'เลือกโค้ดแล้ว';
      }
      setTimeout(() => { button.textContent = original; }, 1600);
    });
  });

  const searchDialog = document.querySelector('[data-search-dialog]');
  const searchInput = document.querySelector('[data-search-input]');
  const searchResults = document.querySelector('[data-search-results]');
  const docsRoot = window.SC_DOCS_ROOT || './';
  const searchIndex = window.SC_SEARCH_INDEX || [];

  function openSearch() {
    if (!searchDialog) return;
    searchDialog.showModal();
    requestAnimationFrame(() => searchInput?.focus());
  }

  document.querySelectorAll('[data-search-open]').forEach((button) => button.addEventListener('click', openSearch));
  document.querySelector('[data-search-close]')?.addEventListener('click', () => searchDialog.close());
  searchDialog?.addEventListener('click', (event) => {
    if (event.target === searchDialog) searchDialog.close();
  });
  document.addEventListener('keydown', (event) => {
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
      event.preventDefault();
      openSearch();
    }
  });

  function normalize(value) {
    return value.toLocaleLowerCase('th').normalize('NFKC');
  }

  function escapeHtml(value) {
    return value.replace(/[&<>"']/g, (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]);
  }

  function runSearch(query) {
    if (!searchResults) return;
    const terms = normalize(query).trim().split(/\s+/u).filter(Boolean);
    if (!terms.length) {
      searchResults.innerHTML = '<div class="search-empty"><strong>ค้นหาเอกสารทั้งหมด</strong><p>พิมพ์ชื่อระบบ เทคโนโลยี หรือคำสำคัญ เช่น ONNX, ความเสี่ยง, API</p></div>';
      return;
    }
    const matches = searchIndex.map((item) => {
      const title = normalize(item.title);
      const tags = normalize(item.tags.join(' '));
      const body = normalize(item.text);
      if (!terms.every((term) => title.includes(term) || tags.includes(term) || body.includes(term))) return null;
      const score = terms.reduce((sum, term) => sum + (title.includes(term) ? 8 : 0) + (tags.includes(term) ? 3 : 0) + (body.includes(term) ? 1 : 0), 0);
      return { ...item, score };
    }).filter(Boolean).sort((a, b) => b.score - a.score || a.title.localeCompare(b.title, 'th')).slice(0, 24);

    if (!matches.length) {
      searchResults.innerHTML = `<div class="search-empty"><strong>ไม่พบ “${escapeHtml(query)}”</strong><p>ลองใช้คำที่สั้นลง หรือค้นหาด้วยคำศัพท์ภาษาอังกฤษ</p></div>`;
      return;
    }
    searchResults.innerHTML = matches.map((item) => `<a class="search-result" href="${docsRoot}${item.url}"><span>${escapeHtml(item.categoryLabel)}</span><strong>${escapeHtml(item.title)}</strong><p>${escapeHtml(item.excerpt)}</p></a>`).join('');
  }

  searchInput?.addEventListener('input', (event) => runSearch(event.target.value));
  runSearch('');

  const tocLinks = [...document.querySelectorAll('.toc a[href^="#"]')];
  const observed = tocLinks.map((link) => document.getElementById(decodeURIComponent(link.hash.slice(1)))).filter(Boolean);
  if ('IntersectionObserver' in window && observed.length) {
    const observer = new IntersectionObserver((entries) => {
      const visible = entries.filter((entry) => entry.isIntersecting).sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];
      if (!visible) return;
      tocLinks.forEach((link) => {
        const current = decodeURIComponent(link.hash.slice(1)) === visible.target.id;
        link.classList.toggle('is-active', current);
        if (current) link.setAttribute('aria-current', 'location'); else link.removeAttribute('aria-current');
      });
    }, { rootMargin: '-12% 0px -72% 0px' });
    observed.forEach((heading) => observer.observe(heading));
  }

  document.querySelectorAll('[data-diagram-expand]').forEach((button) => {
    button.addEventListener('click', () => {
      const dialog = button.closest('.diagram-frame')?.querySelector('dialog');
      dialog?.showModal();
    });
  });
  document.querySelectorAll('[data-diagram-close]').forEach((button) => button.addEventListener('click', () => button.closest('dialog')?.close()));
  document.querySelectorAll('[data-diagram-zoom]').forEach((button) => {
    button.addEventListener('click', () => {
      const dialog = button.closest('dialog');
      const viewport = dialog?.querySelector('[data-diagram-pan]');
      if (!viewport) return;
      const current = Number(viewport.dataset.zoom || 1);
      const delta = button.dataset.diagramZoom === 'in' ? .25 : -.25;
      const next = Math.min(2, Math.max(.75, current + delta));
      viewport.dataset.zoom = String(next);
      viewport.style.setProperty('--diagram-zoom', String(next));
      dialog.querySelector('[data-zoom-status]').textContent = `${Math.round(next * 100)}%`;
    });
  });
})();
