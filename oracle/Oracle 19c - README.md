# Oracle 19c Database Installation and Management Guide

This guide provides a comprehensive walkthrough for installing, configuring, and managing an Oracle 19c database on a Linux system using the RPM package method.

---

## 1. Installation and Configuration

This section covers the initial setup of the Oracle database from start to finish.

### 1.1. Transfer Installation File

First, you need to copy the Oracle RPM installation file to your target server.

```bash
# Use scp (secure copy) to transfer the RPM from your local machine to the server's /tmp directory.
# Replace /path/to/your/local/file.rpm and YOUR_SERVER_IP with your actual file path and server IP.
scp /path/to/your/local/oracle-database-ee-19c-1.0-1.x86_64.rpm root@YOUR_SERVER_IP:/tmp

# Verify that the file was transferred successfully and check its size.
ls -lh /tmp/oracle-database-ee-19c-1.0-1.x86_64.rpm
```

### 1.2. Prepare System Directories

Create the necessary directories for the Oracle software and database files, then set the correct ownership and permissions.

```bash
# Create the base directory for Oracle software and the inventory for installation metadata.
sudo mkdir -p /u01/app/oracle
sudo mkdir -p /u01/app/oraInventory

# Set ownership to the 'oracle' user and 'oinstall' group, which are standard for Oracle installations.
sudo chown -R oracle:oinstall /u01

# Set read, write, and execute permissions for the owner and group.
sudo chmod -R 775 /u01/app/oracle
sudo chmod -R 775 /u01/app/oraInventory
```

### 1.3. Install Oracle Software via RPM

Use the `dnf` package manager to install the Oracle pre-installation package and the database software itself.

```bash
# The preinstall package automatically configures your system with required kernel parameters and user accounts.
sudo dnf install -y oracle-database-preinstall-19c

# Install the Oracle Database software from the RPM file you transferred.
sudo dnf install -y /tmp/oracle-database-ee-19c-1.0-1.x86_64.rpm
```

### 1.4. Create and Configure the Database

With the software installed, you can now create and configure your database instance.

#### 1.4.1. Edit the Configuration File

Define your database parameters by editing the configuration file. Use your preferred text editor.

```bash
# Open the configuration file for editing.
sudo nano /etc/sysconfig/oracledb_ORCLCDB-19c.conf
```

Set the following parameters in the `.conf` file. **You must provide a secure password for `ORACLE_PWD`**.

```ini
# Example Configuration
ORACLE_SID=ORCLCDB                 # System Identifier for the Container Database (CDB)
ORACLE_PDB=ORCLPDB1                # Name for the default Pluggable Database (PDB)
ORACLE_CHARACTERSET=AL32UTF8       # Recommended universal character set
LISTENER_PORT=1521                 # Network listener port
ORACLE_PWD=YourStrongPasswordHere  # Set a strong password for SYS, SYSTEM, and PDBADMIN users
```

#### 1.4.2. Create the Database Instance

Run the provided script to create the database instance using the parameters you just defined.

```bash
# This script automates the database creation and configuration process.
sudo /etc/init.d/oracledb_ORCLCDB-19c configure
```

### 1.5. Set Up the Oracle User Environment

Configure the shell environment for the `oracle` user to easily manage the database.

#### 1.5.1. Edit the Bash Profile

Log in as the `oracle` user and add the necessary environment variables to the `~/.bash_profile`.

```bash
# Switch to the oracle user.
su - oracle

# Open the profile for editing.
nano ~/.bash_profile
```

Add the following lines to define the Oracle environment:

```bash
# Oracle Environment Variables
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1  # Main directory for Oracle software
export ORACLE_SID=ORCLCDB                             # The default SID to connect to
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib # Path for shared libraries
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8             # Language and character set settings

# Add Oracle's binary directory to the system's PATH for direct command access.
export PATH=$ORACLE_HOME/bin:$PATH

# Recommended file creation mask for security.
umask 022
```

#### 1.5.2. Load and Validate the Environment

Apply the new profile settings and verify that the variables are set correctly.

```bash
# Load the profile into the current session.
source ~/.bash_profile

# Validate that the variables are correctly set.
echo $ORACLE_SID
echo $ORACLE_HOME
echo $PATH
```

---

## 2. Post-Installation Verification

Connect to the database using SQL*Plus to ensure it is running correctly.

```bash
# Connect as the 'sysdba' user using operating system authentication.
sqlplus / as sysdba
```

Once connected, check the database name and its open mode.

```sql
-- At the SQL> prompt:
STARTUP;
SELECT name, open_mode FROM v$database;
```

The `open_mode` should be `READ WRITE`, indicating the database is fully operational.

---

## 3. Managing Pluggable Databases (PDBs)

Oracle 19c uses a multitenant architecture. A Container Database (CDB) can host multiple Pluggable Databases (PDBs). This section covers common PDB operations.

### 3.1. List PDBs

To see all PDBs and their current status:

```sql
-- This view shows all PDBs within the current CDB.
SELECT name, open_mode FROM v$pdbs;
```

### 3.2. Create a PDB

Create a new PDB from the `PDB$SEED` (a system-supplied template).

```sql
-- This creates a new PDB named 'pdb_migrate' and an admin user for it.
CREATE PLUGGABLE DATABASE pdb_migrate
  ADMIN USER USR_TSI_SUITE IDENTIFIED BY YourAdminPassword
  FILE_NAME_CONVERT = (
    '/opt/oracle/oradata/ORCLCDB/pdbseed/',         -- Source directory
    '/opt/oracle/oradata/ORCLCDB/pdb_migrate/'      -- Destination directory
  );

-- After creation, you can change the user's password if needed.
ALTER USER USR_TSI_SUITE IDENTIFIED BY NewStrongPassword;
```

### 3.3. Open a PDB

A new PDB is created in a `MOUNTED` state and must be opened to be accessible.

```sql
ALTER PLUGGABLE DATABASE pdb_migrate OPEN;
```

### 3.4. Save PDB State

To ensure a PDB starts automatically whenever the main CDB starts, save its state.

```sql
-- This command saves the current state (e.g., OPEN) for future restarts.
ALTER PLUGGABLE DATABASE pdb_migrate SAVE STATE;
```

### 3.5. Connect to a PDB

To perform operations within a specific PDB, you must switch your session to its container.

```sql
-- Switch the session's context to your PDB.
ALTER SESSION SET CONTAINER=pdb_migrate;

-- Verify you are in the correct container.
SHOW CON_NAME;
```

---

## 4. Running Initialization Scripts

Follow these steps to run custom SQL scripts for database initialization (e.g., creating schemas and tables).

### 4.1. Copy Scripts to the Server

First, copy your initialization scripts to a location accessible by the `oracle` user.

```bash
# Example: Copy scripts from a local directory to the oracle user's home directory.
scp -r /path/to/your/local/init_scripts root@YOUR_SERVER_IP:/home/oracle
```

### 4.2. Execute Scripts in the PDB

Log in to SQL*Plus, connect to the target PDB, and run your scripts.

```bash
# Connect as sysdba
sqlplus / as sysdba
```

```sql
-- Switch to your PDB
ALTER SESSION SET CONTAINER=pdb_migrate;

-- Create a tablespace for your application data.
CREATE TABLESPACE TBS_MIGRATE
  DATAFILE '/opt/oracle/oradata/ORCLCDB/pdb_migrate/tbs_migrate_pdb01.dbf'
  SIZE 100M
  AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED;

-- Assign the new tablespace as the default for your application user.
ALTER USER USR_TSI_SUITE DEFAULT TABLESPACE TBS_MIGRATE;

-- Grant the user unlimited storage quota on the tablespace.
ALTER USER USR_TSI_SUITE QUOTA UNLIMITED ON TBS_MIGRATE;

-- Grant the DBA role to your user for full administrative privileges.
-- Note: For production, grant specific privileges instead of the full DBA role.
GRANT DBA TO USR_TSI_SUITE;

-- Run your initialization scripts.
@/home/oracle/init/TABLES_fix.sql
@/home/oracle/init/TRIGGERS.sql
```

---

## 5. Configure Listener for Remote Access

To allow remote clients to connect, you must configure the `listener.ora` and `tnsnames.ora` files and open the firewall port.

### 5.1. Configure `listener.ora`

Edit `listener.ora` as the `oracle` user to make the listener accept connections from any IP address.

```bash
# Open the listener configuration file.
vi $ORACLE_HOME/network/admin/listener.ora
```

Change `(HOST = localhost)` or the server's hostname to `(HOST = 0.0.0.0)`. This allows the listener to accept connections on any network interface.

### 5.2. Configure `tnsnames.ora`

Edit `tnsnames.ora` to define connection aliases for your databases.

```bash
# Open the TNS names configuration file.
vi $ORACLE_HOME/network/admin/tnsnames.ora
```

Add entries for your PDB and CDB. Replace `YOUR_SERVER_IP` with your actual server IP address.

```
PDB_MIGRATE =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = YOUR_SERVER_IP)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = pdb_migrate)
    )
  )

ORCLCDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = YOUR_SERVER_IP)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCLCDB)
    )
  )
```

### 5.3. Restart the Listener and Configure Firewall

Apply the changes by restarting the listener and opening the port in your system's firewall.

```bash
# As the 'oracle' user, restart the listener to apply changes.
lsnrctl stop
lsnrctl start

# As a user with sudo privileges, open the listener port in firewalld.
sudo firewall-cmd --zone=public --add-port=1521/tcp --permanent
sudo firewall-cmd --reload
```

### 5.4. Test Remote Connection

Test the connection from a client machine using SQL*Plus.

```bash
# Example connection string format: user/password@host:port/service_name
sqlplus USR_TSI_SUITE/YourUserPassword@YOUR_SERVER_IP:1521/pdb_migrate
```

---

## 6. Delete a PDB

To permanently delete a PDB and all its associated data files, follow these steps.

**Warning:** This action is irreversible and will result in permanent data loss.

```sql
-- 1. Connect to the root container (CDB$ROOT).
ALTER SESSION SET CONTAINER=CDB$ROOT;

-- 2. Close the PDB.
ALTER PLUGGABLE DATABASE pdb_migrate CLOSE IMMEDIATE;

-- 3. Drop the PDB and delete its data files.
DROP PLUGGABLE DATABASE pdb_migrate INCLUDING DATAFILES;
```

---

## 7. Uninstallation

If you need to completely remove the Oracle installation, follow these steps.

**WARNING: This is a destructive operation. Proceed with extreme caution.**

### 7.1. Remove Files and Directories

```bash
# Remove all Oracle-related files, directories, and configuration.
sudo rm -rf /u01 /opt/oracle /opt/ORCLfmap /etc/oratab /tmp/.oracle
sudo rm -f /etc/init.d/oracle-init
sudo rm -f /etc/security/limits.d/oracle-database-preinstall-19c.conf
sudo rm -f /etc/sysctl.d/oracle-database-preinstall-19c.conf
sudo rm -f /etc/sysconfig/oracle-database-19c
```

### 7.2. Remove RPM Packages

```bash
# Remove the main database package.
sudo dnf remove -y oracle-database-ee-19c-1.0-1.x86_64

# Remove the preinstall package.
sudo dnf remove -y oracle-database-preinstall-19c
```