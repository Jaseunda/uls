# ULS — What's New

Small, human notes about what changed.  Dates are when the update shipped.

## 0.116.191 — 2026-09-30
- **Clickable Version & Release Links**:
  - Update notification banners and update completion notices now render clickable version links and a direct `[view changelog]` link in your terminal, opening the release page directly in your browser.
- **Clear Distro & Image Display in Pickers**:
  - The cross-device selection menus in `uls ssh`, `uls mount`, and `uls login` now display the friendly distribution name alongside the container identifier (e.g. `Arq (arq) on SM-F926B`) instead of duplicate or ambiguous directory names.
- **Resilient Distro Deployment & Package Setup**:
  - Distro deployments now automatically detect and clear lingering cryptographic agent sockets from earlier aborted sessions, preventing initialization hangs during first boot.
  - Package manager keyring setup now safely handles network and wireless ADB timeouts without crashing the deployment process, gracefully falling back to offline trusted key imports.

## 0.111.184 — 2026-09-30
- **`uls mount` — Your Linux Home as a Drive on the Mac**:
  - Mounts the container home on this Mac over SMB: a Finder window opens straight onto the mounted folder, and VS Code or any editor can open it by path. No installs, no dialogs, no root.
  - Modern macOS no longer mounts `sftp://` network drives at all — which is why earlier versions could report success while no volume ever appeared. The mount now uses macOS's native SMB stack end to end, and an SFTP server is still provisioned inside the container for command-line and editor SFTP workflows.
  - Mounts are verified before success is reported, failed or abandoned attempts no longer leave port forwards behind, and `uls mount --umount` unmounts the real volume and cleans everything up.
  - File sharing runs on its own ports inside the container, so mounting never restarts or disturbs `uls ssh` sessions (and a running SSH session no longer blocks mounting).
  - Fixed the file-transfer backends refusing to start under the sandbox's hardened process self-check — SFTP used to close the moment authentication succeeded, and the SMB server never started at all. A small compatibility layer now lets them run, delivered to existing containers automatically on the next `uls mount`.
- **`uls vnc` Device Picker**:
  - With several phones attached — or one phone reachable over both Wi-Fi and USB — `uls vnc` now asks which one to stream from, instead of failing with a misleading "no device connected". `--serial <SERIAL>` still targets a device directly.
  - Runtime output now follows the ULS design language end to end: banner up front, `::`/`✓`/`!`/`✗` status symbols with 16-color on terminals, instead of bare `uls-vnc:` lines.
  - Fixed a leftover control socket (after interrupting a session) blocking every new desktop from starting.
- **VNC Desktop Streaming (`uls vnc`)**:
  - Stream a full graphical desktop from your Android container straight to macOS over VNC with automatic port forwarding and TigerVNC client launching.
  - Zero-configuration desktop bridge with support for `--serial <SERIAL>` targeting.


## 0.105.167 — 2026-09-28
- **Broader Linux App & Package Compatibility**:
  - Enhanced system communication and local service handling, ensuring background daemons and container tools run reliably across older and newer Android phones alike. *(Contributed by Ethan Blanch, reviewed & merged by @jaseunda)*
  - Resolved file attribute and permission permission issues during package installation and archive extraction on devices with strict security policies. *(Contributed by Ethan Blanch, merged by @jaseunda)*
  - Improved file status queries for older phone kernels, preventing crashes and hangs when running modern Linux distributions. *(Contributed by Ethan Blanch, reviewed with @ItsPhysip)*
  - Hardened kernel feature detection across diverse phone architectures to ensure smooth startup on devices from Linux 4.8 up to modern Android 16. *(Co-authored by Ethan Blanch & @ItsPhysip, merged by @jaseunda)*
- **Community Developer Tooling**:
  - Added streamlined live compilation tools and container extension hooks so contributors can test enhancements directly on real devices with zero setup overhead. *(Designed & implemented by @jaseunda)*
  - Stabilized multi-architecture build pipelines for consistent performance across all supported device platforms. *(Contributed by Ethan Blanch, reviewed by @ItsPhysip, merged by @jaseunda)*
- **Changelog Audit**:
  - Verified and audited by [`Darnes`](https://darnes.notapublicfigureanymore.com/gitbot).

## 0.102.157 — 2026-09-26
- **Improved Compatibility for Package Managers on Modern Android 15 & 16 Devices**:
  - Resolves path resolution and directory lookup issues that could cause package managers (like `pacman`) to fail when initializing local databases on newer Android phone kernels.
  - Ensures clean, universal fallback across all background processes and subshells so software installs reliably out of the box. *(Contributed by Ethan Blanch)*

## 0.100.152 — 2026-09-26
- **Fixed Package Managers on Modern Android Phones (Kernel ≥ 5.8)**:
  - Resolved `pacman` and `pacman-key` initialization errors (`could not find or read directory`) on newer Android kernels (e.g. Linux 6.12 on Samsung Galaxy S24 Ultra / SM-S948B).
  - Modern glibc 2.43 prioritizes `faccessat2` (syscall 439), which reaches host Android untranslated. Interposed `faccessat`, `euidaccess`, and `eaccess` via the `libfaccessatfix.so` preload shim, routing directly to `__NR_faccessat` to ensure seamless operation across all Android kernel versions.
- **Fixed File Linking Inside Sandboxes**: Hard links now behave correctly, so `git clone`, `uv`, Python package builds and archive extraction produce intact files again instead of quietly writing damaged ones.
- **Fixed Firefox Crashing on Startup**: Firefox — and anything else that needs shared memory — now starts normally. Sandboxes had no `/dev/shm` at all, which made Firefox exit immediately every time it was launched.
- **`uls upgrade` Now Detects and Reports Damage**: Upgrading carries the fix down to sandboxes you already have, then checks them for files damaged by the old linking bug and tells you how to repair them if any are found.
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