# Contributing to the ULS Distro Catalog

Thank you for helping grow ULS! This guide explains how to add or update
Linux distro entries and mirror URLs in `latest.json`.

---

## What lives here

| File | Purpose |
|---|---|
| `latest.json` | The community distro catalog — this is what you edit |
| `CONTRIBUTING.md` | This guide |
| `README.md` | End-user install + usage guide |

---

## Adding a distro

### 1 — Find a `.tar.gz` bootstrap rootfs

ULS uses the on-device **toybox tar** to extract the rootfs.
Toybox tar only understands gzip — so images **must** be `.tar.gz`.

> ❌ Not supported: `.tar.xz`, `.tar.zst`, `.tar.bz2`, OCI layer tarballs

Good sources:
- Ubuntu base images — `cdimage.ubuntu.com/ubuntu-base/`
- Arch Linux ARM — `archlinuxarm.org/os/`
- Alpine minirootfs — `dl-cdn.alpinelinux.org/alpine/`
- Debian debuerreotype — `github.com/debuerreotype/docker-debian-artifacts`

### 2 — Edit `latest.json`

Add an entry to the `"distros"` array. Use this shape exactly:

```json
{
  "id": "mydistro",
  "name": "My Distro 1.0",
  "arches": ["aarch64", "arm"],
  "note": "One short sentence shown to the user during setup.",
  "bootstrap": {
    "aarch64": [
      "https://primary-mirror.example.com/mydistro-aarch64.tar.gz",
      "https://fallback-mirror.example.com/mydistro-aarch64.tar.gz"
    ],
    "arm": [
      "https://primary-mirror.example.com/mydistro-armv7.tar.gz"
    ]
  },
  "sha256": {
    "aarch64": "<hex sha256 of the aarch64 tarball>",
    "arm": "<hex sha256 of the arm tarball>"
  }
}
```

**Rules:**
- `id` — lowercase, no spaces, only `a-z 0-9 _ -`. Must be unique.
- `name` — human label shown in `uls setup`. Keep it short.
- `arches` — list the arches you have verified URLs for.
- `bootstrap` — list mirrors in priority order. ULS tries them top-to-bottom.
- `sha256` — optional, but strongly encouraged. Get it from the upstream release page.
- `note` — one plain sentence. No markdown.

### 3 — Verify the URLs manually

Before opening a PR, check that every URL you added is reachable:

```sh
curl -sIL --max-time 20 <your-url>
```

A `200 OK` or `302` redirect response means the URL is live.

### 4 — Open a Pull Request

**PR title format:** `[catalog] Add <distro-name> (<arch>)`

Example: `[catalog] Add Void Linux (aarch64, arm)`

In the PR description, include:
- What the distro is and why it's useful on Android
- Where the image comes from (link to the upstream release page)
- SHA-256 checksums (if available)
- Which device/Android version/arch you tested on

---

## Updating a dead mirror

1. Replace the stale URL in `latest.json` with a working one.
2. Verify the new URL with `curl -sIL`.
3. PR title: `[catalog] Fix <distro-name> mirror (<arch>)`

---

## Updating proot binaries

The `"proot_binaries"` block tracks static builds from
[proot-me/proot](https://github.com/proot-me/proot).
When a new release ships:

1. Update the `url` and `sha256` for each arch in `"proot_binaries"`.
2. Verify each URL with `curl -sIL`.
3. PR title: `[proot] Bump to v<version>`

---

## Code of Conduct

Be kind and constructive. We follow the
[Contributor Covenant v2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

---

## Questions?

Open an [issue](https://github.com/Jaseunda/uls/issues) and tag it `catalog`.
