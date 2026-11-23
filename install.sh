#!/bin/bash
set -Eeuo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run the installer as root." >&2
    exit 1
fi

PROJECT_OWNER="${PROJECT_OWNER:-NevermoreSSH}"
PROJECT_REPO="${PROJECT_REPO:-hop}"
PROJECT_BRANCH="${PROJECT_BRANCH:-main}"
for _name in "$PROJECT_OWNER" "$PROJECT_REPO"; do
    case "$_name" in *[!A-Za-z0-9_.-]*|"") echo "Invalid project owner or repository." >&2; exit 2 ;; esac
done
case "$PROJECT_BRANCH" in *[!A-Za-z0-9_./-]*|"") echo "Invalid project branch." >&2; exit 2 ;; esac

if [ ! -r /etc/os-release ]; then
    echo "Cannot identify this Linux distribution." >&2
    exit 1
fi
. /etc/os-release
case "${ID:-}:${VERSION_ID:-}" in
    debian:9*|debian:10*|debian:11*|ubuntu:18.04*|ubuntu:20.04*) ;;
    *) echo "Supported distributions: Debian 9/10/11 and Ubuntu 18.04/20.04. Found ${PRETTY_NAME:-unknown}." >&2; exit 2 ;;
esac

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl wget tar gzip screen jq bzip2 coreutils unzip

_tmp=$(mktemp -d /tmp/nevermore-vpn-install.XXXXXX)
cleanup() { rm -rf "$_tmp"; }
trap cleanup EXIT

_sha=$(curl -fsSL --max-time 20 "https://api.github.com/repos/${PROJECT_OWNER}/${PROJECT_REPO}/commits/${PROJECT_BRANCH}" 2>/dev/null | sed -n 's/.*"sha"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F]\{40\}\)".*/\1/p' | head -n 1 || true)
if [[ "$_sha" =~ ^[0-9a-fA-F]{40}$ ]]; then
    _archive_url="https://codeload.github.com/${PROJECT_OWNER}/${PROJECT_REPO}/tar.gz/${_sha}"
else
    _archive_url="https://codeload.github.com/${PROJECT_OWNER}/${PROJECT_REPO}/tar.gz/refs/heads/${PROJECT_BRANCH}"
fi
curl -fL --retry 3 --connect-timeout 15 --max-time 600 "$_archive_url" -o "$_tmp/project.tar.gz"
mkdir "$_tmp/source"
tar -xzf "$_tmp/project.tar.gz" -C "$_tmp/source" --strip-components=1
[ -s "$_tmp/source/setup.sh" ] && [ -s "$_tmp/source/lib/project-config.sh" ] || { echo "The downloaded project archive is incomplete." >&2; exit 1; }

export PROJECT_OWNER PROJECT_REPO PROJECT_BRANCH
export PROJECT_INSTALL_SHA="$_sha"
cd "$_tmp/source"
bash ./setup.sh
