// quiz-core.js — pure quiz logic shared by the web UI, the macOS app (WKWebView)
// and the Windows app (Tauri). No DOM access here so it can be unit-tested in Node.
(function (root) {
  "use strict";

  function uid() {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  }

  // Parse bulk questions written in Markdown.
  // Format:
  //   # Question text
  //   - [ ] wrong answer
  //   - [x] correct answer
  //   > explanation (optional, shown when the user answers wrong)
  function parseMarkdown(md) {
    const lines = String(md).replace(/\r\n?/g, "\n").split("\n");
    const out = [];
    let cur = null;
    const push = () => { if (cur && cur.text) out.push(cur); cur = null; };
    for (const raw of lines) {
      const line = raw.trim();
      const h = line.match(/^#{1,6}\s+(.*)$/);
      if (h) { push(); cur = { text: h[1].trim(), options: [], explanation: "" }; continue; }
      if (!cur) continue;
      const opt = line.match(/^[-*]\s*\[\s*([xX ])\s*\]\s*(.*)$/);
      if (opt) { cur.options.push({ text: opt[2].trim(), correct: opt[1].toLowerCase() === "x" }); continue; }
      const ex = line.match(/^>\s?(.*)$/);
      if (ex) { cur.explanation = (cur.explanation ? cur.explanation + " " : "") + ex[1].trim(); continue; }
    }
    push();
    return out.map(q => ({ id: uid(), text: q.text, options: q.options, explanation: q.explanation }));
  }

  // Returns an array of human-readable error strings (empty = valid).
  function validateQuestion(q) {
    const errs = [];
    if (!q || !q.text || !q.text.trim()) errs.push("• Thiếu nội dung câu hỏi.");
    const options = (q && q.options) || [];
    const filled = options.filter(o => o.text && o.text.trim());
    if (filled.length < 2) errs.push("• Cần ít nhất 2 đáp án có nội dung.");
    if (!options.some(o => o.correct && o.text && o.text.trim())) errs.push("• Cần chọn ít nhất 1 đáp án đúng.");
    return errs;
  }

  // Serialize questions back to the Markdown format above.
  function toMarkdown(qs) {
    return (qs || []).map(q => {
      let s = "# " + q.text + "\n";
      (q.options || []).filter(o => o.text && o.text.trim()).forEach(o => {
        s += "- [" + (o.correct ? "x" : " ") + "] " + o.text + "\n";
      });
      if (q.explanation && q.explanation.trim()) s += "> " + q.explanation.trim() + "\n";
      return s;
    }).join("\n");
  }

  const api = { uid, parseMarkdown, validateQuestion, toMarkdown };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else root.QuizCore = api;
})(typeof window !== "undefined" ? window : globalThis);
