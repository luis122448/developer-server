#!/bin/bash

sed -i 's/ COLLATE "USING_NLS_COMP"//g' oracle/init/TABLES.sql

sed -i 's/DEFAULT COLLATION "USING_NLS_COMP"//g' oracle/init/TABLES.sql

sed -i 's/SEGMENT CREATION IMMEDIATE//g' oracle/init/TABLES.sql

sed -i 's/MAXVALUE [0-9]\+//g' oracle/init/TABLES.sql