#!/bin/bash

# Fixed source IP of the VPN server
IP_SRC="10.8.0.1"

# Function to display usage
show_usage() {
    echo "Usage: $0 -p PORT_PUBLIC -d IP_DEST -t PORT_DEST"
    echo
    echo "  -p    Public port (incoming traffic)"
    echo "  -d    Destination IP (internal VPN IP)"
    echo "  -t    Destination port"
    echo "  -h    Show this help message"
    echo
    echo "Example:"
    echo "  sudo $0 -p 1163 -d 10.8.0.61 -t 8003"
}

# Parse options
while getopts ":p:d:t:h" opt; do
    case $opt in
        p) PORT_PUBLIC=$OPTARG ;;
        d) IP_DEST=$OPTARG ;;
        t) PORT_DEST=$OPTARG ;;
        h) show_usage; exit 0 ;;
        \?) echo "Invalid option: -$OPTARG" >&2; show_usage; exit 1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2; show_usage; exit 1 ;;
    esac
done

# Validations
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] This script must be run as root."
    exit 1
fi

if [ -z "$PORT_PUBLIC" ] || [ -z "$IP_DEST" ] || [ -z "$PORT_DEST" ]; then
    echo "[ERROR] Missing required parameters."
    show_usage
    exit 1
fi

# Apply iptables rules
echo "Applying iptables rules:"
echo "- Redirecting port $PORT_PUBLIC to $IP_DEST:$PORT_DEST using source IP $IP_SRC"

# PREROUTING: Redirect external traffic to destination
sudo iptables -t nat -A PREROUTING \
  -p tcp --dport "$PORT_PUBLIC" \
  -j DNAT --to-destination "$IP_DEST:$PORT_DEST"

# OUTPUT: Redirect localhost traffic to destination
sudo iptables -t nat -A OUTPUT \
  -p tcp --dport "$PORT_PUBLIC" \
  -j DNAT --to-destination "$IP_DEST:$PORT_DEST"

# FORWARD: Allow traffic forwarding to destination
sudo iptables -A FORWARD \
  -p tcp -d "$IP_DEST" --dport "$PORT_DEST" \
  -j ACCEPT

# POSTROUTING: Ensure return packets go through the VPN source IP
sudo iptables -t nat -A POSTROUTING \
  -p tcp -d "$IP_DEST" --dport "$PORT_DEST" \
  -j SNAT --to-source "$IP_SRC"

echo "[SUCCESS] iptables rules applied."