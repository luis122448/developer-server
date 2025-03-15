#!/bin/bash

# Define las variables
VERSION=1.0.0
DEVICE_NAME=${HOSTNAME}
CONFIG_FILE_NETPLAN="/etc/netplan/01-main.yaml"
IP_ADDRESS=''
MAC_ADDRESS=''

source /srv/developer-server/scripts/functions.sh
source /etc/environment

# Parseo de las opciones de línea de comandos
while getopts "hi:g:" opt; do
    case $opt in
        h|--help)
            show_usage
            exit 0
            ;;
        i|--interface)
            INTERFACE=$OPTARG
            ;;
        g|--gateway)
            IP_GATEWAY=$OPTARG
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
done

# Validaciones
if [[ $EUID -ne 0 ]]; then
    echo "[FAIL] This script must be run as root."
    exit 1
fi

if [ -z "$INTERFACE" ]; then
    echo "Error: The -i or --interface option is mandatory."
    show_usage
    exit 1
fi

if [ -z "$IP_GATEWAY" ]; then
    echo "Error: The -g or --gateway option is mandatory."
    show_usage
    exit 1
fi

IP_ADDRESS=$(get_config_value "$DEVICE_NAME" "IP")

MAC_ADDRESS=$(ip link show "$INTERFACE" | awk '/ether/ {print $2}')

if [ -z "$MAC_ADDRESS" ]; then
    echo "[FAIL] MAC address not found"
    exit 1
fi

write_config_value "$DEVICE_NAME" "MAC" "$MAC_ADDRESS"

echo "Configuring network interface $INTERFACE with IP address $IP_ADDRESS and MAC address $MAC_ADDRESS"

if [ -d /etc/netplan ] && ls /etc/netplan/*.yaml 1> /dev/null 2>&1; then
    echo "Detectado: Netplan"
    rm -f /etc/netplan/*.yaml

    umask 077
    cat << EOF > /tmp/netcfg.yaml
network:
  renderer: networkd
  ethernets:
    $INTERFACE:
      addresses:
        - $IP_ADDRESS/24
      routes:
        - to: default
          via: $IP_GATEWAY
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
  version: 2
EOF

    mv /tmp/netcfg.yaml $CONFIG_FILE_NETPLAN
    chmod 600 $CONFIG_FILE_NETPLAN
    chown root:root $CONFIG_FILE_NETPLAN

    if [[ "$DEVICE_NAME" =~ "raspberry"* ]]; then
      cat << EOF > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
network: {config: disabled}
EOF
    fi

    netplan apply

elif [ -d /etc/sysconfig/network-scripts ]; then
    echo "Detectado: Sysconfig"
    CONFIG_FILE_SYS="/etc/sysconfig/network-scripts/ifcfg-$INTERFACE"

    cat << EOF > "$CONFIG_FILE_SYS"
DEVICE=$INTERFACE
BOOTPROTO=none
ONBOOT=yes
IPADDR=$IP_ADDRESS
NETMASK=255.255.255.0
GATEWAY=$IP_GATEWAY
DNS1=8.8.8.8
DNS2=8.8.4.4
EOF

    systemctl restart network
else
    echo "[FAIL] No se pudo detectar el sistema de configuración de red (ni netplan ni sysconfig)."
    exit 1
fi
