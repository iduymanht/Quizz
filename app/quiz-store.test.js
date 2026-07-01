const store = new Map();
globalThis.localStorage = { getItem:k=>store.has(k)?store.get(k):null, setItem:(k,v)=>store.set(k,String(v)) };
const QS = require("./quiz-store.js");
let pass=0, fail=0; const ok=(c,m)=>{c?pass++:(fail++,console.error("FAIL "+m));};
(async () => {
  const qs = [{id:"1",text:"Q?",options:[{text:"a",correct:true},{text:"b",correct:false}],explanation:"x"}];
  await QS.saveQuestions(qs);
  const back = await QS.loadQuestions();
  ok(back.length===1 && back[0].text==="Q?", "save/load roundtrip via localStorage fallback");
  const empty = new Map(); globalThis.localStorage.getItem=k=>null;
  const none = await QS.loadQuestions();
  ok(Array.isArray(none)&&none.length===0, "empty load returns []");
  console.log(`\n${pass} passed, ${fail} failed`); process.exit(fail?1:0);
})();
