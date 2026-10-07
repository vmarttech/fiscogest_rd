import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const buf = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(buf)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function verifyPassword(plain: string, stored: string): Promise<boolean> {
  const s = (stored ?? "").trim();
  if (!plain || !s) return false;
  if (s.startsWith("s1$")) {
    const parts = s.split("$");
    if (parts.length !== 3) return false;
    const check = await sha256Hex(`${parts[1]}${plain}`);
    return check === parts[2];
  }
  return (await sha256Hex(plain)) === s;
}

function posEmail(username: string, negocioId: string) {
  const u = username.toLowerCase().replace(/[^a-z0-9._-]/g, "").slice(0, 32) || "user";
  const n = negocioId.replace(/-/g, "").slice(0, 12);
  return `pos.${n}.${u}@fiscogest.local`;
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method" }, 405);

  try {
    const body = await req.json();
    const username = String(body.username ?? "").trim();
    const password = String(body.password ?? "");
    const negocioHint = String(body.negocio_id ?? "").trim();
    if (!username || !password) return json({ error: "faltan_campos" }, 400);

    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const anon = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    if (!url || !service || !anon) {
      return json({
        error: "server_misconfigured",
        has_url: !!url,
        has_service: !!service,
        has_anon: !!anon,
      }, 500);
    }

    const admin = {
      apikey: service,
      Authorization: `Bearer ${service}`,
      "Content-Type": "application/json",
    };

    const qs = new URLSearchParams({
      select: "id,username,negocio_id,password_hash,activo,rol",
      username: `eq.${username}`,
    });
    if (negocioHint) qs.set("negocio_id", `eq.${negocioHint}`);
    const ures = await fetch(`${url}/rest/v1/usuarios?${qs}`, { headers: admin });
    if (!ures.ok) return json({ error: "db", status: ures.status }, 502);
    const rows = await ures.json();
    if (!Array.isArray(rows) || rows.length === 0) {
      return json({ error: "credenciales" }, 401);
    }
    if (rows.length > 1) return json({ error: "usuario_ambiguo" }, 409);
    const u = rows[0];
    if (u.activo === false) return json({ error: "credenciales" }, 401);
    if (!(await verifyPassword(password, String(u.password_hash ?? "")))) {
      return json({ error: "credenciales" }, 401);
    }

    const negocioId = String(u.negocio_id);
    const email = posEmail(username, negocioId);

    const created = await fetch(`${url}/auth/v1/admin/users`, {
      method: "POST",
      headers: admin,
      body: JSON.stringify({
        email,
        password,
        email_confirm: true,
        app_metadata: { negocio_id: negocioId, username },
        user_metadata: { username },
      }),
    });
    if (!created.ok && created.status !== 422) {
      const t = await created.text();
      return json({ error: "auth_create", status: created.status, body: t }, 502);
    }
    if (created.status === 422) {
      const listed = await fetch(
        `${url}/auth/v1/admin/users?page=1&per_page=200`,
        { headers: admin },
      );
      const data = await listed.json();
      const existing = (data.users ?? []).find((x: { email?: string }) =>
        x.email === email
      );
      if (!existing?.id) {
        return json({ error: "auth_lookup" }, 502);
      }
      const upd = await fetch(`${url}/auth/v1/admin/users/${existing.id}`, {
        method: "PUT",
        headers: admin,
        body: JSON.stringify({
          password,
          email_confirm: true,
          app_metadata: { negocio_id: negocioId, username },
        }),
      });
      if (!upd.ok) {
        return json({ error: "auth_update", status: upd.status }, 502);
      }
    }

    const tok = await fetch(`${url}/auth/v1/token?grant_type=password`, {
      method: "POST",
      headers: {
        apikey: anon,
        Authorization: `Bearer ${anon}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, password }),
    });
    const tj = await tok.json();
    const token = tj.access_token as string | undefined;
    if (!tok.ok || !token) {
      return json({ error: "auth_token", status: tok.status, body: tj }, 502);
    }

    return json({
      token,
      expires_in: tj.expires_in ?? 3600,
      negocio_id: negocioId,
      username,
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
