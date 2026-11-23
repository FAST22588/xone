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

# ==========================================
# Color
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
# ==========================================
# Getting
MYIP=$(wget -qO- ipinfo.io/ip);
echo "Checking VPS"
IZIN=$( curl ipinfo.io/ip | grep $MYIP )
if [ $MYIP = $MYIP ]; then
echo -e "${NC}${GREEN}Permission Accepted...${NC}"
else
echo -e "${NC}${RED}Permission Denied!${NC}";
echo -e "${NC}${LIGHT}Fuck You!!"
exit 0
fi
clear
source /var/lib/crot/ipvps.conf
if [[ "$IP2" = "" ]]; then
domain=$(cat /etc/xray/domain)
else
domain=$IP2
fi
IP=$(wget -qO- ipinfo.io/ip);
sstp="$(cat ~/log-install.txt | grep -i SSTP | cut -d: -f2|sed 's/ //g')"
until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
		read -rp "Usernew : " -e user
		CLIENT_EXISTS=$(grep -w $user /var/lib/crot/data-user-sstp | wc -l)

		if [[ ${CLIENT_EXISTS} == '1' ]]; then
			echo ""
			echo -e "Username ${RED}${user}${NC} Already On VPS Please Choose Another"
			exit 1
		fi
	done
read -p "Password : " pass
read -p "Expired (Days) : " masaaktif
hariini=`date -d "0 days" +"%Y-%m-%d"`
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
cat >> /home/sstp/sstp_account <<EOF
$user * $pass *
EOF
echo -e "### $user $exp">>"/var/lib/crot/data-user-sstp"
clear
cat <<EOF

============================
SSTP VPN
============================
IP/Host   : $IP
Domain    : $domain
Username  : $user
Password  : $pass
Port      : $sstp
Cert      : http://$IP:89/server.crt
Created   : $hariini
Expired   : $exp
============================
Script Mod By ${PROJECT_OWNER}
EOF
