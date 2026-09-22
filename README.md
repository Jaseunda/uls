# ULS — Universal Linux Shell

> **Run a real GNU/Linux distro on any Android phone over ADB — no root, no app to install.**

```
     :::    ::::::       ::::::::
    :+:    :+::+:      :+:    :+:
   +:+    +:++:+      +:+
  +#+    +:++#+      +#++:++#++
 +#+    +#++#+             +#+
#+#    #+##+#      #+#    #+#     ULS — Universal Linux Shell
######## ##################
```

ULS prepares and sets up a rootfs container environment on your Android device, then boots an interactive shell into it — all from your Mac, over USB.

---

## Table of Contents

- [Requirements](#requirements)
- [Install from a Release](#install-from-a-release)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Supported Distros](#supported-distros)
- [Device Requirements](#device-requirements)
- [Uninstall](#uninstall)
- [Contributing a Distro](#contributing-a-distro)
- [License](#license)

---

## Requirements

| What | Details |
|---|---|
| **Mac** | Apple Silicon (arm64) |
| **ADB** | `brew install android-platform-tools` |
| **Android device** | ARM64 or ARMv7, Android 8+ |
| **USB cable** | Or an already-paired wireless ADB connection |

---

## Install from a Release

### Option 1 — Quick Install (Recommended)

Run directly in your terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/Jaseunda/uls/main/install.sh | bash
```

This will:
- Automatically download the latest release `.zip` from [GitHub Releases](https://github.com/Jaseunda/uls/releases)
- Verify integrity against `SHA256SUMS`
- Extract and install `uls` into `~/.uls/bin`
- Symlink to `/usr/local/bin` (or `$HOME/.local/bin`) so it's in your `$PATH`
- Clear macOS Gatekeeper quarantine flags automatically

### Option 2 — Manual Download

1. Download the latest `uls-<version>.zip` from the [Releases page](https://github.com/Jaseunda/uls/releases).
2. Unzip and install:

```sh
unzip uls-<version>.zip
cd uls-<version>
./install.sh
```

3. Verify:

```sh
uls --help
```

> **Tip:** If your shell doesn't pick up the PATH change, add
> `export PATH="$HOME/.uls/bin:$PATH"` to your `~/.zshrc` or `~/.bashrc`.

---

## Quick Start

### 1 — Onboard your device

Connect your Android phone over USB and run:

```sh
uls setup
```

This will:
- Detect all connected ADB devices and let you pick your phone
- Let you choose a Linux distro (Arch Linux, Ubuntu, Debian, Alpine, …)
- Save a per-device config for future commands

### 2 — Deploy Linux to the phone

```sh
uls deploy
```

Downloads the chosen distro bootstrap tarball matched to your device's
CPU, then configures and extracts it on the phone.
First run takes a few minutes depending on your connection speed.

### 3 — Log in

```sh
uls login arch        # or: ubuntu, debian, alpine, etc.
```

Drops you into a full interactive Linux shell on your phone.
`pacman`, `apt`, `apk` — all work.

---

## Commands

| Command | What it does |
|---|---|
| `uls setup` | Interactive device onboarding + distro selection |
| `uls deploy` | Download + push distro rootfs to device |
| `uls login <distro>` | Enter the Linux container (real PTY) |
| `uls upgrade` | Re-push ULS files — updates an already-installed Linux |
| `uls repair` | Re-extract rootfs on-device (fixes corrupt installs) |
| `uls distros` | List available distros and download links |
| `uls monitor` | Watch USB/ADB device events in dmesg style |
| `uls uninstall` | Remove ULS environment + rootfs from device ⚠ |

### Passing flags

```sh
uls deploy --dry-run           # show the plan without touching the device
uls deploy --no-download       # use already-cached tarballs
uls deploy --repair            # re-extract rootfs from cached tarball
uls login arch 'echo hello'    # run a one-shot command inside the container
```

---

## Supported Distros

| ID | Name | Arches |
|---|---|---|
| `archlinux` | Arch Linux (latest rolling) | arm64, armv7 |
| `ubuntu` | Ubuntu 24.04 LTS (Noble) | arm64, armv7 |
| `debian` | Debian 12 (Bookworm) | arm64, armv7 |
| `alpine` | Alpine Linux 3.24 | arm64, armv7 |

Run `uls distros` to see the live list with download links.

> Want to add a distro? See [Contributing a Distro](#contributing-a-distro).

---

## Device Requirements

- **CPU:** ARM64 (`arm64-v8a`) or ARMv7 (`armeabi-v7a`)
- **Android:** 8.0+ (API level 26+)
- **System support:** Kernel must allow container ptrace syscalls. Galaxy-class and standard ARM64 devices generally work.

---

## Uninstall

### From the device

```sh
uls uninstall              # removes /data/local/tmp/uls/ from the phone
uls uninstall --dry-run    # preview what would be deleted
```

### From your Mac

```sh
cd <the release folder you downloaded>
./uninstall.sh             # removes ~/.uls and the PATH symlink
```

---

## Contributing a Distro

The distro catalog is community-maintained in this folder's [`latest.json`](./latest.json).

To add a new distro or fix a dead mirror:

1. Fork this repo.
2. Edit `partial/latest.json` — add your entry under `"distros"`.
3. Verify each URL is reachable: `curl -sIL --max-time 20 <url>`
4. Open a PR — title format: `[catalog] Add <distro-name> (<arch>)`

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the full guide and entry format.

---

## License

© 2026 Jaseunda. See [LICENSE](./LICENSE).
