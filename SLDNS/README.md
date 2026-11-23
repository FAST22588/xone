# SlowDNS

SlowDNS settings are read from `/etc/nevermore-vpn/config.env`. The installer uses the configured `SLOWDNS_OWNER`, `SLOWDNS_REPO`, and `SLOWDNS_BRANCH` values to fetch the SlowDNS assets.

The installer keeps existing nameserver settings and key files. It adds SSH ports only when missing and validates `sshd_config` before reloading SSH.

Run `install-sldns` from the root menu installation. To set up a fork, edit the shared `config.env` before publishing.