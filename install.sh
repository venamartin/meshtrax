#!/usr/bin/env bash
# MeshTrax installer / updater for Linux.
# Installs the latest GitHub release under ~/.local/share/meshtrax and
# registers a desktop entry. Re-run to upgrade. No root required.
set -euo pipefail

REPO="venamartin/meshtrax"
APP_ID="com.meshtrax.app"
APP_DIR="$HOME/.local/share/meshtrax"
BIN_LINK="$HOME/.local/bin/meshtrax"
DESKTOP_FILE="$HOME/.local/share/applications/$APP_ID.desktop"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
ICON_FILE="$ICON_DIR/$APP_ID.png"
ICON_URL="https://raw.githubusercontent.com/$REPO/master/mesh-icon.png"

info() { echo "==> $*"; }
note() { echo "    $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

usage() {
    cat <<USAGE
MeshTrax installer for Linux

  install.sh                   install, or upgrade to the latest release
  install.sh --version v1.7.22 install a specific release (also forces a reinstall)
  install.sh --uninstall       remove MeshTrax (your app data is kept)
USAGE
}

TAG=""
PINNED=false
UNINSTALL=false
while [ $# -gt 0 ]; do
    case $1 in
        --version) TAG="${2:-}"; [ -n "$TAG" ] || die "--version needs a tag, e.g. --version v1.7.22"
                   PINNED=true; shift ;;
        --uninstall) UNINSTALL=true ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
    shift
done

refresh_caches() {
    if command -v update-desktop-database > /dev/null; then
        update-desktop-database "$(dirname "$DESKTOP_FILE")" 2> /dev/null || true
    fi
    if command -v gtk-update-icon-cache > /dev/null; then
        gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2> /dev/null || true
    fi
}

if [ "$UNINSTALL" = true ]; then
    info "Removing MeshTrax..."
    rm -rf "$APP_DIR"
    rm -f "$BIN_LINK" "$DESKTOP_FILE" "$ICON_FILE"
    refresh_caches
    info "Done. Your messages and settings were left untouched."
    exit 0
fi

command -v curl  > /dev/null || die "curl is required (sudo apt install curl)"
command -v unzip > /dev/null || die "unzip is required (sudo apt install unzip)"

case "$(uname -m)" in
    x86_64)        ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7l|armv6l) die "32-bit ARM is not supported. MeshTrax needs a 64-bit OS -
       reflash with the 64-bit Raspberry Pi OS image and run this again." ;;
    *) die "unsupported architecture: $(uname -m)" ;;
esac

api="https://api.github.com/repos/$REPO/releases/latest"
[ "$PINNED" = true ] && api="https://api.github.com/repos/$REPO/releases/tags/$TAG"

info "Looking up the $( [ "$PINNED" = true ] && echo "$TAG" || echo "latest" ) release..."
release=$(curl -fsSL "$api") || die "could not reach the GitHub API. Check your connection, or the tag name."

TAG=$(printf '%s' "$release" | grep -m1 '"tag_name"' | cut -d'"' -f4)
[ -n "$TAG" ] || die "could not read the release tag from GitHub."
VERSION=${TAG#v}

urls=$(printf '%s' "$release" | grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4)
url=$(printf '%s' "$urls" | grep -E "meshtrax-linux-$ARCH-v[^/]+\.zip$" | head -1 || true)

if [ -z "$url" ]; then
    echo "ERROR: release $TAG has no Linux $ARCH build." >&2
    available=$(printf '%s' "$urls" | grep -E "linux" || true)
    if [ -n "$available" ]; then
        echo "       It does contain:" >&2
        printf '%s\n' "$available" | sed 's#.*/#         #' >&2
    fi
    echo "       Please open an issue at https://github.com/$REPO/issues" >&2
    exit 1
fi

installed=""
[ -L "$APP_DIR/current" ] && installed=$(basename "$(readlink "$APP_DIR/current")")
if [ "$installed" = "$VERSION" ] && [ "$PINNED" = false ]; then
    info "MeshTrax $VERSION is already installed and up to date."
    exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if [ -n "$installed" ]; then
    info "Upgrading MeshTrax $installed -> $VERSION ($ARCH)..."
else
    info "Installing MeshTrax $VERSION ($ARCH)..."
fi

curl -fL --progress-bar -o "$tmp/meshtrax.zip" "$url" || die "download failed."

if curl -fsSL -o "$tmp/meshtrax.sha1" "$url.sha1" 2> /dev/null; then
    expected=$(cut -d' ' -f1 < "$tmp/meshtrax.sha1")
    actual=$(sha1sum "$tmp/meshtrax.zip" | cut -d' ' -f1)
    [ "$expected" = "$actual" ] || die "checksum mismatch - the download is corrupted. Try again."
    info "Checksum verified."
fi

# Unpack beside the live version and swap the symlink, so a failed download or
# a bad archive can never leave a half-replaced install behind.
rm -rf "${APP_DIR:?}/$VERSION.tmp"
mkdir -p "$APP_DIR/$VERSION.tmp"
unzip -q "$tmp/meshtrax.zip" -d "$APP_DIR/$VERSION.tmp"
[ -f "$APP_DIR/$VERSION.tmp/meshtrax" ] || die "that archive does not look like a MeshTrax bundle."
chmod +x "$APP_DIR/$VERSION.tmp/meshtrax"
rm -rf "${APP_DIR:?}/$VERSION"
mv "$APP_DIR/$VERSION.tmp" "$APP_DIR/$VERSION"
ln -sfn "$VERSION" "$APP_DIR/current"

mkdir -p "$(dirname "$BIN_LINK")"
ln -sfn "$APP_DIR/current/meshtrax" "$BIN_LINK"

mkdir -p "$(dirname "$DESKTOP_FILE")" "$ICON_DIR"
curl -fsSL -o "$ICON_FILE" "$ICON_URL" 2> /dev/null || true
cat > "$DESKTOP_FILE" <<DESKTOP
[Desktop Entry]
Type=Application
Name=MeshTrax
Comment=Chat over MeshCore LoRa mesh networks
Exec=$APP_DIR/current/meshtrax
Icon=$APP_ID
Terminal=false
Categories=Network;InstantMessaging;
StartupWMClass=$APP_ID
DESKTOP
refresh_caches

# Keep the previous version so a bad upgrade can be rolled back by hand.
mapfile -t versions < <(for dir in "$APP_DIR"/*/; do
    name=${dir%/}; name=${name##*/}
    [ "$name" = current ] || printf '%s\n' "$name"
done | sort -V)
if [ "${#versions[@]}" -gt 2 ]; then
    for name in "${versions[@]:0:${#versions[@]}-2}"; do
        [ "$name" = "$VERSION" ] || rm -rf "${APP_DIR:?}/$name"
    done
fi

info "MeshTrax $VERSION installed."
note "Launch it from your applications menu, or run: meshtrax"

case ":${PATH:-}:" in
    *":$HOME/.local/bin:"*) ;;
    *) note ""
       # shellcheck disable=SC2088  # display text, not a path to expand
       note "~/.local/bin is not on your PATH. To fix that:"
       note "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.profile" ;;
esac

if ! id -nG 2> /dev/null | tr ' ' '\n' | grep -qx dialout; then
    note ""
    note "For USB-serial radios, add yourself to the dialout group:"
    note "  sudo usermod -aG dialout $(id -un)   (then log out and back in)"
fi
