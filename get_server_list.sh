#!/bin/bash

mcmd='/usr/bin/mysql'
user='user_dtc'
dbname='dtc'
fullist='/opt/full_server.lst'
fuldblist='/opt/db_full_server.lst'

NAME=`basename $0`
if [ ${NAME:0:1} = "S" -o ${NAME:0:1} = "K" ]
    then
    NAME=${NAME:3}
fi

function help() {
    echo -e "\e[1;37mNAME\e[0m"
    echo "      $NAME"
    echo ""
    echo -e "\e[1;37mSYNOPSIS\e[0m"
    echo "      $NAME -e <environment_name> [ -a ] [ -p ] [ -h ]"
    echo ""
    echo -e "\e[1;37mDESCRIPTION\e[0m"
    echo "      Script used to list servers of platform or all environment."
    echo ""
    echo -e "\e[1;37mOPTIONS\e[0m"
    echo "      -h | --help                                        Print help"
    echo ""
    echo "      -e | --environment                                 An option of environments are [ Prod_Retail | Prep_Retail | Prod_Inix | Prep_Inix ]"
    echo ""
    echo "      -a | --all                                         It is a default option, list all servers on the Environment or Platform"
    echo ""
    echo "      -p | --platform                                    Optional parameter, list all servers on platform"
    echo ""
    exit 0;
}

function usage() {
    echo -e "\e[1;37mWarning:\e[0m correct command-line should be $NAME -e <environment_name> [ -a ] [ -p ] [ -h ]"
    echo ""
    exit 3;
}

while [ $# -gt 0 ]
do
        case $1 in
            -h|--help)
            help
            ;;
            -e|--environment)
            shift
                if [ $# -eq 0 ]
                then
                    usage
            elif [[ $ops =~ 'help' ]] ; then
                help
                break
            elif [[ ! $1 =~ ^[Pp]r* ]] ; then
                    echo "Work with a wrong option, the options are [ Prod_Retail | Prep_Retail | Prod_Inix | Prep_Inix ]"
                break
                fi
            envir=$(echo $1 | awk -F'_' '{print $1}')
            group=$(echo $1 | awk -F'_' '{print $2}')
            if [[ ${envir} = [Pp]rod ]] ; then
                ENVIR='infra1gat01'
            else
                ENVIR='bditz1gat01'
            fi
            if [ -z ${group} ] ; then
                TEAM=\(\'Retail\',\'Mutualized\'\)
            elif [[ ${group} = [Ii]nix ]] ; then
                TEAM=\(\'Mutualized\'\)
            else
                TEAM=\(\'Retail\'\)
            fi
            ;;
            -p|--platform)
                shift
                if [ $# -eq 0 ]
                then
                    echo "Command without platforms,plz give detail info about platform"
                    usage
                fi
                PLAT=$1
            ;;
            -a|--all)
                HOSTS=ALL
            ;;
            *)
            echo "Unkown option $1"
            usage
            ;;
        esac
    shift
done

paswd='pVHswfIcHv'

platlist="/opt/${ENVIR}_${PLAT}_server.lst"
platdblist="/opt/db_${ENVIR}_${PLAT}_server.lst"

if [[ ${ENVIR} != '' ]] ; then
if [[ ${PLAT} = '' ]] ; then
    ${mcmd} -N -u${user} -p${paswd} ${dbname} -e "SELECT distinct ms.server_name Server_name
    FROM man_server ms
    JOIN man_status mt ON mt.id = ms.status_id 
    JOIN man_platform mp ON mp.id = mt.platform
    WHERE ms.reachable_from = '${ENVIR}' and cex in ${TEAM}
    ORDER BY mp.name"  > ${fullist}
    echo "Please take a look at the file ${fullist}"
    ${mcmd} -N -u${user} -p${paswd} ${dbname} -e "SELECT distinct db_server from pool p where exists (SELECT distinct ms.server_name Server_name
    FROM man_server ms
    JOIN man_status mt ON mt.id = ms.status_id 
    JOIN man_platform mp ON mp.id = mt.platform
    WHERE ms.reachable_from = '${ENVIR}' and cex in ${TEAM}
    and ms.server_name = p.db_server)
    ORDER BY db_server"  > ${fuldblist}
    echo "As for all dbs please take a look at the file ${fuldblist}"
else
    ${mcmd} -N -u${user} -p${paswd} ${dbname} -e "SELECT distinct ms.server_name Server_name
    FROM man_server ms
    JOIN man_status mt ON mt.id = ms.status_id 
    JOIN man_platform mp ON mp.id = mt.platform
    WHERE ms.reachable_from = '${ENVIR}' and mp.name= '${PLAT}' and cex in ${TEAM}
    ORDER BY mp.name" > ${platlist}
    echo "To see whole platform, please take a look at the file ${platlist}"
    ${mcmd} -N -u${user} -p${paswd} ${dbname} -e "SELECT ms.server_name 
    FROM man_server ms
    JOIN man_status mt ON mt.id = ms.status_id 
    JOIN man_platform mp ON mp.id = mt.platform
    WHERE ms.reachable_from='${ENVIR}' and mp.name='${PLAT}' and cex in ${TEAM}
    and ms.server_name in (select db_server from pool)" > ${platdblist}
    echo "Only shows dbs which inside the platform,please take a look at the file ${platdblist}"
fi
#else
#    echo 'No option usage for environment'
#    usage
fi