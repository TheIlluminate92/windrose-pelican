#!/bin/sh
set -eu
cd "$(dirname "$0")"
archive=cpython-3.12.16-linux-amd64.tar.gz
digest=7e1adaea26c959d13aa1120be1ae62a1ea1bb52adcb382679fffe9217e22adff
if [ ! -f "$archive" ]; then
    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
        'https://github.com/astral-sh/python-build-standalone/releases/download/20261124/cpython-3.12.16%2B20261124-x86_64-unknown-linux-gnu-install_only_stripped.tar.gz' \
        -o "$archive"
fi
printf '%s  %s\n' "$digest" "$archive" | sha256sum --check
case "${1:-local}" in
    local) docker build --platform linux/amd64 --target server --network none -t windrose-pelican:0.10.0.9-first-run . ;;
    runtime) docker build --platform linux/amd64 -f Dockerfile.runtime -t windrose-pelican-runtime:test . ;;
    *) echo 'Usage: build.sh [local|runtime]' >&2; exit 2 ;;
esac
