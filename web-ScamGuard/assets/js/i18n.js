/* ScamGuard Docs TH/EN chrome dictionary + toggle (Loop 3).
 * Static fallback text in HTML equals the th values, so no-JS and
 * crawlers see correct Thai. Body stays Thai; EN shows the EN-WIP notice.
 * Single toggle button shows the TARGET language. Choice persists in
 * localStorage; every switch updates document.documentElement.lang.
 */
var I18N = {
  brand: { th: "ScamGuard Docs", en: "ScamGuard Docs" },
  nav_overview: { th: "ภาพรวม", en: "Overview" },
  nav_layers: { th: "หลายชั้น", en: "Layers" },
  nav_risk: { th: "คะแนนเสี่ยง", en: "Risk score" },
  nav_arch: { th: "สถาปัตยกรรม", en: "Architecture" },
  lang_toggle: { th: "EN", en: "TH" },
  crumb: { th: "เทมเพลตทั้งหมด", en: "All templates" },
  en_wip: { th: "English body translation in progress — เนื้อหาภาษาอังกฤษอยู่ระหว่างแปล", en: "English body translation in progress" }
};

(function () {
  var KEY = "scamguard-lang";
  function current() {
    try {
      var v = localStorage.getItem(KEY);
      if (v === "en") {
        return "en";
      }
      return "th";
    } catch (e) {
      return "th";
    }
  }
  function apply(lang) {
    document.documentElement.lang = lang;
    var els = document.querySelectorAll("[data-i18n]");
    for (var i = 0; i < els.length; i++) {
      var k = els[i].getAttribute("data-i18n");
      if (k in I18N) {
        els[i].textContent = I18N[k][lang];
      }
    }
    try {
      localStorage.setItem(KEY, lang);
    } catch (e) {
      return;
    }
  }
  document.addEventListener("DOMContentLoaded", function () {
    apply(current());
    var btn = document.getElementById("lang-toggle");
    if (btn) {
      btn.addEventListener("click", function () {
        if (current() === "en") {
          apply("th");
        } else {
          apply("en");
        }
      });
    }
  });
})();
