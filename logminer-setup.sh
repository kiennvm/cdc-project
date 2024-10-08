#!/bin/sh

# Set archive log mode and enable GG replication
ORACLE_SID=ORCLCDB
export ORACLE_SID
sqlplus /nolog <<- EOF
        CONNECT sys/top_secret AS SYSDBA
        alter system set db_recovery_file_dest_size = 10G;
        alter system set db_recovery_file_dest = '/opt/oracle/oradata/recovery_area' scope=spfile;
        shutdown immediate
        startup mount
        alter database archivelog;
        alter database open;
        -- Should show "Database log mode: Archive Mode"
        archive log list
        exit;
EOF

# Enable LogMiner required database features/settings
sqlplus sys/top_secret@//localhost:1521/ORCLCDB as sysdba <<- EOF
        ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
        exit;
EOF

# Create Log Miner Tablespace and User
sqlplus sys/top_secret@//localhost:1521/ORCLCDB as sysdba <<- EOF
  CREATE TABLESPACE logminer_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/logminer_tbs.dbf' SIZE 500M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
  exit;
EOF

sqlplus sys/top_secret@//localhost:1521/ORCLPDB1 as sysdba <<- EOF
  CREATE TABLESPACE logminer_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/ORCLPDB1/logminer_tbs.dbf' SIZE 500M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
  exit;
EOF


sqlplus sys/top_secret@//localhost:1521/ORCLCDB as sysdba <<- EOF

CREATE USER c##dbzuser IDENTIFIED BY dbz DEFAULT TABLESPACE logminer_tbs QUOTA UNLIMITED ON logminer_tbs CONTAINER=ALL;

  GRANT CREATE SESSION TO c##dbzuser CONTAINER=ALL; 
  GRANT SET CONTAINER TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT ON V_\$DATABASE to c##dbzuser CONTAINER=ALL; 
  GRANT FLASHBACK ANY TABLE TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT ANY TABLE TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT_CATALOG_ROLE TO c##dbzuser CONTAINER=ALL; 
  GRANT EXECUTE_CATALOG_ROLE TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT ANY TRANSACTION TO c##dbzuser CONTAINER=ALL; 
  GRANT LOGMINING TO c##dbzuser CONTAINER=ALL; 

  GRANT CREATE TABLE TO c##dbzuser CONTAINER=ALL; 
  GRANT LOCK ANY TABLE TO c##dbzuser CONTAINER=ALL; 
  GRANT CREATE SEQUENCE TO c##dbzuser CONTAINER=ALL; 

  GRANT EXECUTE ON DBMS_LOGMNR TO c##dbzuser CONTAINER=ALL; 
  GRANT EXECUTE ON DBMS_LOGMNR_D TO c##dbzuser CONTAINER=ALL; 

  GRANT SELECT ON V_\$LOG TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT ON V_\$LOG_HISTORY TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT ON V_\$LOGMNR_LOGS TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT ON V_\$LOGMNR_CONTENTS TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT ON V_\$LOGMNR_PARAMETERS TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT ON V_\$LOGFILE TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT ON V_\$ARCHIVED_LOG TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT ON V_\$ARCHIVE_DEST_STATUS TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT ON V_\$TRANSACTION TO c##dbzuser CONTAINER=ALL; 

  GRANT SELECT ON V_\$MYSTAT TO c##dbzuser CONTAINER=ALL; 
  GRANT SELECT ON V_\$STATNAME TO c##dbzuser CONTAINER=ALL; 

  exit;
EOF

sqlplus sys/top_secret@//localhost:1521/ORCLPDB1 as sysdba <<- EOF
  CREATE USER debezium IDENTIFIED BY dbz;
  GRANT CONNECT TO debezium;
  GRANT CREATE SESSION TO debezium;
  GRANT CREATE TABLE TO debezium;
  GRANT CREATE SEQUENCE to debezium;
  ALTER USER debezium QUOTA 500M on users;
  
  exit;
EOF
