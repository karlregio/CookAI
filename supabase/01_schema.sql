-- CookAI database schema (Supabase / Postgres)
-- Paste into Supabase > SQL Editor > New query > Run. Safe to run once on an empty project.
-- Column names match the Swift models' CodingKeys (snake_case).

create extension if not exists "pgcrypto";

-- ───────── Types ─────────
create type user_role         as enum ('standard', 'admin');
create type recipe_source     as enum ('library', 'ai_generated', 'community');
create type recipe_status     as enum ('visible', 'flagged', 'removed');
create type difficulty_level  as enum ('Easy', 'Medium', 'Hard');
create type notification_type as enum ('cooked', 'liked', 'commented', 'saved', 'flagged', 'removed');

-- ───────── Tables ─────────
create table profiles (
  id               uuid primary key references auth.users(id) on delete cascade,
  username         text unique not null,
  display_name     text not null,
  email            text not null,
  role             user_role not null default 'standard',
  avatar_color_hex text not null default '#D9713C',
  bio              text not null default '',
  is_verified      boolean not null default false,
  recipes_count    int not null default 0,
  total_likes      int not null default 0,
  created_at       timestamptz not null default now()
);

create table recipes (
  id                  uuid primary key default gen_random_uuid(),
  title               text not null,
  cuisine             text not null,
  cook_time_minutes   int  not null check (cook_time_minutes > 0),
  difficulty          difficulty_level not null default 'Easy',
  servings            int  not null default 2 check (servings > 0),
  image_url           text not null,
  source              recipe_source not null default 'community',
  status              recipe_status not null default 'visible',
  moderation_reason   text,
  moderated_by        uuid references profiles(id),
  uploader_id         uuid not null references profiles(id) on delete cascade,
  ingredients         jsonb not null default '[]',  -- [{id,name,quantity,category}]
  steps               jsonb not null default '[]',  -- [{id,order,text,timer_seconds,action}]
  rating_average      numeric(3,2) not null default 0,
  rating_count        int not null default 0,
  like_count          int not null default 0,
  save_count          int not null default 0,
  created_at          timestamptz not null default now()
);
create index recipes_uploader_idx on recipes(uploader_id);
create index recipes_cuisine_idx  on recipes(cuisine);
create index recipes_status_idx   on recipes(status, source);

create table ratings (
  recipe_id  uuid references recipes(id) on delete cascade,
  user_id    uuid references profiles(id) on delete cascade,
  stars      int not null check (stars between 1 and 5),
  created_at timestamptz not null default now(),
  primary key (recipe_id, user_id)
);

create table likes (
  recipe_id uuid references recipes(id) on delete cascade,
  user_id   uuid references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (recipe_id, user_id)
);

create table saves (
  recipe_id uuid references recipes(id) on delete cascade,
  user_id   uuid references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (recipe_id, user_id)
);

create table cook_history (
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid not null references profiles(id) on delete cascade,
  recipe_id uuid not null references recipes(id) on delete cascade,
  cooked_at timestamptz not null default now(),
  rating    int check (rating between 1 and 5),
  note      text
);
create index cook_history_user_idx on cook_history(user_id, cooked_at desc);

create table grocery_items (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references profiles(id) on delete cascade,
  name         text not null,
  recipe_title text not null default '',
  category     text not null default 'Other',
  is_checked   boolean not null default false,
  created_at   timestamptz not null default now()
);

create table comments (
  id         uuid primary key default gen_random_uuid(),
  recipe_id  uuid not null references recipes(id) on delete cascade,
  author_id  uuid not null references profiles(id) on delete cascade,
  text       text not null check (length(trim(text)) > 0),
  created_at timestamptz not null default now()
);
create index comments_recipe_idx on comments(recipe_id, created_at);

create table notifications (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references profiles(id) on delete cascade, -- recipient
  type          notification_type not null,
  from_user_id  uuid not null references profiles(id) on delete cascade,
  recipe_id     uuid not null references recipes(id) on delete cascade,
  recipe_name   text not null,
  admin_reason  text,
  is_read       boolean not null default false,
  created_at    timestamptz not null default now()
);
create index notifications_user_idx on notifications(user_id, created_at desc);

create table conversations (
  id              uuid primary key default gen_random_uuid(),
  user_a          uuid not null references profiles(id) on delete cascade,
  user_b          uuid not null references profiles(id) on delete cascade,
  last_message    text not null default '',
  last_message_at timestamptz not null default now(),
  check (user_a < user_b),
  unique (user_a, user_b)
);

create table messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(id) on delete cascade,
  sender_id       uuid not null references profiles(id) on delete cascade,
  text            text not null check (length(trim(text)) > 0),
  sent_at         timestamptz not null default now(),
  is_read         boolean not null default false
);
create index messages_conv_idx on messages(conversation_id, sent_at);

-- ───────── Helpers ─────────
create or replace function is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin');
$$;

-- New auth user -> profile row (role is always 'standard'; promote admins manually).
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, username, display_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1) || '_' || substr(new.id::text, 1, 4)),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    new.email
  );
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

-- Create a notification for the recipe's uploader (skips self-actions).
create or replace function notify_uploader(p_type notification_type, p_recipe uuid, p_from uuid, p_reason text default null)
returns void language plpgsql security definer set search_path = public as $$
declare r recipes%rowtype;
begin
  select * into r from recipes where id = p_recipe;
  if found and r.uploader_id <> p_from then
    insert into notifications (user_id, type, from_user_id, recipe_id, recipe_name, admin_reason)
    values (r.uploader_id, p_type, p_from, r.id, r.title, p_reason);
  end if;
end $$;

-- ───────── Triggers: counters + notifications ─────────
create or replace function on_like_change() returns trigger
language plpgsql security definer set search_path = public as $$
declare rid uuid := coalesce(new.recipe_id, old.recipe_id); up uuid; d int := case when tg_op = 'INSERT' then 1 else -1 end;
begin
  update recipes set like_count = greatest(0, like_count + d) where id = rid returning uploader_id into up;
  update profiles set total_likes = greatest(0, total_likes + d) where id = up;
  if tg_op = 'INSERT' then perform notify_uploader('liked', rid, new.user_id); end if;
  return null;
end $$;
create trigger likes_after after insert or delete on likes for each row execute function on_like_change();

create or replace function on_save_change() returns trigger
language plpgsql security definer set search_path = public as $$
declare rid uuid := coalesce(new.recipe_id, old.recipe_id);
begin
  update recipes set save_count = greatest(0, save_count + case when tg_op = 'INSERT' then 1 else -1 end) where id = rid;
  if tg_op = 'INSERT' then perform notify_uploader('saved', rid, new.user_id); end if;
  return null;
end $$;
create trigger saves_after after insert or delete on saves for each row execute function on_save_change();

create or replace function on_rating_change() returns trigger
language plpgsql security definer set search_path = public as $$
declare rid uuid := coalesce(new.recipe_id, old.recipe_id);
begin
  update recipes set
    rating_count   = (select count(*) from ratings where recipe_id = rid),
    rating_average = coalesce((select round(avg(stars)::numeric, 2) from ratings where recipe_id = rid), 0)
  where id = rid;
  return null;
end $$;
create trigger ratings_after after insert or update or delete on ratings for each row execute function on_rating_change();

create or replace function on_comment_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin perform notify_uploader('commented', new.recipe_id, new.author_id); return null; end $$;
create trigger comments_after after insert on comments for each row execute function on_comment_insert();

create or replace function on_history_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin perform notify_uploader('cooked', new.recipe_id, new.user_id); return null; end $$;
create trigger history_after after insert on cook_history for each row execute function on_history_insert();

create or replace function on_recipe_count() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then update profiles set recipes_count = recipes_count + 1 where id = new.uploader_id;
  else update profiles set recipes_count = greatest(0, recipes_count - 1) where id = old.uploader_id; end if;
  return null;
end $$;
create trigger recipes_count_after after insert or delete on recipes for each row execute function on_recipe_count();

-- Stop non-admin clients from editing moderation fields, counters, or ownership directly.
create or replace function protect_recipe_fields() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if pg_trigger_depth() = 1 and not is_admin() then
    new.status := old.status; new.moderation_reason := old.moderation_reason; new.moderated_by := old.moderated_by;
    new.uploader_id := old.uploader_id; new.source := old.source;
    new.rating_average := old.rating_average; new.rating_count := old.rating_count;
    new.like_count := old.like_count; new.save_count := old.save_count;
  end if;
  return new;
end $$;
create trigger recipes_protect before update on recipes for each row execute function protect_recipe_fields();

create or replace function protect_profile_fields() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if pg_trigger_depth() = 1 then
    new.role := old.role; new.is_verified := old.is_verified;
    new.recipes_count := old.recipes_count; new.total_likes := old.total_likes; new.email := old.email;
  end if;
  return new;
end $$;
create trigger profiles_protect before update on profiles for each row execute function protect_profile_fields();

-- Community uploads must be created as the caller, as 'community' or 'ai_generated', and visible.
create or replace function force_recipe_defaults() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then
    if new.source = 'library' then new.source := 'community'; end if;
    new.status := 'visible'; new.moderation_reason := null; new.moderated_by := null;
    new.rating_average := 0; new.rating_count := 0; new.like_count := 0; new.save_count := 0;
  end if;
  return new;
end $$;
create trigger recipes_defaults before insert on recipes for each row execute function force_recipe_defaults();

-- Admin moderation: Approve (visible) / Flag / Remove. Flag and Remove require a reason.
create or replace function moderate_recipe(p_recipe uuid, p_status recipe_status, p_reason text default null)
returns recipes language plpgsql security definer set search_path = public as $$
declare r recipes;
begin
  if not is_admin() then raise exception 'Admins only'; end if;
  if p_status in ('flagged','removed') and coalesce(trim(p_reason), '') = '' then
    raise exception 'A reason is required to flag or remove a recipe';
  end if;
  update recipes set status = p_status,
         moderation_reason = case when p_status = 'visible' then null else p_reason end,
         moderated_by = auth.uid()
   where id = p_recipe returning * into r;
  if p_status = 'flagged' then
    insert into notifications (user_id, type, from_user_id, recipe_id, recipe_name, admin_reason)
    values (r.uploader_id, 'flagged', auth.uid(), r.id, r.title, p_reason);
  elsif p_status = 'removed' then
    insert into notifications (user_id, type, from_user_id, recipe_id, recipe_name, admin_reason)
    values (r.uploader_id, 'removed', auth.uid(), r.id, r.title, p_reason);
  end if;
  return r;
end $$;

-- Keep conversation preview in sync.
create or replace function on_message_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update conversations set last_message = new.text, last_message_at = new.sent_at where id = new.conversation_id;
  return null;
end $$;
create trigger messages_after after insert on messages for each row execute function on_message_insert();

-- ───────── Row Level Security ─────────
alter table profiles       enable row level security;
alter table recipes        enable row level security;
alter table ratings        enable row level security;
alter table likes          enable row level security;
alter table saves          enable row level security;
alter table cook_history   enable row level security;
alter table grocery_items  enable row level security;
alter table comments       enable row level security;
alter table notifications  enable row level security;
alter table conversations  enable row level security;
alter table messages       enable row level security;

-- profiles: readable by signed-in users; you edit only your own (protected fields locked by trigger)
create policy profiles_read   on profiles for select to authenticated using (true);
create policy profiles_update on profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- recipes: visible ones to everyone signed in; owners see their own; admins see all
create policy recipes_read on recipes for select to authenticated
  using (status = 'visible' or uploader_id = auth.uid() or is_admin());
create policy recipes_insert on recipes for insert to authenticated
  with check (uploader_id = auth.uid() or is_admin());
create policy recipes_update on recipes for update to authenticated
  using (uploader_id = auth.uid() or is_admin());
create policy recipes_delete on recipes for delete to authenticated
  using (uploader_id = auth.uid() or is_admin());

-- ratings / likes / saves: public read, each user manages only their own rows
create policy ratings_read  on ratings for select to authenticated using (true);
create policy ratings_write on ratings for all    to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy likes_read    on likes   for select to authenticated using (true);
create policy likes_write   on likes   for all    to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy saves_own     on saves   for all    to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- private per-user data
create policy history_own on cook_history  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy grocery_own on grocery_items for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- comments: public read; write as yourself; delete your own (or admin)
create policy comments_read   on comments for select to authenticated using (true);
create policy comments_insert on comments for insert to authenticated with check (author_id = auth.uid());
create policy comments_delete on comments for delete to authenticated using (author_id = auth.uid() or is_admin());

-- notifications: only the recipient reads / marks read (inserts happen via security-definer triggers)
create policy notif_read   on notifications for select to authenticated using (user_id = auth.uid());
create policy notif_update on notifications for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- chat: only the two participants
create policy conv_read   on conversations for select to authenticated using (auth.uid() in (user_a, user_b));
create policy conv_insert on conversations for insert to authenticated with check (auth.uid() in (user_a, user_b));
create policy msg_read    on messages for select to authenticated
  using (exists (select 1 from conversations c where c.id = conversation_id and auth.uid() in (c.user_a, c.user_b)));
create policy msg_insert  on messages for insert to authenticated
  with check (sender_id = auth.uid() and exists (select 1 from conversations c where c.id = conversation_id and auth.uid() in (c.user_a, c.user_b)));

-- ───────── Storage: recipe photos ─────────
insert into storage.buckets (id, name, public) values ('recipe-images', 'recipe-images', true)
on conflict (id) do nothing;
create policy recipe_images_read   on storage.objects for select using (bucket_id = 'recipe-images');
create policy recipe_images_upload on storage.objects for insert to authenticated
  with check (bucket_id = 'recipe-images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy recipe_images_delete on storage.objects for delete to authenticated
  using (bucket_id = 'recipe-images' and (storage.foldername(name))[1] = auth.uid()::text);

-- ───────── Realtime (chat + notifications) ─────────
alter publication supabase_realtime add table messages, notifications;

-- AFTER running: make your admin account.
--   1) Sign up in the app (or Auth > Users > Add user) with the admin email.
--   2) Run:  update profiles set role = 'admin', is_verified = true where email = 'your-admin@email.com';
