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
        sudo ./torrent/setup_qbittorrent.sh
        ```
    * **Specifying a custom port (e.g., 9090):**
        ```bash
        sudo ./torrent/setup_qbittorrent.sh -w 9090
        ```

---
## Important Notes After Execution

* The Web UI interface will be available at `http://<your_server_ip>:<chosen_port>`.
* The default credentials for accessing the Web UI are:
    * User: `admin`
    * Password: `adminadmin`
  
* **It is CRUCIAL that you access the Web UI immediately and change the default password to a strong one!**
* The default download directory is configured at `/var/lib/qbittorrent-nox/downloads`. The user who ran the script will have access to this directory.
* You can check the service status by running:
    ```bash
    systemctl status qbittorrent-nox.service
    ```