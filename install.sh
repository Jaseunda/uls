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
#               curl -fsSL https://raw.githubusercontent.com/Jaseunda/uls/main/install.sh | bash
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
# Color helpers (TTY + NO_COLOR aware)
# ---------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    _C='\033['; _R='\033[0m'
else
    _C=''; _R=''
fi
dim() { printf '%b' "${_C}2m${1}${_R}"; }
cyl() { printf '%b' "${_C}1;36m${1}${_R}"; }
grn() { printf '%b' "${_C}1;32m${1}${_R}"; }
ylw() { printf '%b' "${_C}1;33m${1}${_R}"; }
red() { printf '%b' "${_C}1;31m${1}${_R}"; }

say_banner() {
    printf '%b\n' \
        "${_C}34m     :::    ::::::       :::::::: ${_R}" \
        "${_C}34m    :+:    :+::+:      :+:    :+: ${_R}" \
        "${_C}36m   +:+    +:++:+      +:+         ${_R}" \
        "${_C}35m  +#+    +:++#+      +#++:++#++   ${_R}" \
        "${_C}35m +#+    +#++#+             +#+    ${_R}" \
        "${_C}35m#+#    #+##+#      #+#    #+#     ${_R}" \
        "${_C}35m######## ##################       ${_R}" \
        ""
}

clear 2>/dev/null || true
echo ""
say_banner
echo "  $(cyl "ULS — Universal Linux Shell")"
echo "  $(dim "A real GNU/Linux, running on your Android phone.")"
echo "  $(dim "----------------------------------------------")"

# ---------------------------------------------------------------------------
# Detect mode: local (files already present) or remote (need to download)
# ---------------------------------------------------------------------------
SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
DOWNLOAD_MODE=0

if [ "${1:-}" = "--download" ]; then
    DOWNLOAD_MODE=1
elif [ ! -f "$SRC/uls" ] || [ ! -f "$SRC/SHA256SUMS" ]; then
    # Running as a piped script or standalone without the bundle — download it
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
        read -r answer || true
        case "$answer" in
            y|Y|yes|YES) break ;;
            n|N|no|NO|"")
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
    echo "  $(red "✗")  uls is a macOS arm64 (Apple Silicon) binary; this Mac is $ARCH."
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
        echo "  $(red "✗")  curl is required to download ULS. Install it and retry."
        exit 1
    fi

    # Resolve version
    if [ -n "${ULS_VERSION:-}" ]; then
        VERSION="$ULS_VERSION"
        ZIP_URL="${GITHUB_RELEASES}/download/v${VERSION}/uls-${VERSION}.zip"
        SUMS_URL="${GITHUB_RELEASES}/download/v${VERSION}/SHA256SUMS"
    else
        echo ""
        echo "  $(dim "Looking up the latest release…")"
        # Use GitHub API if available, else parse releases page
        if LATEST_JSON=$(curl -fsSL --max-time 10 "$GITHUB_API" 2>/dev/null); then
            VERSION=$(echo "$LATEST_JSON" | grep '"tag_name"' | sed 's/.*"tag_name": *"v\?\([^"]*\)".*/\1/' | head -1)
        else
            echo "  $(ylw "!")  GitHub API unavailable — checking releases page…"
            VERSION=$(curl -fsSL --max-time 10 "${GITHUB_RELEASES}" 2>/dev/null \
                | grep -o 'uls-[0-9][0-9.]*\.zip' | head -1 | sed 's/uls-//;s/\.zip//' || true)
        fi
        if [ -z "${VERSION:-}" ]; then
            echo "  $(red "✗")  Could not determine the latest version."
            echo "     Check ${GITHUB_RELEASES} and set ULS_VERSION=x.y.z to pin one."
            exit 1
        fi
        ZIP_URL="${GITHUB_RELEASES}/download/v${VERSION}/uls-${VERSION}.zip"
        SUMS_URL="${GITHUB_RELEASES}/download/v${VERSION}/SHA256SUMS"
    fi

    TMPDIR_DL="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR_DL"' EXIT

    ZIP="$TMPDIR_DL/uls-${VERSION}.zip"
    SUMSFILE="$TMPDIR_DL/SHA256SUMS"

    echo "  $(dim "Downloading ULS v${VERSION}…")"
    if ! curl -fL --progress-bar "$ZIP_URL" -o "$ZIP"; then
        echo "  $(red "✗")  Download failed: $ZIP_URL"
        echo "     Check your internet connection or visit ${GITHUB_RELEASES}"
        exit 1
    fi

    echo "  $(dim "Downloading SHA256SUMS…")"
    if ! curl -fsSL "$SUMS_URL" -o "$SUMSFILE"; then
        echo "  $(ylw "!")  Could not fetch SHA256SUMS — skipping verification."
    else
        # Verify the zip checksum
        echo "  $(dim "Verifying download…")"
        ZIP_BASENAME="uls-${VERSION}.zip"
        EXPECTED_SUM=$(grep " ${ZIP_BASENAME}$" "$SUMSFILE" | awk '{print $1}' || true)
        if [ -z "$EXPECTED_SUM" ]; then
            echo "  $(ylw "!")  No checksum found for ${ZIP_BASENAME} in SHA256SUMS — skipping."
        else
            if command -v shasum >/dev/null 2>&1; then
                ACTUAL_SUM=$(shasum -a 256 "$ZIP" | awk '{print $1}')
            elif command -v sha256sum >/dev/null 2>&1; then
                ACTUAL_SUM=$(sha256sum "$ZIP" | awk '{print $1}')
            else
                ACTUAL_SUM=""
                echo "  $(ylw "!")  No sha256 tool found — skipping checksum verification."
            fi
            if [ -n "$ACTUAL_SUM" ]; then
                if [ "$ACTUAL_SUM" = "$EXPECTED_SUM" ]; then
                    echo "  $(grn "✓")  Checksum verified."
                else
                    echo "  $(red "✗")  Checksum mismatch!"
                    echo "     expected: $EXPECTED_SUM"
                    echo "     got:      $ACTUAL_SUM"
                    echo "     The download may be corrupt or tampered. Aborting."
                    exit 1
                fi
            fi
        fi
    fi

    # Extract
    echo "  $(dim "Extracting…")"
    EXTRACT_DIR="$TMPDIR_DL/bundle"
    mkdir -p "$EXTRACT_DIR"
    unzip -q "$ZIP" -d "$EXTRACT_DIR"

    # Find the bundle root (zip may or may not contain a top-level folder)
    if [ -f "$EXTRACT_DIR/uls" ]; then
        SRC="$EXTRACT_DIR"
    else
        SRC="$(find "$EXTRACT_DIR" -maxdepth 2 -name "uls" -type f | head -1 | xargs dirname 2>/dev/null || true)"
    fi
    if [ -z "$SRC" ] || [ ! -f "$SRC/uls" ]; then
        echo "  $(red "✗")  Could not find the uls binary inside the zip."
        exit 1
    fi

    # Copy SHA256SUMS into the bundle dir so install step below can find it
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
        echo "  $(red "✗")  $SRC/$f not found."
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
# Remove first: overwriting a signed binary in place causes macOS taskgated
# to reject it with "Code Signature Invalid".
rm -f "$BIN/uls"
cp "$SRC/uls" "$BIN/uls"
chmod 755 "$BIN/uls"
if command -v xattr >/dev/null 2>&1; then
    xattr -d com.apple.quarantine "$BIN/uls" 2>/dev/null || true
fi
cp "$SRC/README.md"    "$PREFIX/README.md"
cp "$SRC/NOTICE"       "$PREFIX/NOTICE"
cp "$SRC/CHANGELOG.md" "$PREFIX/CHANGELOG.md"
# Copy SHA256SUMS alongside the installed binary for future reference
[ -f "$SRC/SHA256SUMS" ] && cp "$SRC/SHA256SUMS" "$PREFIX/SHA256SUMS" || true

# ---------------------------------------------------------------------------
# Optional: install adb
# ---------------------------------------------------------------------------
if ! command -v adb >/dev/null 2>&1; then
    echo ""
    echo "  ULS needs one helper on this Mac: $(ylw "adb") — Google's tool that"
    echo "  talks to your phone.  Without it, ULS can't see your phone."
    if command -v brew >/dev/null 2>&1; then
        while true; do
            printf "  Install it now with Homebrew? [y/N] "
            read -r answer || true
            case "$answer" in
                y|Y|yes|YES) break ;;
                n|N|no|NO|"") ADB_SKIP=1; break ;;
                *) echo "  $(dim "please answer yes or no.")" ;;
            esac
        done
        if [ -z "${ADB_SKIP:-}" ]; then
            echo "  $(dim "Adding it with Homebrew — may take a moment…")"
            brew install android-platform-tools >/dev/null 2>&1 || {
                echo "  $(ylw "!")  That didn't complete. You can add it later:"
                echo "        $(ylw "brew install android-platform-tools")"
            }
        fi
    else
        echo "  The safe way is Homebrew (brew.sh).  You can also get adb from"
        echo "  Google directly — ULS will use it the moment it's ready."
    fi
fi
if ! command -v adb >/dev/null 2>&1; then
    echo ""
    echo "  $(dim "adb isn't ready yet — ULS is installed; add adb before running 'uls setup'.")"
fi

# ---------------------------------------------------------------------------
# Link into a PATH directory
# ---------------------------------------------------------------------------
LINKED=""
for c in /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
    if [ -d "$c" ] && [ -w "$c" ] && [[ ":$PATH:" == *":$c:"* ]]; then
        if [ -e "$c/uls" ] && [ ! -L "$c/uls" ]; then
            echo "  !  $c/uls exists and is not a symlink — leaving it alone."
            continue
        fi
        ln -sf "$BIN/uls" "$c/uls"
        LINKED="$c"
        break
    fi
done
if [ -z "$LINKED" ]; then
    echo ""
    echo "  Add ULS to your PATH (add to ~/.zshrc or ~/.bashrc):"
    echo "      export PATH=\"$BIN:\$PATH\""
fi

# ---------------------------------------------------------------------------
# Final check + summary
# ---------------------------------------------------------------------------
VER="$(sed -n 's/^ULS version:[[:space:]]*/v/p' "$PREFIX/NOTICE" | head -1)"
echo ""
echo "  $(grn "✓") ULS $(ylw "$VER") is installed on this Mac, ready to go."
echo ""
echo "  $(ylw "Three easy steps:")"
echo "    $(dim "1.") Plug your Android phone into this Mac $(dim "(USB cable)")."
echo "    $(dim "2.") Run:   $(ylw "uls setup")   $(dim "(a few simple questions, once)")"
echo "    $(dim "3.") Run:   $(ylw "uls login")   $(dim "you now have a real Linux on your phone!")"
echo ""
echo "  $(dim "Had enough?")   $(ylw "uls uninstall")   $(dim "removes everything.")"
echo "  $(dim "Getting an update?")   $(ylw "uls upgrade")   $(dim "refreshes your device in seconds.")"
echo ""
if ! "$BIN/uls" help >/dev/null 2>&1; then
    echo "  $(ylw "!")  '$BIN/uls' did not start. If downloaded via browser, macOS may have"
    echo "     quarantined it — clear that with:"
    echo "         $(ylw "xattr -dr com.apple.quarantine \"$BIN/uls\"")"
    echo ""
    echo "  Installed, but needs the quarantine step above before first run."
    exit 1
fi
echo "  $(dim "Installed where:")  $(cyl "~/.uls")   $(dim "(one folder — you won't need to look inside)")"
echo ""
echo "  $(grn "✓ Enjoy ULS!")"
echo ""