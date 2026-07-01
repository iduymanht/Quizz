const { segments, sliceRects, clipForMood } = require("./pet-sprite.js");
let pass=0, fail=0;
const eq=(a,e,m)=>{const A=JSON.stringify(a),E=JSON.stringify(e);if(A===E)pass++;else{fail++;console.error("FAIL "+m+"\n exp "+E+"\n got "+A);}};

// segments
eq(segments([false,true,true,false,true]), [[1,3],[4,5]], "segments basic");
eq(segments([true,true]), [[0,2]], "segments all true");
eq(segments([false,false]), [], "segments none");

// clipForMood
eq(clipForMood("idle",5),0,"mood idle");
eq(clipForMood("happy",5),2,"mood happy");
eq(clipForMood("sad",5),1,"mood sad");
eq(clipForMood("happy",1),0,"mood happy clamp n=1");
eq(clipForMood("sad",1),0,"mood sad clamp n=1");

// sliceRects: build 8x8 RGBA, 2 rows of frames with gutters.
// Layout (rows y): row band y1..2 and y4..5 opaque; y0,3,6,7 transparent gutters.
// Within each row: cols x1..2 and x4..5 opaque -> 2 frames per row.
const w=8,h=8; const data=new Uint8ClampedArray(w*h*4);
function set(x,y){const i=(y*w+x)*4; data[i]=255;data[i+1]=0;data[i+2]=0;data[i+3]=255;}
for(const y of [1,2,4,5]) for(const x of [1,2,4,5]) set(x,y);
const clips = sliceRects({data}, w, h, 16);
eq(clips.length, 2, "sliceRects: 2 clips (rows)");
eq(clips[0].length, 2, "sliceRects: row0 has 2 frames");
eq(clips[1].length, 2, "sliceRects: row1 has 2 frames");
eq(clips[0][0], {x:1,y:1,w:2,h:2}, "sliceRects: first frame rect");
eq(clips[1][1], {x:4,y:4,w:2,h:2}, "sliceRects: last frame rect");

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail?1:0);
