#!/bin/sh
# Makes lib/src/generated from proto/. Needs protoc on the PATH and the Dart
# plugin (dart pub global activate protoc_plugin). The Dart it writes is
# committed, so a build needs neither.
set -e
cd "$(dirname "$0")/.."
mkdir -p lib/src/generated
protoc --dart_out=lib/src/generated -Iproto proto/meshtrax.proto
