import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-chat-cleanup-secret",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const expected = Deno.env.get("CHAT_CLEANUP_SECRET");
  if (!expected || req.headers.get("x-chat-cleanup-secret") !== expected) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) {
    return new Response(JSON.stringify({ error: "Missing server configuration" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const cutoff = new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString();
  const results: Record<string, number> = {};

  for (const table of ["direct_messages", "group_messages"]) {
    const { data: oldRows, error: readError } = await supabase
      .from(table)
      .select("id, media_path")
      .lt("created_at", cutoff)
      .order("created_at", { ascending: true })
      .limit(500);

    if (readError) {
      return new Response(JSON.stringify({ error: readError.message, table }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (!oldRows?.length) {
      results[table] = 0;
      continue;
    }

    const paths = oldRows.map((row) => row.media_path).filter(Boolean);
    if (paths.length) {
      const { error: storageError } = await supabase.storage.from("chat-media").remove(paths);
      if (storageError) {
        return new Response(JSON.stringify({ error: storageError.message, table, files: paths.length }), {
          status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    const ids = oldRows.map((row) => row.id);
    const { error: deleteError } = await supabase.from(table).delete().in("id", ids);
    if (deleteError) {
      return new Response(JSON.stringify({ error: deleteError.message, table }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    results[table] = ids.length;
  }

  return new Response(JSON.stringify({ success: true, cutoff, deleted: results }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
