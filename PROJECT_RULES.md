# CookAI Project Rules

These rules apply to all work on CookAI from this point forward.

1. **DesignReference is the VISUAL reference only** (colors, fonts, spacing, radii, shadows, layout, animations). Build a real production app, not a demo.
2. **Do NOT port prototype-only elements**: "Prototype tip" boxes, quick-fill/demo buttons, instructional helper text aimed at testers, the fake iPhone frame/notch/home indicator, hardcoded "Alex" or other hardcoded current-user data, fake placeholder values that look like real input, and code comments like "for prototype purposes".
3. **Use real placeholder text** (e.g. "Enter your password"), never values that look already filled in.
4. **The current user's name, email, and role always come from AuthController**, never hardcoded. Guests get neutral text (e.g. "Good morning 👋").
5. **Mock data lives ONLY in MockData/** and is accessed ONLY through the Service protocols, so Supabase can replace it later. Views never reference MockData directly (except in `#Preview` blocks).
6. **Finals-only features** (Community, Upload, Messages, Notifications, Admin) keep their entry points visible but open `ComingSoonScreen` for the midterm.
7. **MVC**: Views are UI only; state and actions live in `@Observable` Controllers; data access lives in Services.
8. **Every async action has a loading state and a user-friendly error state.** No silent failures.
9. **Build must pass with no errors before committing.** Commit at the end of every task with a descriptive message. Never push to a remote.
10. If something in the prototype is demo-only or conflicts with these rules, skip it and mention it in the summary.
