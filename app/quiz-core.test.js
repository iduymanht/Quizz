const { parseMarkdown, validateQuestion, toMarkdown } = require("./quiz-core.js");

let pass = 0, fail = 0;
function eq(actual, expected, msg) {
  const a = JSON.stringify(actual), e = JSON.stringify(expected);
  if (a === e) { pass++; } else { fail++; console.error("FAIL: " + msg + "\n  expected " + e + "\n  got      " + a); }
}
function ok(cond, msg) { if (cond) pass++; else { fail++; console.error("FAIL: " + msg); } }

// --- parseMarkdown: basic two questions ---
const md = `# Thủ đô của Việt Nam?
- [ ] TP HCM
- [x] Hà Nội
- [ ] Đà Nẵng
- [ ] Huế
> Hà Nội là thủ đô.

# 2 + 2 = ?
- [ ] 3
- [x] 4
* [ ] 5
- [X] 22`;
const qs = parseMarkdown(md);
eq(qs.length, 2, "parse: two questions");
eq(qs[0].text, "Thủ đô của Việt Nam?", "parse: q1 text");
eq(qs[0].options.length, 4, "parse: q1 four options");
eq(qs[0].options.map(o => o.correct), [false, true, false, false], "parse: q1 correctness");
eq(qs[0].explanation, "Hà Nội là thủ đô.", "parse: q1 explanation");
// q2: supports '*' bullet and uppercase X as correct
eq(qs[1].options.map(o => o.correct), [false, true, false, true], "parse: q2 mixed bullets + uppercase X");
ok(qs[1].explanation === "", "parse: q2 no explanation");

// --- parseMarkdown: multi-line explanation joins ---
const md2 = `## Câu hỏi
- [x] A
- [ ] B
> Dòng 1
> Dòng 2`;
eq(parseMarkdown(md2)[0].explanation, "Dòng 1 Dòng 2", "parse: multi-line explanation joins");

// --- parseMarkdown: ignores junk before first heading, empty input ---
eq(parseMarkdown("rác\n- [ ] x").length, 0, "parse: options before any heading are ignored");
eq(parseMarkdown("").length, 0, "parse: empty string");

// --- validateQuestion ---
ok(validateQuestion({ text: "q", options: [{ text: "a", correct: true }, { text: "b", correct: false }] }).length === 0, "validate: valid question");
ok(validateQuestion({ text: "", options: [{ text: "a", correct: true }, { text: "b" }] }).length === 1, "validate: missing text");
ok(validateQuestion({ text: "q", options: [{ text: "a", correct: false }, { text: "b", correct: false }] }).length === 1, "validate: no correct answer");
ok(validateQuestion({ text: "q", options: [{ text: "a", correct: true }] }).length === 1, "validate: fewer than 2 options");
ok(validateQuestion({ text: "q", options: [{ text: "", correct: true }, { text: "b", correct: false }] }).length >= 1, "validate: correct option must have text");

// --- round-trip: parse -> toMarkdown -> parse ---
const back = parseMarkdown(toMarkdown(qs));
eq(back.length, qs.length, "roundtrip: count preserved");
eq(back[0].text, qs[0].text, "roundtrip: text preserved");
eq(back[0].options.map(o => [o.text, o.correct]), qs[0].options.map(o => [o.text, o.correct]), "roundtrip: options preserved");
eq(back[0].explanation, qs[0].explanation, "roundtrip: explanation preserved");

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
