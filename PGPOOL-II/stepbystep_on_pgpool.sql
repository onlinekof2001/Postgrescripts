step:
yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum install -y lvm2 postgresql10-server mlocate vim postgresql10-devel gcc openssl-devel clang-devel policycoreutils-python
updatedb
locate pg_ctl | grep bin

fdisk -l /dev/xvdb

pvcreate /dev/xvdb1
vgcreate vgdata /dev/xvdb1
lvcreate -n lvdata -L +40G vgdata
lvcreate -n lvxlog -L +30G /dev/vgdata
lvcreate -n lvrecover -l 5119 /dev/vgdata

mkfs.ext4 /dev/mapper/vgdata-lvdata
mkfs.ext4 /dev/mapper/vgdata-lvxlog
mkfs.ext4 /dev/mapper/vgdata-lvrecover

blkid /dev/mapper/vgdata-lvdata
blkid /dev/mapper/vgdata-lvxlog
blkid /dev/mapper/vgdata-lvrecover

mkdir -p /u01/app/postgres
mkdir -p /u01/app/postgres/pg_xlog
mkdir -p /u01/app/postgres/recovery

vim /etc/fstab
UUID=2ba4a201-8ee2-4be8-96fe-87f54d0f7e9f /u01/app/postgres ext4 defaults 0 0
UUID=5e11f3ee-8a83-417a-bf06-4fadadcfd1ce /u01/app/postgres/pg_xlog ext4 defaults 0 0
UUID=7a775b12-0544-4e5c-8155-5c2a2626c8bd /u01/app/postgres/recovery ext4 defaults 0 0

updatedb
locate pg_ctl | grep bin

vim /etc/pgtab
#PGINSTANCE PGDATA PGPROT

mkdir -p $PGDATA

chown postgres. -R /u01


vim /var/lib/pgsql/.bash_profile

[ -f /etc/bashrc ] && . /etc/bashrc

if [ -f /etc/pgtab ]
then
	PGDATA=$(awk -F':' '{print $2}' /etc/pgtab)
	PGPORT=$(awk -F':' '{print $3}' /etc/pgtab)
	PATH=/usr/pgsql-10/bin/:${PATH}
	export PGDATA
	export PGPORT
	export PATH
fi

cd $PGDATA

alias pg_reload="pg_ctl reload && tail -n10 $postgres_log_file"
alias pg_ctl="echo Please use systemctl instead of pg_ctl"

alias psqlpp="$HOME/bin/psqlpp"
alias oxycreatedb="$HOME/oxycreatedb.sh"
alias pg_view="pg_view -c /etc/pg_service.conf"

alias cdsup="cd /usr/local/sbin/supervision"
alias cdsuplog="cd /var/log/supervision"
alias sup="/usr/local/sbin/supervision/supervision_postgres.sh all"
alias suplog="grep -v ' OK$' /var/log/supervision/supervision_degradee.log"
alias pgmetrics="/usr/local/sbin/postgres_tools/pgmetrics/pgmetrics -h localhost --no-password"
alias cdtools="cd /usr/local/sbin/postgres_tools"

/usr/pgsql-10/bin/pg_ctl -D $PGDATA initdb

vim $PGDATA/

listen_addresses = '*' 
port = 60901
max_connections = 300
superuser_reserved_connections = 5
shared_buffers = 128MB
work_mem = 4MB
maintenance_work_mem = 64MB
effective_io_concurrency = 200
max_worker_processes = 4
max_parallel_workers_per_gather = 2
max_parallel_workers = 4
max_wal_size = 1GB
min_wal_size = 80MB
checkpoint_completion_target = 0.9
archive_mode = on
archive_command = 'test ! -f /u01/app/postgres/data/pgpool-ii/archive/%f && rsync %p /u01/app/postgres/data/pgpool-ii/archive/%f'
archive_timeout = 1800
max_wal_senders = 10
wal_keep_segments = 16
max_replication_slots = 10
random_page_cost = 1.1


vim pg_hba.conf
host    replication     all             172.31.23.16/32                 trust

/usr/pgsql-10/bin/pg_ctl -D $PGDATA status/start

psql -h172.31.21.253 -U streaming_barman -c"IDENTIFY_SYSTEM" replication=1

pg_basebackup -h 172.31.21.253 -U replicator -p 60901 -D $PGDATA -P -Xs -R
or
/usr/bin/rsync -C -a -v --delete -e ssh --exclude postgresql.conf --exclude postmaster.pid --exclude pg_hba.conf --exclude pg_ident --exclude postmaster.opts --exclude pg_log --exclude recovery.conf /u01/app/postgres/data/$instance/* <remote_hostname>:/u01/app/postgres/data/$instance/

Replication database
vim recovery.conf
standby_mode = 'on'
recovery_target_timeline='latest'
primary_conninfo = 'host=172.31.23.16 port=60901 user=replicator password=replicator'
restore_command = 'rsync /u01/app/postgres/data/pgpool-ii/archive/%f %p'
archive_cleanup_command = 'pg_archivecleanup /u01/app/postgres/data/pgpool-ii/archive %r'

/*PGPOOL part*/

http://www.pgpool.net/mediawiki/index.php/Main_Page
/*Download */
http://pgpool.net/mediawiki/index.php/Downloads

export https_proxy='proxy-internet-azure-cn.pp.dktapp.cloud:3128'
curl -o pgpool-II-4.0.5.tar.gz http://www.pgpool.net/mediawiki/images/pgpool-II-4.0.5.tar.gz
tar zxvf pgpool-II-4.0.5.tar.gz -C /opt

cd /opt/pgpool-II

/*Install all both master & slaves*/
./configure --prefix=/opt/pgpool-II/
./configure --prefix=/opt/pgpool-II/ --with-pgsql=/usr/pgsql-10/bin/ --with-pgsql-includedir=/usr/pgsql-10/include --with-pgsql-libdir=/usr/pgsql-10/lib --with-openssl

make && make install


PG11
curl -o llvm-toolset-7-llvm-libs-5.0.1-8.el7.x86_64.rpm http://mirror.centos.org/centos/7/sclo/x86_64/rh/llvm-toolset-7/llvm-toolset-7-llvm-libs-5.0.1-8.el7.x86_64.rpm
curl -o llvm-toolset-7-runtime-5.0.1-4.el7.x86_64.rpm http://mirror.centos.org/centos/7/sclo/x86_64/rh/llvm-toolset-7/llvm-toolset-7-runtime-5.0.1-4.el7.x86_64.rpm
curl -o llvm-toolset-7-llvm-5.0.1-8.el7.x86_64.rpm http://mirror.centos.org/centos/7/sclo/x86_64/rh/llvm-toolset-7/llvm-toolset-7-llvm-5.0.1-8.el7.x86_64.rpm
curl -o llvm-toolset-7-clang-5.0.1-4.el7.x86_64.rpm http://mirror.centos.org/centos/7/sclo/x86_64/rh/llvm-toolset-7/llvm-toolset-7-clang-5.0.1-4.el7.x86_64.rpm
curl -o llvm-toolset-7-clang-libs-5.0.1-4.el7.x86_64.rpm http://mirror.centos.org/centos/7/sclo/x86_64/rh/llvm-toolset-7/llvm-toolset-7-clang-libs-5.0.1-4.el7.x86_64.rpm
curl -o devtoolset-7-gcc-c++-7.3.1-5.15.el7.x86_64.rpm http://mirror.centos.org/centos/7/sclo/x86_64/rh/devtoolset-7/devtoolset-7-gcc-c++-7.3.1-5.15.el7.x86_64.rpm
curl -o devtoolset-7-libstdc++-devel-7.3.1-5.15.el7.x86_64.rpm http://mirror.centos.org/centos/7/sclo/x86_64/rh/devtoolset-7/devtoolset-7-libstdc++-devel-7.3.1-5.15.el7.x86_64.rpm
curl -o llvm-toolset-7-compiler-rt-5.0.1-2.el7.x86_64.rpm http://mirror.centos.org/centos/7/sclo/x86_64/rh/llvm-toolset-7/llvm-toolset-7-compiler-rt-5.0.1-2.el7.x86_64.rpm
curl -o llvm-toolset-7-libomp-5.0.1-2.el7.x86_64.rpm http://mirror.centos.org/centos/7/sclo/x86_64/rh/llvm-toolset-7/llvm-toolset-7-libomp-5.0.1-2.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/sclo/x86_64/rh/devtoolset-7/devtoolset-7-gcc-7.3.1-5.15.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/sclo/x86_64/rh/devtoolset-7/devtoolset-7-runtime-7.1-4.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/sclo/x86_64/rh/devtoolset-7/devtoolset-7-binutils-2.28-11.el7.x86_64.rpm
wget https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/l/llvm5.0-libs-5.0.1-7.el7.x86_64.rpm
wget https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/l/llvm5.0-5.0.1-7.el7.x86_64.rpm

rpm -Uvh llvm-toolset-7-libomp-5.0.1-2.el7.x86_64.rpm devtoolset-7-gcc-7.3.1-5.15.el7.x86_64.rpm devtoolset-7-runtime-7.1-4.el7.x86_64.rpm devtoolset-7-binutils-2.28-11.el7.x86_64.rpm llvm5.0-5.0.1-7.el7.x86_64.rpm llvm5.0-libs-5.0.1-7.el7.x86_64.rpm llvm-toolset-7-clang-libs-5.0.1-4.el7.x86_64.rpm llvm-toolset-7-clang-5.0.1-4.el7.x86_64.rpm devtoolset-7-gcc-c++-7.3.1-5.15.el7.x86_64.rpm  devtoolset-7-libstdc++-devel-7.3.1-5.15.el7.x86_64.rpm llvm-toolset-7-compiler-rt-5.0.1-2.el7.x86_64.rpm 

/opt/pgpool-II-4.0.5/src/sql/pgpool-recovery
make && make install

psql -f pgpool-recovery.sql template1

cd /opt/pgpool-II-4.0.5/src/sql/pgpool-regclass/

postgres=# create extension pgpool_recovery;

cd 


/*configuration pgpool*/
cd /opt/pgpool-II/etc

cp pgpool.conf.sample pgpool.conf
listen_addresses = '*'
port = 60999
socket_dir = '/tmp'
pcp_listen_addresses = '*'
pcp_port = 60898
pcp_socket_dir = '/tmp'
# master node
backend_hostname0 = '<maste_hostname>'
backend_port0 = 60901
backend_weight0 = 1
backend_data_directory0 = '/u01/app/postgres/data/pgpool-ii'
backend_flag0 = 'ALLOW_TO_FAILOVER'
# slave node
backend_hostname0 = '<slave_hostname>'
backend_port0 = 60901
backend_weight0 = 1
backend_data_directory0 = '/u01/app/postgres/data/pgpool-ii'
backend_flag0 = 'ALLOW_TO_FAILOVER'
enable_pool_hba = on
pool_passwd = 'pool_passwd'
#log configuration
log_connections = on
log_hostname = on
log_statement = on
log_per_node_statement = on
logdir = '/opt/pgpool-II/log/pgpool'
load_balance_mode = on
master_slave_mode = on
sr_check_period = 10
sr_check_user = 'pgviewer'
sr_check_password = 'pgviewer'
sr_check_database = 'postgres'
health_check_period = 10
health_check_user = 'replicator'
health_check_password = ''
health_check_database = 'postgres'
failover_command = '/opt/pgpool-II/scripts/failover.sh %h'
recovery_user = 'pgreviewer'
recovery_password = 'pgreviewer'
recovery_1st_stage_command =
recovery_2st_stage_command =
# watchdog configuration
use_watchdog = on
wd_hostname = '<maste_hostname>'
wd_port = 60897
wd_authkey = ''
wd_lifecheck_method = 'heartbeat'
wd_interval = 10
wd_heartbeat_port = 60694
wd_heartbeat_keepalive = 2
heartbeat_destination0 = '172.31.21.112'
heartbeat_destination_port0 = 60694
heartbeat_device0 = 'eth0'
wd_life_point = 2
wd_lifecheck_query = 'SELECT 1'
wd_lifecheck_dbname = 'template1'
wd_lifecheck_user = 'pgreviewer'
wd_lifecheck_password = 'pgreviewer'
other_pgpool_hostname0 = '172.31.21.112'
other_pgpool_port0 = 60999
other_wd_port0 = 60897


cp pcp.conf.sample pcp.conf
# /opt/pgpool-II/bin/pg_md5 pgviewer
776ba39d6b70119119e57f769161e5a9
/opt/pgpool-II/bin/pg_md5 -p -m -u postgres pool_passwd
Decathlon2018

cp pool_hba.conf.sample pool_hba.conf
host    all         all         127.0.0.1/32          md5
host    all         all         ::1/128               md5
host    all         all         172.31.21.0/24        md5

create user pgviewer with login password 'pgviewer' nocreatedb nosuperuser nocreaterole noreplication;

vim failover.sh

#!/bin/bash -x 
falling_node=$1 # %d
old_primary=172.31.21.253 # %P
new_primary=172.31.21.112 # %H 
pgdata=/u01/app/postgres/data/pgpool-ii # %R 
pghome='/usr/pgsql-10'
log='/opt/pgpool-II/log/failover.log'
date >> $log
echo "failed_node_id=$falling_node new_primary=$new_primary" >> $log 
if [ $falling_node = $old_primary ]; 
 then
   if [ $UID -eq 0 ] 
   then 
       su postgres -c "ssh -T postgres@$new_primary $pghome/bin/pg_ctl promote -D $pgdata"
   else 
       ssh -T postgres@$new_primary $pghome/bin/pg_ctl promote -D $pgdata
   fi 
   exit 0;
fi 
exit 0;

chmod 755 failover.sh 

