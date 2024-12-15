# Developer Server: Reserved and Static IPs

This project is designed to manage reserved and static IPs for the development server. 
Follow the steps below to configure your server and execute the script.

## **1. Verify the Hostname**

Run the following command to check your current hostname:

```bash
    hostnamectl
```

## Change Hostname and Reboot ( If Necessary )

```bash
    # Edit the /etc/hostname file:
    sudo nano /etc/hostname
    # Edit the /etc/hosts file:
    sudo nano /etc/hosts
    # Reboot the system for the changes to take effect:
    sudo reboot
```

## **3. Check the Configuration File**

The configuration file is located at `./config/config.ini.` Use the following command to review it:

```bash
    cat ./config/config.ini
``` 

Ensure your hostname is listed in the configuration file. If it's not present, add it using the following format:

```example
    [server-001]
    IP=192.168.100.199
    MAC=
```

**IP:** The reserved IP address for the server.
**MAC:** Always leave this field empty. (It's automatically filled by the script.)

# ** 4. Execute the script**

```bash
    chmod +x ./start.sh
    sudo bash ./start.sh
```