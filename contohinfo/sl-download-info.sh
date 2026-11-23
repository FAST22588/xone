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

cd /usr/bin

rm info-cek-tersedia
rm info-contoh-payload
rm info-contohws
rm info-exra-unli
rm info-tsel-opok
rm info-status-respon

wget -O info-cek-tersedia "${PROJECT_RAW_BASE}/contohinfo/info-cek-tersedia.sh"

wget -O info-contoh-payload "${PROJECT_RAW_BASE}/contohinfo/info-contoh-payload.sh"

wget -O info-contohws "${PROJECT_RAW_BASE}/contohinfo/info-contohws.sh"

wget -O info-exra-unli "${PROJECT_RAW_BASE}/contohinfo/info-exra-unli.sh"

wget -O info-status-respon "${PROJECT_RAW_BASE}/contohinfo/info-status-respon.sh"

wget -O info-tsel-opok "${PROJECT_RAW_BASE}/contohinfo/info-tsel-opok.sh"

chmod +x info-cek-tersedia
chmod +x info-contoh-payload
chmod +x info-contohws
chmod +x info-exra-unli
chmod +x info-tsel-opok
chmod +x info-status-respon
