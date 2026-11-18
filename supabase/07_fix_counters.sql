-- Run once in the Supabase SQL Editor (after 05 and 06).
-- Fixes the "recipes uploaded" and "likes" numbers on profiles. They are
-- stored counters that only changed when a recipe was created or deleted, so
-- handing the library recipes to the admin left the admin at 0.
-- Now they also follow a recipe when its owner changes, and everyone is
-- recounted from the real recipes right away.

create or replace function on_recipe_count() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update profiles set recipes_count = recipes_count + 1 where id = new.uploader_id;
  elsif tg_op = 'DELETE' then
    update profiles set recipes_count = greatest(0, recipes_count - 1) where id = old.uploader_id;
  elsif new.uploader_id is distinct from old.uploader_id then
    update profiles set recipes_count = greatest(0, recipes_count - 1),
                        total_likes   = greatest(0, total_likes - old.like_count)
     where id = old.uploader_id;
    update profiles set recipes_count = recipes_count + 1,
                        total_likes   = total_likes + new.like_count
     where id = new.uploader_id;
  end if;
  return null;
end $$;

drop trigger if exists recipes_count_after on recipes;
create trigger recipes_count_after
  after insert or delete or update of uploader_id on recipes
  for each row execute function on_recipe_count();

-- Recount everyone now.
update profiles p set
  recipes_count = (select count(*) from recipes r where r.uploader_id = p.id),
  total_likes   = coalesce((select sum(r.like_count) from recipes r where r.uploader_id = p.id), 0);

-- Check: each account with its recipe count.
select username, recipes_count, total_likes from profiles order by recipes_count desc;
