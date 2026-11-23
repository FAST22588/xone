#!/bin/bash
_PROJECT_CONFIG_LIB=/usr/local/lib/nevermore-vpn/project-config.sh
if [ ! -r "$_PROJECT_CONFIG_LIB" ]; then
    _PROJECT_SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE:-$0}")" 2>/dev/null && pwd)
    if [ -r "$_PROJECT_SCRIPT_DIR/../lib/project-config.sh" ]; then
        _PROJECT_CONFIG_LIB="$_PROJECT_SCRIPT_DIR/../lib/project-config.sh"
    elif [ -r "$_PROJECT_SCRIPT_DIR/lib/project-config.sh" ]; then
        _PROJECT_CONFIG_LIB="$_PROJECT_SCRIPT_DIR/lib/project-config.sh"
    fi
fi
[ -r "$_PROJECT_CONFIG_LIB" ] && . "$_PROJECT_CONFIG_LIB"

clear
echo -e "================================================="
echo -e "#    Premium Auto Script Mod By ${PROJECT_OWNER}    #"
echo -e "================================================="
echo -e "# For Debian 9 / 10 / 11 64 bit                 #"
echo -e "# For Ubuntu 18.04 / Ubuntu 20.04 64 bit        #"
echo -e "# For VPS with KVM and VMWare virtualization    #"
echo -e "# Build Up By ${PROJECT_OWNER}                      #"
echo -e "================================================="
echo -e "# Thanks To                                     #"
echo -e "================================================="
echo -e "# XrayCore Mod by dharak36                      #"
echo -e "# BBRPLUS 5.15.96 by UJX6N                      #"
echo -e "# Modified Script from fisabiliyusri/Mantap     #"
echo -e "================================================="
