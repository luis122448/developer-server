#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Define variables
SERVICE_FILE_QBITTORRENT="/etc/systemd/system/qbittorrent-nox.service"
CONFIG_FILE_QBITTORRENT="/var/lib/qbittorrent-nox/.config/qBittorrent/qBittorrent.conf"
DEFAULT_WEBUI_PORT="8080"
WEBUI_PORT="$DEFAULT_WEBUI_PORT" # Default port
DOWNLOAD_DIR="/mnt/torrent/downloads" # Default download directory (keeping your custom path)

# Note: Sourcing /etc/environment is kept from your original script,
# but it might not be necessary unless your environment specifically requires it.
# source /etc/environment

# Parse the command-line options
while getopts "hw:" opt; do
    case $opt in
        h|\? ) # Handle -h or any unknown option
            echo "Usage: $0 [options]"
            echo ""
            echo "Este script instala y configura qBittorrent-nox como un servicio systemd."
            echo "Crea un usuario dedicado 'qbittorrent-nox' y configura la base."
            echo ""
            echo "Opciones:"
            echo "  -h, --help      Mostrar este mensaje de ayuda."
            echo "  -w PORT         Especificar el puerto de la Web UI (por defecto: $DEFAULT_WEBUI_PORT)."
            echo ""
            echo "Nota: Para versiones >= 4.4.0, la contraseña inicial de la Web UI es aleatoria"
            echo "y se mostrará al final del script. Deberás cambiarla."
            echo "Accede a la Web UI en http://<tu_direccion_ip>:$WEBUI_PORT"
            exit 0
            ;;
        w ) WEBUI_PORT=$OPTARG
            if ! [[ "$WEBUI_PORT" =~ ^[0-9]+$ ]]; then
                echo "Error: El puerto debe ser un número." >&2
                exit 1
            fi
            if (( WEBUI_PORT < 1024 || WEBUI_PORT > 65535 )); then
                 echo "Advertencia: El puerto $WEBUI_PORT está fuera del rango típico de puertos de usuario (1024-65535)." >&2
            fi
            ;;
    esac
done

shift $((OPTIND-1)) # Shift off the options so remaining arguments can be processed (though none expected here)

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Por favor, ejecuta este script con sudo."
    exit 1
fi

echo "--- Instalando qBittorrent-nox ---"
# Credits: https://linuxcapable.com/how-to-install-qbittorrent-on-ubuntu-linux/
# Actualiza el índice de paquetes y luego instala qbittorrent-nox de forma no interactiva
apt update && apt install -y qbittorrent-nox

echo "--- Configurando usuario y directorios de qBittorrent ---"
# Create system user and group if they don't exist
if ! id "qbittorrent-nox" &>/dev/null; then
    echo "Creando usuario y grupo 'qbittorrent-nox'..."
    adduser --system --group qbittorrent-nox
else
    echo "El usuario 'qbittorrent-nox' ya existe."
fi

# Set user home directory (important for config files)
usermod -d /var/lib/qbittorrent-nox qbittorrent-nox

# Create necessary directories for config, cache, and downloads
echo "Creando directorios necesarios..."
mkdir -p /var/lib/qbittorrent-nox/.cache/qBittorrent
mkdir -p /var/lib/qbittorrent-nox/.config/qBittorrent
mkdir -p "$DOWNLOAD_DIR" # Create the default download directory

# Set ownership and permissions for the user's directories
echo "Estableciendo permisos para /var/lib/qbittorrent-nox y $DOWNLOAD_DIR..."
chown -R qbittorrent-nox:qbittorrent-nox /var/lib/qbittorrent-nox "$DOWNLOAD_DIR"
chmod -R 755 /var/lib/qbittorrent-nox # Standard directory permissions

# Add the current user to the qbittorrent-nox group to allow access to download files
echo "Añadiendo al usuario '$SUDO_USER' al grupo 'qbittorrent-nox'..."
# Use SUDO_USER to get the user who ran sudo
adduser $SUDO_USER qbittorrent-nox || true # '|| true' evita que el script falle si el usuario ya está en el grupo

# Stop the service if it's running before making changes
echo "Deteniendo el servicio qbittorrent-nox (si está corriendo)..."
systemctl stop qbittorrent-nox || true # '|| true' evita que el script falle si el servicio no está corriendo

echo "--- Creando archivo de servicio systemd para qBittorrent ---"
# Create the service file content
cat << EOF > /tmp/qbittorrent-nox.service
[Unit]
Description=qBittorrent Command Line Client
After=network.target

[Service]
Type=forking
User=qbittorrent-nox
Group=qbittorrent-nox
UMask=007
ExecStart=/usr/bin/qbittorrent-nox -d --webui-port=$WEBUI_PORT
Restart=on-failure
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

# Move the service file to the systemd directory
echo "Instalando archivo de servicio en $SERVICE_FILE_QBITTORRENT..."
mv /tmp/qbittorrent-nox.service "$SERVICE_FILE_QBITTORRENT"

echo "--- Creando archivo de configuración de qBittorrent ---"
# Create the configuration file content
# Nota: El hash de la contraseña requiere PBKDF2 y salt, generados por qBittorrent.
# Configuramos opciones básicas aquí. El usuario debe cambiar la contraseña inicial.
cat << EOF > /tmp/qbittorrent-nox.conf
[BitTorrent]
Session\\Port=35118 # Puerto de escucha por defecto de BitTorrent
Session\\QueueingSystemEnabled=false

[Meta]
MigrationVersion=6

[Network]
Cookies=@Invalid()

[Preferences]
WebUI\\Port=$WEBUI_PORT
WebUI\\UseUPnP=false # Deshabilitar UPnP para WebUI por defecto
Downloads\\SavePath=$DOWNLOAD_DIR # Establecer el directorio de descarga por defecto
# WebUI\\Password_PBKDF2=... # Establecido por qBittorrent al cambiar la contraseña
# WebUI\\PasswordSalt=...
EOF

# Move the configuration file to the qbittorrent user's config directory
echo "Instalando archivo de configuración en $CONFIG_FILE_QBITTORRENT..."
mv /tmp/qbittorrent-nox.conf "$CONFIG_FILE_QBITTORRENT"
# Ensure the config file has correct permissions after moving as root
chown qbittorrent-nox:qbittorrent-nox "$CONFIG_FILE_QBITTORRENT"
chmod 644 "$CONFIG_FILE_QBITTORRENT"

echo "--- Iniciando y habilitando el servicio qBittorrent-nox ---"
# Reload the systemd manager configuration to pick up the new service file
systemctl daemon-reload

# Enable the service to start on boot
systemctl enable qbittorrent-nox

# Start the service
systemctl start qbittorrent-nox

# Give the service a moment to start and write the initial password to logs
echo "Dando tiempo al servicio para iniciar y generar la contraseña inicial..."
sleep 10 # Espera 10 segundos

# Attempt to retrieve the initial Web UI password from the systemd journal
echo "Intentando recuperar la contraseña inicial de la Web UI de los registros..."
# Search for the line containing the password information in the last 5 minutes of logs
initial_password=$(sudo journalctl -u qbittorrent-nox.service --since "5 minutes ago" | grep "The WebUI password is" | tail -n 1 | sed -n "s/.*The WebUI password is '\(.*\)'/\1/p")

# Check if the password was found and display it
if [ -n "$initial_password" ]; then
    echo ""
    echo "--- Credenciales Iniciales de la Web UI ---"
    echo "Usuario: admin"
    echo "Contraseña: $initial_password"
    echo "--------------------------------------------"
    echo "¡IMPORTANTE! Usa estas credenciales para iniciar sesión y CAMBIA la contraseña inmediatamente a través de la interfaz Web UI."
    echo ""
else
    echo ""
    echo "Advertencia: No se pudo recuperar automáticamente la contraseña inicial de la Web UI de los registros."
    echo "Es probable que el servicio aún no la haya generado o que el formato del log haya cambiado."
    echo "Por favor, encuéntrala manualmente ejecutando:"
    echo "  sudo journalctl -u qbittorrent-nox.service"
    echo "Y buscando una línea que contenga 'The WebUI password is' cerca de la hora de inicio del servicio."
    echo ""
fi

# Check the service status
echo "--- Estado del servicio qBittorrent-nox ---"
systemctl status qbittorrent-nox.service --no-pager || true

echo "--- Configuración Completa ---"
echo "qBittorrent-nox ha sido instalado y configurado."
echo "La Web UI es accesible en http://<tu_direccion_ip>:$WEBUI_PORT"
echo "El directorio de descarga por defecto es: $DOWNLOAD_DIR"
echo ""
# La instrucción importante sobre cambiar la contraseña ya se dio arriba si se encontró
# pero la repetimos si no se encontró, o simplemente la dejamos al final siempre.
# La dejaremos clara en la sección de credenciales si se encontraron.