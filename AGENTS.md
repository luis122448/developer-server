# AGENTS.md — developer-server

Contexto para agentes de IA que trabajen en este repositorio. Léelo antes de proponer o aplicar cambios.

## Qué es este proyecto

Repositorio de las **herramientas y servicios internos** desplegados en el servidor de
desarrollo, de uso principalmente en **red local** (algunos accesibles vía web pública).
Es un **homelab multipropósito**: desarrollo, control de red, productividad y media.

No es una aplicación: es infraestructura como código + manifiestos Docker Compose + documentación operativa.

## Límite de alcance (IMPORTANTE)

- **ESTE repo** cubre: servicios Docker (`docker/`) y automatización del servidor
  (Ansible, IPs estáticas, VPN, port-forwarding, SSH).
- **NO pertenece aquí**: la capa de exposición pública (FRP server, Kubernetes, Ingress,
  cert-manager). Eso vive en `/srv/kubernetes-server`.
- Excepción tolerada: `docker/frp/` es el **cliente** FRP (frpc) local. Si se propone moverlo,
  consultar con el dueño primero.

## Estructura

| Directorio        | Propósito                                                        |
| ----------------- | ---------------------------------------------------------------- |
| `docker/`         | Servicios con Docker Compose, uno por subdirectorio              |
| `ansible/`        | Playbooks de provisión (SSH, Docker, UFW, reboot/shutdown)       |
| `vpn/`            | Generación y despliegue de clientes OpenVPN                      |
| `vps/`            | Notas y llaves de VPS externos (AWS, etc.)                       |
| `portforwarding/` | Reenvío de puertos por dispositivo (Ansible + iptables)          |
| `networks/`       | Utilidades de red (nmap)                                         |
| `ssh/`, `windows/`| Notas de configuración por plataforma                            |
| `config/`         | Inventario Ansible, IPs reservadas, configuración base           |
| `scripts/`        | Scripts de soporte (git, ssh, funciones bash)                    |
| `start.sh` / `verify.sh` | Asignan/verifican IP estática vía netplan o dhcpcd        |

## Cómo funciona lo central

- **IP estática**: `start.sh -i <interfaz> -g <gateway>` lee el hostname, busca su IP
  reservada en `config/config.ini` y genera el netplan. `verify.sh` valida.
- **`config/config.ini`**: mapa `hostname → IP + MAC`. El MAC lo escribe `start.sh`
  automáticamente (campo `MAC=` se deja vacío y el script lo completa).
  - ⚠️ **El MAC hoy es dato registrado pero NO consumido** por ningún código
    (el netplan matchea por nombre de interfaz, no por MAC). Se mantiene a propósito
    para un futuro **Wake-on-LAN** (`wake-servers.yml`, aún no existe; complementa a
    `ansible/shutdown-servers.yml`). No lo elimines sin consultar.
- **Ansible**: inventario en `config/inventory.ini`, config en `config/ansible.cfg`.
  Siempre usar `--limit` en playbooks destructivos (shutdown/reboot).
- **Docker**: cada servicio se levanta con `cd docker/<servicio> && docker compose up -d`.

## Convenciones

- **Un servicio = un subdirectorio** en `docker/` con `docker-compose.yml` + `<app>-readme.md`.
- **Secretos en `.env`** por servicio. NUNCA hardcodear credenciales en compose o configs.
  Los `.env`, `*.ovpn`, `*.key`, `*.sql` y `vps/keys/*` están en `.gitignore` — verificado, no se versionan.
- **Commits convencionales** (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`).
  **NO** agregar atribución de IA ni `Co-Authored-By`.
- **Dockerfile** con D mayúscula.

## Seguridad — estado y pendientes

- ✅ Verificado: ningún `.env` ni `.ovpn` está trackeado en git (ni en el historial).
- 🔴 **PENDIENTE antes de hacer el repo PÚBLICO**: `config/config.ini` e
  `config/inventory.ini` SÍ están versionados y exponen IPs internas (192.168.x / 10.8.x VPN),
  MACs físicas reales y `ansible_user=luis122448`. Resolver (sanitizar / mover a `.gitignore` /
  usar variables) antes de publicar.
- `config/ansible.cfg` tiene `host_key_checking = False` (cómodo en homelab, riesgo MITM).
- `scripts/setup-ssh-*.sh` copian la **clave privada** al servidor remoto vía scp — anti-patrón
  pendiente de revisión.

## Backlog de mejoras conocidas (no urgente)

- Pinning de versiones: los 21 compose usan `:latest` (sin rollback reproducible).
- Faltan `healthcheck` en casi todos los servicios.
- Sin README: `docker/immich/`, `docker/arr/`, `docker/webtop/`.
- READMEs con puertos desactualizados vs compose (verificar antes de confiar).
- Scripts bash sin `set -euo pipefail` (`start.sh`, `verify.sh`, `functions.sh`, `music.sh`).
- Redundancia en `vpn/`: 3 scripts `generate-ovpn*.sh` y 3 playbooks `generate-single-client*.yml`
  casi idénticos; `generate-local-clients.yml` llama a `generate_ovpn.sh` (underscore) que no existe.

## Reglas de trabajo para el agente

- **Verifica antes de afirmar.** Este repo tuvo falsos positivos en auditorías (un agente
  reportó un secreto "en git" que en realidad estaba gitignored). Confirma con `git ls-files` /
  `git log` antes de declarar exposición de secretos.
- No borres archivos sin confirmar que son dummy y que nadie los referencia.
- No hagas build ni `docker compose up` salvo que se pida explícitamente.
- Cuando una acción sea destructiva o de cara al exterior (publicar, push, borrar), confirma primero.
