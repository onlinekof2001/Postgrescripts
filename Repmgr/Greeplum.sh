# 预先准备
yum install -y apr apr-util bash bzip2 curl krb5 krb5-devel libcurl libevent libxml2 libyaml zlib openldap openssh openssl openssl-libs perl readline rsync R sed tar zip

# 安装jdk
cat << 'EOF' > /etc/yum.repos.d/adoptopenjdk.repo
[AdoptOpenJDK]
name=AdoptOpenJDK
baseurl=http://adoptopenjdk.jfrog.io/adoptopenjdk/rpm/centos/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public
EOF

yum install adoptopenjdk-8-openj9 -y


# 配置系统参数
http://docs.greenplum.org/6-8/install_guide/prep_os.html#topic3
# kernel.shmall = _PHYS_PAGES / 2 # See Shared Memory Pages
kernel.shmall = 335711
# kernel.shmmax = kernel.shmall * PAGE_SIZE
kernel.shmmax = 1375074986
kernel.shmmni = 4096
vm.overcommit_memory = 2 # See Segment Host Memory
vm.overcommit_ratio = 95 # See Segment Host Memory
net.ipv4.ip_local_port_range = 10000 65535 # See Port Settings
kernel.sem = 500 2048000 200 4096
kernel.sysrq = 1
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.msgmni = 2048
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.conf.all.arp_filter = 1
net.core.netdev_max_backlog = 10000
net.core.rmem_max = 2097152
net.core.wmem_max = 2097152
vm.swappiness = 10
vm.zone_reclaim_mode = 0
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.dirty_background_ratio = 0 # See System Memory
vm.dirty_ratio = 0
vm.dirty_background_bytes = 1375074986
vm.dirty_bytes = 1375074986

echo never > /sys/kernel/mm/*transparent_hugepage/enabled

groupadd gpadmin
useradd gpadmin -r -m -g gpadmin
echo gpadmin | passwd gpadmin --stdin

# 下载gp并安装
https://github.com/greenplum-db/gpdb/releases

rpm -Uvh /tmp/greenplum-db-6.12.0-rhel7-x86_64.rpm

# 配置环境变量
source /usr/local/greenplum-db-6.12.0/greenplum_path.sh

# 创建一个列表文件，把主机名配置在该文件中
cat << EOF > /home/gpadmin/hostfile_exkeys
pg-pgpool2-01 172.16.0.4
pg-pgpool2-02 172.16.0.5
pg-pgpool2-03 172.16.0.6
EOF

# 创建master节点的目录
mkdir -p /u01/app/postgres/gp/master
chown gpadmin:gpadmin /u01/app/postgres/gp/master

# 通过gpssh命令创建目录
gpssh -f hostfile_exkeys -e 'mkdir -p /u01/app/postgres/gp/master'
gpssh -f hostfile_exkeys -e 'chown gpadmin:gpadmin /u01/app/postgres/gp/master'

gpssh -f hostfile_exkeys -e 'mkdir -p /u01/app/postgres/gp/primary'
gpssh -f hostfile_exkeys -e 'mkdir -p /u01/app/postgres/gp/mirror'
gpssh -f hostfile_exkeys -e 'chown gpadmin:gpadmin /u01/app/postgres/gp/mirror'

验证IO
gpcheckperf -f hostfile_exkeys -r ds -D   -d  /u01/app/postgres/gp/primary   -d  /u01/app/postgres/gp/mirror


配置文件




