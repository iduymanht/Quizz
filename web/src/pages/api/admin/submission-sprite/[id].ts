import type { APIRoute } from "astro";
import { env } from "cloudflare:workers";
import { adminUser } from "../../../../lib/admin";

export const prerender = false;

// Same-origin proxy for a pending submission's spritesheet, so the admin review
// modal can slice it on a canvas without a cross-origin (tainted) read. Mirrors
// /api/sprite for published pets. Admin-only.
export const GET: APIRoute = async ({ params, cookies }) => {
  const user = await adminUser(cookies);
  if (!user) return new Response("forbidden", { status: 403 });

  const id = params.id ?? "";
  if (!/^[a-zA-Z0-9-]{1,80}$/.test(id)) return new Response("bad request", { status: 400 });

  const base = (env as any).PETS_ORIGIN || (import.meta as any).env?.PETS_ORIGIN || "";
  if (!base) return new Response("not configured", { status: 500 });

  let upstream = await fetch(`${base}/submissions/${id}.webp`);
  if (!upstream.ok) upstream = await fetch(`${base}/submissions/${id}.png`);
  if (!upstream.ok) return new Response("not found", { status: upstream.status });

  return new Response(upstream.body, {
    headers: {
      "content-type": upstream.headers.get("content-type") || "image/png",
      "cache-control": "private, max-age=120",
    },
  });
};
