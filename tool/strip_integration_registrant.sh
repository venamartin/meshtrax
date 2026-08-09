#!/usr/bin/env bash
#
# Delete the Android plugin registrant when it has been generated with the
# integration_test plugin baked in.
#
# Running the desktop integration suite:
#
#     flutter test integration_test -d windows
#
# regenerates android/app/src/main/java/io/flutter/plugins/
# GeneratedPluginRegistrant.java WITH integration_test registered — and a
# plain 'flutter pub get' can bring it straight back, because the plugin is
# resolved as a dev dependency. It is NOT on the release compile path, so the
# next release build dies with:
#
#     error: package dev.flutter.plugins.integration_test does not exist
#
# The file is gitignored and every Android build regenerates it (correctly,
# with dev dependencies excluded), so deleting it is always safe and
# self-healing. Call this AFTER any 'flutter pub get' and BEFORE the build.
#
# Usage:  bash tool/strip_integration_registrant.sh
set -euo pipefail

cd "$(dirname "$0")/.."

REGISTRANT="android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"

if [ -f "$REGISTRANT" ] && grep -q "integration_test" "$REGISTRANT"; then
  echo "==> Removing integration_test-contaminated $REGISTRANT"
  rm -f "$REGISTRANT"
fi
