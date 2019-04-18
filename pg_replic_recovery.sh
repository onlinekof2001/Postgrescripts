#!/bin/bash

###########################################################################
#
#
#   The purpose of This script is automatically repair the replication.
#   We assume the operators already have exactly information about the replication.
#   To avoid human mistake while repair the slave server, we decide build this automatically
#   script.
#   1. check database version
#   2. check replication gaps
#   3. check wal missing
#   4. repair replication by rsync
#   
#   more detail: http://
#
#######################################################################

POSTGRES_HOME=/u01/app/postgres
PSQL_CMD=$(find /usr/bin -name psql -executable)
PGCTL_CMD=$(find /usr/pgsql-9.5/ -name pg_ctl -executable)
RSYNC_CMD=$(find /usr/bin -name rsync -executable)

function timestamp {
    date +'%b %d %H:%M:%S'
}

function log {
    TYPE=$(echo $1 | tr '[:lower:]' '[:upper:]')
    shift
    if [[ "${TYPE}" == "PRINT" ]]; then
        TYPE=$(echo $1 | tr '[:lower:]' '[:upper:]')
        shift
        echo $TYPE: ${*}
    fi
    echo "$(timestamp) $TYPE: ${*}" >> ${LOGFILE}
    if [[ "${TYPE}" == "FATAL" ]]; then
        exit 1
    fi
}

### Usage
Usage(){
        echo "##############################################################################################"
        echo "Usage: $0 i <instance_name> -m <master_site> -r <replication_site>  { -c }"
        echo ""
        echo "  -i <instance_name> = PostgreSQL instance name"
        echo "  -m <master_site> = PostgreSQL master database hostname"
	echo "  -r <replication_site> = PostgreSQL slave database hostname"
        echo ""
        echo "  -c                 = Confirm the status of master site and lags between master and slave"
        echo ""
        echo "##############################################################################################"
        exit 1
}

PGTAB='/etc/pgtab'

function chk_pg_version {
    PG_VER=$(${PSQL_CMD} -A -q -t -c 'select version()' | awk '{print $2}')
}


function chk_pg_scenario {
    STATE=(`${PSQL_CMD} -A -q -t -c 'select pg_is_in_recovery(), count(client_addr) from pg_stat_replication' | awk -F'|' '{print $1" "$2}'`)

}

function pg_slave_status {
    INST_NAME=$1
    REPL_SITE=$2
    CONN_STR=($(grep ${INST_NAME} ${PGTAB} | awk -F':' '{print $1" "$2" "$3}'))
    log $(ssh ${REPL_SITE} "export PGDATA=${CONN_STR[1]} ; export PORT=${CONN_STR[2]} ; ${PGCTL_CMD} -d ${CONN_STR[1]} status")
}

function pg_slave_stop {
    INST_NAME=$1
    REPL_SITE=$2
    CONN_STR=($(grep ${INST_NAME} ${PGTAB} | awk -F':' '{print $1" "$2" "$3}'))
    log $(ssh ${REPL_SITE} "export PGDATA=${CONN_STR[1]} ; export PORT=${CONN_STR[2]} ; ${PGCTL_CMD} -d ${CONN_STR[1]} stop")
}

function pg_slave_start {
    INST_NAME=$1
    REPL_SITE=$2
    CONN_STR=($(grep ${INST_NAME} ${PGTAB} | awk -F':' '{print $1" "$2" "$3}'))
    log $(ssh ${REPL_SITE} "export PGDATA=${CONN_STR[1]} ; export PORT=${CONN_STR[2]} ; ${PGCTL_CMD} -d ${CONN_STR[1]} start")
}

function repair_pg_slave {
    INST_NAME=$1
    REPL_SITE=$2
    ${PSQL_CMD} -A -q -t -c "select pg_start_backup('init')"
    ${RSYNC_CMD} -n -C -a -v --delete -e ssh --exclude-from=${EXCLUDE_FILE} ${POSTGRES_HOME}/data/${INST_NAME}/* ${REPL_SITE}:${POSTGRES_HOME}/data/${INST_NAME}/
    ${PSQL_CMD} -A -q -t -c "select pg_stop_backup()"
}

# Check parameter count
if [[ $# -lt 4 || $# == "-h" || $# == "--help" ]]
then
  Usage
  exit 1;
fi

# Get parameters
while [[ $# -gt 0 ]]
do
    i="$1"
    case $i in
        -i)
            INSTANCE=$(echo $2 | tr '[:upper:]' '[:lower:]')
            shift # past argument
            shift # past value
            ;;
        -m)
            MASTER_DB=$(echo $2 | tr '[:upper:]' '[:lower:]')
            shift # past argument
            shift # past value
            ;;
        -r)
            SLAVE_DB=$(echo $2 | tr '[:upper:]' '[:lower:]')
            shift # past argument
            shift # past value
	    ;;
        -c) # check replication status
            CHECK_BOOLEAN=Y
	    shift # past argument
            ;;
        *)    # unknown option
            echo "unknown parameter $i" && Usage && exit 1;
            ;;
    esac
done

LOGFILE="/u01/app/postgres/recovery/repair_${SLAVE_DB}_${INSTANCE}_$(date +%H%M%S).log"
EXCLUDE_FILE='/u01/app/postgres/recovery/exclude_files.lst'

# Ensure using postgres user to do the task
if [[ $(id -un) != 'postgres' ]]
then
  log print error "You didn't running the script with postgres user. COMMAND-LINE[su - postgres]"
  exit 1;
fi

# Check psql command can be find in server, then go next step
if [[ -x ${PSQL_CMD} ]]
then
    log print info "The execution logs are in ${LOGFILE}"
    chk_pg_scenario
    if [ ${STATE[0]} == 'f' ]
    then
	log print info "It is a master server"
        pg_slave_status ${INSTANCE} ${SLAVE_DB}
        read -p "You're go to stop the slave instance" opti
        option=$(echo $opti | tr '[:upper:]' '[:lower:]')
        if [[ ${opti} = 'y' ]]
        then
	    pg_slave_stop ${INSTANCE} ${SLAVE_DB}
        else
            pg_slave_status ${INSTANCE} ${SLAVE_DB}
            exit 1;
        fi
        repair_pg_slave ${INSTANCE} ${SLAVE_DB}
    fi
else
    exit 1;
fi


