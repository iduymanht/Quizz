import type { APIRoute } from "astro";
import { loadManifest, applyOverrides } from "../../lib/pets";
import { getDB, ensureSchema, getOverrides } from "../../lib/db";

export const prerender = false;

// Public pet list for the gallery / home / leaderboard. Real `kind` + `source` from
// the manifest, with admin overrides applied (edited kinds, hidden pets dropped).
export const GET: APIRoute = async () => {
  const manifest = await loadManifest();
  if (!manifest.length) return new Response(JSON.stringify({ pets: [] }), { status: 502 });

  let ovr = {};
  const db = getDB();
  if (db) { await ensureSchema(db); ovr = await getOverrides(db); }

  const pets = applyOverrides(manifest, ovr).map((p) => ({ slug: p.slug, name: p.name, kind: p.kind, source: p.source }));
  return new Response(JSON.stringify({ pets }), {
    headers: { "content-type": "application/json", "cache-control": "public, max-age=60" },
  });
};
