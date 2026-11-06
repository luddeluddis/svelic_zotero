#!/bin/bash
# Compatible with macOS Bash 3.2 and Linux Bash. No sudo or Python required.

installer_error() { printf 'Installation failed: %s\n' "$*" >&2; exit 1; }

translator_id() {
    # Read only the metadata header, never translator code or test data.
    awk '
        /^[[:space:]]*}/ { exit }
        /^[[:space:]]*"translatorID"[[:space:]]*:/ {
            sub(/^[^:]*:[[:space:]]*"/, "")
            sub(/".*$/, "")
            print; exit
        }
    ' "$1"
}

wait_zotero_closed() {
    local answer status
    while true; do
        if pgrep -u "$(id -u)" -x 'zotero|zotero-bin|Zotero' >/dev/null; then
            printf '\nZotero is still running. Please close Zotero before continuing.\n'
            printf 'The installer needs Zotero closed to update its translators and style.\n'
            printf 'Close Zotero, then press Enter to retry (or type Q to cancel): '
            if ! IFS= read -r answer; then printf '\nInstallation cancelled.\n'; return 1; fi
            case "$answer" in q|Q) printf 'Installation cancelled.\n'; return 1 ;; esac
        else
            status=$?
            [ "$status" -eq 1 ] || installer_error 'Could not check whether Zotero is running.'
            return 0
        fi
    done
}

fetch_file() {
    curl --fail --location --silent --show-error --connect-timeout 15 --max-time 60 \
        --proto '=https' --proto-redir '=https' --user-agent 'SVELIC-Zotero-Installer' \
        --output "$2" "$1"
}

expected_translator_id() {
    case "$1" in
        translators/FASS.js) printf '%s' '2b0a6048-39c4-4f48-9e61-7a4482f87793' ;;
        translators/Janusmed.js) printf '%s' 'b02d942c-24a8-4db2-8728-ef40cc4eca49' ;;
        translators/Lexicomp.js) printf '%s' 'bf16028e-e50c-404b-9368-077c02bb4152' ;;
        translators/MedicinesComplete.js) printf '%s' '7111b34c-127b-43aa-a7ac-fecd449041c4' ;;
        translators/SVELIC.js) printf '%s' '9a8e9820-46b5-455e-9edb-89491163fd50' ;;
        'translators/UpToDate Article.js') printf '%s' '4af8c4da-cf3d-4ec2-989f-15d4d0723bf1' ;;
    esac
}

installer_cleanup() {
    if [ -n "${pending:-}" ] && [ -f "$pending" ]; then rm -f -- "$pending"; fi
    if [ -n "${stage:-}" ] && [ -d "$stage" ]; then rm -rf -- "$stage"; fi
}

install_zotero_files() {
    local data_directory="$HOME/Zotero" repository='luddeluddis/svelic_zotero' ref='main'
    local answer tool encoded_ref commit base file destination saved status
    local backup=''
    local files=(
        'translators/FASS.js'
        'translators/Janusmed.js'
        'translators/Lexicomp.js'
        'translators/MedicinesComplete.js'
        'translators/SVELIC.js'
        'translators/UpToDate Article.js'
        'styles/nlm-citation-sequence-unnumbered-bibliography.csl'
    )
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --data-directory|--repository|--ref)
                [ "$#" -ge 2 ] || installer_error "Missing value for $1"
                case "$1" in
                    --data-directory) data_directory="$2" ;;
                    --repository) repository="$2" ;;
                    --ref) ref="$2" ;;
                esac
                shift 2 ;;
            --help|-h)
                printf 'Install SVELIC translators and style into an existing Zotero library.\n'
                printf 'Usage: bash install-translators-and-style.sh [options]\n'
                printf '  --data-directory PATH            Default: ~/Zotero\n'
                printf '  --repository OWNER/NAME          Default: luddeluddis/svelic_zotero\n'
                printf '  --ref BRANCH-OR-COMMIT            Default: main\n'
                return 0 ;;
            *) installer_error "Unknown option: $1 (use --help)" ;;
        esac
    done
    [[ "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || installer_error 'Invalid repository name.'
    [[ "$ref" =~ ^[A-Za-z0-9_./-]+$ ]] || installer_error 'Invalid branch or commit.'
    for tool in curl pgrep awk grep mktemp cmp cp mv id date; do
        command -v "$tool" >/dev/null 2>&1 || installer_error "Required tool is missing: $tool"
    done
    wait_zotero_closed || return 0
    while [ ! -f "$data_directory/zotero.sqlite" ]; do
        printf 'No Zotero library found at: %s\n' "$data_directory"
        printf 'Find it in Zotero Settings > Advanced > Files and Folders > Show Data Directory.\n'
        printf 'Enter that data directory (blank to cancel): '
        if ! IFS= read -r answer || [ -z "$answer" ]; then printf '\nInstallation cancelled.\n'; return 0; fi
        # Expand a typed ~/ prefix without evaluating the user's input as code.
        case "$answer" in '~/'*) data_directory="$HOME/${answer#\~/}" ;; *) data_directory="$answer" ;; esac
    done
    data_directory=$(cd -- "$data_directory" && pwd -P)
    printf 'Zotero data directory: %s\n' "$data_directory"
    stage=$(mktemp -d "${TMPDIR:-/tmp}/svelic-zotero.XXXXXX")
    encoded_ref=${ref//\//%2F}
    fetch_file "https://api.github.com/repos/$repository/commits/$encoded_ref" "$stage/commit.json"
    commit=$(awk '/^[[:space:]]*[{]?[[:space:]]*"sha"[[:space:]]*:/ { sub(/^[^:]*:[[:space:]]*"/, ""); sub(/".*$/, ""); print; exit }' "$stage/commit.json")
    [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || installer_error 'GitHub returned an invalid commit.'
    base="https://raw.githubusercontent.com/$repository/$commit"
    # Stage and check all downloads before changing the installed files.
    for file in "${files[@]}"; do
        mkdir -p -- "$stage/$(dirname -- "$file")"
        fetch_file "$base/${file// /%20}" "$stage/$file"
        case "$file" in
            *.js)
                [ "$(translator_id "$stage/$file")" = "$(expected_translator_id "$file")" ] || installer_error "Unexpected translator ID: $file"
                ;;
            *.csl)
                grep -q '<style[[:space:]]' "$stage/$file" &&
                    grep -q 'xmlns="http://purl.org/net/xbiblio/csl"' "$stage/$file" &&
                    grep -q '<id>http://www.zotero.org/styles/vancouver-unnumbered-bibliography</id>' "$stage/$file" &&
                    grep -q '</style>' "$stage/$file" || installer_error "Invalid or unexpected CSL style: $file"
                # Use the system XML validator when available (included on macOS).
                if command -v xmllint >/dev/null 2>&1; then xmllint --nonet --noout "$stage/$file"; fi
                ;;
        esac
    done
    wait_zotero_closed || return 0
    for file in "${files[@]}"; do
        destination="$data_directory/$file"
        if [ -f "$destination" ]; then
            if cmp -s -- "$stage/$file" "$destination"; then
                printf 'Unchanged: %s\n' "$file"
                continue
            else
                status=$?
                [ "$status" -eq 1 ] || installer_error "Could not compare $file"
            fi
            if [ -z "$backup" ]; then
                mkdir -p -- "$data_directory/svelic-installer-backups"
                backup=$(mktemp -d "$data_directory/svelic-installer-backups/$(date +%Y%m%d-%H%M%S)-XXXXXX")
            fi
            saved="$backup/$file"
            mkdir -p -- "$(dirname -- "$saved")"
            cp -p -- "$destination" "$saved"
        fi
        mkdir -p -- "$(dirname -- "$destination")"
        pending=$(mktemp "$destination.XXXXXX")
        cp -- "$stage/$file" "$pending"
        mv -f -- "$pending" "$destination"
        pending=''
        printf 'Installed: %s\n' "$file"
    done
    # Retire the previous filename only when it belongs to this translator.
    local legacy="$data_directory/translators/UpToDate_article.js"
    if [ -f "$legacy" ] && [ "$(translator_id "$legacy")" = '4af8c4da-cf3d-4ec2-989f-15d4d0723bf1' ]; then
        if [ -z "$backup" ]; then
            mkdir -p -- "$data_directory/svelic-installer-backups"
            backup=$(mktemp -d "$data_directory/svelic-installer-backups/$(date +%Y%m%d-%H%M%S)-XXXXXX")
        fi
        mkdir -p -- "$backup/translators"
        mv -- "$legacy" "$backup/translators/UpToDate_article.js"
        printf 'Backed up previous filename: UpToDate_article.js\n'
    fi
    if [ -n "$backup" ]; then printf 'Previous files backed up to: %s\n' "$backup"; fi
    printf 'Finished. Source commit: %s\n' "$commit"
    printf 'Open Zotero, restart your browser, and reload the article page.\n'
    printf 'Select NLM/Vancouver (unnumbered bibliography) in Zotero or the Word document preferences.\n'
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    set -Eeuo pipefail
    stage=''
    pending=''
    trap installer_cleanup EXIT
    trap 'printf "Installation failed. Review the message above, then try again.\n" >&2' ERR
    install_zotero_files "$@"
fi
