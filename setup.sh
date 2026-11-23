#!/bin/bash
PROJECT_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [ -r /etc/nevermore-vpn/config.env ]; then
	PROJECT_CONFIG_FILE=/etc/nevermore-vpn/config.env
else
	PROJECT_CONFIG_FILE="$PROJECT_ROOT/config.env"
fi
if [ ! -r "$PROJECT_ROOT/lib/project-config.sh" ]; then
	echo "Project configuration helper is missing from $PROJECT_ROOT/lib."
	exit 1
fi
. "$PROJECT_ROOT/lib/project-config.sh"

for _name in "$PROJECT_OWNER" "$PROJECT_REPO"; do
	case "$_name" in *[!A-Za-z0-9_.-]*|"") echo "Invalid project owner or repository name." >&2; exit 2 ;; esac
done
case "$PROJECT_BRANCH" in *[!A-Za-z0-9_./-]*|"") echo "Invalid project branch." >&2; exit 2 ;; esac

if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
fi
if [ "$(systemd-detect-virt)" == "openvz" ]; then
		echo "OpenVZ is not supported"
		exit 1
fi

if [ -f "/etc/xray/domain" ]; then
	echo "Script Already Installed"
	echo "Use menu option 17 (UPDATE SSH) to update the installed script package."
	exit 0
fi

mkdir -p "$PROJECT_CONFIG_DIR" "$PROJECT_INSTALL_DIR/releases" /usr/local/lib/nevermore-vpn
if [ ! -e "$PROJECT_CONFIG_DIR/config.env" ]; then
	_config_tmp=$(mktemp "$PROJECT_CONFIG_DIR/config.env.XXXXXX")
	cp "$PROJECT_ROOT/config.env" "$_config_tmp"
	# Persist values supplied by the one-paste installer in the live project config.
	for _key in PROJECT_OWNER PROJECT_REPO PROJECT_BRANCH; do
		case "$_key" in
			PROJECT_OWNER) _value=$PROJECT_OWNER ;;
			PROJECT_REPO) _value=$PROJECT_REPO ;;
			PROJECT_BRANCH) _value=$PROJECT_BRANCH ;;
		esac
		if grep -q "^${_key}=" "$_config_tmp"; then
			sed -i "s|^${_key}=.*|${_key}=\"${_value}\"|" "$_config_tmp"
		else
			printf '%s=\"%s\"\n' "$_key" "$_value" >> "$_config_tmp"
		fi
	done
	install -m 0600 "$_config_tmp" "$PROJECT_CONFIG_DIR/config.env"
	rm -f "$_config_tmp"
fi
. "$PROJECT_CONFIG_DIR/config.env"
while IFS='|' read -r _source _target; do
	[ -n "$_source" ] || continue
	[ -f "$PROJECT_ROOT/$_source" ] || { echo "Missing package file: $_source"; exit 1; }
	_install_mode=0755
	case "$_source" in udp/config.json) _install_mode=0640 ;; esac
	install -D -m "$_install_mode" "$PROJECT_ROOT/$_source" "$_target"
done < "$PROJECT_ROOT/update/install-manifest.tsv"

PROJECT_SOURCE_SHA="${PROJECT_INSTALL_SHA:-}"
if [[ ! "$PROJECT_SOURCE_SHA" =~ ^[0-9a-fA-F]{40}$ ]]; then
	PROJECT_SOURCE_SHA="$(curl -fsSL --max-time 20 "https://api.github.com/repos/${PROJECT_OWNER}/${PROJECT_REPO}/commits/${PROJECT_BRANCH}" 2>/dev/null | sed -n 's/.*"sha"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F]\{40\}\)".*/\1/p' | head -n 1 || true)"
fi
if [[ "$PROJECT_SOURCE_SHA" =~ ^[0-9a-fA-F]{40}$ ]]; then
	PROJECT_VERSION="${PROJECT_SOURCE_SHA:0:7}"
	PROJECT_RELEASE="$PROJECT_INSTALL_DIR/releases/$PROJECT_SOURCE_SHA"
else
	PROJECT_VERSION="unknown"
	PROJECT_RELEASE="$PROJECT_INSTALL_DIR/releases/initial-$(date +%Y%m%d%H%M%S)"
fi
if [ ! -d "$PROJECT_RELEASE" ]; then
	PROJECT_RELEASE_TMP="${PROJECT_RELEASE}.tmp.$$"
	mkdir -p "$PROJECT_RELEASE_TMP"
	tar -C "$PROJECT_ROOT" --exclude=.git -cf - . | tar -C "$PROJECT_RELEASE_TMP" -xf -
	mv "$PROJECT_RELEASE_TMP" "$PROJECT_RELEASE"
fi
PROJECT_LINK_TMP="$PROJECT_INSTALL_DIR/.current.$$"
ln -s "$PROJECT_RELEASE" "$PROJECT_LINK_TMP"
if [ -e "$PROJECT_INSTALL_DIR/current" ] && [ ! -L "$PROJECT_INSTALL_DIR/current" ]; then
	mv "$PROJECT_INSTALL_DIR/current" "$PROJECT_INSTALL_DIR/current.legacy-$(date +%Y%m%d%H%M%S)"
fi
mv -Tf "$PROJECT_LINK_TMP" "$PROJECT_INSTALL_DIR/current"
printf '%s\n' "$PROJECT_VERSION" > "$PROJECT_VERSION_FILE"

if ! command -v jq >/dev/null 2>&1; then
	apt-get update -y
	apt-get install -y jq
fi
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
# Link Hosting Kalian Untuk Ssh Vpn
akbarvpn="${PROJECT_RAW_HOST}/ssh"
# Link Hosting Kalian Untuk Sstp
akbarvpnn="${PROJECT_RAW_HOST}/sstp"
# Link Hosting Kalian Untuk Ssr
akbarvpnnn="${PROJECT_RAW_HOST}/ssr"
# Link Hosting Kalian Untuk Shadowsocks
akbarvpnnnn="${PROJECT_RAW_HOST}/shadowsocks"
# Link Hosting Kalian Untuk Wireguard
akbarvpnnnnn="${PROJECT_RAW_HOST}/wireguard"
# Link Hosting Kalian Untuk Xray
akbarvpnnnnnn="${PROJECT_RAW_HOST}/xray"
# Link Hosting Kalian Untuk Ipsec
akbarvpnnnnnnn="${PROJECT_RAW_HOST}/ipsec"
# Link Hosting Kalian Untuk Backup
akbarvpnnnnnnnn="${PROJECT_RAW_HOST}/backup"
# Link Hosting Kalian Untuk Websocket
akbarvpnnnnnnnnn="${PROJECT_RAW_HOST}/websocket"
# Link Hosting Kalian Untuk Ohp
akbarvpnnnnnnnnnn="${PROJECT_RAW_HOST}/ohp"

# Getting
MYIP=$(wget -qO- ipinfo.io/ip);
MYIP=$(curl -s ipinfo.io/ip )
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -sS ifconfig.me )
echo "Checking VPS"
IZIN=$(wget -qO- ipinfo.io/ip);

# Keep provider-managed DNS settings; add fallbacks only if resolv.conf is empty.
if [ ! -s /etc/resolv.conf ]; then
	printf '%s\n' 'nameserver 1.1.1.1' 'nameserver 8.8.8.8' > /etc/resolv.conf
fi

clear
mkdir /var/lib/crot;
echo "IP=" >> /var/lib/crot/ipvps.conf
wget https://${akbarvpn}/slhost.sh && chmod +x slhost.sh && ./slhost.sh
#install xray
wget https://${akbarvpnnnnnn}/ins-xray.sh && chmod +x ins-xray.sh && screen -S xray ./ins-xray.sh
#install ssh ovpn
wget https://${akbarvpn}/ssh-vpn.sh && chmod +x ssh-vpn.sh && screen -S ssh-vpn ./ssh-vpn.sh
wget https://${akbarvpnn}/sstp.sh && chmod +x sstp.sh && screen -S sstp ./sstp.sh
#install ssr
wget https://${akbarvpnnn}/ssr.sh && chmod +x ssr.sh && screen -S ssr ./ssr.sh
wget https://${akbarvpnnnn}/sodosok.sh && chmod +x sodosok.sh && screen -S ss ./sodosok.sh
#installwg
wget https://${akbarvpnnnnn}/wg.sh && chmod +x wg.sh && screen -S wg ./wg.sh
#install L2TP
wget https://${akbarvpnnnnnnn}/ipsec.sh && chmod +x ipsec.sh && screen -S ipsec ./ipsec.sh
wget https://${akbarvpnnnnnnnn}/set-br.sh && chmod +x set-br.sh && ./set-br.sh
# Websocket
wget https://${akbarvpnnnnnnnnn}/edu.sh && chmod +x edu.sh && ./edu.sh
# Ohp Server
wget https://${akbarvpnnnnnnnnnn}/ohp.sh && chmod +x ohp.sh && ./ohp.sh
# Install SlowDNS
wget "${PROJECT_RAW_BASE}/SLDNS/install-sldns" -O install-sldns && chmod +x install-sldns && ./install-sldns
# Informasi IP Saya dan Semua Port TCP UDP
# wget "${PROJECT_RAW_BASE}/ipsaya.sh" && chmod +x ipsaya.sh
#
# install xray sl-grpc
# wget "${PROJECT_RAW_BASE}/grpc/sl-grpc.sh" && chmod +x sl-grpc.sh && screen -S sl-grpc ./sl-grpc.sh
# install xray grpc
# wget "${PROJECT_RAW_BASE}/grpc/xray-grpc.sh" && chmod +x xray-grpc.sh && screen -S xray-grpc ./xray-grpc.sh
# install shadowsocks plugin
# wget "${PROJECT_RAW_BASE}/shadowsocks-plugin/install-ss-plugin.sh" && chmod +x install-ss-plugin.sh && ./install-ss-plugin.sh
 

rm -f /root/ssh-vpn.sh
rm -f /root/sstp.sh
rm -f /root/wg.sh
rm -f /root/ss.sh
rm -f /root/ssr.sh
rm -f /root/ins-xray.sh
rm -f /root/ipsec.sh
rm -f /root/set-br.sh
rm -f /root/edu.sh
rm -f /root/ohp.sh
rm -f /root/install
rm -f /root/sl-grpc.sh
rm -f /root/install-sldns
rm -f /root/install-ss-plugin.sh
cat <<EOF> /etc/systemd/system/autosett.service
[Unit]
Description=autosetting
Documentation=nekopoi.care

[Service]
Type=oneshot
ExecStart=/bin/bash /etc/set.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable autosett
wget -O /etc/set.sh "https://${akbarvpn}/set.sh"
chmod +x /etc/set.sh
echo "1.2" > /home/ver
echo " "
echo "Installation has been completed!!"
echo " "
if ! /usr/local/lib/nevermore-vpn/udp-manage.sh install "$UDP_CUSTOM_PORT" "$UDP_CUSTOM_EXCLUDE"; then
	echo "WARNING: Base services installed, but UDP Custom setup failed. Retry from menu option 1 after reviewing the error."
fi
echo "============================================================================" | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "----------------------------------------------------------------------------" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "   >>> Service & Port"  | tee -a log-install.txt
echo "   - SlowDNS SSH             : ALL Port SSH"  | tee -a log-install.txt
echo "   - OpenSSH                 : 22, 2253"  | tee -a log-install.txt
echo "   - OpenVPN                 : TCP 1194, UDP 2200, SSL 990"  | tee -a log-install.txt
echo "   - Stunnel5                : 443, 445"  | tee -a log-install.txt
echo "   - Dropbear                : 443, 109, 143"  | tee -a log-install.txt
echo "   - CloudFront Websocket    : "  | tee -a log-install.txt
echo "   - SSH Websocket TLS       : 443"  | tee -a log-install.txt
echo "   - SSH Websocket HTTP      : 8880"  | tee -a log-install.txt
echo "   - Websocket OpenVPN       : 2086"  | tee -a log-install.txt
echo "   - Squid Proxy             : 3128, 8000"  | tee -a log-install.txt
echo "   - Badvpn                  : 7100, 7200, 7300"  | tee -a log-install.txt
echo "   - UDP Custom              : ${UDP_CUSTOM_PORT}/udp"  | tee -a log-install.txt
echo "   - Nginx                   : 89"  | tee -a log-install.txt
echo "   - Wireguard               : 7070"  | tee -a log-install.txt
echo "   - L2TP/IPSEC VPN          : 1701"  | tee -a log-install.txt
echo "   - PPTP VPN                : 1732"  | tee -a log-install.txt
echo "   - SSTP VPN                : 444"  | tee -a log-install.txt
echo "   - Shadowsocks-R           : 1443-1543"  | tee -a log-install.txt
echo "   - SS-OBFS TLS             : 2443-2543"  | tee -a log-install.txt
echo "   - SS-OBFS HTTP            : 3443-3543"  | tee -a log-install.txt
echo "   - XRAYS Vmess TLS         : 8443"  | tee -a log-install.txt
echo "   - XRAYS Vmess None TLS    : 80"  | tee -a log-install.txt
echo "   - XRAYS Vless TLS         : 8443"  | tee -a log-install.txt
echo "   - XRAYS Vless None TLS    : 80"  | tee -a log-install.txt
echo "   - XRAYS Trojan            : 2083"  | tee -a log-install.txt
echo "   - XRAYS VMESS GRPC        : 1180"  | tee -a log-install.txt
echo "   - XRAYS VLESS GRPC        : 2280"  | tee -a log-install.txt
echo "   - OHP SSH                 : 8181"  | tee -a log-install.txt
echo "   - OHP Dropbear            : 8282"  | tee -a log-install.txt
echo "   - OHP OpenVPN             : 8383"  | tee -a log-install.txt
echo "   - TrojanGo                : 2087"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "   >>> Server Information & Other Features"  | tee -a log-install.txt
echo "   - Timezone                : Asia/Kuala_Lumpur (GMT +8)"  | tee -a log-install.txt
echo "   - Fail2Ban                : [ON]"  | tee -a log-install.txt
echo "   - Dflate                  : [ON]"  | tee -a log-install.txt
echo "   - IPtables                : [ON]"  | tee -a log-install.txt
echo "   - Auto-Reboot             : [ON]"  | tee -a log-install.txt
echo "   - IPv6                    : [OFF]"  | tee -a log-install.txt
echo "   - Autoreboot On 05.00 GMT +8" | tee -a log-install.txt
echo "   - Autobackup Data" | tee -a log-install.txt
echo "   - Restore Data" | tee -a log-install.txt
echo "   - Auto Delete Expired Account" | tee -a log-install.txt
echo "   - Full Orders For Various Services" | tee -a log-install.txt
echo "   - White Label" | tee -a log-install.txt
echo "   - Installation Log --> /root/log-install.txt"  | tee -a log-install.txt
echo ""
echo ""
echo "Installation completed. SSH was left running; reboot manually if a service requires it."
