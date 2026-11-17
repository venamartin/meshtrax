#!/usr/bin/env bash
# Builds the MeshTrax Linux desktop bundle in Docker, from the committed tree
# at HEAD, or at the tag or commit given (tool/linux_docker/build.sh v1.10.2);
# uncommitted changes are not built. Flutter can't cross-compile
# Linux, so the host decides the bundle: x86-64 gives linux-x64, arm64 gives
# linux-arm64. Writes dist/meshtrax-linux-<arch>-v<version>.zip and its .sha1,
# the names release.sh uses, after the same release-engine check.
#
# Needs git and Docker. On Windows, run it inside WSL2 with Docker Engine.
# A giphy.key at the repo root is passed in at build time, never stored in
# the image.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

case "$(uname -m)" in
    x86_64)        ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "ERROR: unsupported architecture '$(uname -m)'." >&2; exit 1 ;;
esac

REF="${1:-HEAD}"
VERSION=$(git show "$REF:pubspec.yaml" | sed -n 's/^version: *\([^+]*\).*/\1/p' | tr -d '\r ')
NAME="meshtrax-linux-$ARCH-v$VERSION.zip"
IMAGE="meshtrax-linux-build"

source tool/giphy_define.sh
export GIPHY_API_KEY="${GIPHY_KEY:-}"

docker build -t "$IMAGE" tool/linux_docker

mkdir -p dist
rm -f "dist/$NAME" "dist/$NAME.sha1"

git -c core.autocrlf=false archive --format=tar "$REF" | docker run -i --rm \
    -e ARCH="$ARCH" -e NAME="$NAME" -e GIPHY_API_KEY \
    -e HOST_IDS="$(id -u):$(id -g)" \
    -v "$PWD/dist:/out" \
    -v meshtrax-linux-pub-cache:/root/.pub-cache \
    "$IMAGE" bash -euo pipefail -c '
mkdir /src && tar -x -C /src && cd /src
defines=()
[ -z "$GIPHY_API_KEY" ] || defines=(--dart-define=GIPHY_API_KEY="$GIPHY_API_KEY")
flutter build linux --release "${defines[@]}"

bundle=build/linux/$ARCH/release/bundle
reference=/opt/flutter/bin/cache/artifacts/engine/linux-$ARCH-release/libflutter_linux_gtk.so
[ -f "$bundle/lib/libapp.so" ] || { echo "ERROR: no lib/libapp.so; not an AOT release build." >&2; exit 1; }
[ "$(sha1sum < "$bundle/lib/libflutter_linux_gtk.so")" = "$(sha1sum < "$reference")" ] \
    || { echo "ERROR: the bundle does not carry the release Flutter engine." >&2; exit 1; }

(cd "$bundle" && zip -qr "/out/$NAME" ./*)
cd /out
sha1sum "$NAME" | cut -d" " -f1 > "$NAME.sha1"
chown "$HOST_IDS" "$NAME" "$NAME.sha1" 2>/dev/null || true
'

echo "SUCCESS: dist/$NAME"
