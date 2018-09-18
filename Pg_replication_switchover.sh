## Define global variables
### COMMON
logFile=/var/log/refresh
myDate=`date +%Y-%m-%d`
myweekday=`date +%a`
### BARMAN
Bmuser=barman
### POSTGRES
Pguser='postgres'
Pgexec="/usr/pgsql-9.2/bin"
Pgpath="/u01/app/postgres/data/crm03"
Pgreco="/var/lib/pgsql/refresh"
Pgmasterserv='rtdkm1pgs91.hosting.as'
Pgslaveserv='rtdkm1pgs90.hosting.as'
PgData="/u01/app/postgres/data/crm03"
### TOMCAT
Tcpath=/opt/tomcat-servers
Tcuser='tomcat'
Tomserv='rtdkm1pgs90.hosting.as'

## Function prototypes
### manageTomcat SERVER ACTION
manageTomcat () {
    # Possible ACTION: stop start status
        action=$1
        servName=$2
        instance=$3
    case ${action} in
        stop)
                    if [ ${instance} != 'ALL' ]
                        then               
            ssh ${Tcuser}@${servName} "sudo ${Tcpath}/bin/tomcat.pl --action stop --instance ${instance}"
                        else
                        ssh ${Tcuser}@${servName} "sudo ${Tcpath}/bin/tomcat.pl --action start --instance ALL"
                        fi
        ;;
        start)
                    if [ ${instance} != 'ALL' ]
                        then
            ssh ${Tcuser}@${servName} "sudo ${Tcpath}/bin/tomcat.pl --action start --instance ${instance}"
                        else
                        ssh ${Tcuser}@${servName} "sudo ${Tcpath}/bin/tomcat.pl --action start --instance ALL"
                        fi
        ;;
        status)
                        ssh ${Tcuser}@${servName} "/opt/tomcat-servers/bin/tomcat.pl --action list | grep 'application(s)' | awk '{print $1}'" > ${logFile}/tomcat_instances.lst
                        startproc=`ssh ${Tcuser}@${servName} "/opt/tomcat-servers/bin/tomcat.pl --action status --instance ALL | grep -c ' is runnin'"`
            totalproc=`ssh ${Tcuser}@${Tomserv} "/opt/tomcat-servers/bin/tomcat.pl --action list | grep -c 'application(s)'"`
                        #if [ ${totalproc} == ${startproc} ]
            #then
            #    exit 0;
            #fi
        ;;
    esac
}

### managePostgres SERVER ACTION
managePostgres () {
    # Possible ACTION: stop start status
        action=$1
        servName=$2
    case ${action} in
               stop)
                       ssh ${Pguser}@${servName} "source ~/.bash_profile;${Pgexec}/pg_ctl stop -m fast"
                       ;;
               start)
                       ssh ${Pguser}@${servName} "source ~/.bash_profile;${Pgexec}/pg_ctl start " &
                       ;;
               status)
                       result=`ssh ${Pguser}@${servName} "${Pgexec}/pg_ctl status -D ${Pgpath}| grep -c 'server is running'"`
                       ;;
        esac
}

### configPostgres SERVER ACTION
configPostgres () {
    # Possible ACTION: backup restore rsync
        action=$1
    servName=$2
    case ${action} in
               backup)
                        ssh ${Pguser}@${servName} "mkdir -p ${Pgreco}/${myDate}"
                        ssh ${Pguser}@${servName} "cp ${Pgpath}/pg_hba.conf ${Pgreco}/${myDate}/pg_hba.conf${myDate}"
                        ssh ${Pguser}@${servName} "cp ${Pgpath}/postgresql.conf ${Pgreco}/${myDate}/postgresql.conf${myDate}"
                        ;;
               restore)
                        ssh ${Pguser}@${servName} "cp ${Pgreco}/${myDate}/pg_hba.conf${myDate} ${Pgpath}/pg_hba.conf"
                        ssh ${Pguser}@${servName} "cp ${Pgreco}/${myDate}/postgresql.conf${myDate} ${Pgpath}/postgresql.conf"
                        ;;
               startsync)
                        ssh ${Pguser}@${servName} "/usr/bin/psql -p 60904 -c\"alter user repli_agent with password 'repli_agent'\"";
                        ssh ${Pguser}@${servName} "/usr/bin/psql -p 60904 -c\"select pg_start_backup('init cluster');\""
                        ssh ${Pguser}@${servName} "/usr/bin/rsync -C -a -v --delete -e ssh --exclude postgresql.conf --exclude postmaster.pid --exclude pg_hba.conf --exclude pg_ident --exclude postmaster.opts --exclude pg_log --exclude recovery.conf ${PgData}/* ${Pgslaveserv}:${PgData}/"
                        ssh ${Pguser}@${servName} "/usr/bin/psql -p 60904 -c\"select pg_stop_backup();\""
                        ;;
    esac
}

### recoverBarman
recoverBarman () {
    LastBackupset=`/usr/bin/barman list-backup rtdkm1pgs51_crm03 | awk '{print $2}'`
    /usr/bin/barman recover --remote-ssh-command "ssh ${Pguser}@${Pgmasterserv}" rtdka1pgs51_crm03 ${LastBackupset} /u01/app/postgres/data/crm03
}

###################
#   Work area     #
###################

#check log file exists
if [ ! -d ${logFile} ]
then
    mkdir ${logFile}
fi
#ensure the user should be barman
current_user=`id | awk -F'[(| |)]' '{print $2}'`

#automotive recovery whole database from production enviroment to laboratory(in manaully way)
#if [ ${current_user} = ${Bmuser} ]
#then
#    case $1 in
#                stoptc)
#                ###step stop tomcat
#                manageTomcat status ${Tomserv}  >${logFile}/refresh${myDate}.log
#                ### Check whether tomcat processes has been shutdown
#                if [ ${totalproc} == ${startproc} ]
#                then
#                        manageTomcat stop ${Tomserv} ALL  >>${logFile}/refresh${myDate}.log
#                        manageTomcat status ${Tomserv}  >>${logFile}/refresh${myDate}.log
#                        echo "Tomcat has been shutdown, work processes: ${startproc}" >>${logFile}/refresh${myDate}.log
#                fi
#                ;;
#                startc)
#                ###step start tomcat
#                manageTomcat status ${Tomserv}  >>${logFile}/refresh${myDate}.log
#                ### Check whether tomcat processes has been shutdown
#                if [ ${startproc} == 0 ]
#                then
#                        manageTomcat start ${Tomserv} ALL  >>${logFile}/refresh${myDate}.log
#                        manageTomcat status ${Tomserv}  >>${logFile}/refresh${myDate}.log
#                        echo "Tomcat has been shutdown, work processes: ${startproc}" >>${logFile}/refresh${myDate}.log
#                fi
#                ;;
#                stoppgs)
#                ### check whether slave postgres has been shutdown
#                managePostgres stop ${Pgslaveserv} >>${logFile}/refresh${myDate}.log
#                managePostgres status ${Pgslaveserv} >>${logFile}/refresh${myDate}.log
#                echo "Slave Postgres has been shutdown, work processes: ${result}" >>${logFile}/refresh${myDate}.log
#                ;;
#                stoppgm)
#                ### check whether master postgres has been shutdown
#                configPostgres backup ${Pgmasterserv} >>${logFile}/refresh${myDate}.log
#                managePostgres stop ${Pgmasterserv} >>${logFile}/refresh${myDate}.log
#                managePostgres status ${Pgmasterserv} >>${logFile}/refresh${myDate}.log
#                echo "Master Postgres has been shutdown, work processes: ${result}" >>${logFile}/refresh${myDate}.log
#                ;;
#                recover)
#                recoverBarman  >>${logFile}/refresh${myDate}.log
#                ;;
#                startpgm)
#                configPostgres restore ${Pgmasterserv}  >>${logFile}/refresh${myDate}.log
#                managePostgres start ${Pgmasterserv}  >>${logFile}/refresh${myDate}.log
#                managePostgres status ${Pgmasterserv}  >>${logFile}/refresh${myDate}.log
#                sleep 3
#                echo "Master Postgres has been shutdown, work processes: ${result}" >>${logFile}/refresh${myDate}.log
#                ;;
#                startrsync)
#                configPostgres startrsync ${Pgmasterserv} >>${logFile}/refresh${myDate}.log
#                managePostgres start ${Pgslaveserv}  >>${logFile}/refresh${myDate}.log
#                managePostgres status ${Pgslaveserv}  >>${logFile}/refresh${myDate}.log
#                sleep 3
#                echo "Slave Postgres has been shutdown, work processes: ${result}" >>${logFile}/refresh${myDate}.log
#                ;;
#                *)
#                echo "actions should be [stoptom|starttom|stoppgs|stoppgm|recover|startpgmaster|startrsync|]"
#                ;;
#        esac
#fi


#automotive recovery whole database from production enviroment to laboratory(in automotive way)
echo "=======================================${myDate} recovery step begin=======================================" >${logFile}/refresh${myDate}.log
if [ ${current_user} = ${Bmuser} ]
then
    manageTomcat status ${Tomserv} >>${logFile}/refresh${myDate}.log
elif [ ${totalproc} == ${startproc} ]
then
        manageTomcat stop ${Tomserv} ALL >>${logFile}/refresh${myDate}.log
        manageTomcat status ${Tomserv} >>${logFile}/refresh${myDate}.log
        echo "Tomcat has been shutdown, work processes: ${startproc}" >>${logFile}/refresh${myDate}.log
elif [ ${startproc} = '0' ]
then
        managePostgres stop ${Pgslaveserv} >>${logFile}/refresh${myDate}.log
        managePostgres status ${Pgslaveserv} >>${logFile}/refresh${myDate}.log
        echo "Slave Postgres has been shutdown, work processes: ${result}" >>${logFile}/refresh${myDate}.log
elif [ ${result} = '0' ]
then
        configPostgres backup ${Pgmasterserv} >>${logFile}/refresh${myDate}.log
        managePostgres stop ${Pgmasterserv} >>${logFile}/refresh${myDate}.log
        managePostgres status ${Pgmasterserv} >>${logFile}/refresh${myDate}.log
        echo "Master Postgres has been shutdown, work processes: ${result}" >>${logFile}/refresh${myDate}.log
elif [ ${result} = '0' ]
then
        recoverBarman >>${logFile}/refresh${myDate}.log
elif [ $? = '0' ]
then
        configPostgres restore ${Pgmasterserv} >>${logFile}/refresh${myDate}.log
        managePostgres start ${Pgmasterserv} >>${logFile}/refresh${myDate}.log
        managePostgres status ${Pgmasterserv} >>${logFile}/refresh${myDate}.log
        sleep 3
        echo "Master Postgres has been shutdown, work processes: ${result}" >>${logFile}/refresh${myDate}.log
elif [ ${result} = '1' ]
then
        configPostgres startrsync ${Pgmasterserv} >>${logFile}/refresh${myDate}.log
        managePostgres start ${Pgslaveserv} >>${logFile}/refresh${myDate}.log
        managePostgres status ${Pgslaveserv} >>${logFile}/refresh${myDate}.log
        sleep 3
        echo "Slave Postgres has been shutdown, work processes: ${result}" >>${logFile}/refresh${myDate}.log
elif [ ${result} = '1' ]
then
    repl_status=`ssh ${Pguser}@${Pgslaveserv} "grep ${myDate} ${Pgpath}/pg_log/postgresql-${myweekday}.log | grep -c 'streaming replication successfully'"`
elif [ ${repl_status} = '1' ]
then
    echo "Replication status works fine,check ${Pgpath}/pg_log/postgresql-${myweekday}.log see more detail" >>${logFile}/refresh${myDate}.log
        echo "=======================================${myDate} recovery step end=======================================" >>${logFile}/refresh${myDate}.log
else
        break;
fi
#ssh -oStrictHostKeyChecking=no postgres@${_SRV} "/var/lib/pgsql/refresh/ "
#_RET=$?