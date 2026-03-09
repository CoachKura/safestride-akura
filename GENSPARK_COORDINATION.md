# Genspark Coordination Brief (SafeStride Login)

Date: 2026-03-09
Project path: `C:\safestride\webapp`
Target file: `login.html`

## Current state already implemented
- Added favicon data URI to reduce missing favicon requests.
- Updated Supabase URL and anon key to match `public/signup.html`.
- Switched login RPC call to use a dedicated `supabaseClient` instance.
- Removed console logs that exposed test credentials.
- Improved session restore logic to check both `localStorage` and `sessionStorage`, with invalid JSON cleanup.

## Known open item
- Footer text still shows mojibake (copyright symbol appears as garbled text) in `login.html`.

## Prompt to send to Genspark
Use this exact prompt in the provided Genspark agent chat:

---
I am maintaining `login.html` for SafeStride.

Please do a focused security and reliability review for this login flow:
1) Supabase client usage and RPC auth pattern (`authenticate_user`) safety.
2) Client-side session handling (`localStorage` vs `sessionStorage`) and tamper risks.
3) Error handling/logging that might leak sensitive info.
4) Recommended secure forgot-password implementation for Supabase.
5) A minimal patch to fix mojibake in footer text (garbled copyright symbol -> `&copy;`) robustly.

Constraints:
- Keep changes minimal and production-safe.
- Return actionable patch snippets for `login.html` only.
- Include a short test checklist for browser console + network panel.
---

## What to bring back from Genspark
- Their exact patch snippet(s) for `login.html`.
- Any new security findings with severity (`high`, `medium`, `low`).
- Their test checklist.

