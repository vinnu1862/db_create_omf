#!/bin/bash
#
#################################################################################
#Author: Vinaykumar Srirangam
#Purpose: Database verification script before releasing to business
#
#
#################################################################################


NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
C_PATT=`echo -e '\033[31;01m'`
C_NORM=`echo -e '\033[m'`
Date=`date +%d%m%Y-%H%M%S `
(
if [ $# -ne 2 ]; then
        echo ; echo -e "${CYAN}Don't be adventurous, below is the usage:${NONE}"
        echo;echo -e "${RED}Usage: `basename $0 ` <DBNAME> <RAC|NONRAC> ${NONE}";echo
        exit 1
fi
if [ aa`echo $2 | tr 'a-z' 'A-Z' ` == aaRAC ] || [ aa`echo $2 | tr 'a-z' 'A-Z'` == aaNONRAC ]; then
	echo
else
        echo ; echo -e "${CYAN}Don't be adventurous, below is the usage:${NONE}"
        echo;echo -e "${RED}Usage: `basename $0 ` <DBNAME> <RAC|NONRAC> ${NONE}";echo
        exit 1
fi

echo;


givenDbName=$1
ISRAC=`echo $2 | tr 'a-z' 'A-Z'`
echo -e "${YELLOW} \t\t DATABASE CHECKLIST REPORT FOR DATABASE: ${CYAN}${givenDbName} ${NONE} ${YELLOW}on host ${CYAN}`hostname`  ${NONE}"
echo -e "${YELLOW} \t\t REPORT DATE\t\t\t       : ${CYAN}`date +%d-%b-%Y\ %H:%M:%S` ${NONE}"
echo -e "${YELLOW} \t\t NOTE\t\t\t               : ${RED}[] ${YELLOW}contains the recommended values ${NONE}"
echo -e "${YELLOW}\t+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++${NONE}"
if [ `uname`=='Linux' ] ; then
      if [ `grep -i ^${givenDbName} /etc/oratab|grep -v ^#|uniq|wc -l` -eq 1 ];then
          if [ `ps -ef|grep [s]mon_|grep -i ${givenDbName}|grep -v '+'|grep -v .bin|wc -l` -eq 1 ];then
               if [ a${ISRAC} == 'aRAC' ];then
                actualDatabase=`ps -ef|grep [s]mon_|grep -i ${givenDbName}|grep -v '+'|grep -v .bin|awk -F"_" '{print $3}' | rev | cut -c2- | rev`
               else
                actualDatabase=`ps -ef|grep [s]mon_|grep -i ${givenDbName}|grep -v '+'|grep -v .bin|awk -F"_" '{print $3}'`
               fi
                  if [ ${givenDbName} == `echo ${actualDatabase}` ]; then
                    export ORACLE_SID=`ps -ef|grep [s]mon_|grep -i ${givenDbName}|grep -v '+'|grep -v .bin|awk -F"_" '{print $3}'`
                    export ORACLE_HOME=`grep ^${actualDatabase} /etc/oratab|awk -F: '{print $2}'`
                    echo;echo -e "ORATAB ENTRY\t\t\t: ${GREEN}YES${NONE}";
                   else
                    echo;echo -e "${RED}Given database name is incorrect${NONE}";echo
                    exit 1;
                   fi
           else
            echo;echo -e "${RED}The database is not running on the server but listed in oratab file${NONE}";echo
            exit 1;
           fi
       else
         if [ `grep -i ^#${givenDbName} /etc/oratab|wc -l` -eq 1 ];then
          echo;echo -e "${RED}DB Entry is commented in oratab${NONE}";echo
          exit 1;
         else
           if [ `grep -i ^${givenDbName} /etc/oratab|wc -l` -gt 1 ];then
             echo;echo -e "${RED}Mutliple entries found, please check${NONE}";echo
             exit 1;
           else
              echo;echo -e "${RED}The database '${givenDbName}' does not exist in oratab${NONE}";echo
              exit 1;
            fi
          fi
       fi
 else
   echo;echo -e "This script does not support `uname` platform";echo
   exit 1;
fi
	
if [ `grep ${actualDatabase} ~/.bash_profile | wc -l ` -eq 1 ]; then
	echo -e "BASH_PROFILE ENTRY\t\t: ${GREEN}YES${NONE}";
else
	echo -e "BASH_PROFILE ENTRY\t\t: ${RED}NO${NONE}";
fi

DBSTATUS=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit  
select status from v\\$instance;  
exit
EOF
`

if [ `echo $DBSTATUS|grep -E 'ORA-|STARTED|MOUNTED|OPEN MIGRATE'|wc -l` -gt 0 ];then
        echo -e "${RED}Database/Instance  is not in open mode.Please check!!! ${NONE}";echo
        exit 1
fi
DBNAME=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit  
select name from v\\$database;
exit
EOF
`

DB_ENV=`echo ${DBNAME} | rev | cut -c1-3 | rev | tr '[:lower:]' '[:upper:]'`

if [ `echo ${DB_ENV}` == "PRD" ];then
	IS_PRD=TRUE
	echo -e "ENVIRONMENT\t\t\t: ${GREEN}PRODUCTION${NONE}";
else
	IS_PRD=FALSE
	if [ `echo ${DB_ENV}` == 'VAL' ];then
		echo -e "ENVIRONMENT\t\t\t: ${GREEN}VALIDATION${NONE}";
	elif [ `echo ${DB_ENV}` == 'DEV' ];then
                echo -e "ENVIRONMENT\t\t\t: ${GREEN}DEVELOPMENT${NONE}";
	elif [ `echo ${DB_ENV}` == 'TST' ];then
		echo -e "ENVIRONMENT\t\t\t: ${GREEN}TEST${NONE}";
	elif [ `echo ${DB_ENV}` == 'TRN' ];then
                echo -e "ENVIRONMENT\t\t\t: ${GREEN}TRAINING${NONE}";
        elif [ `echo ${DB_ENV}` == 'SBX' ];then
                echo -e "ENVIRONMENT\t\t\t: ${GREEN}SANDBOX${NONE}";
	elif [ `echo ${DB_ENV}` == 'STG' ];then
                echo -e "ENVIRONMENT\t\t\t: ${GREEN}STAGING${NONE}";
	else
		echo -e "ENVIRONMENT\t\t\t: ${RED}NOT STANDARD [Database name should end with prd|val|dev|tst|trn|sbx|stg]${NONE}";
	fi
fi

GlobalName=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 heading off feedback off
conn / as sysdba
select * from global_name;
exit
EOF
`
OpenMode=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 heading off feedback off
conn / as sysdba
select open_mode from v\\$database;
exit
EOF
`

if [ `echo $DBNAME|grep ORA-|wc -l` -gt 0 ];then
	echo -e "${RED}Database is in abnormal state ${NONE}";echo
	exit 1
else
	echo -e "DBNAME\t\t\t\t: ${GREEN}${DBNAME}${NONE}";
        echo -e "DB Status\t\t\t: ${GREEN}${DBSTATUS} ${NONE}";
	echo -e "GLOBAL NAME\t\t\t: ${GREEN}${GlobalName}${NONE}";
        echo -e "OPEN MODE\t\t\t: ${GREEN}${OpenMode}${NONE}";
fi

ArchiverStatus=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 heading off feedback off
conn / as sysdba
select archiver from v\\$instance;
exit
EOF
`

if [ `echo ${IS_PRD}` == "TRUE" ];then
        if [ `echo ${ArchiverStatus}|grep START|wc -l` -eq 1 ];then
                echo -e "Archive Status\t\t\t: ${GREEN}ENABLED${NONE}";
        else
                echo -e "Archive Status\t\t\t: ${RED}DISABLED [ENABLED]${NONE}";
        fi
else
        if [ `echo ${ArchiverStatus}|grep START|wc -l` -eq 1 ];then
                echo -e "Archive Status\t\t\t: ${RED}ENABLED [DISABLED]${NONE}";
        else
                echo -e "Archive Status\t\t\t: ${GREEN}DISABLED${NONE}";
        fi
fi


PROCESSES=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select VALUE from v\\$parameter where NAME='processes';
exit
EOF
`
if [ `echo $PROCESSES` -eq 1000 ];then
        echo -e "PROCESSES\t\t\t: ${GREEN}${PROCESSES}${NONE}";
else
        echo -e "PROCESSES\t\t\t: ${RED}${PROCESSES} [ 1000 ]${NONE}";
fi
SESSIONS=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select VALUE from v\\$parameter where NAME='sessions';
exit
EOF
`
#if [ `echo ${SESSIONS}` -eq 1000 ];then
#        echo -e "SESSIONS\t\t\t: ${GREEN}${SESSIONS}${NONE}";
#else
#        echo -e "SESSIONS\t\t\t: ${RED}${SESSIONS} [ 1000 ] ${NONE}";
#fi

OPEN_CURSORS=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select VALUE from v\\$parameter where NAME='open_cursors';
exit
EOF
`
if [ `echo $OPEN_CURSORS` -eq 1000 ];then
	echo -e "OPEN CURSORS\t\t\t: ${GREEN}${OPEN_CURSORS}${NONE}";
else
	echo -e "OPEN CURSORS\t\t\t: ${RED}${OPEN_CURSORS}[ 1000 ]${NONE}";
fi

DBDOMAIN=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select VALUE from v\\$parameter where NAME='db_domain';
exit
EOF
`
if [ aa`echo $DBDOMAIN` == aa ]; then
	echo -e "DBDOMAIN\t\t\t: ${GREEN}NONE${NONE}";
else
	echo -e "DBDOMAIN\t\t\t: ${RED}$DBDOMAIN[NONE]${NONE}";
fi

IS_RACDB=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select VALUE from v\\$parameter where NAME='cluster_database';
exit
EOF
`
MEMORY=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select VALUE from v\\$parameter where NAME='memory_target';
exit
EOF
`

if [ `echo ${IS_RACDB} | grep -i true | wc -l ` -eq 1 ];then
	echo -e "IS RAC DATABASE\t\t\t: ${GREEN}${IS_RACDB}${NONE}";
	if [ `echo $MEMORY | tr '[:lower:]' '[:upper:]'` == '6G' ] || [ `echo $MEMORY | tr '[:lower:]' '[:upper:]'` == '6442450944' ] ;then
        	echo -e "DB MEMORY(memory_target)\t: ${GREEN}6G ${NONE}";
	else
        	echo -e "DB MEMORY(memory_target)\t: ${RED}${MEMORY} [6G]${NONE}";
	fi
elif [ `echo ${IS_RACDB} | grep -i false | wc -l ` -eq 1 ];then
        echo -e "IS RAC DATABASE\t\t\t: ${GREEN}${IS_RACDB}${NONE}";
        if [ `echo $MEMORY | tr '[:lower:]' '[:upper:]'` == '4G' ] || [ `echo $MEMORY | tr '[:lower:]' '[:upper:]'` == '4294967296' ] ;then
                echo -e "DB MEMORY(memory_target)\t: ${GREEN}4G${NONE}";
        else
                echo -e "DB MEMORY(memory_target)\t: ${RED}${MEMORY} [4G]${NONE}";
        fi
fi

PROFILES=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select distinct profile from dba_profiles where profile in ('USERS','SYSTEM','SERVICE') order by 1;
exit
EOF
`

if [ `echo ${PROFILES} | grep -i "USERS" | wc -l ` -eq 1 ];then
	echo -e "USER PROFILE\t\t\t: ${GREEN}CREATED${NONE}";
else
	echo -e "USER PROFILE\t\t\t: ${RED}NOT CREATED [ CREATED ]${NONE}";
fi

if [ `echo ${PROFILES} | grep -i "SYSTEM" | wc -l ` -eq 1 ];then
        echo -e "SYSTEM PROFILE\t\t\t: ${GREEN}CREATED${NONE}";
else
        echo -e "SYSTEM PROFILE\t\t\t: ${RED}NOT CREATED [ CREATED ]${NONE}";
fi

if [ `echo ${PROFILES} | grep -i "SERVICE" | wc -l ` -eq 1 ];then
        echo -e "SERVICE PROFILE\t\t\t: ${GREEN}CREATED${NONE}";
else
        echo -e "SERVICE PROFILE\t\t\t: ${RED}NOT CREATED [ CREATED ]${NONE}";
fi


SYS_PROFILE=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select profile from dba_users where username='SYS';
exit
EOF
`

if [ ${SYS_PROFILE} == SYSTEM ]; then
        echo -e "SYS ACCOUNT PROFILE\t\t:${GREEN} ${SYS_PROFILE}${NONE}";
else
	echo -e "SYS ACCOUNT PROFILE\t\t:${RED} ${SYS_PROFILE} [ SYSTEM ]${NONE}";
fi

SYSTEM_PROFILE=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select profile from dba_users where username='SYSTEM';
exit
EOF
`

if [ ${SYSTEM_PROFILE} == SYSTEM ]; then
        echo -e "SYSTEM ACCOUNT PROFILE\t\t:${GREEN} ${SYSTEM_PROFILE}${NONE}";
else
        echo -e "SYSTEM ACCOUNT PROFILE\t\t:${RED} ${SYSTEM_PROFILE} [ SYSTEM ]${NONE}";
fi

DBSNMP_PROFILE=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select profile from dba_users where username='DBSNMP';
exit
EOF
`

if [ ${DBSNMP_PROFILE} == SERVICE ]; then
        echo -e "DBSNMP ACCOUNT PROFILE\t\t:${GREEN} ${DBSNMP_PROFILE}${NONE}";
else
        echo -e "DBSNMP ACCOUNT PROFILE\t\t:${RED} ${DBSNMP_PROFILE} [ SERVICE ]${NONE}";
fi


CHAR_SET=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select VALUE from nls_database_parameters where PARAMETER='NLS_CHARACTERSET';
exit
EOF
`

if [ ${CHAR_SET} == AL32UTF8 ]; then
	echo -e "NLS CHARACTERSET\t\t: ${GREEN}${CHAR_SET}${NONE}";
else
	echo -e "NLS CHARACTERSET\t\t: ${RED}${CHAR_SET}${NONE}";
fi

if [ `$ORACLE_HOME/bin/lsnrctl status | grep $ORACLE_SID | grep READY | wc -l ` -gt 0 ]; then
	echo -e "LISTENER REGISTATION\t\t: ${GREEN}REGISTERED${NONE}";
else
        echo -e "LISTENER REGISTATION\t\t: ${RED}REGISTERED${NONE}";
fi

DIAG_DEST=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select VALUE from v\\$parameter where NAME='diagnostic_dest';
exit
EOF
`

if [ aa${DIAG_DEST} == aa/u01/app/oracle ]; then
        echo -e "DIAGNOSTIC DEST\t\t\t: ${GREEN}${DIAG_DEST}${NONE}";
else
        echo -e "DIAGNOSTIC DEST\t\t\t: ${RED}${DIAG_DEST}${NONE}";
fi


DBFILE=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select VALUE from v\\$parameter where NAME='db_create_file_dest';
exit
EOF
`

if [ aa`echo ${DBFILE}` == aa ]; then
	echo -e "DATAFILE DEST\t\t\t: ${RED}NONE ${NONE}";
	flag_dbf=1
else
	echo -e "DATAFILE DEST\t\t\t: ${GREEN}${DBFILE} ${NONE}";
	flag_dbf=0
fi

RECOFILE=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select VALUE from v\\$parameter where NAME='db_recovery_file_dest';
exit
EOF
`

if [ aa`echo ${RECOFILE}` == aa ]; then
        echo -e "RECOVERY DEST\t\t\t: ${RED}NONE ${NONE}";
	flag_reco=1
else
        echo -e "RECOVERY DEST\t\t\t: ${GREEN}${RECOFILE} ${NONE}";
	flag_reco=0
fi
REGISTRY=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
set lines 222 
col COMP_NAME for a40
conn / as sysdba
whenever sqlerror exit
select comp_name,version,status from dba_registry order by STATUS,VERSION,COMP_NAME;
exit
EOF
`
echo -e "REGISTRY COMPONENTS \t\t:"
REPLY=''
if [ aa${ISRAC} == aaRAC ]; then
	if [ `echo ${REGISTRY} | grep "Oracle Workspace Manager" | wc -l ` -eq 1 ] && [ `echo ${REGISTRY} | grep "Oracle XML Database" | wc -l ` -eq 1 ] && [ `echo ${REGISTRY} | grep "Oracle Database Catalog Views" | wc -l ` -eq 1 ] && [ `echo ${REGISTRY} | grep "Oracle Database Packages and Types" | wc -l ` -eq 1 ] && [ `echo ${REGISTRY} | grep "Oracle Real Application Clusters" | wc -l ` -eq 1 ]; then
		while read -r; do
			if [ `echo ${REPLY} | grep INVALID | wc -l ` -eq 0 ]; then
				echo -e "${GREEN}\t\t\t\t  ${REPLY}${NONE}"
			else
				echo -e "${RED}\t\t\t\t  ${REPLY}${NONE}"
			fi
		done <<EOF
${REGISTRY}
EOF
	else
		while read -r; do
                        echo -e "${RED}\t\t\t\t  ${REPLY}${NONE}"
                done <<EOF
${REGISTRY}
EOF
	fi
else
	 if [ `echo ${REGISTRY} | grep "Oracle Workspace Manager" | wc -l ` -eq 1 ] && [ `echo ${REGISTRY} | grep "Oracle XML Database" | wc -l ` -eq 1 ] && [ `echo ${REGISTRY} | grep "Oracle Database Catalog Views" | wc -l ` -eq 1 ] && [ `echo ${REGISTRY} | grep "Oracle Database Packages and Types" | wc -l ` -eq 1 ]; then
                while read -r; do
			if [ `echo ${REPLY} | grep INVALID | wc -l ` -eq 0 ]; then
	                        echo -e "${GREEN}\t\t\t\t  ${REPLY}${NONE}"
			else
				echo -e "${RED}\t\t\t\t  ${REPLY}${NONE}"
			fi
                done <<EOF
${REGISTRY}
EOF
        else
                while read -r; do
                        echo -e "${RED}\t\t\t\t  ${REPLY}${NONE}"
                done <<EOF
${REGISTRY}
EOF
        fi

fi

SPFILE=`$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select VALUE from v\\$parameter where NAME='spfile';
exit
EOF
`

if [ aa${SPFILE} == aa ]; then
	echo -e "SPFILE\t\t\t\t: ${RED}NONE ${NONE}";
	echo -ne "HIDDEN PARAMETERS\t\t:"
	HIDDEN_PARAMS=`grep "^*._" ${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora | grep -v __ `
        if [ aa`echo ${HIDDEN_PARAMS} | wc -l ` != aa0 ]; then
		echo
		while read -r; do
                        echo -e "${RED}\t\t\t\t  ${REPLY}${NONE}"
                done <<EOF
${HIDDEN_PARAMS}
EOF
	else
        	echo -e "${GREEN} NONE${NONE}"
	fi
else
	if [ ${ISRAC} == RAC ] && [ `echo ${SPFILE} | grep ${DBFILE} | wc -l ` -eq 1 ]; then
                echo -e "SPFILE\t\t\t\t: ${GREEN}${SPFILE} ${NONE}";
	elif [ ${ISRAC} == RAC ]; then	
		echo -e "SPFILE\t\t\t\t: ${RED}NONE${NONE}";
	elif [ `echo ${SPFILE} | grep $ORACLE_SID | wc -l ` -eq 1 ]; then
		echo -e "SPFILE\t\t\t\t: ${GREEN}${SPFILE}${NONE}";
	else
		echo -e "SPFILE\t\t\t\t: ${RED}${SPFILE}${NONE}";
	fi
${ORACLE_HOME}/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
create pfile='/tmp/init${ORACLE_SID}.ora' from spfile;
exit
EOF
echo -ne "HIDDEN PARAMETERS\t\t:"
HIDDEN_PARAMS=`grep "^*._" /tmp/init${ORACLE_SID}.ora| grep -v __ `
	if [ `grep "^*._" /tmp/init${ORACLE_SID}.ora| grep -v __ | wc -l ` -gt 0 ]; then
		echo
		while read -r; do
                        echo -e "${RED}\t\t\t\t  ${REPLY}${NONE}"
                done <<EOF
${HIDDEN_PARAMS}
EOF
	else
		echo -e "${GREEN} NONE${NONE}"
	fi
fi

flag_reco_ctl=1
flag_data_ctl=1
echo -e "CONTROL FILES \t\t\t:"
for ControlFile in `$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select name from v\\$controlfile;
exit
EOF
`
do
if [ ${flag_reco} -eq 0 ] && [ `echo ${ControlFile} | grep ^${RECOFILE} | wc -l ` -eq 1 ]; then
	flag_reco_ctl=0
elif [ ${flag_dbf} -eq 0 ] && [ `echo ${ControlFile} | grep ^${DBFILE} | wc -l ` -eq 1 ]; then
	flag_data_ctl=0
fi
if [ ${flag_reco_ctl} -eq 0 ] || [ ${flag_data_ctl} -eq 0 ] ; then
	echo -e "\t\t\t\t${GREEN}  ${ControlFile}${NONE}";
else 
	echo -e "\t\t\t\t${RED}  ${ControlFile}${NONE}";
fi
done

flag_reco_redo=1
flag_data_redo=1
echo -e "REDO LOG FILES \t\t\t:"
for RedoLog in `$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select member from v\\$logfile order by member;
exit
EOF
`
do
if [ ${flag_reco} -eq 0 ] && [ `echo ${RedoLog} | grep ^${RECOFILE} | wc -l ` -eq 1 ]; then
        flag_reco_redo=0
elif [ ${flag_dbf} -eq 0 ] && [ `echo ${RedoLog} | grep ^${DBFILE} | wc -l ` -eq 1 ]; then
        flag_data_redo=0
fi

if [ ${flag_reco_redo} -eq 0 ] || [ ${flag_data_redo} -eq 0 ] ; then
	echo -e "\t\t\t\t${GREEN}  ${RedoLog}${NONE}";
else
	echo -e "\t\t\t\t${RED}  ${RedoLog}${NONE}";
fi
done

echo -e "DATAFILES \t\t\t:"
for DataFile in `$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select name from v\\$datafile;
exit
EOF
`
do
if [ ${flag_dbf} -eq 0 ] && [ `echo ${DataFile} | grep ${DBFILE} | wc -l ` -eq 1 ]; then
        echo -e "\t\t\t\t${GREEN}  ${DataFile}${NONE}";
else
	echo -e "\t\t\t\t${RED}  ${DataFile}${NONE}";
fi
done

echo -e "TEMPFILES \t\t\t:"
for TempFile in `$ORACLE_HOME/bin/sqlplus -s /nolog <<EOF
set pages 0 feedback off heading off
conn / as sysdba
whenever sqlerror exit
select name from v\\$tempfile;
exit
EOF
`
do
if [ ${flag_dbf} -eq 0 ] && [ `echo ${TempFile} | grep ${DBFILE} | wc -l ` -eq 1 ]; then
	echo -e "\t\t\t\t${GREEN}  ${TempFile}${NONE}";
else
	echo -e "\t\t\t\t${RED}  ${TempFile}${NONE}";
fi
done

)
