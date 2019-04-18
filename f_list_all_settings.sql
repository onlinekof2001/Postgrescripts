-- https://pgtune.leopard.in.ua/#/

-- check all settings from postgreSQL
select name, unit, setting, boot_val, reset_val, context
  from pg_settings
 where name in ('max_connections',
                'shared_buffers',
                'effective_cache_size',
                'maintenance_work_mem',
                'checkpoint_completion_target',
                'wal_buffers',
                'default_statistics_target',
                'random_page_cost',
                'effective_io_concurrency',
                'work_mem',
                'min_wal_size',
                'max_wal_size',
                'max_worker_processes',
                'max_parallel_workers_per_gather')
				
				
/*
AWS RDS
shared_buffers {DBInstanceClassMemory/32768}
effective_cache_size {DBInstanceClassMemory/10922}
maintenance_work_mem LEAST({DBInstanceClassMemory/16384},2097152)	

*/

7agr855268h86

SELECT "A2"."SEL_ID",
       "A2"."SES_CATEGORY",
       "A2"."SES_AXIS",
       "A2"."SES_AXIS_DECLENSION",
       "A2"."SES_PAST_YEAR",
       "A2"."SES_CURRENT_YEAR",
       "A2"."SES_PAST_YEAR_DDS",
       "A2"."SES_PAST_YEAR_FORECASTED",
       "A2"."SES_UPDATE_DATE",
       "A2"."SES_UPDATE_USER",
       "A2"."TTI_NUM_TYPE_TIERS_GEO",
       "A2"."TIR_NUM_TIERS_GEO",
       "A2"."TIR_SOUS_NUM_TIERS_GEO",
       "A2"."SES_DETAILS_FOR"
  FROM "BRANDATA"."SELECTION_SYNTHESIS" "A2",
       (SELECT DISTINCT "A3"."SEL_ID"                 "SEL_ID",
                        "A3"."SES_AXIS"               "SES_AXIS",
                        "A3"."SES_AXIS_DECLENSION"    "SES_AXIS_DECLENSION",
                        "A3"."SES_CATEGORY"           "SES_CATEGORY",
                        "A3".                         "SES_DETAILS_FOR" "SES_DETAILS_FOR",
                        "A3"."TIR_NUM_TIERS_GEO"      "TIR_NUM_TIERS_GEO",
                        "A3"."TIR_SOUS_NUM_TIERS_GEO" "TIR_SOUS_NUM_TIERS_GEO",
                        "A3"."TTI_NUM_TYPE_TIERS_GEO" "TTI_NUM_TYPE_TIERS_GEO"
          FROM "BRANDATA"."MLOG$_SELECTION_SYNTHESIS" "A3"
         WHERE "A3"."SNAPTIME$$" > :1
           AND "A3"."DMLTYPE$$" <> 'D') "A1"
 WHERE "A2"."SEL_ID" = "A1"."SEL_ID"
   AND "A2"."SES_AXIS" = "A1"."SES_AXIS"
   AND "A2"."SES_AXIS_DECLENSION" = "A1"."SES_AXIS_DECLENSION"
   AND "A2"."SES_CATEGORY" = "A1"."SES_CATEGORY"
   AND "A2"."SES_DETAILS_FOR" = "A1"."SES_DETAILS_FOR"
   AND "A2"."TIR_NUM_TIERS_GEO" = "A1"."TIR_NUM _TIERS_GEO"
   AND "A2"."TIR_SOUS_NUM_TIERS_GEO" = "A1"."TIR_SOUS_NUM_TIERS_GEO"
   AND "A2"."TTI_NUM_TYPE_TIERS_GEO" = "A1"."TTI_NUM_TYPE_TIERS_GEO"