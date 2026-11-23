#!/bin/bash

_PROJECT_CONFIG_LIB=/usr/local/lib/nevermore-vpn/project-config.sh
if [ ! -r "$_PROJECT_CONFIG_LIB" ]; then
    _PROJECT_SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)
    [ -r "$_PROJECT_SCRIPT_DIR/../lib/project-config.sh" ] && _PROJECT_CONFIG_LIB="$_PROJECT_SCRIPT_DIR/../lib/project-config.sh"
fi
[ -r "$_PROJECT_CONFIG_LIB" ] && . "$_PROJECT_CONFIG_LIB"

_blue='\033[0;1;34m'
_yellow='\033[0;1;33m'
_white='\033[0;1;37m'
_reset='\033[0m'

get_ip() {
    local value
    value=$(curl -fsS --max-time 4 https://ipv4.icanhazip.com 2>/dev/null || true)
    [ -n "$value" ] || value=$(curl -fsS --max-time 4 https://ifconfig.me 2>/dev/null || true)
    printf '%s' "${value:-unknown}"
}

show_menu() {
    clear
    local os_name domain dnstt ip_version version netdev ssh_count udp_count vmess_count vless_count trojan_count trgo_count
    local uptime ram_total ram_used cpu_cores cpu_load daily yesterday monthly
    os_name=$( . /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-$(uname -s)}" )
    domain=$(cat /etc/xray/domain 2>/dev/null || printf '%s' '- none -')
    dnstt=$(cat /root/nsdomain 2>/dev/null || printf '%s' '- none -')
    ip_version=$(get_ip)
    version=$(project_version 2>/dev/null || printf '%s' unknown)
    uptime=$(uptime -p 2>/dev/null | sed 's/^up //' || uptime 2>/dev/null | sed 's/.*up //')
    ram_total=$(free -m 2>/dev/null | awk 'NR==2 {print $2}')
    ram_used=$(free -m 2>/dev/null | awk 'NR==2 {print $3}')
    cpu_cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || printf '1')
    cpu_load=$(top -bn1 2>/dev/null | awk '/Cpu\(s\)|%Cpu/ {for (i=1;i<=NF;i++) if ($i ~ /id,?$/) {gsub(/[^0-9.]/,"",$(i-1)); print 100-$(i-1) "%"; exit}}')
    cpu_load=${cpu_load:-unknown}
    netdev=$(ip route show default 2>/dev/null | awk 'NR==1 {for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}')
    netdev=${netdev:-eth0}
    ssh_count=$(awk -F: '$3 >= 1000 && $1 != "nobody" {n++} END {print n+0}' /etc/passwd 2>/dev/null)
    udp_count=$(jq -r 'if (.auth.passwords | type) == "array" then .auth.passwords | length else 0 end' "$PROJECT_CONFIG_DIR/udp-custom/config.json" 2>/dev/null || printf '0')
    vmess_count=$(grep -c -E '^### ' /etc/xray/config.json 2>/dev/null || true)
    vless_count=$(grep -c -E '^#### ' /etc/xray/config.json 2>/dev/null || true)
    trojan_count=$(grep -c -E '^#&# ' /etc/xray/config.json 2>/dev/null || true)
    trgo_count=$(grep -c -E '^### ' /etc/trojan-go/akun.conf 2>/dev/null || true)
    daily=$(vnstat -i "$netdev" 2>/dev/null | awk '/today/ {print $8, $9; exit}')
    yesterday=$(vnstat -i "$netdev" 2>/dev/null | awk '/yesterday/ {print $8, $9; exit}')
    monthly=$(vnstat -i "$netdev" -m 2>/dev/null | awk -v month="$(date +"%b '%y")" 'index($0,month) {print $9, $10; exit}')

    echo
    printf '                        MAIN MENU\n'
    printf '                %s%s%s\n' 'Script Mod By ' "${PROJECT_OWNER:-unknown}" ''
    printf '%s————————————————————————————————————————————————————————%s\n' "$_blue" "$_reset"
    printf '                %s ♦️ Server Information ♦️ %s\n' "$_white" "$_reset"
    printf '%s————————————————————————————————————————————————————————%s\n' "$_blue" "$_reset"
    printf ' ♦️ OS       : %s\n' "$os_name"
    printf ' ♦️ KERNEL   : %s\n' "$(uname -r)"
    printf ' ♦️ UPTIME   : %s\n' "${uptime:-unknown}"
    printf ' ♦️ CPU      : %s core (%s)\n' "$cpu_cores" "$cpu_load"
    printf ' ♦️ RAM      : %s MB / %s MB\n' "${ram_used:-0}" "${ram_total:-0}"
    printf ' ♦️ DOMAIN   : %s\n' "$domain"
    printf ' ♦️ DNSTT    : %s\n' "$dnstt"
    printf ' ♦️ IPVPS    : %s\n' "$ip_version"
    printf ' ♦️ Version  : %s\n' "$version"
    printf '%s————————————————————————————————————————————————————————%s\n' "$_blue" "$_reset"
    printf '                  %s ♦️ Total Bandwidth ♦️ %s\n' "$_white" "$_reset"
    printf '%s————————————————————————————————————————————————————————%s\n' "$_blue" "$_reset"
    printf ' ♦️ Daily Usage         : %s\n' "${daily:-unknown}"
    printf ' ♦️ Yesterday Usage     : %s\n' "${yesterday:-unknown}"
    printf ' ♦️ Monthly Usage       : %s\n' "${monthly:-unknown}"
    printf '%s————————————————————————————————————————————————————————%s\n' "$_blue" "$_reset"
    printf ' UDP      SSH     VMESS     VLESS     TROJAN     TROJANGO\n'
    printf ' %-8s %-7s %-9s %-9s %-10s %-8s\n' "$udp_count" "${ssh_count:-0}" "${vmess_count:-0}" "${vless_count:-0}" "${trojan_count:-0}" "${trgo_count:-0}"
    printf '%s————————————————————————————————————————————————————————%s\n' "$_blue" "$_reset"
    printf '%s1.%s  UDP CUSTOM MENU\n' "$_yellow" "$_reset"
    printf '%s2.%s  SSH WEBSOCKET MENU\n' "$_yellow" "$_reset"
    printf '%s3.%s  L2TP MENU\n' "$_yellow" "$_reset"
    printf '%s4.%s  PPTP MENU\n' "$_yellow" "$_reset"
    printf '%s5.%s  SSTP MENU\n' "$_yellow" "$_reset"
    printf '%s6.%s  WIREGUARD MENU\n' "$_yellow" "$_reset"
    printf '%s7.%s  SHADOWSOCKS MENU\n' "$_yellow" "$_reset"
    printf '%s8.%s  SHADOWSOCKSR MENU\n' "$_yellow" "$_reset"
    printf '%s9.%s  XRAY VMESS MENU\n' "$_yellow" "$_reset"
    printf '%s10.%s XRAY VLESS MENU\n' "$_yellow" "$_reset"
    printf '%s11.%s XRAY TROJAN MENU\n' "$_yellow" "$_reset"
    printf '%s12.%s TROJAN GO MENU\n' "$_yellow" "$_reset"
    printf '%s13.%s INFO ALL PORT\n' "$_yellow" "$_reset"
    printf '%s14.%s XRAY VERSION\n' "$_yellow" "$_reset"
    printf '%s15.%s CHECK IP PORT\n' "$_yellow" "$_reset"
    printf '%s16.%s CHECK SERVICE VPN\n' "$_yellow" "$_reset"
    printf '%s17.%s UPDATE SSH\n' "$_yellow" "$_reset"
    printf '%s18.%s FIX SSLH+WS-TLS Error after reboot\n' "$_yellow" "$_reset"
    printf '%s19.%s SETTINGS\n' "$_yellow" "$_reset"
    printf '%s20.%s CHECK CPU & RAM\n' "$_yellow" "$_reset"
    printf '%s21.%s CHECK BANDWIDTH\n' "$_yellow" "$_reset"
    printf '%s22.%s DNS CHANGER\n' "$_yellow" "$_reset"
    printf '%s23.%s NETFLIX CHECKER\n' "$_yellow" "$_reset"
    printf '%s24.%s DELETE EXPIRED USERS\n' "$_yellow" "$_reset"
    printf '%s25.%s EXIT\n' "$_yellow" "$_reset"
    printf '%s————————————————————————————————————————————————————————%s\n' "$_blue" "$_reset"
}

show_menu
read -r -p 'Select From Options [ 1 - 25 ] : ' menu
case "$menu" in
    1) clear; udpmenu ;;
    2) clear; sshovpnmenu ;;
    3) clear; l2tpmenu ;;
    4) clear; pptpmenu ;;
    5) clear; sstpmenu ;;
    6) clear; wgmenu ;;
    7) clear; ssmenu ;;
    8) clear; ssrmenu ;;
    9) clear; vmessmenu ;;
    10) clear; vlessmenu ;;
    11) clear; trmenu ;;
    12) clear; trgomenu ;;
    13) clear; vpninfo ;;
    14) clear; xray version ;;
    15) clear; ipsaya ;;
    16) clear; running ;;
    17) clear; updatemenu ;;
    18) clear; sl-fix ;;
    19) clear; setmenu ;;
    20) clear; htop ;;
    21) clear; vnstat ;;
    22) clear; dns ;;
    23) clear; netf ;;
    24) clear; delexp && xp && restart ;;
    25) clear; exit 0 ;;
    *) clear; menu ;;
esac
