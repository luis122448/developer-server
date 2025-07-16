# Oracle 19c Database Installation Guide (RPM Method)

This guide outlines the steps to install and configure an Oracle 19c database using the RPM package on a Linux system.

---

## 1. Transfer Installation File

First, copy the Oracle RPM file to your target server.

```bash
# Copy the RPM from your local machine to the server's /tmp directory
scp /path/to/your/local/oracle-database-ee-19c-1.0-1.x86_64.rpm root@YOUR_SERVER_IP:/tmp
```

Verify that the file was transferred successfully.

```bash
# Check the file in the /tmp directory on the server
ls -lh /tmp/oracle-database-ee-19c-1.0-1.x86_64.rpm
```

---

## 2. Prepare System Directories

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

---

## 3. Install Oracle Software via RPM

Install the Oracle Database software using the `dnf` package manager. This will also handle required dependencies.

```bash
# Install dependency
sudo dnf install -y oracle-database-preinstall-19c

# Install the Oracle Database RPM
sudo dnf install -y /tmp/oracle-database-ee-19c-1.0-1.x86_64.rpm
```

---

## 4. Configure and Create the Database

Before creating the database, you must configure the settings.

### 4.1. Edit Configuration Files

Edit the service and configuration files to define your database parameters.

```bash
# Edit the main service script (optional, for review)
sudo nano /etc/init.d/oracledb_ORCLCDB-19c

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

### 4.2. Create the Database Instance

Run the configuration script to create the database instance based on your settings.

```bash
# This command will create and configure the database
sudo /etc/init.d/oracledb_ORCLCDB-19c configure
```

---

## 5. Set Up Oracle User Environment

To interact with the database, you must configure the environment for the `oracle` user.

### 5.1. Edit the Bash Profile

Log in as the `oracle` user and add the necessary environment variables to the `.bash_profile`.

```bash
# Switch to the oracle user
su - oracle

# Open the profile for editing
nano ~/.bash_profile
```

Add the following lines to the file:

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

### 5.2. Load and Validate the Environment

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

## 6. Validate Database Operation

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

## Appendix: Uninstallation Steps

If you need to remove the Oracle installation, follow these steps.

**WARNING: This is a destructive operation.**

### Step 1: Remove Files and Directories

```bash
# Remove all Oracle-related files and configuration
rm -rf /u01 /opt/oracle /opt/ORCLfmap /etc/oratab /tmp/.oracle
rm -f /etc/init.d/oracle-init
rm -f /etc/security/limits.d/oracle-database-preinstall-19c.conf
rm -f /etc/sysctl.d/oracle-database-preinstall-19c.conf
rm -f /etc/sysconfig/oracle-database-19c
```

### Step 2: Remove RPM Packages

```bash
# Remove the main database package
dnf remove -y oracle-database-ee-19c-1.0-1.x86_64

# Remove the preinstall package
dnf remove -y oracle-database-preinstall-19c
```