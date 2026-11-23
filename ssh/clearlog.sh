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
data=(`find /var/log/ -name *.log`);
for log in "${data[@]}"
do
echo "$log clear"
echo > $log
done
data=(`find /var/log/ -name *.err`);
for log in "${data[@]}"
do
echo "$log clear"
echo > $log
done
data=(`find /var/log/ -name mail.*`);
for log in "${data[@]}"
do
echo "$log clear"
echo > $log
done
echo > /var/log/syslog
echo > /var/log/btmp
echo > /var/log/messages
echo > /var/log/debug
echo -e "Mod By ${PROJECT_OWNER}"
