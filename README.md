# SSH/VPN menu with UDP Custom

This package is based on the `hop` source tree and adds a configurable UDP Custom service, a consolidated project settings file, and safer script-package updates.

## OS compatibility targets

- Debian 9, 10, and 11
- Ubuntu 18.04 and 20.04
- UDP Custom binary: x86_64/amd64 VPS

These releases are compatibility targets from the upstream project, not a claim of current OS security support. This package has not been installed against live VPS instances for every listed release; older releases may need working archive mirrors or an extended-support repository before `apt-get update` can succeed.

## Configure the project owner and repository

Edit `config.env` in one place before publishing a fork. Set `PROJECT_OWNER`, `PROJECT_REPO`, and `PROJECT_BRANCH`. The same values drive the displayed owner, source downloads, and menu update. Add-on binaries can use `ADDONS_OWNER` and `ADDONS_REPO` separately.

## One-paste installation

Replace the three values, then paste the whole command once as root:

```sh
PROJECT_OWNER="YOUR_GITHUB_OWNER"; PROJECT_REPO="YOUR_REPOSITORY"; PROJECT_BRANCH="main"; export PROJECT_OWNER PROJECT_REPO PROJECT_BRANCH; apt-get update -y && apt-get install -y ca-certificates curl && curl -fsSL "https://raw.githubusercontent.com/${PROJECT_OWNER}/${PROJECT_REPO}/${PROJECT_BRANCH}/install.sh" -o /tmp/project-install.sh && bash /tmp/project-install.sh
```

The installer downloads one pinned repository archive, checks the operating system, installs required tools, and starts the existing service setup. It stores the selected owner/repository/branch for future updates, leaves SSH running, and does not reboot the VPS automatically.

## Menu

- `menu` opens the main menu.
- Option 1 opens UDP Custom management.
- Option 17 updates the script package from the repository in `/etc/nevermore-vpn/config.env`.
- The server information panel displays the installed GitHub commit prefix when available. The UDP column counts configured UDP Custom passwords when the JSON config contains a password list.

UDP Custom uses the bundled UDP Custom server binary and defaults to UDP port `36712`. The menu can install/configure it, show status, start, stop, restart, or remove its service. The JSON configuration and project environment file are kept when the service is removed. Only the selected UDP port is added to iptables, and a pre-existing firewall rule is not claimed by the installer.

## Configuration and update behavior

The live configuration is `/etc/nevermore-vpn/config.env`. Updates stage the complete source under `/opt/nevermore-vpn/releases/`, switch the `current` source pointer, and refresh all menu and service-management command scripts listed in `update/install-manifest.tsv`. They do not overwrite project configuration, UDP JSON, account files, or credentials stored outside those command scripts. Replaced command scripts are backed up under `/var/backups/nevermore-vpn/`.

## Uninstall

Run `bash /opt/nevermore-vpn/current/hapus/uninstall` to remove the package-managed menu and UDP Custom service. The uninstaller keeps account/configuration data, credentials, and SSH access; the original VPN services and operating-system packages are not purged automatically.

## UDP implementation references

- `VVV` advertises UDP Custom in its README and installs BadVPN UDP gateways on localhost ports 7100, 7200, and 7300.
- The actual UDP Custom server/service pattern used here is adapted from `Vergil/Tunnel/udp.sh` and its default config; the downloaded `VVV` tree does not contain a UDP Custom installer.
- The original `hop` BadVPN UDPGW remains available separately from UDP Custom.
