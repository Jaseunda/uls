# ULS — What's New

Small, human notes about what changed.  Dates are when the update shipped.

## 0.78.138 — 2026-09-24
- **Enhanced `ncode` / VS Code Replica Environment for Arq**:
  - Automatically provisions the full editor plugin ecosystem, custom themes, and keybindings on deploy and upgrade.
  - Directory opens (`code .`) now reliably launch directly into the Ayu Mirage editor layout with pinned file tree navigation without falling back to stock directory buffers.
- **Pure Distro Separation**: Arq productivity tools, custom developer environments, and visual brandings are strictly isolated to Arq containers, ensuring all other Linux distributions (Arch, Ubuntu, Debian, Alpine) remain completely stock.
- **Streamlined Container Storage**: Cleaned up internal documentation directories from device containers to minimize container disk footprint.
- **Clean Terminal Interruption**: Pressing Ctrl+C during any setup, upgrade, or menu flow cleanly restores the terminal cursor and exits immediately without error traces.

## 0.70.117 — 2026-09-24
- **Live Elapsed Timer in `uls deploy`**: Added a live elapsed seconds and minutes timer during sandbox installation, download preparation, ADB transfers, and on-device unpacking so you always know operations are progressing without terminal lockup.
- **Native `ncode` Editor for Arq**:
  - Rebranded editor workflow to `ncode`, natively aliasing `code`, `code .`, and `lvim`.
  - Hardcoded Ayu Mirage (Dark) & Ayu Light (Light) palette with sleek bordered floating windows and seamless 1px sidebar divider.
  - Full mouse click, cursor positioning, and scroll wheel support.
  - Safe folder navigation with Left/Right arrow keys (`→` to expand/open, `←` to collapse) with strict root project locking to prevent accidental escape to Linux `/`.
  - Suppressed all benign tree-sitter and illuminate `nil parent` warnings and popup interruptions.
  - Pure VS Code shortcuts without modal escapes (`Ctrl+S`, `Ctrl+P`, `Ctrl+B`, `Ctrl+F`, `Ctrl+Z`, `Ctrl+C`/`X`/`V`).
- **Dedicated Arq Container Banner**: `uls login arq` now specifically renders the cyberpunk slash sweep ASCII banner with the violet-to-cyan gradient on container startup.
- **Interactive Checkbox Uninstaller**: `uls uninstall` features interactive multi-selection checkboxes (`Space` to toggle, `a` to select/deselect all, `Enter` to confirm, `←` to cancel) so you can selectively remove specific Linux distros without wiping your other containers or the core ULS runtime.
- **SSH Multi-Container Port Isolation**: `uls ssh` now tracks active container rootfs instances, preventing port collisions and enabling side-by-side SSH sessions across multiple Linux containers on the same device.

## 0.56.87 — 2026-09-23
- Added interactive arrow-key navigation interface: navigate menus and options using Up/Down arrows (`↑`/`↓`), select or enter with Right arrow or Enter (`→`/`↵`), and go back or cancel with Left arrow (`←`/`q`).
- Added pre-installed native Docker userland engine: run Docker containers (`docker run`, `docker pull`, `docker images`, `docker ps`) directly inside your Linux containers without kernel permissions or background daemon crashes.
- Automatic multi-device upgrade: `uls upgrade` now automatically refreshes all connected devices and installed containers without interactive prompts.

## 0.51.76 — 2026-09-23
- Added `uls install update` command to seamlessly update the ULS binary and automatically refresh all connected devices.
- Automatic version checking: ULS now checks for updates in the background and notifies you when a newer version is available.
- Fixed an issue on macOS where updating binaries in-place could cause crashes (`killed`).
- Resolved duplicate device detection when devices are connected simultaneously over Wi-Fi and USB.
- Enhanced SSH over Wi-Fi (`uls ssh`): Dropbear remote shell and terminal sessions now run reliably without unexpected connection resets.
- Added full support for forced and scripted terminal sessions (`ssh -tt`) over Wi-Fi with reliable input/output streaming and clean exit status propagation.
- Dropbear is now the default lightweight SSH server on device, delivering immediate cable-free access with minimal memory footprint.

## 0.47.64 — 2026-09-23
- Agent reference docs (`AGENTS.md`, `SKILL.md`, `USER.md`) are now shipped
  into each container at `/root/agents/` during deploy, so agents running
  inside the Linux environment can read them directly.
- Softened "proot" terminology in user-facing docs to "sandboxed container" /
  "sandbox" — the technology name doesn't matter to users, and some agents
  were skipping work assuming proot limitations.
- The on-device KNOX error now says "Linux sandbox was blocked" instead of
  "proot was blocked".
- `make distros` is the new shorthand for `make proot-distros`.
- `uls login` now shows installed Linux images across **all** connected phones,
  so you can pick Arch on your Pixel even if your Samsung only has Ubuntu.
- Deploying Ubuntu/Debian/Alpine no longer runs Arch-only steps (pacman.conf,
  pacman-key, keyring bootstrap) that don't apply — no more noise from
  "can't open file /etc/pacman.conf" on apt-based distros.
- Bash aliases in the container now match the distro: `update`/`install` use
  pacman for Arch, apt-get for Ubuntu/Debian, and apk for Alpine.
- The builder+n1 key (77193F152BDBE6A6) is now fetched entirely inside the
  container over HKPS — the host-side ADB push fallback is gone.
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