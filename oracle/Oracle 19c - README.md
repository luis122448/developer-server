

copyt installation 

scp /home/luis122448/Downloads/oracle-database-ee-19c-1.0-1.x86_64.rpm root@192.168.100.191:/tmp

-- Verify
ls -lh /tmp/oracle-database-ee-19c-1.0-1.x86_64.rpm

-- Minimal configuracion

sudo mkdir -p /u01/app/oracle
sudo mkdir -p /u01/app/oraInventory
sudo chown -R oracle:oinstall /u01
sudo chmod -R 775 /u01/app/oracle
sudo chmod -R 775 /u01/app/oraInventory

-- Dependency
ls -lh /tmp/oracle-database-ee-19c-1.0-1.x86_64.rpm

-- Install Oracle RPM
sudo dnf install -y /tmp/oracle-database-ee-19c-1.0-1.x86_64.rpm

# sudo /etc/init.d/oracledb_ORCLCDB-19c configure
-- Configure

sudo nano /etc/init.d/oracledb_ORCLCDB-19c
sudo nano /etc/sysconfig/oracledb_ORCLCDB-19c.conf

```bash
ORACLE_SID=ORCLCDB
ORACLE_PDB=ORCLPDB1
ORACLE_CHARACTERSET=AL32UTF8
LISTENER_PORT=1521
ORACLE_PWD=
```

-- create database sudo /etc/init.d/oracledb_ORCLCDB-19c configure

-- logged oracle

nano ~/.bash_profile

```bash
# Oracle Environment Variables
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export ORACLE_SID=ORCLCDB

# Add Oracle binaries to PATH
export PATH=$ORACLE_HOME/bin:$PATH

# Set LD_LIBRARY_PATH for shared libraries
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib

# Optional: Set TNS_ADMIN if you're using a centralized tnsnames.ora
# export TNS_ADMIN=$ORACLE_HOME/network/admin
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8

umask 022 # Recommended umask for Oracle installations
```

source ~/.bash_profile

-- Validate
echo $ORACLE_SID ( ORCLCDB )
echo $ORACLE_HOME
echo $PATH

-- logged by sqlplus 

sqlplus / as sysdba

STARTUP;

SELECT name, open_mode FROM v\$database;


-- Unistall

rm -rf /u01 /opt/oracle /opt/ORCLfmap /etc/oratab /tmp/.oracle /etc/init.d/oracle-init /etc/security/limits.d/oracle-database-preinstall-19c.conf /etc/sysctl.d/oracle-database-preinstall-19c.conf /etc/sysconfig/oracle-database-19c

dnf remove -y oracle-database-ee-19c-1.0-1.x86_64

dnf remove -y oracle-database-preinstall-19c
