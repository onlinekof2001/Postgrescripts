Citus 集群

1. 读写分离，主备切换？
2. 分片出现故障时，分散在各节点的副本是否可用？

/* 添加工作节点 */
SELECT * from master_add_node('xxx.xxx.xxx.224', 1921);

/* 创建分片表sharding */
select create_distributed_table('f_online_order','paytime');

/* 查看分片的数量 默认32 */
show citus.shard_count;