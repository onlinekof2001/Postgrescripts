Citus 集群

1. 读写分离，主备切换？
2. 分片出现故障时，分散在各节点的副本是否可用？

/* 添加工作节点 */
SELECT * from master_add_node('xxx.xxx.xxx.224', 1921);

/* 在Coordinator节点上查看worker节点 */
select master_get_active_worker_nodes();

/* 查看分片的数量 默认32 */
show citus.shard_count;

/* 创建分片表sharding */
http://docs.citusdata.com/en/stable/develop/api_udf.html#user-defined-functions
https://docs.citusdata.com/en/v6.0/reference/user_defined_functions.html?highlight=create_distributed_table#create-distributed-table
https://github.com/citusdata/citus/blob/master/src/backend/distributed/commands/create_distributed_table.c
select create_distributed_table('f_online_order','paytime');

可对已知表进行分片
SELECT truncate_local_data_after_distributing_table($$public.f_online_order$$);

/* 为表添加副本数 */
SELECT master_create_worker_shards('f_online_order', 2, 2);