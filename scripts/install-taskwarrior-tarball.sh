#!/usr/bin/env bash
# Build Taskwarrior from the official release tarball (includes git submodules).
# Do not use GitHub's auto-generated "Source code" archives — they are incomplete.
#
# Build deps (Ubuntu): sudo apt install build-essential cmake rustc cargo uuid-dev libssl-dev pkg-config
set -euo pipefail

TW_VERSION="${TW_VERSION:-3.4.2}"
SHA256="${SHA256:-d302761fcd1268e4a5a545613a2b68c61abd50c0bcaade3b3e68d728dd02e716}"
URL="https://github.com/GothenburgBitFactory/taskwarrior/releases/download/v${TW_VERSION}/task-${TW_VERSION}.tar.gz"
WORKDIR="${WORKDIR:-/tmp}"

die() { echo "error: $*" >&2; exit 1; }

command -v cmake >/dev/null || die "install cmake"
command -v rustc >/dev/null || die "install rustc and cargo (e.g. apt install rustc cargo)"

cd "$WORKDIR"
rm -rf "task-${TW_VERSION}" "task-${TW_VERSION}.tar.gz"
curl -fsSL -o "task-${TW_VERSION}.tar.gz" "$URL"
echo "${SHA256}  task-${TW_VERSION}.tar.gz" | sha256sum -c -
tar xzf "task-${TW_VERSION}.tar.gz"
cd "task-${TW_VERSION}"
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
echo "Build OK. Install with: sudo cmake --install build"
echo "Then remove source to save disk: rm -rf $WORKDIR/task-${TW_VERSION} $WORKDIR/task-${TW_VERSION}.tar.gz"
