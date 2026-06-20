# AGENTS.md — developer-server

Context for AI agents working in this repository. Read it before proposing or applying changes.

## What this project is

Repository of the **internal tools and services** deployed on the development server,
used mainly on the **local network** (some reachable over the public web).
It is a **multi-purpose homelab**: development, network control, productivity and media.

It is not an application: it is infrastructure as code + Docker Compose manifests + operational documentation.

## Scope boundary (IMPORTANT)

- **THIS repo** covers: Docker services (`docker/`) and server automation
  (Ansible, static IPs, VPN, SSH).
- **Does NOT belong here**: the public-exposure layer (FRP server, Kubernetes, Ingress,
  cert-manager). That lives in `/srv/kubernetes-server`.
- Tolerated exception: `docker/frp/` is the local FRP **client** (frpc). If moving it is
  proposed, check with the owner first.

## Structure

| Directory         | Purpose                                                          |
| ----------------- | ---------------------------------------------------------------- |
| `docker/`         | Docker Compose services, one per subdirectory                    |
| `homepage/`       | Homelab dashboard (gethomepage), config in YAML                  |
| `ansible/`        | Provisioning playbooks (SSH, Docker, UFW, reboot/shutdown)       |
| `vpn/`            | OpenVPN client generation and deployment                         |
| `vps/`            | Notes and keys for external VPS (AWS, etc.)                      |
| `ssh/`            | SSH configuration notes                                          |
| `docs/`           | Reference guides (nmap, ansible, Windows machines)               |
| `config/`         | Ansible inventory, reserved IPs, base configuration              |
| `scripts/`        | Support scripts (git, ssh, bash functions)                       |
| `start.sh` / `verify.sh` | Assign/verify the static IP via netplan or dhcpcd         |

## How the core works

- **Static IP**: `start.sh -i <interface> -g <gateway>` reads the hostname, looks up its
  reserved IP in `config/config.ini` and generates the netplan. `verify.sh` validates it.
- **`config/config.ini`**: `hostname → IP + MAC` map. The MAC is written by `start.sh`
  automatically (leave the `MAC=` field empty and the script fills it in).
  - ⚠️ **The MAC is currently recorded but NOT consumed** by any code
    (netplan matches by interface name, not by MAC). It is kept on purpose for a future
    **Wake-on-LAN** (`wake-servers.yml`, does not exist yet; complements
    `ansible/shutdown-servers.yml`). Do not remove it without asking.
- **Ansible**: inventory in `config/inventory.ini`, config in `config/ansible.cfg`.
  Always use `--limit` on destructive playbooks (shutdown/reboot).
- **Docker**: each service is started with `cd docker/<service> && docker compose up -d`.

## Conventions

- **English & minimalist.** All documentation (`README`, `*-readme.md`) and code comments
  are written in English. Keep them minimal — comment only where necessary (non-obvious
  decisions, gotchas, security notes), never to restate what the code already says.
- **One service = one subdirectory** in `docker/` with `docker-compose.yml` + `<app>-readme.md`.
- **Config via `env_file`.** Compose files load container config from `.env` (via `env_file:`),
  not inline `environment:` values. Commit a `.env.example` with dummy values as the template;
  the real `.env` is gitignored. NEVER hardcode credentials in compose or configs.
  `.env`, `*.ovpn`, `*.key`, `*.sql` and `vps/keys/*` are gitignored — verified, not versioned.
- **Conventional commits** (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`).
  Do **NOT** add AI attribution or `Co-Authored-By`.
- **Dockerfile** with a capital D.

## Security — state and pending items

- ✅ Verified: no `.env` or `.ovpn` is tracked in git (nor in history).
- 🔴 **PENDING before making the repo PUBLIC**: `config/config.ini` and
  `config/inventory.ini` ARE versioned and expose internal IPs (192.168.x / 10.8.x VPN),
  real physical MACs and `ansible_user=luis122448`. Resolve (sanitize / move to `.gitignore` /
  use variables) before publishing.
- `config/ansible.cfg` has `host_key_checking = False` (convenient in a homelab, MITM risk).
- `scripts/setup-ssh-*.sh` copy the **private key** to the remote server via scp — anti-pattern
  pending review.

## Known improvement backlog (not urgent)

- Version pinning: the compose files use `:latest` (no reproducible rollback).
- Missing `healthcheck` on almost every service.
- No README: `docker/immich/`, `docker/arr/`, `docker/webtop/`.
- READMEs with ports out of sync vs compose (verify before trusting).
- Bash scripts without `set -euo pipefail` (`start.sh`, `verify.sh`, `functions.sh`, `music.sh`).
- Redundancy in `vpn/`: 3 `generate-ovpn*.sh` scripts and 3 `generate-single-client*.yml` playbooks
  that are nearly identical; `generate-local-clients.yml` calls `generate_ovpn.sh` (underscore) which does not exist.

## Working rules for the agent

- **Verify before asserting.** This repo has had false positives in audits (an agent
  reported a secret "in git" that was actually gitignored). Confirm with `git ls-files` /
  `git log` before declaring a secret exposure.
- Do not delete files without confirming they are dummy and unreferenced.
- Do not build or `docker compose up` unless explicitly asked.
- When an action is destructive or outward-facing (publish, push, delete), confirm first.
