# Xone VPN + UDP Custom

Xone is based on the Hop VPN script package and adds a configurable UDP Custom service, a consolidated project settings file, and safer script-package updates.

## OS compatibility targets

- Debian 9, 10, and 11
- Ubuntu 18.04 and 20.04
- UDP Custom binary: x86_64/amd64 VPS

These are compatibility targets from the upstream project, not a claim of current OS security support. This package has not been installed on live VPS instances for every listed release. Older releases may need working archive mirrors or an extended-support repository before `apt-get update` can succeed.

## One-paste installation

Run as root. Paste the whole command once:

```sh
PROJECT_OWNER="FAST22588"; PROJECT_REPO="xone"; PROJECT_BRANCH="main"; export PROJECT_OWNER PROJECT_REPO PROJECT_BRANCH; apt-get update -y && apt-get install -y ca-certificates curl && curl -fsSL "https://raw.githubusercontent.com/${PROJECT_OWNER}/${PROJECT_REPO}/${PROJECT_BRANCH}/install.sh" -o /tmp/xone-install.sh && bash /tmp/xone-install.sh
```

The installer downloads a pinned repository archive when GitHub provides the commit information, checks the operating system, installs required tools, and starts the service setup. It records the selected owner/repository/branch for later updates, leaves SSH running, and does not reboot the VPS automatically.

## Project settings

Edit `config.env` before publishing a fork. The primary values are:

```sh
: "${PROJECT_NAME:=Xone VPN}"
: "${PROJECT_OWNER:=FAST22588}"
: "${PROJECT_REPO:=xone}"
: "${PROJECT_BRANCH:=main}"
```

Add-on and SlowDNS sources have separate owner/repository settings. Keep them pointed at repositories that actually provide those files, or mirror the dependencies and update the corresponding settings. Do not change every dependency owner just because the main project moved to `FAST22588/xone`.

## Main menu

- Option 1 opens UDP Custom management.
- Option 17 updates the managed script package from the repository configured in `/etc/nevermore-vpn/config.env`.
- The server information panel displays the installed GitHub commit prefix when available.
- The UDP count uses the configured UDP Custom password list when one is present in the JSON config.

UDP Custom defaults to UDP port `36712`. Its menu can install/configure the service, show status, start, stop, restart, or remove it. The JSON configuration and project environment file are kept when the service is removed. The installer adds only the selected UDP port to iptables and does not claim a pre-existing rule.

## Update behavior

Updates stage the full source under `/opt/nevermore-vpn/releases/`, switch the `current` source pointer, and refresh the menu and service-management command scripts listed in `update/install-manifest.tsv`. Replaced command scripts are backed up under `/var/backups/nevermore-vpn/`. Project configuration, UDP JSON, account files, and credentials outside those command scripts are kept.

## Uninstall

Run:

```sh
bash /opt/nevermore-vpn/current/hapus/uninstall
```

The uninstaller asks for an explicit confirmation phrase, backs up its managed files, then removes the package-managed menu and UDP Custom runtime. It keeps the project configuration, UDP JSON, accounts, credentials, SSH access, other legacy VPN services, and operating-system packages.

## UDP implementation notes

- The downloaded VVV source advertises UDP Custom in its README but contains BadVPN UDP gateway services rather than a separate UDP Custom installer.
- The UDP Custom binary/configuration and systemd service pattern in this package are adapted from `NevermoreSSH/Vergil/Tunnel/udp.sh`.
- Hop's BadVPN UDPGW remains separate from UDP Custom.

## Deployment note

This repository is public. Keep Cloudflare credentials, API tokens, private keys, and personal account values in VPS-side configuration rather than committing their values to the repository.
