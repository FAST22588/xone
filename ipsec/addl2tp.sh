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
if [[ "$IP" = "" ]]; then
PUBLIC_IP=$(wget -qO- ipinfo.io/ip);
else
PUBLIC_IP=$IP
fi
source /var/lib/crot/ipvps.conf
if [[ "$IP2" = "" ]]; then
domain=$(cat /etc/xray/domain)
else
domain=$IP2
fi
until [[ $VPN_USER =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
		read -rp "Username : " -e VPN_USER
		CLIENT_EXISTS=$(grep -w $VPN_USER /var/lib/crot/data-user-l2tp | wc -l)

		if [[ ${CLIENT_EXISTS} == '1' ]]; then
			echo ""
			echo -e "Username ${RED}${VPN_USER}${NC} Already On VPS Please Choose Another"
			exit 1
		fi
	done
read -p "Password : " VPN_PASSWORD
read -p "Expired (Days) : " masaaktif
hariini=`date -d "0 days" +"%Y-%m-%d"`
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
clear

# Add or update VPN user
cat >> /etc/ppp/chap-secrets <<EOF
"$VPN_USER" l2tpd "$VPN_PASSWORD" *
EOF

VPN_PASSWORD_ENC=$(openssl passwd -1 "$VPN_PASSWORD")
cat >> /etc/ipsec.d/passwd <<EOF
$VPN_USER:$VPN_PASSWORD_ENC:xauth-psk
EOF

# Update file attributes
chmod 600 /etc/ppp/chap-secrets* /etc/ipsec.d/passwd*
echo -e "### $VPN_USER $exp">>"/var/lib/crot/data-user-l2tp"
cat <<EOF

============================
L2TP/IPSEC PSK VPN
============================
IP/Host    : $PUBLIC_IP
Domain     : $domain
IPsec PSK  : myvpn
Username   : $VPN_USER
Password   : $VPN_PASSWORD
Created    : $hariini
Expired    : $exp
============================
Script Mod By ${PROJECT_OWNER}
EOF
