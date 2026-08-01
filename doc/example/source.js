function highlightSource() {
  const scripts = document.querySelectorAll("script[data-lang]");
  if (!scripts.length) return;

  const out = document.getElementById("output");
  out.innerHTML = "";

  scripts.forEach(script => {
    const lang = script.dataset.lang;
    let code = script.textContent;

    let result;
    try {
      result = (lang === "automatic")
        ? hljs.highlightAuto(code)
        : hljs.highlight(code, { language: lang });
    } catch {
      result = { value: hljs.escapeHTML(code) };
    }

    out.innerHTML += result.value + "\n";
  });
}

document.addEventListener("DOMContentLoaded", highlightSource);

