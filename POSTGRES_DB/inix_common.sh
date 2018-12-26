#!/bin/bash

function timestamp {
    # display the current time
    date +'%b %d %H:%M:%S'
}

function info {
    # display on stdout
    echo "$(timestamp) INFO: ${*}."
}

function warning {
    # display on stdout
    echo "$(timestamp) WARNING: ${*}."
}

function error {
    # display on stderr
    echo "$(timestamp) ERROR: ${*}."
}

function die {
    # display an error message then dies
    error "$1"
    echo ""

    exit 1
}

function add_sql_header {
    # set params to sql request to format its output
    typeset SQL="$1"

    echo '\pset tuples_only on
\pset format unaligned
\pset pager off'"
$SQL"
}

function psql_no_check {
    # execute a request on the database
    # assume that PGHOST, PGPORT, PGUSER and PGPASSWORD are set
    # if the sql is a script with parameters, they must have -v with them
    # ie: SQL="script.sql -v var1=value1 -v var2=value2"
    typeset DATABASE="${1}"
    typeset SQL="${2}"

    SQL_FILE=$(mktemp -u)'.sql'

    # there can be up to 4 parameters to the SQL script
    typeset SCRIPT=$(echo "${SQL}" | cut -d ' ' -f 1)
    typeset PARAMS=$(echo "${SQL}" | cut -d ' ' -f 2,3,4,5,6,7,8,9)

    # check if SQL query or SQL script file
    if [ -f "${SCRIPT}" ]; then
	cp "${SCRIPT}" "${SQL_FILE}"
    else
	echo "${SQL}" > "${SQL_FILE}"
	PARAMS=""
    fi
    echo "\q" >> "${SQL_FILE}"

    psql --no-password -q -d ${DATABASE} -f ${SQL_FILE} ${PARAMS}
    typeset RC=$?

    rm -f "$SQL_FILE"

    return $RC
}

function psql_check_errors {
    # assume that PGHOST, PGPORT, PGUSER and PGPASSWORD are set
    typeset DATABASE="${1}"
    typeset SQL="${2}"
    typeset IGNORE="${3}"

    typeset RC=0
    typeset LOG_FILE=$(mktemp)

    psql_no_check "${DATABASE}" "${SQL}" 2>&1 | tee "${LOG_FILE}"

    # check psql_no_check exit code with bash specific PIPESTATUS variable
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
	error "psql exit code != 0"
	RC=1
    fi

    grep 'ERROR:' "$LOG_FILE" |
    if [ -n "${IGNORE}" ]; then
        grep -E -v "${IGNORE}"
    else
        cat <&0
    fi |
    grep -q 'ERROR:'
    if [ $? -eq 0 ]; then
        error "'ERROR: ' detected while executing sql request"
        RC=1
    fi

    rm -f "$LOG_FILE"

    return $RC
}

# 9.5 client is installed on preprod and prod
export PATH=/usr/pgsql-9.5/bin:${PATH}
export LD_LIBRARY_PATH=/usr/pgsql-9.5/lib:${LD_LIBRARY_PATH}
