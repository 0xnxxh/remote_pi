/* Pipeline do preview de markdown (plano 58) — receita VS Code:
   markdown-it (GFM) → DOMPurify (allowlist) → rewrite de imagens relativas
   pro scheme controlado → morphdom (diff de DOM, preserva scroll).
   API chamada pelo Dart: window.__cockpit.setContent(md, docDir) e
   window.__cockpit.setTheme(vars). */
(function () {
  "use strict";

  var md = window.markdownit({
    html: true, // HTML embutido entra cru aqui; quem filtra é o DOMPurify
    linkify: true,
    typographer: false,
  });

  // Allowlist do DOMPurify: default seguro + alvos comuns de README.
  var SANITIZE = {
    USE_PROFILES: { html: true },
    ADD_TAGS: ["details", "summary"],
    // "checked"/"disabled" preservam o checkbox de task list do GFM
    ADD_ATTR: ["align", "width", "height", "open", "checked", "disabled"],
    FORBID_TAGS: ["style", "form", "button"],
    ALLOW_UNKNOWN_PROTOCOLS: false,
  };

  function rewriteImages(root, docDir) {
    var imgs = root.querySelectorAll("img");
    for (var i = 0; i < imgs.length; i++) {
      var src = imgs[i].getAttribute("src") || "";
      if (!src || /^[a-z][a-z0-9+.-]*:/i.test(src)) {
        // scheme explícito: só data: sobrevive (CSP bloqueia o resto)
        continue;
      }
      var abs = src.charAt(0) === "/" ? src : docDir + "/" + src;
      imgs[i].setAttribute("src", "ckp-res://local/" + encodeURIComponent(abs));
    }
  }

  function render(markdown, docDir) {
    var html = md.render(markdown);
    var clean = window.DOMPurify.sanitize(html, SANITIZE);
    var next = document.createElement("div");
    next.id = "content";
    next.innerHTML = clean;
    rewriteImages(next, docDir);
    var cur = document.getElementById("content");
    // Diff de DOM: só os nós que mudaram trocam — sem piscar, sem perder scroll.
    window.morphdom(cur, next);
  }

  window.__cockpit = {
    setContent: function (markdown, docDir) {
      try {
        render(markdown, docDir || "");
      } catch (e) {
        var cur = document.getElementById("content");
        cur.textContent = String((e && e.message) || e);
      }
    },
    setTheme: function (vars) {
      var root = document.documentElement;
      for (var k in vars) {
        if (Object.prototype.hasOwnProperty.call(vars, k)) {
          root.style.setProperty(k, vars[k]);
        }
      }
    },
  };
})();
