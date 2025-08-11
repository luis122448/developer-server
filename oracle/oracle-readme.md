# Oracle Linux 23ai Database Server Minimal Setup

This guide covers the essential steps to configure a minimal Oracle Linux server instance, preparing it to host an Oracle Database 23ai installation.

---
## Prerequisites

* A minimal installation of Oracle Linux is completed.
* You have initial access (e.g., as `root` or an initial user with `sudo` capabilities).
* Check guide [Oracle Database Free Release Quick Start](https://www.oracle.com/database/free/get-started/#quick-start)

---
## Setup Steps:

1.  **Login:**
Log in to the server console or via SSH as `root` or your initial administrative user.

2.  **Update System (Minimal):**
Ensure the system is up-to-date:
```bash
sudo dnf update -y
```

3.  **Configure Network (Hostname & Static IP):**
* Set the hostname (replace `your_hostname`):
```bash
sudo hostnamectl set-hostname your_hostname
```
* **Configure a Static IP Address:** (Crucial for database servers)
Use `nmtui` (text user interface) or manually edit network configuration files (`/etc/sysconfig/network-scripts/ifcfg-*` or files under `/etc/NetworkManager/`) to set a static IP, netmask, gateway, and DNS. This step varies based on your network setup. A common command-line tool for guided network setup is:
```bash
sudo nmtui
```
*Restart networking after changes:* `sudo systemctl restart NetworkManager`

4.  **Configure Firewall (Allow SSH & Database Port):**

* Enable the firewall (if stopped):
  
```bash
sudo systemctl enable firewalld --now
```

* Allow SSH (Port 22):

```bash
sudo firewall-cmd --permanent --add-service=ssh
```

* Allow Oracle Listener Port (default 1521 - adjust if needed):
```bash
sudo firewall-cmd --permanent --add-port=1521/tcp
```

* Reload firewall rules:
```bash
sudo firewall-cmd --reload
```

* *Optional (for simplified initial testing, **NOT** recommended for production):* Temporarily stop/disable the firewall:
  
```bash
sudo systemctl stop firewalld
sudo systemctl disable firewalld
```

***WARNING: Re-enable and configure your firewall properly for security before any production use.***

5.  **Create Oracle Database User and Groups:**
Create the necessary user and groups for the database software owner.
```bash
sudo groupadd oinstall
sudo groupadd dba
sudo groupadd oper
# Add other groups if required for specific features (backupdba, dgdba, kmdba, etc.)
sudo useradd -g oinstall -G dba,oper -m -d /home/oracle -s /bin/bash oracle
# Set password for the oracle user
sudo passwd oracle
```

6.  **Grant `sudo` Access to an Admin User (Optional, but Common):**

Grant `sudo` access to the `oracle` user (or preferably, a separate administrative user) by adding them to the `wheel` group.

```bash
sudo usermod -aG wheel oracle
```
Ensure the `wheel` group is enabled for `sudo` in `/etc/sudoers`. Use `visudo` to edit safely:

```bash
sudo visudo
```
Uncomment the line `%wheel ALL=(ALL) ALL` (remove the `#` at the beginning). Save and exit the editor.

*Note: The user needs to log out and log back in for group changes to take effect.*

7.  **Install Oracle Database Pre-install Package:**

This RPM automatically configures most kernel parameters, packages, user limits, and other prerequisites for Oracle Database installation.
```bash
sudo dnf install oracle-database-preinstall-23ai -y
```

8.  **Configure Storage:**

Create mount points for Oracle software (`/u01`) and data files (`/u02`). Adjust permissions. Ensure these are persistent (e.g., via `/etc/fstab`).
```bash
sudo mkdir -p /u01 /u02
sudo chown -R oracle:oinstall /u01 /u02
sudo chmod -R 775 /u01 /u02
# Configure /etc/fstab for persistent mounts (essential)
```

9.  **Disable SELinux:**

Oracle Database installation is often simpler with SELinux disabled or in permissive mode.
Edit `/etc/selinux/config`:

```bash
sudo vi /etc/selinux/config # or use nano
```

Change the line `SELINUX=enforcing` to `SELINUX=disabled`. Save and exit.

**Reboot the server** for this change to take full effect.
*Alternatively, for permissive mode without reboot:* `sudo setenforce 0` (This is temporary).

---
## Proceed with Oracle Database 23ai Installation:**

The server is now minimally prepared. Download the Oracle Database 23ai installation files and follow the official Oracle documentation for the installation process, running the installer as the `oracle` user.

1. **Download the Database Software:**

Download the Oracle Database 23ai Free RPM package from the official Oracle website. You can use `wget` if the server has internet access. It's recommended to download this as the `oracle` user in a temporary directory.

*Switch to the oracle user:*

```bash
su - oracle
```
*Go to a temporary directory:*

```bash
cd /tmp
```
*Download the RPM (replace with the actual download URL):*

```bash
wget [URL_of_Oracle_Database_23ai_Free_RPM]
# Example (URL is illustrative, find the actual one on oracle.com):
# wget https://download.oracle.com/otn-pub/otn_software/db-free/oracle-database-free-23ai-23.8-1.el9.x86_64.rpm
```

*Exit the oracle user session:*

```bash
exit
```

2. **Install the Database RPM:**

Switch back to your administrative user (with `sudo`) and install the downloaded RPM package using `dnf`. The pre-install RPM should handle dependencies.

```bash
sudo dnf install /tmp/oracle-database-free-23ai-23.8-1.el9.x86_64.rpm -y
```

3.  **Run the Database Configuration Script:**

After the RPM installation completes, run the configuration script provided by the package. This script creates the database instance, configures the listener, sets up passwords, etc.

```bash
sudo /etc/init.d/oracle-free-23ai configure
```

*The script will prompt you for:*
* The Listener port (default is `1521`).
* The Oracle Enterprise Manager (EM) Express HTTP port (default is `5500`).
* The password for the `SYS`, `SYSTEM`, and `PDBADMIN` administrative users. Choose a strong password and remember it.

4.  **Verify Database Status (Basic Check):**

After the configuration script finishes, the database instance and listener should be running. You can check the service status and connect using SQL*Plus.

*Check service status:*
```bash
sudo systemctl status oracle-free-23ai
```

*Switch to the oracle user:*

```bash
su - oracle
```

*Set Oracle environment variables (usually done by pre-install RPM, but source if needed):*

```bash
nano ~/.bashrc # Or check your shell's profile file
```

```bash
# Set manual environment variables
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=$ORACLE_BASE/product/23ai/dbhomeFree
export ORACLE_SID=FREE
export PATH=$ORACLE_HOME/bin:$PATH
```

*Connect to SQL*Plus as SYSDBA:*

```bash
sqlplus / as sysdba
```

*Run a simple query to check the instance status:*

```sql
SELECT instance_name, status FROM v$instance;
SELECT name, open_mode, restricted FROM v$pdbs;
EXIT;
```

*Exit the oracle user session:*

```bash
exit
```

---
## Prepare Target Schema in Database

*Create to Tablespace*

```bash
sudo mkdir -p /u02/oradata/FREEPDB1
sudo chown oracle:oinstall /u02/oradata/FREEPDB1
sudo chmod 775 /u02/oradata/FREEPDB1
```

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;

CREATE TABLESPACE TBS_DATA
DATAFILE '/u02/oradata/FREEPDB1/tbs_data01.dbf'
SIZE 100M
AUTOEXTEND ON
NEXT 10M
MAXSIZE UNLIMITED;
```

*Create by User ( Schema )*

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;

CREATE USER USR_DATA
IDENTIFIED BY `PASSWORD`
DEFAULT TABLESPACE TBS_DATA
TEMPORARY TABLESPACE TEMP
ACCOUNT UNLOCK;
```

*Grant User*

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;

GRANT CREATE SESSION TO USR_DATA;
GRANT RESOURCE TO USR_DATA; 
```

---
## Oracle Schema Backup and Local Import Guide

*Install & Configure OCI CLI*

```bash
# Download and run the install script
bash -c "$(curl -L [https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh](https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh))"

# Configure the CLI with your OCI credentials
oci setup config
```

**Important:** You will need your User OCID, Tenancy OCID, and Region (e.g., `sa-saopaulo-1`). Ensure you upload your generated public key (`~/.oci/oci_api_key_public.pem`) to your OCI User's API Keys setting in the OCI Console.

*Set Up Local Backup Directory*

```bash
sudo mkdir -p /u03/backup/FREEPDB1
sudo chown oracle:oinstall /u03/backup/FREEPDB1
sudo chmod 775 /u03/backup/FREEPDB1
# Optional: Clean up previous attempts
# rm -rf /u03/backup/FREEPDB1/*
```

*Download Backup Files Locally*

```bash
oci os object bulk-download \
  --namespace tsinube \
  --bucket-name bucket-backup-bd-oracle-dbtsi \
  --prefix adb_full_backup_YYYYMMDD_HHMMSS_ \
  --dest-dir /u03/backup/FREEPDB1
```

*Create Object `DIRECTORY` in database*

```sql
CREATE OR REPLACE DIRECTORY BACKUP_LOCAL_DIR AS '/u03/backup/FREEPDB1';
GRANT READ, WRITE ON DIRECTORY BACKUP_LOCAL_DIR TO USR_DATA;
```

*Download and extract Instant Client*

```bash
sudo mkdir -p /opt/oracle-instantclient
sudo chown oracle:oinstall /opt/oracle-instantclient
sudo chmod 775 /opt/oracle-instantclient
```

```bash
wget https://download.oracle.com/otn_software/linux/instantclient/2380000/oracle-instantclient-basic-23.8.0.25.04-1.el9.x86_64.rpm
wget https://download.oracle.com/otn_software/linux/instantclient/2380000/oracle-instantclient-sqlplus-23.8.0.25.04-1.el9.x86_64.rpm
wget https://download.oracle.com/otn_software/linux/instantclient/2380000/oracle-instantclient-tools-23.8.0.25.04-1.el9.x86_64.rpm
```

```bash
sudo dnf install /opt/oracle-instantclient/oracle-instantclient-basic-23.8.0.25.04-1.el9.x86_64.rpm -y
sudo dnf install /opt/oracle-instantclient/oracle-instantclient-sqlplus-23.8.0.25.04-1.el9.x86_64.rpm -y
sudo dnf install /opt/oracle-instantclient/oracle-instantclient-tools-23.8.0.25.04-1.el9.x86_64.rpm -y
```

*Read `tnsnames.ora` for BD alias*

```bash
cat $ORACLE_HOME/network/admin/tnsnames.ora
```

*And define alias for connected PDB `FREEPDB1`*

```bash
nano $ORACLE_HOME/network/admin/tnsnames.ora
```

```sql
-- Add the lines
FREEPDB1 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = oracle-002)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = FREEPDB1)
    )
  )
```

*Import Schema Data*

```bash
impdp system/$PASSWORD@FREEPDB1 \
  DIRECTORY=BACKUP_LOCAL_DIR \
  DUMPFILE=adb_full_backup_20250510_171146_01.dmp,adb_full_backup_20250510_171146_02.dmp,adb_full_backup_20250510_171146_03.dmp,adb_full_backup_20250510_171146_04.dmp \
  LOGFILE=impdp_USR_TSI_SUITE_20250510_171146.log \
  SCHEMAS=USR_TSI_SUITE \
  REMAP_SCHEMA=USR_TSI_SUITE:USR_DATA \
  ENCRYPTION_PASSWORD=$PASSWORD
```

* **Important:** Replace placeholders like `$PASSWORD`, `FREEPDB1`, and `"$PASSWORD"`.
* Monitor the import process using the specified log file (`impdp_USR_TSI_SUITE_to_USR_DATA_20250510.log`) located in `/u03/backup/FREEPDB1`.

---
## Accessing the Database

* **SQL*Plus:** Connect from the server itself as the `oracle` user using connection strings like:
* To the CDB (Container Database - `ORCL`): `sqlplus sys@localhost:1521/ORCL as sysdba`
* To the PDB (Pluggable Database - default `FREEPDB1`): `sqlplus pdbadmin@localhost:1521/FREEPDB1` (or connect to CDB and `ALTER SESSION SET CONTAINER=FREEPDB1;`)
* **SQL Developer or other Clients:** Connect remotely using the server's IP address or hostname, the Listener port (default 1521), and the Service Name (`ORCL` for the CDB, `FREEPDB1` for the PDB).
* **EM Express:** Access the web-based management console via your browser at `https://your_hostname_or_ip:5500/em/` (using the port configured during step 13). Use `SYSTEM` or `PDBADMIN` users to log in.

This concludes the basic setup and installation of Oracle Database 23ai Free on Oracle Linux.