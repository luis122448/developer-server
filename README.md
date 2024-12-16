![Logo del Projecto](./resources/logo.png)

# Developer Server: Reserved and Static IPs

This project is designed to manage reserved and static IPs for the development server. 
Follow the steps below to configure your server and execute the script.

## **0. Define environment variables**

    Then, define the environment variables in /etc/environment:

    ```bash
        sudo nano /etc/environment
    ```

    ```bash
        SERVER_LOCAL_IP=
        SERVER_LOCAL_USER=
        EMAIL=
    ```

    Charge the environment variables:

    ```bash
        source /etc/environment
    ```


## **1. Clone the Repository**

Use the following command to navigate to the `/srv` directory:

```bash
    cd /srv
```

Clone the repository to your local machine:

```bash
    git clone https://github.com/luis122448/developer-server.git
```

## **2. Verify the Hostname**

Run the following command to check your current hostname:

```bash
    hostnamectl
```

Change the hostname only if it's different from the one listed in the configuration file `./config/config.ini`.

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

## **4. Execute the script**

```bash
    chmod +x ./start.sh
    sudo bash ./start.sh
```

The script will automatically assign the reserved IP to the server and update the configuration file with the MAC address.

## **5. Verify the IP Address (Optional)**

Run the following command to verify the IP address:

```bash
    bash ./check_ip.sh
```