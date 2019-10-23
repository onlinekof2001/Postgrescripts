#!/bin/bash

# help for command-line.
usage() {
    printf "This script helps you to create users for RDS DB server more easier.\n 
\033[1;32mUsage:\033[0m\n
     . ./createuser_RDS.sh [Options]\n
\033[1;32mOptions:\033[0m\n
     -h or --help show this help, then exit. 
     -s <db_host> RDS server name.
     -d <db_name> Database name need to be access.
     -g <group_name> group that you need to granted to users.\n"
}

role() {
    dbname=$1
    gpname=$2
    if [ ! -z ${gpname} ]
    then
        rol=$(echo ${gpname} | tr '[:upper:]' '[:lower:]')
        psql -d ${dbname} -A -t -c "select rolname from pg_roles where rolname like '%\_${rol}%'"
    fi
}

exec() {
    dbhost=$1
    dbname=$2
    gpname=$3
    while read prf
    do
        user=$(echo $prf | tr '[:upper:]' '[:lower:]')
        psql -d ${dbname} -c "create user $user with login password 'Decathlon01' nocreatedb nocreaterole noreplication connect limit 2;"
        psql -d ${dbname} -c "grant $gpname to $user;"
    done < userlist.inf
}

if [ $# -eq 0 ]
then
    usage
fi

while [ $# -gt 0 ]
do
    case $1 in
        -h|--help)
            usage
            break
        ;;
        -s)
            shift
            if [ $# -eq 0 ]
            then
                usage
            fi
            SERV=$1
        ;;
        -d)
            shift
            if [ $# -eq 0 ]
            then
                usage
            fi
            DBNM=$1
        ;;
        -g)
            shift
            if [ $# -eq 0 ]
            then
                usage
    	    elif [[ $1 == 'ro' ]]
    	    then
                printf "You are trying to grant the \033[1;40mRead only\033[0m right. \n"
                GROL=$(role ${DBNM} $1)
            elif [[ $1 == 'rw' ]]
            then
                printf "You are trying to grant the \033[1;40mRead Write\033[0m right: ${DBNM}_$1. \n"
                GROL=$(role ${DBNM} $1)
            else
                 usage
                 break     
            fi
        ;;
        *)
            usage
            break
        ;;
    esac
    shift
done

if [ ! -z ${SERV} ] && [ ! -z ${USER} ] && [ ! -z ${DBNM} ]
then
    echo "Set environment to connect to database: ${dbhost}"
    . ./${SERV}/set_administrator.sh 2>&1 >> /dev/null                           
    #read -p "Try to grant user read only or read write privileges [ ro | rw ]: " grt
    if [ ! -z ${GROL} ]
    then
    	echo " ${SERV} ${DBNM} ${GROL}"
    else
        echo "Role doesn't exists!!! Please ask DBA to create role first."
    fi
fi
