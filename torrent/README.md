# Automated qBittorrent-nox Setup Script

This script automates the installation and basic configuration of `qbittorrent-nox` as a system service (`systemd`) on Debian/Ubuntu based distributions.

---
## Script Utility / Purpose

* Installs the `qbittorrent-nox` package.
* Creates a dedicated user and group (`qbittorrent-nox`) to run the service securely.
* Configures `qbittorrent-nox` to run as a `systemd` service.
* Allows specifying a port for the Web UI interface.
* Sets a default download directory (`/mnt/torrent/downloads`).
* Configures appropriate permissions for the service user and the download directory.
* Adds the user running the script to the `qbittorrent-nox` group for easy access to downloaded files.

---
## Prerequisites

* A Debian or Ubuntu based operating system.
* Superuser (`sudo`) privileges.

---
## How to Run

1.  Save the script content to a file (e.g., `setup_qbittorrent.sh`).
2.  Make the file executable:
    ```bash
    chmod +x ./torrent/setup_qbittorrent.sh
    ```
3.  Execute the script using `sudo`. You can specify the Web UI port using the `-w` option:

    * **Using the default port (8080):**
        ```bash
        sudo bash ./torrent/setup_qbittorrent.sh
        ```
    * **Specifying a custom port (e.g., 8001):**
        ```bash
        sudo bash ./torrent/setup_qbittorrent.sh -w 8001
        ```

---
## Important Notes After Execution

* The Web UI interface will be available at `http://<your_server_ip>:<chosen_port>`.
* The default credentials for accessing the Web UI are:
    * User: `admin`
    * Password: `adminadmin`

---
## Firewall Configuration (UFW Example)

To access the qBittorrent Web UI and allow torrent traffic, you need to open the relevant ports in your firewall. If you are using UFW (Uncomplicated Firewall), you can do this as follows:

1.  **Open the Web UI Port:**
    Replace `<chosen_port>` with the port you specified when running the script (default is 8080). This port needs to be open for TCP traffic.

    *Example for default port 8080:*
    ```bash
    sudo ufw allow <chosen_port>/tcp
    ```

2.  **Open the BitTorrent Listening Port:**
    The script configures the default BitTorrent listening port to 35118. This port is needed for incoming connections (seeding and connecting to peers). It typically uses both TCP and UDP. You can verify or change this port later in the qBittorrent Web UI settings (`Options` -> `Connection`).

    ```bash
    sudo ufw allow 35118/tcp
    sudo ufw allow 35118/udp
    ```
    *(Adjust port 35118 if you change it in the Web UI settings)*

3.  **Apply Firewall Rules:**
    If UFW is already active, reload it:

    ```bash
    sudo ufw reload
    ```

4.  **Check UFW Status:**
    ```bash
    sudo ufw status verbose
    ```

**Note:** If you are using a cloud server, you might also need to configure network security groups or firewalls provided by your cloud provider.

* **It is CRUCIAL that you access the Web UI immediately and change the default password to a strong one!**
* The default download directory is configured at `/mnt/torrent/downloads`. The user who ran the script will have access to this directory.
* You can check the service status by running:
    ```bash
    systemctl status qbittorrent-nox.service
    ```

---
## How to Run the Uninstallation Script

1.  Save the uninstallation script code to a file (e.g., `uninstall_qbittorrent.sh`).
2.  Make it executable:
    ```bash
    chmod +x ./torrent/uninstall_qbittorrent.sh
    ```
3.  Run it with `sudo`:
    ```bash
    sudo bash ./torrent/uninstall_qbittorrent.sh
    ```