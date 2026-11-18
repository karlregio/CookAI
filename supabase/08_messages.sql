-- 08: let a message's recipient mark it as read (and nothing else).
-- Run once in the Supabase SQL Editor.

-- Only the person who RECEIVED a message (the other member of the conversation) may update it...
drop policy if exists msg_update on messages;
create policy msg_update on messages for update to authenticated
  using (
    sender_id <> auth.uid()
    and exists (select 1 from conversations c where c.id = conversation_id and auth.uid() in (c.user_a, c.user_b))
  )
  with check (
    sender_id <> auth.uid()
    and exists (select 1 from conversations c where c.id = conversation_id and auth.uid() in (c.user_a, c.user_b))
  );

-- ...and the only column they may change is is_read (the text can never be edited).
revoke update on messages from authenticated;
grant update (is_read) on messages to authenticated;
