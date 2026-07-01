// quiz-store.js — durable question storage shared by the builder and the pet
// overlay, across macOS (WKWebView) and Windows (Tauri). Writes to a real file
// via the native bridge so questions survive app restarts and are visible to
// both windows; falls back to localStorage in a plain browser.
(function (root) {
  "use strict";

  const LS_KEY = "quiz_builder_questions_v1";
  const pending = {};

  // Native → JS delivery for the macOS bridge (Swift evaluates this).
  root.__quizDeliver = function (json) {
    let qs = [];
    try { qs = typeof json === "string" ? JSON.parse(json) : (json || []); } catch (e) { qs = []; }
    if (pending.load) { const r = pending.load; pending.load = null; r(Array.isArray(qs) ? qs : []); }
  };

  function isTauri() { return !!(root.__TAURI__ && root.__TAURI__.core); }
  function isWebKit() {
    return !!(root.webkit && root.webkit.messageHandlers && root.webkit.messageHandlers.quiz);
  }

  function cacheLocal(json) { try { localStorage.setItem(LS_KEY, json); } catch (e) {} }
  function readLocal() {
    try { const r = localStorage.getItem(LS_KEY); const q = r ? JSON.parse(r) : []; return Array.isArray(q) ? q : []; }
    catch (e) { return []; }
  }

  async function saveQuestions(questions) {
    const json = JSON.stringify(questions || []);
    cacheLocal(json);
    if (isTauri()) {
      try { await root.__TAURI__.core.invoke("save_questions", { json }); } catch (e) {}
    } else if (isWebKit()) {
      root.webkit.messageHandlers.quiz.postMessage({ action: "saveQuestions", json });
    }
    return true;
  }

  async function loadQuestions() {
    if (isTauri()) {
      try {
        const json = await root.__TAURI__.core.invoke("load_questions");
        const qs = json ? JSON.parse(json) : [];
        if (Array.isArray(qs)) { cacheLocal(JSON.stringify(qs)); return qs; }
      } catch (e) {}
    } else if (isWebKit()) {
      const qs = await new Promise((resolve) => {
        pending.load = resolve;
        try { root.webkit.messageHandlers.quiz.postMessage({ action: "loadQuestions" }); }
        catch (e) { pending.load = null; resolve(null); }
        setTimeout(() => { if (pending.load) { pending.load = null; resolve(null); } }, 1000);
      });
      if (Array.isArray(qs)) { cacheLocal(JSON.stringify(qs)); return qs; }
    }
    return readLocal();
  }

  const api = { saveQuestions, loadQuestions, LS_KEY };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else root.QuizStore = api;
})(typeof window !== "undefined" ? window : globalThis);
