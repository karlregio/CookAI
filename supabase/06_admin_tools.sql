-- Run once in the Supabase SQL Editor (after 05).
--
-- 1. Email addresses stop being public. Everyone can still read usernames,
--    names, avatars and stats; only the email column is hidden.
-- 2. admin_user_emails(): admins can look up an uploader's email.
-- 3. admin_stats(): live numbers for the admin dashboard cards.

-- 1. Hide the email column from signed-out visitors and signed-in users.
revoke select on profiles from anon, authenticated;
grant select (id, username, display_name, role, avatar_color_hex, bio,
              is_verified, recipes_count, total_likes, created_at)
  on profiles to anon, authenticated;

-- 2. Admin-only email lookup.
create or replace function admin_user_emails(p_ids uuid[])
returns table (user_id uuid, user_email text)
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'Admins only'; end if;
  return query select p.id, p.email from profiles p where p.id = any(p_ids);
end $$;

-- 3. Live numbers for the dashboard cards.
create or replace function admin_stats()
returns json language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'Admins only'; end if;
  return json_build_object(
    'total_users',       (select count(*) from profiles),
    'users_today',       (select count(*) from profiles where created_at >= date_trunc('day', now())),
    'total_recipes',     (select count(*) from recipes),
    'recipes_today',     (select count(*) from recipes where created_at >= date_trunc('day', now())),
    'recipes_this_week', (select count(*) from recipes where source <> 'library' and created_at >= now() - interval '7 days'),
    'flagged',           (select count(*) from recipes where status = 'flagged')
  );
end $$;
