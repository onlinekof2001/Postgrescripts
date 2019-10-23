/* Statistics Collection Configuration */

/* 信息收集控制参数 

-- track_activities  开启收集进程当前执行的命令
-- track_counts      开启收集表和索引的状况
-- track_functions   开启收集用户定义的函数的使用状况
-- track_io_timing   开始收集块读写的时间

-- 统计信息被收集于临时文件中，这个文件被存于目录中，目录定义基于stats_temp_directory参数

show stats_temp_directory;

/u01/app/postgres/data/tech_iso/pg_stat_tmp
[postgres@rtidz1pgs21 pg_stat_tmp]$ tree 
.
|-- db_0.stat
|-- db_13294.stat
|-- db_16387.stat
|-- db_16394.stat
|-- db_2188360.stat
`-- global.stat

*/

-- pg_stat_activity 当前活动进程的相关信息,每一条代表一个活动的进程
postgres@postgres(tech_iso)=# select * from pg_stat_activity limit 1;
-[ RECORD 1 ]----+------------------------------
datid            | 16394
datname          | console7
pid              | 12857
usesysid         | 16391
usename          | console7
application_name | rtidz1tom21_BATCHADMIN_ISO
client_addr      | 10.150.29.44
client_hostname  | rtidz1tom21.hosting.eu
client_port      | 60592
backend_start    | 2019-06-04 05:40:18.899699+00
xact_start       | 
query_start      | 2019-06-06 08:08:33.857321+00
state_change     | 2019-06-06 08:08:33.857398+00
waiting          | f
state            | idle
backend_xid      | 
backend_xmin     | 
query            | SELECT 1

