#!/bin/bash
set -Eeuo pipefail

_PROJECT_CONFIG_LIB=/usr/local/lib/nevermore-vpn/project-config.sh
if [ ! -r "$_PROJECT_CONFIG_LIB" ]; then
    _PROJECT_SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)
    [ -r "$_PROJECT_SCRIPT_DIR/../lib/project-config.sh" ] && _PROJECT_CONFIG_LIB="$_PROJECT_SCRIPT_DIR/../lib/project-config.sh"
fi
[ -r "$_PROJECT_CONFIG_LIB" ] || { echo "Project config helper is missing." >&2; exit 1; }
. "$_PROJECT_CONFIG_LIB"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run the update as root." >&2
    exit 1
fi
for _name in "$PROJECT_OWNER" "$PROJECT_REPO"; do
    case "$_name" in *[!A-Za-z0-9_.-]*|"") echo "Invalid owner or repository name in $PROJECT_CONFIG_FILE." >&2; exit 2 ;; esac
done
case "$PROJECT_BRANCH" in *[!A-Za-z0-9_./-]*|"") echo "Invalid branch name in $PROJECT_CONFIG_FILE." >&2; exit 2 ;; esac
command -v curl >/dev/null 2>&1 || { echo "curl is required for updates." >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "tar is required for updates." >&2; exit 1; }

_tmp=$(mktemp -d)
_backup_root="/var/backups/nevermore-vpn/update-$(date +%Y%m%d-%H%M%S)"
_manifest_state="$_tmp/manifest-state"
_changed="$_tmp/changed-files"
_success=0
_old_current=""
mkdir -p "$_backup_root" "$_manifest_state"
: > "$_changed"
_current="${PROJECT_INSTALL_DIR}/current"
if [ -L "$_current" ]; then _old_current=$(readlink -f "$_current" 2>/dev/null || true); fi

rollback() {
    _status=$?
    if [ "$_success" -ne 1 ]; then
        while IFS='|' read -r _dest _state; do
            [ -n "$_dest" ] || continue
            _saved="$_manifest_state/$_dest"
            if [ "$_state" = present ] && [ -f "$_saved" ]; then
                mkdir -p "$(dirname "$_dest")"
                cp -p "$_saved" "$_dest"
            elif [ "$_state" = absent ]; then
                rm -f "$_dest"
            fi
        done < "$_changed"
        if [ -n "$_old_current" ]; then
            _restore_link="${PROJECT_INSTALL_DIR}/.current.restore.$$"
            ln -s "$_old_current" "$_restore_link"
            mv -Tf "$_restore_link" "$_current"
        else
            rm -f "$_current"
        fi
        echo "Update failed; replaced command files were restored from backup." >&2
    fi
    rm -rf "$_tmp"
    exit "$_status"
}
trap rollback EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

_sha=$(curl -fsSL --max-time 20 "https://api.github.com/repos/${PROJECT_OWNER}/${PROJECT_REPO}/commits/${PROJECT_BRANCH}" 2>/dev/null | sed -n 's/.*"sha"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F]\{40\}\)".*/\1/p' | head -n 1 || true)
if [[ "$_sha" =~ ^[0-9a-fA-F]{40}$ ]]; then
    _version=${_sha:0:7}
    _archive_url="https://codeload.github.com/${PROJECT_OWNER}/${PROJECT_REPO}/tar.gz/${_sha}"
else
    _version=unknown
    _archive_url="https://codeload.github.com/${PROJECT_OWNER}/${PROJECT_REPO}/tar.gz/refs/heads/${PROJECT_BRANCH}"
fi
echo "Downloading ${PROJECT_OWNER}/${PROJECT_REPO} (${_version})..."
curl -fL --retry 3 --connect-timeout 15 --max-time 600 "$_archive_url" -o "$_tmp/project.tar.gz"
mkdir "$_tmp/source"
tar -xzf "$_tmp/project.tar.gz" -C "$_tmp/source" --strip-components=1
[ -s "$_tmp/source/setup.sh" ] && [ -s "$_tmp/source/update/menu.sh" ] || { echo "Downloaded archive is missing required project files." >&2; exit 1; }

_release_root="${PROJECT_INSTALL_DIR}/releases"
mkdir -p "$_release_root" "${PROJECT_CONFIG_DIR}" /usr/local/lib/nevermore-vpn
if [ "$_version" = unknown ]; then
    _release="${_release_root}/branch-${PROJECT_BRANCH}-$(date +%Y%m%d%H%M%S)"
else
    _release="${_release_root}/${_sha}"
fi
if [ ! -d "$_release" ]; then
    _release_tmp="${_release}.tmp.$$"
    mkdir -p "$_release_tmp"
    cp -a "$_tmp/source/." "$_release_tmp/"
    rm -rf "$_release_tmp/.git"
    mv "$_release_tmp" "$_release"
fi

_link_tmp="${PROJECT_INSTALL_DIR}/.current.$$"
ln -s "$_release" "$_link_tmp"
if [ -e "$_current" ] && [ ! -L "$_current" ]; then
    mv "$_current" "${_current}.legacy-$(date +%Y%m%d%H%M%S)"
fi
mv -Tf "$_link_tmp" "$_current"

while IFS='|' read -r _src _dest; do
    [ -n "$_src" ] || continue
    _source="$_release/$_src"
    [ -f "$_source" ] || { echo "Missing managed file in repository: $_src" >&2; exit 1; }
    if [ -f "$_dest" ]; then
        printf '%s|present\n' "$_dest" >> "$_changed"
        mkdir -p "$_manifest_state/$(dirname "$_dest")"
        cp -p "$_dest" "$_manifest_state/$_dest"
        mkdir -p "$_backup_root/$(dirname "${_dest#/}")"
        cp -p "$_dest" "$_backup_root/${_dest#/}"
    else
        printf '%s|absent\n' "$_dest" >> "$_changed"
    fi
    _new="${_dest}.new.$$"
    mkdir -p "$(dirname "$_dest")"
    _mode=0755
    case "$_src" in udp/config.json) _mode=0640 ;; esac
    install -m "$_mode" "$_source" "$_new"
    mv -f "$_new" "$_dest"
done < "$_release/update/install-manifest.tsv"


if [ ! -e "${PROJECT_CONFIG_DIR}/config.env" ]; then
    install -m 0600 "$_release/config.env" "${PROJECT_CONFIG_DIR}/config.env"
fi
if [ -f "$_release/udp/config.json" ] && [ ! -e "${PROJECT_CONFIG_DIR}/udp-custom/config.json" ]; then
    mkdir -p "${PROJECT_CONFIG_DIR}/udp-custom"
    install -m 0640 "$_release/udp/config.json" "${PROJECT_CONFIG_DIR}/udp-custom/config.json"
fi
if [ "$_version" != unknown ]; then
    printf '%s\n' "$_version" > "${PROJECT_CONFIG_DIR}/version.new.$$"
    mv -f "${PROJECT_CONFIG_DIR}/version.new.$$" "$PROJECT_VERSION_FILE"
else
    printf '%s\n' unknown > "${PROJECT_CONFIG_DIR}/version.new.$$"
    mv -f "${PROJECT_CONFIG_DIR}/version.new.$$" "$PROJECT_VERSION_FILE"
fi
_success=1
echo "Updated script package to ${_version}. Existing project config, UDP config, accounts, and tokens were left in place."
echo "Backups of replaced command scripts: $_backup_root"
exit 0
