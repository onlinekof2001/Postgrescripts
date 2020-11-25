repmgr

主库注册
repmgr -f /etc/repmgr/11/repmgr.conf primary register

检查主库节点的状态
repmgr -f /etc/repmgr/11/repmgr.conf node status

检查集群状态
repmgr -f /etc/repmgr/11/repmgr.conf cluster show --all

单独跑测试
repmgr -h <master_ip_address> -U repmgr -d repmgr -f /etc/repmgr/11/repmgr.conf standby clone --dry-run

克隆主库
repmgr -h <master_ip_address> -U repmgr -d repmgr -f /etc/repmgr/11/repmgr.conf standby clone --upstream-node-id=1 --fast-checkpoint -F

upstream-node-id 指定复制的节点


Error:
hell-init: error retrieving current directory: getcwd: cannot access parent directories: No such file or directory
could not identify current directory: No such file or directory
Don't worry about it

检查recovery.conf的状态

systemctl start postgresql@<instance>.service

$ repmgr -f /etc/repmgr/11/repmgr.conf cluster show --compact
 ID | Name          | Role    | Status               | Upstream | Location | Prio. | TLI
----+---------------+---------+----------------------+----------+----------+-------+-----
 1  | pg-pgpool2-01 | primary | * running            |          | default  | 100   | 3   
 2  | pg-pgpool2-02 | primary | ! running as standby |          | default  | 100   | 3   

WARNING: following issues were detected
  - node "pg-pgpool2-02" (ID: 2) is registered as an inactive primary but running as standby

强制注册standby (指定上游复制节点) 
repmgr -f /etc/repmgr/11/repmgr.conf standby register --upstream-node-id=2 -F

先注册，后启动Repmgrd 服务提供自动切换的功能
systemctl start repmgr11.service

自动失效切换
配置promote_command 检查主节点若干次后，自动提升备节点。 坏的节点被踢出集群后，需手动干预后恢复备节点。 
MS模式, 手工剔除主节点，备节点自动提升。

二节点以上的决策问题，
开启wal_log_hints/full_page_write
采用递归流复制的方式, 主节点上异常中断， 用pg_rewind恢复
1. 递归的问题，中间从节点出现故障，下游节点与主节点之间直接断开, 需要逐级修复，无法

一主对多从时的故障节点需要手工恢复并重连
Repmgr选举候选备节点会以以下顺序选举：LSN ， Priority， Node_ID。
[2020-11-19 03:48:16] [INFO] 1 active sibling nodes registered
[2020-11-19 03:48:16] [INFO] 3 total nodes registered
[2020-11-19 03:48:16] [INFO] primary node  "pg-pgpool2-03" (ID: 3) and this node have the same location ("default")
[2020-11-19 03:48:16] [INFO] local node's last receive lsn: B/98
[2020-11-19 03:48:16] [INFO] checking state of sibling node "pg-pgpool2-01" (ID: 1)
[2020-11-19 03:48:16] [INFO] node "pg-pgpool2-01" (ID: 1) reports its upstream is node 3, last seen 7 second(s) ago
[2020-11-19 03:48:16] [INFO] standby node "pg-pgpool2-01" (ID: 1) last saw primary node 7 second(s) ago
[2020-11-19 03:48:16] [INFO] last receive LSN for sibling node "pg-pgpool2-01" (ID: 1) is: B/98
[2020-11-19 03:48:16] [INFO] node "pg-pgpool2-01" (ID: 1) has same LSN as current candidate "pg-pgpool2-02" (ID: 2)
[2020-11-19 03:48:16] [INFO] node "pg-pgpool2-01" (ID: 1) has same priority but lower node_id than current candidate "pg-pgpool2-02" (ID: 2)
[2020-11-19 03:48:16] [INFO] visible nodes: 2; total nodes: 2; no nodes have seen the primary within the last 4 seconds
[2020-11-19 03:48:16] [NOTICE] promotion candidate is "pg-pgpool2-01" (ID: 1)
[2020-11-19 03:48:16] [INFO] follower node awaiting notification from a candidate node
[2020-11-19 03:48:17] [NOTICE] attempting to follow new primary "pg-pgpool2-01" (node ID: 1)
[2020-11-19 03:48:17] [NOTICE] redirecting logging output to "/var/log/repmgr/repmgr.log"

[2020-11-19 03:48:17] [INFO] local node 2 can attach to follow target node 1
[2020-11-19 03:48:17] [DETAIL] local node's recovery point: B/98; follow target node's fork point: B/98
[2020-11-19 03:48:17] [INFO] creating replication slot as user "repmgr"
[2020-11-19 03:48:18] [NOTICE] setting node 2's upstream to node 1
[2020-11-19 03:48:18] [NOTICE] stopping server using "/usr/pgsql-11/bin/pg_ctl  -D '/u01/app/postgres/data/pgpool2-master' -w -m fast stop"
[2020-11-19 03:48:26] [NOTICE] starting server using "/usr/pgsql-11/bin/pg_ctl  -w -D '/u01/app/postgres/data/pgpool2-master' start"
[2020-11-19 03:48:26] [WARNING] unable to connect to old upstream node 3 to remove replication slot
[2020-11-19 03:48:26] [HINT] if reusing this node, you should manually remove any inactive replication slots
[2020-11-19 03:48:26] [NOTICE] STANDBY FOLLOW successful
[2020-11-19 03:48:26] [DETAIL] standby attached to upstream node "pg-pgpool2-01" (ID: 1)
INFO:  set_repmgrd_pid(): provided pidfile is /run/repmgr/repmgrd-11.pid
[2020-11-19 03:48:26] [NOTICE] node "pg-pgpool2-02" (ID: 2) now following new upstream node "pg-pgpool2-01" (ID: 1)
[2020-11-19 03:48:26] [INFO] resuming standby monitoring mode
[2020-11-19 03:48:26] [DETAIL] following new primary "pg-pgpool2-01" (ID: 1)


pgpool的LB和FAILOVER的问题

模拟一下故障的情况，数据库崩溃
如何重建备库
前端VIP的问题
