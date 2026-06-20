# Developer Server — Homelab & Internal Services

Repositorio de las herramientas y servicios desplegados en el servidor de desarrollo,
de uso principalmente en **red local** (algunos también accesibles vía web pública).

> **Alcance:** Este repo cubre los servicios internos (Docker) y la automatización de
> infraestructura del servidor. La capa de exposición pública (FRP, Kubernetes, Ingress,
> certificados) vive en `/srv/kubernetes-server`.

---

## Estructura del repositorio

| Directorio        | Propósito                                                        |
| ----------------- | ---------------------------------------------------------------- |
| `docker/`         | Servicios desplegados con Docker Compose (uno por subdirectorio) |
| `ansible/`        | Playbooks de provisión de servidores (SSH, Docker, UFW, energía) |
| `vpn/`            | Generación y despliegue de clientes OpenVPN                      |
| `vps/`            | Notas y llaves de VPS externos (AWS, etc.)                       |
| `ssh/`            | Notas de configuración SSH                                       |
| `docs/`           | Guías de referencia (nmap, ansible, equipos Windows)             |
| `config/`         | Inventario Ansible, IPs reservadas, configuración base           |
| `scripts/`        | Scripts de soporte (git, ssh, funciones)                         |

---

## Servicios desplegados (`docker/`)

Cada servicio tiene su propio `docker-compose.yml` y un `*-readme.md` con detalles.
El acceso es por `http://<IP-servidor>:<puerto>` salvo que se indique lo contrario.

### 🛠️ Desarrollo

| Servicio           | Puerto | Descripción                          |
| ------------------ | ------ | ------------------------------------ |
| `code-server`      | 8004   | VS Code en el navegador              |
| `code-server-lite` | 8010   | VS Code ligero / efímero             |
| `registry`         | 5000   | Registry Docker privado              |
| `portainer`        | 9000   | Gestión de contenedores Docker       |

### 🌐 Red / Acceso

| Servicio | Acceso         | Descripción                                       |
| -------- | -------------- | ------------------------------------------------- |
| `proxy`  | configs nginx  | Reverse proxy (no es un compose, son `.conf`)     |
| `ssl`    | configs nginx  | Configuración TLS / dominios (`.conf`)            |
| `frp`    | `frpc.toml`    | Cliente de túnel FRP hacia el servidor público    |

### 📄 Productividad / Oficina

| Servicio      | Puerto    | Descripción                       |
| ------------- | --------- | --------------------------------- |
| `nextcloud`   | host net  | NAS / almacenamiento de archivos  |
| `onlyoffice`  | 8008      | Edición de documentos online      |
| `trilium`     | 8009      | Notas jerárquicas                 |
| `stirling-pdf`| 8007      | Utilidades PDF                    |

### 🎬 Media / Personal

| Servicio      | Puerto              | Descripción                          |
| ------------- | ------------------- | ------------------------------------ |
| `plex`        | host net            | Servidor multimedia                  |
| `navidrome`   | 8003                | Servidor de música                   |
| `invidious`   | 8006                | Frontend alternativo de YouTube      |
| `immich`      | 2283                | Gestión de fotos                     |
| `arr`         | 9696/8989/7878/6767 | Stack *arr (prowlarr/sonarr/radarr/bazarr) |
| `qbittorrent` | host net            | Cliente torrent                      |
| `webtop`      | 4500                | Escritorio Linux en el navegador     |
| `brave`       | 8005                | Navegador Brave en el navegador      |

> Levantar un servicio: `cd docker/<servicio> && docker compose up -d`

---

## Aprovisionamiento del servidor

Esta sección configura un nuevo servidor: IP estática reservada + gestión vía Ansible.

### Prerrequisitos — OpenSSH Server

<details>
<summary>Ubuntu</summary>

```bash
sudo apt update
sudo apt install openssh-server
sudo systemctl enable --now ssh
```

</details>

<details>
<summary>Arch Linux</summary>

```bash
sudo pacman -Syu
sudo pacman -S openssh
sudo systemctl enable --now sshd
```

</details>

<details>
<summary>Oracle Linux</summary>

```bash
sudo yum install openssh-server
sudo systemctl enable --now sshd
```

</details>

Generar par de llaves SSH:

```bash
ssh-keygen -t rsa -b 4096
```

### Paso 1 — Clonar el repositorio

```bash
cd /srv
sudo chown -R $USER:$USER /srv
git clone https://github.com/luis122448/developer-server.git
cd developer-server
```

### Paso 2 — Configurar hostname e IP

1. Verificar hostname: `hostnamectl`
2. Editar `config/config.ini` y asegurar que el hostname y la IP estática estén definidos.
   Si no existe, agregar la entrada (dejar `MAC` vacío; el script lo completa):

   ```ini
   [your-hostname]
   IP=192.168.100.X
   MAC=
   ```

3. Si el hostname del sistema no coincide con `config.ini`, sincronizarlo
   (`/etc/hostname`, `/etc/hosts`) y reiniciar.

### Paso 3 — Asignar IP estática

```bash
ip addr show                                          # identificar interfaz
sudo bash ./start.sh -i <interface> -g <gateway_ip>   # asignar IP reservada
sudo bash ./verify.sh -i <interface>                  # verificar
```

---

## Gestión con Ansible (desde la máquina master)

**Requisito:** `sshpass`

<details>
<summary>Instalar sshpass</summary>

```bash
# Ubuntu
sudo apt install sshpass
# Arch
sudo pacman -S sshpass
# Oracle
sudo yum install sshpass
```

</details>

Agregar el nuevo host al inventario `config/inventory.ini`:

```ini
[all]
your-hostname ansible_host=192.168.100.107
```

```bash
# Autenticación inicial por SSH key
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ./config/inventory.ini ./ansible/init-ssh.yml --ask-pass --ask-become-pass --limit $GROUP1

# Abrir puerto en el firewall (UFW)
ansible-playbook -i ./config/inventory.ini ./ansible/ufw-open-port.yml --ask-become-pass -e "target_port=8080" --limit $GROUP1

# Instalar Docker (opcional)
ansible-playbook -i ./config/inventory.ini ./ansible/install-docker.yml --ask-become-pass --limit $GROUP1
```

### Conectividad

```bash
ansible -i ./config/inventory.ini all -m ping        # todos los hosts
ansible -i ./config/inventory.ini $GROUP1 -m ping    # un grupo específico
```

### Apagado de servidores

> **⚠️ Cuidado:** usá siempre `--limit` para no apagar hosts no deseados.

```bash
# Un host específico
ansible-playbook -i ./config/inventory.ini ./ansible/shutdown-servers.yml --ask-become-pass --limit hostname

# Un grupo
ansible-playbook -i ./config/inventory.ini ./ansible/shutdown-servers.yml --ask-become-pass --limit groupname
```
