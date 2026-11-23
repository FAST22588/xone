#!/bin/sh
set -eu

_PROJECT_CONFIG_LIB=/usr/local/lib/nevermore-vpn/project-config.sh
if [ ! -r "$_PROJECT_CONFIG_LIB" ]; then
    _PROJECT_SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE:-$0}")" 2>/dev/null && pwd)
    [ -r "$_PROJECT_SCRIPT_DIR/../lib/project-config.sh" ] && _PROJECT_CONFIG_LIB="$_PROJECT_SCRIPT_DIR/../lib/project-config.sh"
fi
[ -r "$_PROJECT_CONFIG_LIB" ] || { echo "Project config helper is missing: $_PROJECT_CONFIG_LIB" >&2; exit 1; }
. "$_PROJECT_CONFIG_LIB"

UDP_CUSTOM_DIR="${PROJECT_CONFIG_DIR}/udp-custom"
UDP_CUSTOM_BINARY="/usr/local/bin/udp-custom"
UDP_CUSTOM_SERVICE="/etc/systemd/system/udp-custom.service"
UDP_FIREWALL_SERVICE="/etc/systemd/system/udp-custom-firewall.service"
UDP_CUSTOM_WRAPPER="/usr/local/sbin/udp-custom-server"
UDP_FIREWALL_WRAPPER="/usr/local/sbin/udp-custom-firewall"
UDP_FIREWALL_MARKER="${UDP_CUSTOM_DIR}/firewall-managed-port"
UDP_SOURCE_BINARY="/usr/local/lib/nevermore-vpn/udp-custom-linux-amd64"
UDP_SOURCE_CONFIG="/usr/local/lib/nevermore-vpn/udp-custom-default.json"

require_root() {
    [ "$(id -u)" -eq 0 ] || { echo "Run this command as root." >&2; exit 1; }
}

valid_port() {
    case "${1:-}" in *[!0-9]*|"") return 1 ;; esac
    [ "$1" -ge 1 ] && [ "$1" -le 65535 ]
}

valid_exclude() {
    case "${1:-}" in *[!A-Za-z0-9,.:/_-]*) return 1 ;; esac
    return 0
}

write_firewall_wrapper() {
    cat > "$UDP_FIREWALL_WRAPPER" <<EOF
#!/bin/sh
set -eu
_config="$PROJECT_CONFIG_DIR/config.env"
[ -r "\$_config" ] && . "\$_config"
_dir="\${PROJECT_CONFIG_DIR:-/etc/nevermore-vpn}/udp-custom"
_marker="\$_dir/firewall-managed-port"
_action="\${1:-ensure}"
_port="\${UDP_CUSTOM_PORT:-36712}"
case "\$_port" in *[!0-9]*|"") exit 0 ;; esac
[ "\$_port" -ge 1 ] && [ "\$_port" -le 65535 ] || exit 0
_iptables=\$(command -v iptables 2>/dev/null || true)
[ -n "\$_iptables" ] || exit 0
case "\$_action" in
    ensure)
        if ! "\$_iptables" -C INPUT -p udp --dport "\$_port" -j ACCEPT >/dev/null 2>&1; then
            "\$_iptables" -I INPUT -p udp --dport "\$_port" -j ACCEPT
            printf '%s\n' "\$_port" > "\$_marker"
            command -v netfilter-persistent >/dev/null 2>&1 && netfilter-persistent save >/dev/null 2>&1 || true
        fi
        ;;
    remove)
        if [ -r "\$_marker" ]; then
            _port=$(cat "\$_marker" 2>/dev/null || true)
        fi
        case "\$_port" in *[!0-9]*|"") exit 0 ;; esac
        [ "\$_port" -ge 1 ] && [ "\$_port" -le 65535 ] || exit 0
        if [ -r "\$_marker" ]; then
            "\$_iptables" -D INPUT -p udp --dport "\$_port" -j ACCEPT >/dev/null 2>&1 || true
            rm -f "\$_marker"
            command -v netfilter-persistent >/dev/null 2>&1 && netfilter-persistent save >/dev/null 2>&1 || true
        fi
        ;;
esac
EOF
    chmod 0755 "$UDP_FIREWALL_WRAPPER"
}

configure_service() {
    cat > "$UDP_CUSTOM_WRAPPER" <<EOF
#!/bin/sh
set -eu
. "$PROJECT_CONFIG_DIR/config.env"
if [ -n "\${UDP_CUSTOM_EXCLUDE:-}" ]; then
    exec "$UDP_CUSTOM_BINARY" server -exclude "\$UDP_CUSTOM_EXCLUDE"
fi
exec "$UDP_CUSTOM_BINARY" server
EOF
    chmod 0755 "$UDP_CUSTOM_WRAPPER"

    cat > "$UDP_FIREWALL_SERVICE" <<EOF
[Unit]
Description=UDP Custom firewall rule
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$UDP_FIREWALL_WRAPPER ensure
ExecStop=$UDP_FIREWALL_WRAPPER remove

[Install]
WantedBy=multi-user.target
EOF

    cat > "$UDP_CUSTOM_SERVICE" <<EOF
[Unit]
Description=UDP Custom service
After=network-online.target udp-custom-firewall.service
Wants=network-online.target
Requires=udp-custom-firewall.service

[Service]
Type=simple
User=root
WorkingDirectory=$UDP_CUSTOM_DIR
ExecStart=$UDP_CUSTOM_WRAPPER
Restart=on-failure
RestartSec=2s
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF
}

install_udp() {
    require_root
    _port="${1:-$UDP_CUSTOM_PORT}"
    _exclude="${2:-$UDP_CUSTOM_EXCLUDE}"
    valid_port "$_port" || { echo "Port must be an integer from 1 to 65535." >&2; exit 2; }
    valid_exclude "$_exclude" || { echo "Exclude list may contain letters, numbers, comma, dot, colon, slash, underscore and hyphen only." >&2; exit 2; }
    case "$(uname -m)" in x86_64|amd64) ;; *) echo "UDP Custom binary is available for x86_64/amd64 VPS only." >&2; exit 2 ;; esac
    command -v systemctl >/dev/null 2>&1 || { echo "systemd is required for this service." >&2; exit 2; }
    command -v jq >/dev/null 2>&1 || { echo "jq is required. Install it with: apt-get install -y jq" >&2; exit 2; }

    mkdir -p "$UDP_CUSTOM_DIR" /usr/local/lib/nevermore-vpn /usr/local/sbin
    chmod 0750 "$UDP_CUSTOM_DIR"
    if [ ! -s "$UDP_SOURCE_BINARY" ]; then
        _tmp_bin=$(mktemp)
        if ! curl -fsSL "${PROJECT_RAW_BASE}/udp/udp-custom-linux-amd64" -o "$_tmp_bin"; then
            rm -f "$_tmp_bin"
            echo "Could not download the UDP Custom binary from ${PROJECT_RAW_BASE}/udp/." >&2
            exit 1
        fi
        install -m 0755 "$_tmp_bin" "$UDP_SOURCE_BINARY"
        rm -f "$_tmp_bin"
    fi
    install -m 0755 "$UDP_SOURCE_BINARY" "$UDP_CUSTOM_BINARY"

    if [ ! -s "$UDP_CUSTOM_DIR/config.json" ]; then
        _tmp_config=$(mktemp)
        if [ -s "$UDP_SOURCE_CONFIG" ]; then
            cp "$UDP_SOURCE_CONFIG" "$_tmp_config"
        elif ! curl -fsSL "${PROJECT_RAW_BASE}/udp/config.json" -o "$_tmp_config"; then
            rm -f "$_tmp_config"
            cat > "$UDP_CUSTOM_DIR/config.json" <<'EOF'
{
  "listen": ":36712",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": { "mode": "passwords" }
}
EOF
        else
            install -m 0640 "$_tmp_config" "$UDP_CUSTOM_DIR/config.json"
            rm -f "$_tmp_config"
        fi
        if [ -s "$_tmp_config" ]; then
            install -m 0640 "$_tmp_config" "$UDP_CUSTOM_DIR/config.json"
            rm -f "$_tmp_config"
        fi
    fi
    jq -e . "$UDP_CUSTOM_DIR/config.json" >/dev/null || { echo "UDP Custom config is not valid JSON; preserved at $UDP_CUSTOM_DIR/config.json" >&2; exit 1; }
    _tmp_config=$(mktemp)
    jq --arg listen ":$_port" '.listen = $listen' "$UDP_CUSTOM_DIR/config.json" > "$_tmp_config"
    install -m 0640 "$_tmp_config" "$UDP_CUSTOM_DIR/config.json"
    rm -f "$_tmp_config"

    UDP_CUSTOM_PORT="$_port"
    UDP_CUSTOM_EXCLUDE="$_exclude"
    _tmp_env=$(mktemp)
    if [ -r "$PROJECT_CONFIG_DIR/config.env" ]; then
        cp -p "$PROJECT_CONFIG_DIR/config.env" "$_tmp_env"
        if grep -q '^UDP_CUSTOM_PORT=' "$_tmp_env"; then
            sed -i "s/^UDP_CUSTOM_PORT=.*/UDP_CUSTOM_PORT=\"$_port\"/" "$_tmp_env"
        else
            printf '\nUDP_CUSTOM_PORT="%s"\n' "$_port" >> "$_tmp_env"
        fi
        if grep -q '^UDP_CUSTOM_EXCLUDE=' "$_tmp_env"; then
            sed -i "s/^UDP_CUSTOM_EXCLUDE=.*/UDP_CUSTOM_EXCLUDE=\"$_exclude\"/" "$_tmp_env"
        else
            printf 'UDP_CUSTOM_EXCLUDE="%s"\n' "$_exclude" >> "$_tmp_env"
        fi
    else
        cat > "$_tmp_env" <<EOF
PROJECT_NAME="$PROJECT_NAME"
PROJECT_OWNER="$PROJECT_OWNER"
PROJECT_REPO="$PROJECT_REPO"
PROJECT_BRANCH="$PROJECT_BRANCH"
PROJECT_CONFIG_DIR="$PROJECT_CONFIG_DIR"
PROJECT_INSTALL_DIR="$PROJECT_INSTALL_DIR"
ADDONS_OWNER="$ADDONS_OWNER"
ADDONS_REPO="$ADDONS_REPO"
UDP_CUSTOM_PORT="$_port"
UDP_CUSTOM_EXCLUDE="$_exclude"
UDP_CUSTOM_MAX_CLIENTS="$UDP_CUSTOM_MAX_CLIENTS"
EOF
    fi
    install -m 0600 "$_tmp_env" "$PROJECT_CONFIG_DIR/config.env"
    rm -f "$_tmp_env"

    write_firewall_wrapper
    configure_service
    systemctl daemon-reload
    systemctl enable udp-custom-firewall.service >/dev/null
    systemctl enable udp-custom.service >/dev/null
    systemctl restart udp-custom-firewall.service
    systemctl restart udp-custom.service
    echo "UDP Custom is installed. Listen address: :$_port/udp"
}

show_status() {
    _port=$(jq -r '.listen // "unknown"' "$UDP_CUSTOM_DIR/config.json" 2>/dev/null || printf 'unknown')
    printf 'UDP Custom: '
    systemctl is-active udp-custom.service 2>/dev/null || true
    printf 'Listen address: %s/udp\n' "$_port"
    systemctl --no-pager --full status udp-custom.service 2>/dev/null | sed -n '1,10p' || true
}

remove_udp() {
    require_root
    printf 'Remove the UDP Custom service and binary? Configuration will be kept in %s. [y/N] ' "$UDP_CUSTOM_DIR"
    read -r _answer
    case "$_answer" in y|Y|yes|YES)
        systemctl disable --now udp-custom.service udp-custom-firewall.service >/dev/null 2>&1 || true
        rm -f "$UDP_CUSTOM_SERVICE" "$UDP_FIREWALL_SERVICE" "$UDP_CUSTOM_WRAPPER" "$UDP_FIREWALL_WRAPPER" "$UDP_CUSTOM_BINARY"
        systemctl daemon-reload
        echo "UDP Custom service removed; config and tokens were kept in $UDP_CUSTOM_DIR."
        ;; *) echo "Cancelled." ;; esac
}

case "${1:-menu}" in
    install) install_udp "${2:-}" "${3:-}" ;;
    start) require_root; systemctl start udp-custom.service ;;
    stop) require_root; systemctl stop udp-custom.service ;;
    restart) require_root; systemctl restart udp-custom.service ;;
    status) show_status ;;
    remove) remove_udp ;;
    *) echo "Usage: $0 {install [PORT [EXCLUDE]]|start|stop|restart|status|remove}" >&2; exit 2 ;;
esac
