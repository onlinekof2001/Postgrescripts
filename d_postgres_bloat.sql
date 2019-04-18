-- 表膨胀率
select schemaname||'.'||relname,
	   n_dead_tup,
	   n_live_tup,
	   coalesce(round(n_dead_tup * 100 / (case when n_live_tup + n_dead_tup = 0 then null else n_live_tup + n_dead_tup end ),2),0.00) as dead_tup_ratio
  from pg_stat_all_tables
 where 1=1
   and n_dead_tup >= 10000
 order by dead_tup_ratio desc
 limit 10
; 

-- 索引膨胀率
select schemaname||'.'||indexrelname,
n_dead_tup
pg_stat_all_indexes