#!/bin/sh
# Shared project settings. Values in the VPS config override these defaults.

: "${PROJECT_CONFIG_DIR:=/etc/nevermore-vpn}"
PROJECT_CONFIG_FILE="${PROJECT_CONFIG_FILE:-${PROJECT_CONFIG_DIR}/config.env}"
if [ -r "$PROJECT_CONFIG_FILE" ] && [ "${_PROJECT_CONFIG_LOADED:-0}" != 1 ]; then
    _PROJECT_CONFIG_LOADED=1
    . "$PROJECT_CONFIG_FILE"
fi

: "${PROJECT_NAME:=Hop VPN}"
: "${PROJECT_OWNER:=NevermoreSSH}"
: "${PROJECT_REPO:=hop}"
: "${PROJECT_BRANCH:=main}"
: "${PROJECT_CONFIG_DIR:=/etc/nevermore-vpn}"
: "${PROJECT_INSTALL_DIR:=/opt/nevermore-vpn}"
: "${ADDONS_OWNER:=$PROJECT_OWNER}"
: "${ADDONS_REPO:=addons}"
: "${SLOWDNS_OWNER:=$PROJECT_OWNER}"
: "${SLOWDNS_REPO:=hopp}"
: "${SLOWDNS_BRANCH:=main}"
: "${UDP_CUSTOM_PORT:=36712}"
: "${UDP_CUSTOM_EXCLUDE:=}"
: "${UDP_CUSTOM_MAX_CLIENTS:=500}"

PROJECT_RAW_HOST="raw.githubusercontent.com/${PROJECT_OWNER}/${PROJECT_REPO}/${PROJECT_BRANCH}"
PROJECT_RAW_BASE="https://${PROJECT_RAW_HOST}"
PROJECT_REPO_URL="https://github.com/${PROJECT_OWNER}/${PROJECT_REPO}"
PROJECT_ADDONS_RELEASE_BASE="https://github.com/${ADDONS_OWNER}/${ADDONS_REPO}/releases"
SLOWDNS_RAW_BASE="https://raw.githubusercontent.com/${SLOWDNS_OWNER}/${SLOWDNS_REPO}/${SLOWDNS_BRANCH}"
PROJECT_VERSION_FILE="${PROJECT_CONFIG_DIR}/version"

project_version() {
    if [ -s "$PROJECT_VERSION_FILE" ]; then
        tr -d '\r\n' < "$PROJECT_VERSION_FILE"
    else
        printf '%s' "unknown"
    fi
}
