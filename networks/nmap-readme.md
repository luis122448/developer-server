# Nmap Network Scanning Guide

This guide provides instructions on how to install and use `nmap` for scanning local networks on Arch Linux and Ubuntu/Debian-based systems.

## Installation

### Arch Linux
To install `nmap` on Arch Linux, use the `pacman` package manager:

```bash
nsudo pacman -S nmap
```

### Ubuntu / Debian
To install `nmap` on Ubuntu or Debian-based distributions, use `apt`:

```bash
sudo apt update
sudo apt install nmap
```

## Basic Usage for Local Network Scanning

### 1. Identify Your Local Network Range
First, find your local IP address and subnet mask:

```bash
ip addr show
```
Look for your active interface (e.g., `eth0` or `wlan0`) and note the `inet` address (e.g., `192.168.1.15/24`).

### 2. Host Discovery (Ping Scan)
To see which devices are online without performing a deep scan, use the `-sn` flag (formerly `-sP`):

```bash
nmap -sn 192.168.1.0/24
```
*   `-sn`: Disable port scan. Only determine if the hosts are up.

### 3. Detailed Scan (Service and OS Detection)
To get more information about the connected devices, including open ports and operating systems:

```bash
sudo nmap -A 192.168.1.0/24
```
*   `-A`: Enables OS detection, version detection, script scanning, and traceroute.
*   **Note**: Using `-A` or OS detection (`-O`) often requires `sudo` privileges.

### 4. Scan Specific Ports
If you want to check for specific services (e.g., SSH, HTTP):

```bash
nmap -p 22,80,443 192.168.1.0/24
```

### 5. Fast Scan
To scan the most common 100 ports quickly:

```bash
nmap -F 192.168.1.0/24
```

## Output to a File
You can save the results to a text file for later review:

```bash
nmap -sn 192.168.1.0/24 -oN network_scan.txt
```

## Security Note
Always ensure you have permission to scan the network you are targeting. Unauthorized scanning can be flagged as suspicious activity by network administrators.
