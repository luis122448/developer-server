# Contributing

Working rules for adding, modifying or documenting services in this repository.
Keep changes small, reversible and consistent with what is already here.

## Repository layout (where things go)

| Where                | What goes here                                                       |
| -------------------- | -------------------------------------------------------------------- |
| `docker/<service>/`  | One subdirectory per service. Compose stack + env template + readme. |
| `homepage/`          | Dashboard config. Update `config/services.yaml` when adding a stack. |
| `ansible/`           | Provisioning playbooks. Always run destructive ones with `--limit`.  |
| `config/`            | Inventory, reserved IPs, base configuration.                         |
| `scripts/`           | Support scripts (git, ssh, bash helpers).                            |
| `docs/`              | Reference notes, not per-service documentation.                      |

Out of scope: anything related to public exposure (FRP server, Kubernetes, Ingress,
cert-manager) lives in `/srv/kubernetes-server`, not here.

## Adding a new Docker service

Every service is one subdirectory under `docker/` and contains exactly three files:

```
docker/<service>/
├── docker-compose.yml
├── .env.example
└── <service>-readme.md
```

### 1. `docker-compose.yml`

- Service name and `container_name` match the directory name.
- `restart: unless-stopped` unless there is a reason to use `always`.
- Map host port to container port with an explicit `HOST:CONTAINER` pair.
  Pick a host port that does not collide with anything already published on
  the target node — check `homepage/config/services.yaml` before choosing.
- Load configuration from `.env` via `env_file:`. Do NOT inline secrets in
  `environment:`. Variables that need a default may be referenced as
  `${VAR:-default}` inside `environment:`.
- Named volumes only, with `name:` set to match the volume key.
  No bind mounts to host paths unless the data physically belongs outside
  Docker (media library, an external HDD, etc.).
- Pin to an image tag when the upstream project ships one. `:latest` is
  tolerated but not preferred — it blocks reproducible rollback.

### 2. `.env.example`

- First line: `# Copy to .env:  cp .env.example .env`.
- One blank line per variable group. Comment WHY a variable matters when it
  is not obvious from its name (e.g. "required for WebAuthn", "leave empty
  to disable the admin panel").
- Dummy values only — never a real password, token or domain.
- The real `.env` is gitignored. Verified, not assumed.

### 3. `<service>-readme.md`

- Title is the service name. One-paragraph description.
- A "How to start the service" section with the exact commands.
- The port the service listens on, in plain text.
- Data section: which volume holds the state and what it contains.
- Anything non-obvious about first-time setup, clients or backups.
- English. Minimalist. No marketing copy.

## Documentation policy

- **English everywhere.** All `README`, `*-readme.md`, `CONTRIBUTING`, and inline
  comments. Conversations may happen in any language, but what gets committed is English.
- **Comments are minimalist.** Write a comment only when it carries information
  the code itself cannot: a non-obvious decision, a known gotcha, a security note,
  a workaround for a specific bug. Never restate what the code already says.
  If removing the comment would not confuse a future reader, do not write it.
- **Readmes are reference, not tutorial.** Describe what the service is, how to
  start it, where its data lives, and the few non-obvious things a future-you
  will forget. No screenshots, no walkthroughs.

## Configuration and secrets

- No credentials in compose files, configs or readmes — ever.
- `.env`, `*.ovpn`, `*.key`, `*.sql` and `vps/keys/*` are gitignored. Verify with
  `git ls-files` before claiming a secret is or is not tracked.
- If a config file must be versioned but contains a sensitive value, parameterize
  it with an env variable and document the variable in `.env.example`.

## Commits

- **Conventional Commits** only: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`,
  `style:`, `perf:`, `test:`.
- Scope when it adds clarity: `feat(vaultwarden): add stack`, `docs(homepage): ...`.
- One logical change per commit. Do not bundle unrelated edits.
- **No AI attribution.** No `Co-Authored-By: Claude`, no "Generated with ..." footers.
- Imperative mood, present tense, English. Under ~72 chars in the subject line.

## Verifying changes

- Before declaring something works, run it. `docker compose config` validates the
  compose file syntax without starting anything.
- Before declaring a secret is exposed (or safe), check `git ls-files` and
  `git log -- <path>`. This repo has had false positives in audits.
- Do not run `docker compose up`, `ansible-playbook`, `git push`, or anything
  outward-facing unless the task explicitly calls for it.

## Homepage integration

When a new service is added, register it in `homepage/config/services.yaml`
under the correct node block. Reuse the icon naming convention already present
(`<service>.png` in `homepage/config/images/`, or a `mdi-*` icon when no logo
is available).

## Backups

Stateful services must declare clearly which volume holds the irreplaceable
state, so the backup tooling (Kopia) can target it without guessing. This
goes in the readme's "Data" section.
