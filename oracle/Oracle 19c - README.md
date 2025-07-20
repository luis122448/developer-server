# Oracle 19c Database Installation and Management Guide

This guide provides comprehensive instructions for installing, configuring, and managing an Oracle 19c database on a Linux system using the RPM package method.

---

## 1. Installation and Configuration

This section covers the initial setup of the Oracle database.

### 1.1. Transfer Installation File

Copy the Oracle RPM file to your target server.

```bash
# Copy the RPM from your local machine to the server's /tmp directory
scp /path/to/your/local/oracle-database-ee-19c-1.0-1.x86_64.rpm root@YOUR_SERVER_IP:/tmp

# Verify the file transfer
ls -lh /tmp/oracle-database-ee-19c-1.0-1.x86_64.rpm
```

### 1.2. Prepare System Directories

Create the necessary directories for the Oracle installation and set the correct permissions.

```bash
# Create base and inventory directories
sudo mkdir -p /u01/app/oracle
sudo mkdir -p /u01/app/oraInventory

# Set ownership to the oracle user and oinstall group
sudo chown -R oracle:oinstall /u01

# Set permissions for the directories
sudo chmod -R 775 /u01/app/oracle
sudo chmod -R 775 /u01/app/oraInventory
```

### 1.3. Install Oracle Software via RPM

Install the Oracle Database software and its dependencies using the `dnf` package manager.

```bash
# Install dependency
sudo dnf install -y oracle-database-preinstall-19c

# Install the Oracle Database RPM
sudo dnf install -y /tmp/oracle-database-ee-19c-1.0-1.x86_64.rpm
```

### 1.4. Create and Configure the Database

First, define your database parameters and then create the instance.

#### 1.4.1. Edit Configuration File

Edit the configuration file to set your database parameters.

```bash
# Edit the configuration file to set your parameters
sudo nano /etc/sysconfig/oracledb_ORCLCDB-19c.conf
```

Set the following parameters in the `.conf` file. **You must provide a password for `ORACLE_PWD`**.

```ini
# Example Configuration
ORACLE_SID=ORCLCDB
ORACLE_PDB=ORCLPDB1
ORACLE_CHARACTERSET=AL32UTF8
LISTENER_PORT=1521
ORACLE_PWD=YourStrongPasswordHere
```

#### 1.4.2. Create the Database Instance

Run the configuration script to create the database instance based on your settings.

```bash
# This command will create and configure the database
sudo /etc/init.d/oracledb_ORCLCDB-19c configure
```

### 1.5. Set Up Oracle User Environment

Configure the environment for the `oracle` user to interact with the database.

#### 1.5.1. Edit Bash Profile

Log in as the `oracle` user and add the necessary environment variables to `~/.bash_profile`.

```bash
# Switch to the oracle user
su - oracle

# Open the profile for editing
nano ~/.bash_profile
```

Add the following lines:

```bash
# Oracle Environment Variables
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export ORACLE_SID=ORCLCDB
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8

# Add Oracle binaries to PATH
export PATH=$ORACLE_HOME/bin:$PATH

# Recommended umask for Oracle installations
umask 022
```

#### 1.5.2. Load and Validate Environment

Load the new profile and verify that the variables are set correctly.

```bash
# Load the profile
source ~/.bash_profile

# Validate the variables
echo $ORACLE_SID
echo $ORACLE_HOME
echo $PATH
```

---

## 2. Post-Installation Verification

Connect to the database using SQL*Plus to ensure it is running correctly.

```bash
# Connect as the sysdba user
sqlplus / as sysdba
```

Once connected, check the database status.

```sql
-- At the SQL> prompt
STARTUP;
SELECT name, open_mode FROM v$database;
```

The `open_mode` should show `READ WRITE`.

---

## 3. Managing Pluggable Databases (PDBs)

This section covers common operations for managing PDBs.

### 3.1. List PDBs

To see all Pluggable Databases and their status:

```sql
SELECT name, open_mode FROM v$pdbs;
```

### 3.2. Create a PDB

Create a new PDB from the `PDB$SEED`.

```sql
CREATE PLUGGABLE DATABASE pdb_migrate
  ADMIN USER USR_TSI_SUITE IDENTIFIED BY $PASSWORD
  FILE_NAME_CONVERT = (
    '/opt/oracle/oradata/ORCLCDB/pdbseed/',
    '/opt/oracle/oradata/ORCLCDB/pdb_migrate/'
  );
```

Update password

```sql
ALTER USER USR_TSI_SUITE IDENTIFIED BY $PASSWORD;
```

### 3.3. Open a PDB

After creation, a PDB must be opened to be accessible.

```sql
ALTER PLUGGABLE DATABASE pdb_migrate OPEN;
```

### 3.4. Save PDB State

To ensure a PDB starts automatically with the container database (CDB), save its state.

```sql
ALTER PLUGGABLE DATABASE pdb_migrate SAVE STATE;
```

### 3.5. Connect to a PDB

To perform operations within a specific PDB, you must switch your session to its container.

```sql
ALTER SESSION SET CONTAINER=pdb_migrate;
```

To verify you are connected to the correct container:

```sql
SHOW CON_NAME;
```

---

## 4. Running Initialization Scripts

To run custom SQL scripts for database initialization, follow these steps.

### 4.1. Copy Scripts to Server

First, copy your initialization scripts to the server.

```bash
# Example: Copy scripts from a local directory to the oracle user's home
scp -r /path/to/your/local/init_scripts root@YOUR_SERVER_IP:/home/oracle
```

### 4.2. Execute Scripts in the PDB

Log in to SQL*Plus, connect to the target PDB, and run your script.

```bash
# Connect as sysdba
sqlplus / as sysdba
```

```sql
-- Connect to your PDB
ALTER SESSION SET CONTAINER=pdb_migrate;
```

Create and asig default tablespace

```sql
CREATE TABLESPACE TBS_MIGRATE
DATAFILE '/opt/oracle/oradata/ORCLCDB/pdb_migrate/tbs_migrate_pdb01.dbf'
SIZE 100M
AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED;
```

```sql
ALTER USER USR_TSI_SUITE QUOTA UNLIMITED ON TBS_MIGRATE;
```

```sql
ALTER USER USR_TSI_SUITE DEFAULT TABLESPACE TBS_MIGRATE;
```

Grant the `DBA` role to your user:

```sql
GRANT DBA TO USR_TSI_SUITE;
```

Run your initialization script

```sql
@/home/oracle/init/TABLES_fix.sql
@/home/oracle/init/TRIGGERS.sql
```

---
## 5. Configure Listener Access

Open `listener.ora` as a user `oracle`

```bash
vi $ORACLE_HOME/network/admin/listener.ora
```

Set local listener in ..

```vi
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
    )
  )

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ORCLCDB)
      (ORACLE_HOME = /opt/oracle/product/19c/dbhome_1)
      (SID_NAME = ORCLCDB)
    )
    (SID_DESC =
      (GLOBAL_DBNAME = pdb_migrate)
      (ORACLE_HOME = /opt/oracle/product/19c/dbhome_1)
      (SID_NAME = ORCLCDB)
    )
  )
```

Apply changes

```sql
lsnrctl stop
lsnrctl start
```

Configure file red `tnsnames.ora`

```bash
vi $ORACLE_HOME/network/admin/tnsnames.ora
```

```vi
PDB_MIGRATE =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.100.191)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = pdb_migrate)
    )
  )

ORCLCDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.100.191)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCLCDB)
    )
  )
```

Configurate Firewall

```bash
sudo firewall-cmd --zone=public --add-port=1521/tcp --permanent
```

```bash
sudo firewall-cmd --reload
```

Test connection by `sqlplus`

```bash
sqlplus USR_TSI_SUITE/941480149401@localhost:1521/pdb_migrate
```

--- 

### 6. Delete a PDB

To permanently delete a PDB and all its associated data, follow these steps.

**Warning:** This action is irreversible and will result in data loss.

1.  **Connect to the root container (CDB$ROOT)** if you are not already.

```sql
ALTER SESSION SET CONTAINER=CDB$ROOT;
```

2.  **Close the PDB** before dropping it.

```sql
ALTER PLUGGABLE DATABASE pdb_migrate CLOSE IMMEDIATE;
```

3.  **Drop the PDB** and delete its data files.

```sql
DROP PLUGGABLE DATABASE pdb_migrate INCLUDING DATAFILES;
```

---

## 7. Uninstallation

If you need to completely remove the Oracle installation, follow these steps.

**WARNING: This is a destructive operation.**

### 5.1. Remove Files and Directories

```bash
# Remove all Oracle-related files and configuration
sudo rm -rf /u01 /opt/oracle /opt/ORCLfmap /etc/oratab /tmp/.oracle
sudo rm -f /etc/init.d/oracle-init
sudo rm -f /etc/security/limits.d/oracle-database-preinstall-19c.conf
sudo rm -f /etc/sysctl.d/oracle-database-preinstall-19c.conf
sudo rm -f /etc/sysconfig/oracle-database-19c
```

### 5.2. Remove RPM Packages

```bash
# Remove the main database package
sudo dnf remove -y oracle-database-ee-19c-1.0-1.x86_64

# Remove the preinstall package
sudo dnf remove -y oracle-database-preinstall-19c
```
