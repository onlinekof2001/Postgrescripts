WITH x AS (
   SELECT count(*)               AS ct
        , sum(length(t::text))   AS txt_len  -- length in characters
        , 'pg_tbl_benefit_item'::regclass AS pg_tbl_benefit_item  -- provide (qualified) table name here
   FROM   pg_tbl_benefit_item t  -- ... and here
   )
, y AS (
   SELECT ARRAY [pg_relation_size(pg_tbl_benefit_item)
               , pg_relation_size(pg_tbl_benefit_item, 'vm')
               , pg_relation_size(pg_tbl_benefit_item, 'fsm')
               , pg_table_size(pg_tbl_benefit_item)
               , pg_indexes_size(pg_tbl_benefit_item)
               , pg_total_relation_size(pg_tbl_benefit_item)
               , txt_len
             ] AS val
        , ARRAY ['core_relation_size'
               , 'visibility_map'
               , 'free_space_map'
               , 'table_size_incl_toast'
               , 'indexes_size'
               , 'total_size_incl_toast_and_indexes'
               , 'live_rows_in_text_representation'
             ] AS name
   FROM   x
   )
SELECT unnest(name)                AS what
     , unnest(val)                 AS "bytes/ct"
     , pg_size_pretty(unnest(val)) AS bytes_pretty
     , unnest(val) / ct            AS bytes_per_row
FROM   x, y
UNION ALL SELECT '------------------------------', NULL, NULL, NULL
UNION ALL SELECT 'row_count', ct, NULL, NULL FROM x
UNION ALL SELECT 'live_tuples', pg_stat_get_live_tuples(pg_tbl_benefit_item), NULL, NULL FROM x
UNION ALL SELECT 'dead_tuples', pg_stat_get_dead_tuples(pg_tbl_benefit_item), NULL, NULL FROM x;

-- 9.3+
SELECT l.what, l.nr AS "bytes/ct"
     , CASE WHEN is_size THEN pg_size_pretty(nr) END AS bytes_pretty
     , CASE WHEN is_size THEN nr / x.ct END          AS bytes_per_row
FROM  (
   SELECT min(tableoid)        AS pg_tbl_benefit_item      -- same as 'public.pg_tbl_benefit_item'::regclass::oid
        , count(*)             AS ct
        , sum(length(t::text)) AS txt_len  -- length in characters
   FROM   pg_tbl_benefit_item t  -- provide table name *once*
   ) x
 , LATERAL (
   VALUES
      (true , 'core_relation_size'               , pg_relation_size(pg_tbl_benefit_item))
    , (true , 'visibility_map'                   , pg_relation_size(pg_tbl_benefit_item, 'vm'))
    , (true , 'free_space_map'                   , pg_relation_size(pg_tbl_benefit_item, 'fsm'))
    , (true , 'table_size_incl_toast'            , pg_table_size(pg_tbl_benefit_item))
    , (true , 'indexes_size'                     , pg_indexes_size(pg_tbl_benefit_item))
    , (true , 'total_size_incl_toast_and_indexes', pg_total_relation_size(pg_tbl_benefit_item))
    , (true , 'live_rows_in_text_representation' , txt_len)
    , (false, '------------------------------'   , NULL)
    , (false, 'row_count'                        , ct)
    , (false, 'live_tuples'                      , pg_stat_get_live_tuples(pg_tbl_benefit_item))
    , (false, 'dead_tuples'                      , pg_stat_get_dead_tuples(pg_tbl_benefit_item))
   ) l(is_size, what, nr);
   

               what                |  bytes/ct  | bytes_pretty | bytes_per_row 
-----------------------------------+------------+--------------+---------------
 core_relation_size                | 1272348672 | 1213 MB      |           109
 visibility_map                    |          0 | 0 bytes      |             0
 free_space_map                    |     335872 | 328 kB       |             0
 table_size_incl_toast             | 1272684544 | 1214 MB      |           109
 indexes_size                      |          0 | 0 bytes      |             0
 total_size_incl_toast_and_indexes | 1272684544 | 1214 MB      |           109
 live_rows_in_text_representation  | 1231835128 | 1175 MB      |           105
 ------------------------------    |            |              |              
 row_count                         |   11662183 |              |              
 live_tuples                       |   11662183 |              |              
 dead_tuples                       |          0 |              |              
(11 rows)

select pg_column_size("CREATE_TIME") from pg_tbl_benefit_item