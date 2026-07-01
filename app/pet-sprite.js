// pet-sprite.js — loads a spritesheet.webp and slices it into animation clips
// by detecting transparent gutters (a JS port of the app's SpriteSlicer).
// One clip per sheet row; frames per clip detected within the row.
// No grid metadata required, so ragged / AI-generated sheets work too.
(function (root) {
  "use strict";

  function segments(occupancy) {
    const out = [];
    let start = null;
    for (let i = 0; i < occupancy.length; i++) {
      if (occupancy[i] && start === null) start = i;
      else if (!occupancy[i] && start !== null) { out.push([start, i]); start = null; }
    }
    if (start !== null) out.push([start, occupancy.length]);
    return out;
  }

  // Returns clips: Array<Array<{x,y,w,h}>> — frame rects into the sheet.
  function sliceRects(imageData, w, h, alphaThreshold) {
    alphaThreshold = alphaThreshold == null ? 16 : alphaThreshold;
    const a = imageData.data; // RGBA
    const rowHas = new Array(h).fill(false);
    for (let y = 0; y < h; y++) {
      const base = y * w * 4;
      for (let x = 0; x < w; x++) {
        if (a[base + x * 4 + 3] > alphaThreshold) { rowHas[y] = true; break; }
      }
    }
    const rowBands = segments(rowHas);
    const clips = [];
    for (const [ry0, ry1] of rowBands) {
      const colHas = new Array(w).fill(false);
      for (let y = ry0; y < ry1; y++) {
        const base = y * w * 4;
        for (let x = 0; x < w; x++) {
          if (a[base + x * 4 + 3] > alphaThreshold) colHas[x] = true;
        }
      }
      const frames = segments(colHas).map(([cx0, cx1]) => ({
        x: cx0, y: ry0, w: cx1 - cx0, h: ry1 - ry0,
      }));
      if (frames.length) clips.push(frames);
    }
    return clips;
  }

  // Loads a sheet URL and returns { img, clips } where clips are frame rects.
  async function loadPack(sheetUrl) {
    // NOTE: no crossOrigin — the sheet is same-origin (custom scheme on macOS,
    // asset server on Tauri). Forcing CORS mode can make the load fail and would
    // leave the pet blank.
    const img = await new Promise((resolve, reject) => {
      const im = new Image();
      im.onload = () => resolve(im);
      im.onerror = () => reject(new Error("Cannot load sprite: " + sheetUrl));
      im.src = sheetUrl;
    });
    const w = img.naturalWidth, h = img.naturalHeight;
    const c = document.createElement("canvas");
    c.width = w; c.height = h;
    const ctx = c.getContext("2d", { willReadFrequently: true });
    ctx.drawImage(img, 0, 0);
    let clips;
    try {
      clips = sliceRects(ctx.getImageData(0, 0, w, h), w, h, 16);
    } catch (e) {
      // getImageData can throw if the canvas is tainted; fall back to one frame
      // that draws the whole sheet (static pet) rather than nothing.
      clips = [[{ x: 0, y: 0, w, h }]];
    }
    if (!clips.length) clips = [[{ x: 0, y: 0, w, h }]];
    return { img, clips, width: w, height: h };
  }

  // Animates a clip onto a display canvas. Returns a controller with setClip/stop.
  function createPlayer(canvas, pack, opts) {
    opts = opts || {};
    const ctx = canvas.getContext("2d");
    let clipIndex = 0, frame = 0, timer = null, fps = opts.fps || 6;
    let animate = opts.animate !== false;

    function drawFrame() {
      const clip = pack.clips[clipIndex] || pack.clips[0] || [];
      if (!clip.length) return;
      const r = clip[frame % clip.length];
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      // contain the frame within the canvas, preserving aspect
      const scale = Math.min(canvas.width / r.w, canvas.height / r.h);
      const dw = r.w * scale, dh = r.h * scale;
      const dx = (canvas.width - dw) / 2, dy = (canvas.height - dh) / 2;
      ctx.imageSmoothingEnabled = false;
      ctx.drawImage(pack.img, r.x, r.y, r.w, r.h, dx, dy, dw, dh);
    }
    function tick() { frame++; drawFrame(); }
    function start() {
      stop();
      drawFrame();
      if (animate) timer = setInterval(tick, 1000 / fps);
    }
    function stop() { if (timer) { clearInterval(timer); timer = null; } }
    function setClip(i, newFps) {
      const n = pack.clips.length || 1;
      clipIndex = ((i % n) + n) % n;
      frame = 0;
      if (newFps) { fps = newFps; }
      start();
    }
    start();
    return {
      setClip,
      setFps(f) { fps = f; start(); },
      stop,
      clipCount: pack.clips.length,
    };
  }

  // Heuristic mood -> clip index for packs with unknown row semantics.
  function clipForMood(mood, clipCount) {
    const n = Math.max(clipCount, 1);
    switch (mood) {
      case "happy":
      case "celebrate":
      case "thanks": return Math.min(2, n - 1);
      case "sad":
      case "disappointed": return Math.min(1, n - 1);
      case "idle":
      default: return 0;
    }
  }

  const api = { segments, sliceRects, loadPack, createPlayer, clipForMood };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else root.PetSprite = api;
})(typeof window !== "undefined" ? window : globalThis);
