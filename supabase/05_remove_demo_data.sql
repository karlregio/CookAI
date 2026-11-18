-- Run once in the Supabase SQL Editor.
-- Removes the demo community data that was seeded for development (the 6 fake
-- cooks and their recipes, e.g. Pineapple Fried Rice, Smash Burgers) so the app
-- only shows what real accounts upload.
--
-- KEEPS: the 12 library recipes (handed to the admin account) and every real
-- account you created through the app.
-- REMOVES: the seeded accounts (ids 00000000-0000-0000-0000-0000000000NN),
-- their recipes, and anything attached to them (likes, comments, ratings...).

do $$
declare
  admin_id uuid;
begin
  select id into admin_id from profiles where email = 'admin@cookai.com';
  if admin_id is null then
    raise exception 'admin@cookai.com not found - create that account first';
  end if;

  -- 1. The library recipes stay, owned by the admin.
  update recipes set uploader_id = admin_id
   where source = 'library'
     and uploader_id::text like '00000000-0000-0000-0000-0000000000%';

  -- 2. Recipes first (a moderator can't be deleted while recipes point at them).
  delete from recipes
   where uploader_id::text like '00000000-0000-0000-0000-0000000000%';
  update recipes set moderated_by = null
   where moderated_by::text like '00000000-0000-0000-0000-0000000000%';

  -- 3. Then the demo accounts (their profiles and activity go with them).
  delete from auth.users
   where id::text like '00000000-0000-0000-0000-0000000000%';
end $$;

-- Check: should show only real accounts, and 12 library recipes.
select (select count(*) from profiles)                          as accounts,
       (select count(*) from recipes where source = 'library')  as library_recipes,
       (select count(*) from recipes where source <> 'library') as user_recipes;
