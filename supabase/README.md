# CookAI backend (Supabase)

Run in the Supabase SQL Editor, in order:

1. `01_schema.sql` — tables, security rules (RLS), triggers, photo storage bucket.
2. `02_fixes_and_seed.sql` — guest read access, admin-rule fix, seed recipes.
3. `03_auto_confirm.sql` — optional: confirm new accounts automatically while developing.
4. `04_moderation_rules.sql` — admins can't moderate their own recipes.
5. `05_remove_demo_data.sql` — removes the seeded demo cooks and recipes so only real data remains.
6. `06_admin_tools.sql` — live admin dashboard numbers, and hides email addresses from everyone but admins.

Edge Function `functions/ai/index.ts` — the Gemini gateway. Deploy it as a function named `ai`
and set the secrets `GEMINI_API_KEY`, `GEMINI_MODEL` (e.g. `gemini-3.5-flash-lite`) and optionally `GEMINI_FALLBACK_MODEL`.
