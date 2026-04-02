import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const resendApiKey = Deno.env.get("RESEND_API_KEY") ?? "";
const deleteFromEmail = Deno.env.get("ACCOUNT_DELETE_FROM_EMAIL") ?? "";
const deleteFromName = Deno.env.get("ACCOUNT_DELETE_FROM_NAME") ?? "SquaredAway";
const defaultRedirectUrl = Deno.env.get("ACCOUNT_DELETE_REDIRECT_URL") ?? "squaredaway://auth-callback";

const supabase = createClient(supabaseUrl, supabaseServiceKey);

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (req.method === "POST") {
      return await handleDeletionRequest(req);
    }

    if (req.method === "GET") {
      return await handleDeletionConfirmation(req);
    }

    return jsonResponse({ error: "Method not allowed." }, 405);
  } catch (error) {
    console.error("request-account-deletion error", error);
    return jsonResponse({ error: "Internal error. Please try again." }, 500);
  }
});

async function handleDeletionRequest(req: Request) {
  if (!resendApiKey || !deleteFromEmail) {
    return jsonResponse(
      { error: "Delete confirmation email is not configured yet." },
      500,
    );
  }

  const jwt = extractBearerToken(req.headers.get("Authorization"));
  if (!jwt) {
    return jsonResponse({ error: "Missing authorization token." }, 401);
  }

  const { data: authData, error: authError } = await supabase.auth.getUser(jwt);
  if (authError || !authData.user) {
    return jsonResponse({ error: "Unauthorized request." }, 401);
  }

  const email = authData.user.email?.trim();
  if (!email) {
    return jsonResponse({ error: "No email is attached to this account." }, 400);
  }

  const body = await readJsonBody(req);
  const redirectUrl = sanitizeRedirectUrl(body.redirect_url);
  const rawToken = crypto.randomUUID().replaceAll("-", "") + crypto.randomUUID().replaceAll("-", "");
  const tokenHash = await sha256(rawToken);
  const expiresAt = new Date(Date.now() + 30 * 60 * 1000).toISOString();

  await supabase
    .from("account_deletion_requests")
    .delete()
    .eq("user_id", authData.user.id)
    .is("consumed_at", null);

  const { error: insertError } = await supabase
    .from("account_deletion_requests")
    .insert({
      user_id: authData.user.id,
      token_hash: tokenHash,
      expires_at: expiresAt,
    });

  if (insertError) {
    console.error("request-account-deletion insert error", insertError);
    return jsonResponse({ error: "Couldn't prepare your delete confirmation request." }, 500);
  }

  const confirmUrl = new URL(req.url);
  confirmUrl.searchParams.set("token", rawToken);
  confirmUrl.searchParams.set("redirect_url", redirectUrl);

  const resendResponse = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: `${deleteFromName} <${deleteFromEmail}>`,
      to: [email],
      subject: "Confirm your SquaredAway account deletion",
      html: renderDeleteEmail(confirmUrl.toString(), expiresAt),
      text: [
        "Tap the link below to permanently delete your SquaredAway account.",
        "",
        confirmUrl.toString(),
        "",
        `This link expires at ${new Date(expiresAt).toUTCString()}.`,
      ].join("\n"),
    }),
  });

  if (!resendResponse.ok) {
    const resendBody = await resendResponse.text();
    console.error("request-account-deletion resend error", resendBody);
    await supabase
      .from("account_deletion_requests")
      .delete()
      .eq("token_hash", tokenHash);
    return jsonResponse({ error: "Couldn't send the delete confirmation email." }, 500);
  }

  return jsonResponse({ message: "Delete confirmation email sent." }, 200);
}

async function handleDeletionConfirmation(req: Request) {
  const url = new URL(req.url);
  const token = url.searchParams.get("token")?.trim();
  const redirectUrl = sanitizeRedirectUrl(url.searchParams.get("redirect_url"));

  if (!token) {
    return htmlResponse("Missing delete token.", 400);
  }

  const tokenHash = await sha256(token);
  const { data: requestRow, error: requestError } = await supabase
    .from("account_deletion_requests")
    .select("id, user_id, expires_at, consumed_at")
    .eq("token_hash", tokenHash)
    .maybeSingle();

  if (requestError) {
    console.error("request-account-deletion lookup error", requestError);
    return htmlResponse("We couldn't verify this delete link. Please request a new one.", 400);
  }

  if (!requestRow || requestRow.consumed_at) {
    return htmlResponse("This delete link has already been used or is no longer valid.", 400);
  }

  if (new Date(requestRow.expires_at).getTime() < Date.now()) {
    return htmlResponse("This delete link has expired. Please request a new one.", 400);
  }

  const consumedAt = new Date().toISOString();
  const { data: updatedRows, error: updateError } = await supabase
    .from("account_deletion_requests")
    .update({ consumed_at: consumedAt })
    .eq("id", requestRow.id)
    .is("consumed_at", null)
    .select("id");

  if (updateError || !updatedRows || updatedRows.length == 0) {
    console.error("request-account-deletion consume error", updateError);
    return htmlResponse("This delete link is no longer available. Please request a new one.", 400);
  }

  const { error: deleteError } = await supabase.auth.admin.deleteUser(requestRow.user_id);
  if (deleteError) {
    console.error("request-account-deletion delete user error", deleteError);
    return htmlResponse("We couldn't delete this account. Please request a new link and try again.", 500);
  }

  const redirect = new URL(redirectUrl);
  redirect.searchParams.set("action", "account_deleted");
  return Response.redirect(redirect.toString(), 302);
}

function extractBearerToken(header: string | null) {
  if (!header) return null;
  const [scheme, token] = header.split(" ");
  if (scheme?.toLowerCase() !== "bearer" || !token) {
    return null;
  }
  return token;
}

async function readJsonBody(req: Request) {
  try {
    return await req.json() as { redirect_url?: string };
  } catch {
    return {};
  }
}

function sanitizeRedirectUrl(candidate: string | null | undefined) {
  const resolved = candidate?.trim() || defaultRedirectUrl;
  return resolved.startsWith("squaredaway://auth-callback")
    ? resolved
    : defaultRedirectUrl;
}

async function sha256(value: string) {
  const encoded = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", encoded);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function renderDeleteEmail(confirmUrl: string, expiresAt: string) {
  return `
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; color: #111827; line-height: 1.6;">
      <h2 style="margin-bottom: 12px;">Confirm account deletion</h2>
      <p>You requested to permanently delete your SquaredAway account and linked readiness data.</p>
      <p>This action cannot be undone.</p>
      <p style="margin: 24px 0;">
        <a
          href="${confirmUrl}"
          style="display: inline-block; background: #dc2626; color: #ffffff; text-decoration: none; padding: 12px 18px; border-radius: 10px; font-weight: 600;"
        >
          Delete My Account
        </a>
      </p>
      <p>If the button does not work, paste this link into your browser:</p>
      <p><a href="${confirmUrl}">${confirmUrl}</a></p>
      <p>This link expires at ${new Date(expiresAt).toUTCString()}.</p>
    </div>
  `;
}

function jsonResponse(payload: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function htmlResponse(message: string, status: number) {
  return new Response(
    `
      <!doctype html>
      <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <title>SquaredAway</title>
        </head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #050816; color: #f8fafc; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 24px;">
          <div style="max-width: 480px; text-align: center;">
            <h1 style="margin-bottom: 12px;">SquaredAway</h1>
            <p style="color: #cbd5e1;">${message}</p>
          </div>
        </body>
      </html>
    `,
    {
      status,
      headers: {
        "Content-Type": "text/html; charset=utf-8",
      },
    },
  );
}
