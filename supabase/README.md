# CookAI backend (Supabase)

Run in the Supabase SQL Editor, in order:

1. `01_schema.sql` — tables, security rules (RLS), triggers, photo storage bucket.
2. `02_fixes_and_seed.sql` — guest read access, admin-rule fix, seed recipes.
3. `03_auto_confirm.sql` — optional: confirm new accounts automatically while developing.

Edge Function `functions/ai/index.ts` — the Gemini gateway. Deploy it as a function named `ai`
and set the secret `GEMINI_API_KEY` (and optionally `GEMINI_MODEL`).
