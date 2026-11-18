-- Run once in the Supabase SQL Editor (after 01, 02 and 03).
-- Moderation stays a check on OTHER people's content: an admin can upload
-- recipes like anyone else, but cannot flag/remove/approve their own.

create or replace function moderate_recipe(p_recipe uuid, p_status recipe_status, p_reason text default null)
returns recipes language plpgsql security definer set search_path = public as $$
declare r recipes;
begin
  if not is_admin() then raise exception 'Admins only'; end if;
  if p_status in ('flagged','removed') and coalesce(trim(p_reason), '') = '' then
    raise exception 'A reason is required to flag or remove a recipe';
  end if;
  select * into r from recipes where id = p_recipe;
  if not found then raise exception 'Recipe not found'; end if;
  if r.uploader_id = auth.uid() then
    raise exception 'You can''t moderate your own recipe';
  end if;
  update recipes set status = p_status,
         moderation_reason = case when p_status = 'visible' then null else trim(p_reason) end,
         moderated_by = auth.uid()
   where id = p_recipe returning * into r;
  if p_status = 'flagged' then
    insert into notifications (user_id, type, from_user_id, recipe_id, recipe_name, admin_reason)
    values (r.uploader_id, 'flagged', auth.uid(), r.id, r.title, trim(p_reason));
  elsif p_status = 'removed' then
    insert into notifications (user_id, type, from_user_id, recipe_id, recipe_name, admin_reason)
    values (r.uploader_id, 'removed', auth.uid(), r.id, r.title, trim(p_reason));
  end if;
  return r;
end $$;
