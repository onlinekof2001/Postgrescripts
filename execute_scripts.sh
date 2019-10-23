#!/bin/bash

# list the command
pgcmd='/usr/bin/psql'
pgpwd='/home/postgres/.pgpass'

function help(){
   echo 'source ./execute_sql.sh or . ./execute_sql.sh'
}

function job(){
read -p "scripts locations: " scpth

for fn in $(ls $scpth)
do
    constr=${fn%%.*}    #
    if [[ ${fn%%.*} =~ '_' ]]
    then
        constr=${constr%%_*}
    fi
    constr=$(echo $constr | tr '[A-Z]' '[a-z]')
    if [ -e $pgpwd ]
    then
        pghst=$(awk -F':' "/$constr/ {print \$1}" $pgpwd)
        pgprt=$(awk -F':' "/$constr/ {print \$2}" $pgpwd)
        export PGPASSFILE=~/.pgpass
        export PGPORT=$pgprt
        export PGHOST=$pghst
    fi
    echo "$pgcmd -U$constr $constr -f $fn"
    #$pgcmd -U$constr $constr -f $fn
done
}

case $1 in
    -h|--help)
    help
    ;;
    *)
    job
    ;;
esac