# Build environment for the MeshTrax Linux desktop bundle. Use
# tool/linux_docker/build.sh rather than running this image by hand.
#
# Ubuntu 22.04 on purpose: a Linux binary runs only on systems at least as
# new as the one it was built on, so this base reaches Ubuntu 22.04+, Debian
# 12, Mint 21+ and Fedora 36+. Flutter can't cross-compile Linux, so the
# host's architecture decides the bundle: x86-64 gives x64, arm64 gives arm64.
FROM ubuntu:22.04

ARG FLUTTER_VERSION=3.50.0

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates clang cmake curl git libgtk-3-dev liblzma-dev \
      libstdc++-12-dev ninja-build pkg-config unzip xz-utils zip \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git /opt/flutter
ENV PATH=/opt/flutter/bin:$PATH

RUN flutter config --no-analytics --no-cli-animations \
 && flutter precache --linux --no-android --no-ios
