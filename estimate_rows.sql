/*
查询行, 替代count(*)
http://www.varlena.com/GeneralBits/120.php
https://www.postgresql.org/docs/9.2/row-estimation-examples.html
中解释到reltuples的更新来自于最近一次的VACUUM or ANALYZE.
*/

\set schema '''snop_db'''
\echo schema

SELECT relname, reltuples, relpages
  FROM pg_class r
  JOIN pg_namespace n
    ON (relnamespace = n.oid)
 WHERE relkind = 'r'
   AND n.nspname = :schema;


/*
拓展通过trigger计数, 创建一张用于记录行数的记录表, 并创建触发器
*/
CREATE TABLE row_counts (
   relname text PRIMARY KEY,
   reltuples numeric);


CREATE OR REPLACE FUNCTION count_trig()
  RETURNS TRIGGER AS
  $$
     DECLARE
     BEGIN
     IF TG_OP = 'INSERT' THEN
        EXECUTE 'UPDATE row_counts set reltuples=reltuples +1 where relname = ''' || TG_RELNAME || '''';
        RETURN NEW;
     ELSIF TG_OP = 'DELETE' THEN
        EXECUTE 'UPDATE row_counts set reltuples=reltuples -1 where relname = ''' || TG_RELNAME || '''';
        RETURN OLD;
     END IF;
     END;
  $$
  LANGUAGE 'plpgsql';   
   
CREATE OR REPLACE FUNCTION add_count_trigs()
RETURNS void AS
$$
   DECLARE
      rec   RECORD;
      q     text;
   BEGIN
      FOR rec IN SELECT relname
               FROM pg_class r JOIN pg_namespace n ON (relnamespace = n.oid)
               WHERE relkind = 'r' AND n.nspname = 'public' LOOP
         q := 'CREATE TRIGGER ' || rec.relname || '_count BEFORE INSERT OR DELETE ON ' ;
         q := q || rec.relname || ' FOR EACH ROW EXECUTE PROCEDURE count_trig()';
         EXECUTE q;
      END LOOP;
   RETURN;
   END;
$$
LANGUAGE 'plpgsql';   

-- 初始化行记录表
insert into row_counts select relname, reltuples from pg_class;

-- 如果没有vacuum或者analyze,不能保证pg_class中记录的行数是否正确, 也可以通过count()的方式初始化记录表.
CREATE OR REPLACE FUNCTION init_row_counts()
  RETURNS void AS
  $$
     DECLARE
        rec   RECORD;
        crec  RECORD;
     BEGIN
        FOR rec IN SELECT relname
                 FROM pg_class r JOIN pg_namespace n ON (relnamespace = n.oid)
                 WHERE relkind = 'r' AND n.nspname = 'public' LOOP
           FOR crec IN EXECUTE 'SELECT count(*) as rows from '|| rec.relname LOOP
              -- nothing here, move along
           END LOOP;
           INSERT INTO row_counts values (rec.relname, crec.rows) ;
        END LOOP;
  
     RETURN;
     END;
  $$
  LANGUAGE 'plpgsql';
  
/*
looks up the selectivity function for the operator < in pg_operator
统计信息直方图通常将表的行分配到bucket中, 通过histogram_bounds可以看到直方图的边界.
*/
\set tabname '''parameter_mp'''
\set uniqcol '''parameter_mp_id'''
\echo schema

SELECT histogram_bounds FROM pg_stats
WHERE tablename = :tabname AND attname = :uniqcol;
101 
-[ RECORD 1 ]----+----------------------------------------------------------------------------------------------------------
histogram_bounds | {1,15,29,44,58,73,87,102,116,131,145,160,174,189,203,218,232,246,261,275,290,304,319,333,348,362,377,391,406,420,435,449,464,478,492,507,521,536,550,565,579,594,608,623,637,652,666,681,695,710,724,738,753,767,782,796,811,825,840,854,869,883,898,912,927,941,956,970,984,999,1013,1028,1042,1057,1071,1086,1100,1115,1129,1144,1158,1173,1187,1202,1216,1230,1245,1259,1274,1288,1303,1317,1332,1346,1361,1375,1390,1404,1419,1433,1448}


/*
如果有where parameter_mp_id < 1000 的比较操作时, 根据直方图的边界可以看到bucket第71个介于这个范围999,1013

选择性的计算公式:
selectivity = (1 + (1000 - bucket[71].min)/(bucket[71].max - bucket[71].min))/num_buckets
            = (1 + (1000 - 999)/(1013 - 999))/101
			= 0.01061
			
rows = rel_cardinality * selectivity
     = 1448 * 0.01061
     = 15
	 
这里和实际测试效果不符合!!!


cost计算公式:
The estimated cost is computed as (disk pages read * seq_page_cost) + (rows scanned * cpu_tuple_cost). By default, seq_page_cost is 1.0 and cpu_tuple_cost is 0.01, so the estimated cost is (358 * 1.0) + (10000 * 0.01) = 458
seq_page_cost从磁盘取页的成本

*/


/*
模拟bucket, drb 是 team_stats表的字段
https://tapoueh.org/blog/2014/02/postgresql-aggregates-and-histograms/
*/
with drb_stats as
 (select min(drb) as min, max(drb) as max from team_stats),
histogram as
 (select width_bucket(drb, min, max, 9) as bucket,
         int4range(min(drb), max(drb), '[]') as range,
         count(*) as freq
    from team_stats, drb_stats
   group by bucket
   order by bucket)
select bucket,
       range,
       freq,
       repeat('■', (freq ::float / max(freq) over() * 30) ::int) as bar
  from histogram;

-- 模拟直方图的function https://blog.faraday.io/how-to-do-histograms-in-postgresql/
CREATE OR REPLACE FUNCTION histogram(table_name_or_subquery text, column_name text)
RETURNS TABLE(bucket int, "range" numrange, freq bigint, bar text)
AS $func$
BEGIN
RETURN QUERY EXECUTE format('
  WITH
  source AS (
    SELECT * FROM %s
  ),
  min_max AS (
    SELECT min(%s) AS min, max(%s) AS max FROM source
  ),
  histogram AS (
    SELECT
      width_bucket(%s, min_max.min, min_max.max, 20) AS bucket,
      numrange(min(%s)::numeric, max(%s)::numeric, ''[]'') AS "range",
      count(%s) AS freq
    FROM source, min_max
    WHERE %s IS NOT NULL
    GROUP BY bucket
    ORDER BY bucket
  )
  SELECT
    bucket,
    "range",
    freq::bigint,
    repeat(''*'', (freq::float / (max(freq) over() + 1) * 15)::int) AS bar
  FROM histogram',
  table_name_or_subquery,
  column_name,
  column_name,
  column_name,
  column_name,
  column_name,
  column_name,
  column_name
  );
END
$func$ LANGUAGE plpgsql;


barman recover --target-time '2019-03-27 06:45:52' --remote-ssh-command "ssh postgres@10.70.1.100" mstpn1pgs00_master 20190327T073433 /u01/app/postgres/data/masterprice/