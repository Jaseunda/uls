# ULS — What's New

Small, human notes about what changed.  Dates are when the update shipped.

## 0.27.52 — 2026-09-22
- Logging in is smarter: ULS finds your connected phone by itself, even if
  you've never set anything up.  You pick your phone, pick your Linux, and
  you're in.
- If a phone can't run Linux, ULS now explains why (some Samsung phones
  block the technology ULS uses) instead of dropping you back at a bare
  prompt.
- Installing ULS now asks you to agree to the licence before starting, and
  can add one missing helper tool (adb) for you if you say yes.
- Refreshing ULS on your phone is a single command:  `uls upgrade`.

## 0.20.15 — 22 Sep 2026
- `uls login` opens a real GNU/Linux on your Android phone — no rooting, no
  app to install.
- `uls upgrade` re-syncs ULS on your phone in a few seconds.
- A friendly installer with three easy steps — no scary technical details.

## 0.20.x — earlier
- ULS runs a complete Linux (Arch Linux ARM and friends) on your Android
  phone from the Mac's USB cable.
- You can install, update and remove everything from your Mac.