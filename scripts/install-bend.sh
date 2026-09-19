#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
version=$(cat "$root/.bend-version")
destination="$root/.tools/bend"

if [ -x "$destination/bin/bend" ]; then
  installed=$(BEND_NO_TELEMETRY=1 "$destination/bin/bend" --version)
  if [ "$installed" = "bend $version" ]; then
    printf '%s is already installed locally.\n' "$installed"
    exit 0
  fi
  printf 'Expected Bend %s; found %s. Move .tools/bend aside before reinstalling.\n' "$version" "$installed" >&2
  exit 1
fi
if [ -e "$destination" ]; then
  printf 'Move the incomplete .tools/bend directory aside before reinstalling.\n' >&2
  exit 1
fi

# Checksums published by https://bend-lang.com/install.sh for 2.0.16.
case "$version:$(uname -s):$(uname -m)" in
  2.0.16:Linux:x86_64)
    platform=linux-x64
    checksum=496ff13a312221c3dc0dde4077368ced42c0f3eadcb61c2d43de5caddf0e50b4 ;;
  2.0.16:Linux:aarch64)
    platform=linux-arm64
    checksum=7270295dc1bb6e7a0c337c0d8258a98df5220b636a01f655868ad1bdb2aff249 ;;
  2.0.16:Darwin:arm64)
    platform=darwin-arm64
    checksum=856a7b80c4401569228d3e3d4aa3efbe8b535741a57793aa343c95b49db7490c ;;
  2.0.16:Darwin:x86_64)
    platform=darwin-x64
    checksum=510b38f743b3c5e2ea41bdaee9087b66cc29c60b0fb803a8b5255b6283a4c01f ;;
  *)
    printf 'No pinned Bend archive for this version and platform.\n' >&2
    exit 1 ;;
esac

mkdir -p "$root/.tools"
staging=$(mktemp -d "$root/.tools/bend-download.XXXXXX")
trap 'rm -rf "$staging"' EXIT HUP INT TERM
archive="bend-$version-$platform.tar.gz"
curl --proto '=https' --tlsv1.2 -fsSL \
  "https://github.com/bendlang/bend/releases/download/v$version/$archive" \
  -o "$staging/$archive"
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$staging/$archive")
else
  actual=$(shasum -a 256 "$staging/$archive")
fi
if [ "${actual%% *}" != "$checksum" ]; then
  printf 'Bend archive checksum mismatch.\n' >&2
  exit 1
fi
tar -xzf "$staging/$archive" -C "$staging"
mv "$staging/bend" "$destination"
BEND_NO_TELEMETRY=1 "$destination/bin/bend" --version
