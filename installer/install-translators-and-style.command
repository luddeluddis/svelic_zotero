#!/bin/bash
# macOS Terminal launcher. An adjacent .sh is used when present.
set -euo pipefail
stage=''
finish() {
    local status=$?
    if [ -n "$stage" ] && [ -d "$stage" ]; then rm -rf -- "$stage"; fi
    if [ -t 0 ]; then
        printf '\nPress Enter to close this window... '
        IFS= read -r answer || true
    fi
    exit "$status"
}
trap finish EXIT
script_directory=$(cd -- "$(dirname -- "$0")" && pwd -P)
if [ -f "$script_directory/install-translators-and-style.sh" ]; then
    bash "$script_directory/install-translators-and-style.sh" "$@"
else
    stage=$(mktemp -d "${TMPDIR:-/tmp}/svelic-launcher.XXXXXX")
    printf 'Downloading the translator and style installer...\n'
    curl --fail --location --silent --show-error --connect-timeout 15 --max-time 60 \
        --proto '=https' --proto-redir '=https' \
        --output "$stage/installer.sh" \
        'https://raw.githubusercontent.com/luddeluddis/svelic_zotero/main/installer/install-translators-and-style.sh'
    bash "$stage/installer.sh" "$@"
fi
