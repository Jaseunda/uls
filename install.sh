#!/bin/bash
# ULS — Universal Linux Shell
#
# Proprietary License Agreement
# Copyright (c) 2026 Jaseunda
#
# This Software is provided by Jaseunda under a strictly proprietary license.
# Use of this Software grants the recipient a non-exclusive, non-transferable,
# revocable right to use the Software solely for internal purposes, subject to
# the following conditions:
#
# No Redistribution: The Software (or substantial portions thereof) may not be
# redistributed or sold without the express written permission of Jaseunda.
#
# Attribution: The copyright notice and this proprietary license agreement must
# be included in all copies or substantial portions of the Software.
#
# Warranty Disclaimer: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
# KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL JASEUNDA (OR ITS AFFILIATES) BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
# By using this Software, you acknowledge that these terms apply and agree to
# abide by them.
#
# TWO MODES:
#
#   Local  — run from inside an extracted release zip (next to the `uls` binary):
#               ./install.sh
#
#   Remote — pipe from curl / run standalone; downloads the latest release zip
#            from GitHub, verifies SHA256SUMS, extracts, then installs:
#               curl -fsSL https://notapublicfigureanymore.com/uls/install.sh | bash
#               bash install.sh --download
#
# Environment overrides:
#   ULS_HOME=<dir>    install root (default: ~/.uls)
#   ULS_ACCEPT=1      skip the licence prompt
#   ULS_VERSION=x.y.z pin a specific release (default: latest)
#   ULS_FORCE=1       allow install on non-arm64 Macs
#   NO_COLOR=1        disable ANSI output

set -euo pipefail

GITHUB_REPO="Jaseunda/uls"
GITHUB_RELEASES="https://github.com/${GITHUB_REPO}/releases"
GITHUB_API="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

PREFIX="${ULS_HOME:-$HOME/.uls}"
BIN="$PREFIX/bin"

# ---------------------------------------------------------------------------
# Color helpers (TTY + NO_COLOR aware, DESIGN.md 16-color ANSI SGR)
# ---------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    _C='\033['; _R='\033[0m'
else
    _C=''; _R=''
fi
dim()  { printf '%b' "${_C}2m${1}${_R}"; }
bld()  { printf '%b' "${_C}1m${1}${_R}"; }
cyl()  { printf '%b' "${_C}1;36m${1}${_R}"; }
grn()  { printf '%b' "${_C}1;32m${1}${_R}"; }
ylw()  { printf '%b' "${_C}1;33m${1}${_R}"; }
red()  { printf '%b' "${_C}1;31m${1}${_R}"; }
blu()  { printf '%b' "${_C}1;34m${1}${_R}"; }

step() { printf '%b\n' "  ${_C}1;36m::${_R} ${_C}1m[${1}/${2}]${_R}  ${_C}1m${3}${_R}"; }
ok()   { printf '%b\n' "     ${_C}1;32m✓${_R}  ${1}"; }
fail() { printf '%b\n' "     ${_C}1;31m✗${_R}  ${1}"; }
warn() { printf '%b\n' "     ${_C}1;33m!${_R}  ${1}"; }

say_banner() {
    printf '%b\n' \
        "${_C}1;34m     :::    ::::::       :::::::: ${_R}" \
        "${_C}1;34m    :+:    :+::+:      :+:    :+: ${_R}" \
        "${_C}1;36m   +:+    +:++:+      +:+         ${_R}" \
        "${_C}1;35m  +#+    +:++#+      +#++:++#++   ${_R}" \
        "${_C}1;35m +#+    +#++#+             +#+    ${_R}" \
        "${_C}1;35m#+#    #+##+#      #+#    #+#     ${_R}" \
        "${_C}1;35m######## ##################       ${_R}" \
        ""
}

download_file() {
    local url="$1"
    local dest="$2"

    if command -v python3 >/dev/null 2>&1; then
        python3 -c '
import sys, urllib.request, time

url = sys.argv[1]
dest = sys.argv[2]

req = urllib.request.Request(url, headers={"User-Agent": "ULS-Installer"})
try:
    with urllib.request.urlopen(req, timeout=45) as resp, open(dest, "wb") as out_f:
        total = int(resp.headers.get("Content-Length", 0))
        dl = 0
        last = 0
        while True:
            chunk = resp.read(65536)
            if not chunk:
                break
            out_f.write(chunk)
            dl += len(chunk)
            now = time.time()
            if now - last > 0.05 or dl == total:
                last = now
                pct = (dl / total) if total > 0 else 0
                width = 28
                filled = int(width * pct)
                bar = "━" * filled + "─" * (width - filled)
                dl_mb = dl / (1024 * 1024)
                tot_mb = total / (1024 * 1024)
                sys.stdout.write(f"\r     \033[1;36m[\033[1;32m{bar}\033[1;36m]\033[0m \033[1m{pct*100:5.1f}%\033[0m \033[2m({dl_mb:.1f}/{tot_mb:.1f} MB)\033[0m")
                sys.stdout.flush()
    print()
except Exception:
    sys.exit(1)
' "$url" "$dest" && return 0
    fi

    # Fallback to curl
    curl -fL -sS "$url" -o "$dest"
}

clear 2>/dev/null || true
echo ""
say_banner
echo "  $(cyl "ULS — Universal Linux Shell")  $(dim "— proot Linux via ADB")"
echo "  $(dim "A real GNU/Linux, running on your Android phone.")"
echo "  $(dim "──────────────────────────────────────────────")"

# ---------------------------------------------------------------------------
# Detect mode: local (files already present) or remote (need to download)
# ---------------------------------------------------------------------------
SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
DOWNLOAD_MODE=0

if [ "${1:-}" = "--download" ]; then
    DOWNLOAD_MODE=1
elif [ ! -f "$SRC/uls" ] || [ ! -f "$SRC/SHA256SUMS" ]; then
    DOWNLOAD_MODE=1
fi

# ---------------------------------------------------------------------------
# Licence agreement (before any download or write)
# ---------------------------------------------------------------------------
if [ "${ULS_ACCEPT:-0}" != "1" ]; then
    echo ""
    echo "  $(cyl "Before we begin — please read:")"
    echo ""
    echo "  ULS gives your Android phone a real Linux, for your own use."
    echo "  It stays your own use — you're not licensed to resell or"
    echo "  redistribute ULS itself."
    echo ""
    echo "  $(ylw "There is no warranty.")  You run ULS at your own risk."
    echo "  Some phones cannot run it (e.g. some Samsung phones block the"
    echo "  technology ULS uses). Nothing is changed on your phone until"
    echo "  you later run 'uls setup'."
    echo ""
    while true; do
        printf "  Do you agree, and want to install ULS now? [y/N] "
        read -r answer </dev/tty || true
        case "$answer" in
            y|Y|yes|YES) break ;;
            n|N|no|NO|"")
                echo ""
                echo "  $(ylw "That's OK — nothing was installed. See you later!")"
                exit 1 ;;
            *) echo "  $(dim "please answer yes or no.")" ;;
        esac
    done
fi

# ---------------------------------------------------------------------------
# Apple Silicon check
# ---------------------------------------------------------------------------
ARCH="$(uname -m)"
if [ "$ARCH" != "arm64" ] && [ "$ARCH" != "aarch64" ]; then
    echo ""
    fail "uls is a macOS arm64 (Apple Silicon) binary; this Mac is $ARCH."
    if [ "${ULS_FORCE:-0}" != "1" ]; then
        echo "     Set ULS_FORCE=1 to copy it anyway."
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# Download mode: fetch .zip from GitHub Releases, verify SHA256SUMS
# ---------------------------------------------------------------------------
if [ "$DOWNLOAD_MODE" = "1" ]; then
    if ! command -v curl >/dev/null 2>&1; then
        echo ""
        fail "curl is required to download ULS. Install it and retry."
        exit 1
    fi

    # Step 1: Resolve version
    echo ""
    step 1 4 "Resolving latest release"
    if [ -n "${ULS_VERSION:-}" ]; then
        VERSION="$ULS_VERSION"
    else
        if LATEST_JSON=$(curl -fsSL --max-time 10 "$GITHUB_API" 2>/dev/null) && [ -n "$LATEST_JSON" ]; then
            VERSION=$(echo "$LATEST_JSON" | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name":[[:space:]]*"v?([^",]+)".*/\1/')
        fi
        if [ -z "${VERSION:-}" ]; then
            VERSION=$(curl -fsSIL --max-time 10 "${GITHUB_RELEASES}/latest" 2>/dev/null \
                | grep -i '^location:' | tail -1 | sed -E 's/.*\/tag\/v?([^[:space:]\r\n]+).*/\1/')
        fi
        if [ -z "${VERSION:-}" ]; then
            fail "Could not determine the latest version."
            printf '%b\n' "     Check ${GITHUB_RELEASES} and set ULS_VERSION=x.y.z to pin one."
            exit 1
        fi
    fi
    ZIP_URL="${GITHUB_RELEASES}/download/v${VERSION}/uls-${VERSION}.zip"
    SUMS_URL="${GITHUB_RELEASES}/download/v${VERSION}/SHA256SUMS"
    ok "Found release: $(cyl "v${VERSION}")"

    TMPDIR_DL="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR_DL"' EXIT

    ZIP="$TMPDIR_DL/uls-${VERSION}.zip"
    SUMSFILE="$TMPDIR_DL/SHA256SUMS"

    # Step 2: Download release
    echo ""
    step 2 4 "Downloading ULS $(cyl "v${VERSION}")"
    if ! download_file "$ZIP_URL" "$ZIP"; then
        fail "Download failed: $ZIP_URL"
        printf '%b\n' "     Check your internet connection or visit ${GITHUB_RELEASES}"
        exit 1
    fi
    ok "Download complete $(dim "(uls-${VERSION}.zip)")"

    # Step 3: Checksum
    echo ""
    step 3 4 "Verifying package integrity"
    if ! curl -fsSL "$SUMS_URL" -o "$SUMSFILE" 2>/dev/null; then
        warn "Could not fetch SHA256SUMS — skipping verification."
    else
        ZIP_BASENAME="uls-${VERSION}.zip"
        EXPECTED_SUM=$(grep " ${ZIP_BASENAME}$" "$SUMSFILE" | awk '{print $1}' || true)
        if [ -z "$EXPECTED_SUM" ]; then
            warn "No checksum found for ${ZIP_BASENAME} in SHA256SUMS — skipping."
        else
            if command -v shasum >/dev/null 2>&1; then
                ACTUAL_SUM=$(shasum -a 256 "$ZIP" | awk '{print $1}')
            elif command -v sha256sum >/dev/null 2>&1; then
                ACTUAL_SUM=$(sha256sum "$ZIP" | awk '{print $1}')
            else
                ACTUAL_SUM=""
                warn "No sha256 tool found — skipping checksum verification."
            fi
            if [ -n "$ACTUAL_SUM" ]; then
                if [ "$ACTUAL_SUM" = "$EXPECTED_SUM" ]; then
                    ok "SHA256 checksum verified $(dim "(${EXPECTED_SUM:0:12}…)")"
                else
                    fail "Checksum mismatch!"
                    printf '%b\n' "     expected: $EXPECTED_SUM"
                    printf '%b\n' "     got:      $ACTUAL_SUM"
                    printf '%b\n' "     The download may be corrupt or tampered. Aborting."
                    exit 1
                fi
            fi
        fi
    fi

    # Step 4: Extract
    echo ""
    step 4 4 "Extracting release files"
    EXTRACT_DIR="$TMPDIR_DL/bundle"
    mkdir -p "$EXTRACT_DIR"
    unzip -q "$ZIP" -d "$EXTRACT_DIR"

    if [ -f "$EXTRACT_DIR/uls" ]; then
        SRC="$EXTRACT_DIR"
    else
        SRC="$(find "$EXTRACT_DIR" -maxdepth 2 -name "uls" -type f | head -1 | xargs dirname 2>/dev/null || true)"
    fi
    if [ -z "$SRC" ] || [ ! -f "$SRC/uls" ]; then
        fail "Could not find the uls binary inside the zip."
        exit 1
    fi
    ok "Extracted release files"

    cp "$SUMSFILE" "$SRC/SHA256SUMS" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Clear Gatekeeper quarantine from the source folder
# ---------------------------------------------------------------------------
if command -v xattr >/dev/null 2>&1; then
    xattr -dr com.apple.quarantine "$SRC" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Validate required bundle files
# ---------------------------------------------------------------------------
for f in uls README.md NOTICE CHANGELOG.md; do
    if [ ! -f "$SRC/$f" ]; then
        fail "$SRC/$f not found."
        if [ "$DOWNLOAD_MODE" = "0" ]; then
            echo "     Run this from inside the extracted release folder."
        fi
        exit 1
    fi
done

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
mkdir -p "$BIN"
rm -f "$BIN/uls"
cp "$SRC/uls" "$BIN/uls"
chmod 755 "$BIN/uls"
if command -v xattr >/dev/null 2>&1; then
    xattr -d com.apple.quarantine "$BIN/uls" 2>/dev/null || true
fi
cp "$SRC/README.md"    "$PREFIX/README.md"
cp "$SRC/NOTICE"       "$PREFIX/NOTICE"
cp "$SRC/CHANGELOG.md" "$PREFIX/CHANGELOG.md"
[ -f "$SRC/SHA256SUMS" ] && cp "$SRC/SHA256SUMS" "$PREFIX/SHA256SUMS" || true

# ---------------------------------------------------------------------------
# Optional: install adb
# ---------------------------------------------------------------------------
if ! command -v adb >/dev/null 2>&1; then
    echo ""
    printf '%b\n' "  ${_C}1;36m::${_R} ${_C}1mHelper tool needed:${_R} $(ylw "adb") $(dim "— Google's tool that talks to your phone.")"
    echo "     Without it, ULS cannot see or control your phone over USB."
    if command -v brew >/dev/null 2>&1; then
        while true; do
            printf "     Install it now with Homebrew? [y/N] "
            read -r answer </dev/tty || true
            case "$answer" in
                y|Y|yes|YES) break ;;
                n|N|no|NO|"") ADB_SKIP=1; break ;;
                *) echo "     $(dim "please answer yes or no.")" ;;
            esac
        done
        if [ -z "${ADB_SKIP:-}" ]; then
            echo "     $(dim "Adding it with Homebrew — may take a moment…")"
            brew install android-platform-tools >/dev/null 2>&1 || {
                warn "Homebrew install didn't complete. You can add it later:"
                printf '%b\n' "           $(ylw "brew install android-platform-tools")"
            }
        fi
    else
        echo "     The recommended way is Homebrew (brew.sh), or get adb from"
        echo "     Google directly — ULS will use it as soon as it is in your PATH."
    fi
fi
if ! command -v adb >/dev/null 2>&1; then
    echo ""
    warn "adb isn't ready yet — ULS is installed; add adb before running 'uls setup'."
fi

# ---------------------------------------------------------------------------
# Link into a PATH directory
# ---------------------------------------------------------------------------
LINKED=""
for c in /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
    if [ -d "$c" ] && [ -w "$c" ] && [[ ":$PATH:" == *":$c:"* ]]; then
        if [ -e "$c/uls" ] && [ ! -L "$c/uls" ]; then
            warn "$c/uls exists and is not a symlink — leaving it alone."
            continue
        fi
        ln -sf "$BIN/uls" "$c/uls"
        LINKED="$c"
        break
    fi
done

# ---------------------------------------------------------------------------
# Final check + summary
# ---------------------------------------------------------------------------
VER="$(sed -n 's/^ULS version:[[:space:]]*/v/p' "$PREFIX/NOTICE" 2>/dev/null | head -1 || true)"
[ -z "$VER" ] && VER="v${VERSION:-ready}"

if ! "$BIN/uls" help >/dev/null 2>&1; then
    echo ""
    warn "'$BIN/uls' did not start. If downloaded via browser, macOS may have"
    printf '%b\n' "     quarantined it — clear that with:"
    printf '%b\n' "         $(ylw "xattr -dr com.apple.quarantine \"$BIN/uls\"")\n"
    printf '%b\n' "     Installed, but needs the quarantine step above before first run.\n"
    exit 1
fi

echo ""
printf '%b\n' "  ${_C}1;32m✓${_R}  ${_C}1mULS${_R} ${_C}1;36m${VER}${_R} ${_C}1mis installed on this Mac, ready to go.${_R}"
if [ -n "$LINKED" ]; then
    ok "Command linked: $(cyl "$LINKED/uls")"
else
    warn "Add ULS to your PATH (add to ~/.zshrc or ~/.bashrc):"
    printf '%b\n' "        export PATH=\"$BIN:\$PATH\""
fi

echo ""
printf '%b\n' "  ${_C}1;36m::${_R} ${_C}1mNext steps:${_R}"
printf '%b\n' "     ${_C}1;34m1.${_R} Plug your Android phone into this Mac $(dim "(USB cable)")."
printf '%b\n' "     ${_C}1;34m2.${_R} Run:   ${_C}1;33muls setup${_R}   $(dim "(interactive device & Linux wizard)")"
printf '%b\n' "     ${_C}1;34m3.${_R} Run:   ${_C}1;33muls login${_R}   $(dim "drops into your real Linux shell!")"
echo ""
printf '%b\n' "  ${_C}1;36m::${_R} ${_C}1mQuick commands:${_R}"
printf '%b\n' "     ${_C}1;33muls ssh${_R}         $(dim "reconnect wirelessly over Wi-Fi")"
printf '%b\n' "     ${_C}1;33muls upgrade${_R}     $(dim "refresh on-device scripts in seconds")"
printf '%b\n' "     ${_C}1;33muls uninstall${_R}   $(dim "cleanly remove Linux & ULS from phone")"
echo ""
printf '%b\n' "  $(dim "Installed to:")  $(cyl "$PREFIX")"
echo ""
printf '%b\n' "  ${_C}1;32m✓  Enjoy ULS!${_R}"
echo ""