#!/bin/bash
_PROJECT_CONFIG_LIB=/usr/local/lib/nevermore-vpn/project-config.sh
[ -r "$_PROJECT_CONFIG_LIB" ] && . "$_PROJECT_CONFIG_LIB"
_UDP_MANAGER=/usr/local/lib/nevermore-vpn/udp-manage.sh
if [ ! -x "$_UDP_MANAGER" ]; then
    _UDP_SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)
    _UDP_MANAGER="$_UDP_SCRIPT_DIR/manage.sh"
fi
run_manager() {
    if [ "$(id -u)" -eq 0 ]; then
        "$_UDP_MANAGER" "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$_UDP_MANAGER" "$@"
    else
        echo "Run the UDP menu as root (sudo is not installed)." >&2
        return 1
    fi
}
while true; do
    clear
    echo "UDP CUSTOM MENU"
    echo "------------------------------------------------------------"
    echo "Project: ${PROJECT_NAME:-Hop VPN} (${PROJECT_OWNER:-unknown})"
    echo "1. Install / configure UDP Custom"
    echo "2. Show status"
    echo "3. Start service"
    echo "4. Stop service"
    echo "5. Restart service"
    echo "6. Remove UDP Custom service"
    echo "0. Back to main menu"
    echo "------------------------------------------------------------"
    read -r -p "Select option: " choice
    case "$choice" in
        1)
            read -r -p "UDP port [${UDP_CUSTOM_PORT:-36712}]: " udp_port
            udp_port=${udp_port:-${UDP_CUSTOM_PORT:-36712}}
            read -r -p "Excluded ports (optional) [${UDP_CUSTOM_EXCLUDE:-none}]: " udp_exclude
            udp_exclude=${udp_exclude:-${UDP_CUSTOM_EXCLUDE:-}}
            run_manager install "$udp_port" "$udp_exclude"
            read -r -p "Press Enter to continue..." _
            ;;
        2) "$_UDP_MANAGER" status; read -r -p "Press Enter to continue..." _ ;;
        3) run_manager start; read -r -p "Press Enter to continue..." _ ;;
        4) run_manager stop; read -r -p "Press Enter to continue..." _ ;;
        5) run_manager restart; read -r -p "Press Enter to continue..." _ ;;
        6) run_manager remove; read -r -p "Press Enter to continue..." _ ;;
        0) exit 0 ;;
        *) echo "Invalid option."; sleep 1 ;;
    esac
done
