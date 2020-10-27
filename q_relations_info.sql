/* Get the all relation details information */

/* General Table Size Information, total/table/toast/indexes size of the table. */

SELECT
  relname AS table_name,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_bytes,
  pg_size_pretty(pg_relation_size(relid)) AS table_bytes,
  pg_size_pretty(pg_table_size(relid) - pg_relation_size(relid)) AS toast_bytes,
  pg_size_pretty(pg_indexes_size(relid)) AS indexes_bytes
FROM pg_catalog.pg_statio_user_tables
WHERE (schemaname=any(array['public'::text,'pg_catalog'::text,'information_schema'::text])) is false
ORDER BY pg_total_relation_size(relid) DESC;

/* General Table hit ratio, table hit ratio indicate how many page can be cache to the mem while the pages read */

SELECT psot.schemaname as schema_name,
  psot.relname AS table_name,
  round(idx_scan::numeric/(seq_scan + idx_scan)::numeric,2) * 100 idx_scan_ratio,
  round(heap_blks_hit::numeric/(heap_blks_read + heap_blks_hit)::numeric,2) * 100 tbl_hit_ratio,
  last_autoanalyze
FROM pg_statio_user_tables psot, pg_stat_user_tables pst
WHERE psot.relid=pst.relid 
AND (heap_blks_read + heap_blks_hit) > 0 
AND (seq_scan + idx_scan) > 0
ORDER BY 3,4,5 limit 10;

/* General freeze age ratio, auto va*/
SELECT c.oid::regclass,
  100 * round(age(c.relfrozenxid)::numeric/(select setting::int from pg_settings where name='vacuum_freeze_table_age')::numeric,2) freeze_age_ratio,
  pg_total_relation_size(c.oid) 
FROM pg_class c
JOIN pg_namespace n on c.relnamespace = n.oid
WHERE relkind IN ('r') 
AND n.nspname !~ '^pg_' 
AND n.nspname <> 'information_schema' 
AND n.nspname != 'public'
AND round(age(c.relfrozenxid)::numeric/(select setting::int from pg_settings where name='vacuum_freeze_table_age')::numeric,2) > 0.8
ORDER BY 2,3 DESC 
LIMIT 100;

-- Autovacuum VACUUM thresold for tables
SELECT schemaname schema_name,
  relname table_name, 
  round(n_dead_tup::numeric / (n_dead_tup + n_live_tup * (select setting from pg_settings where name in ('autovacuum_vacuum_scale_factor'))::numeric + (select setting from pg_settings where name in ('autovacuum_vacuum_threshold'))::numeric),2) vac_threshold,
  last_autovacuum 
FROM pg_stat_user_tables 
ORDER BY 3 DESC
LIMIT 10;

