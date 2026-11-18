-- CookAI: skip email confirmation during development.
-- Every new account is marked confirmed the moment it is created, so Sign Up
-- in the app works with any email (no inbox needed) and Login works right away.
-- Run once in Supabase > SQL Editor. Before launch, drop the trigger and turn real confirmation on:
--   drop trigger if exists auto_confirm_new_user on auth.users;

create or replace function auto_confirm_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.email_confirmed_at := coalesce(new.email_confirmed_at, now());
  return new;
end $$;

drop trigger if exists auto_confirm_new_user on auth.users;
create trigger auto_confirm_new_user before insert on auth.users
  for each row execute function auto_confirm_new_user();

-- Also confirm any accounts you already created while confirmation was on.
update auth.users set email_confirmed_at = now() where email_confirmed_at is null;
