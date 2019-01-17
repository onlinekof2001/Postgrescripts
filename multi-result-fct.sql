CREATE OR REPLACE FUNCTION list_obj_size(obj varchar) RETURNS SETOF RECORD AS 
$$
DECLARE
	dblist record;
	tablist record;
	BEGIN 
	IF obj = 'db'::varchar THEN
	FOR dblist IN (SELECT d.datname as "Name",
       pg_catalog.pg_get_userbyid(d.datdba)::text as "Owner",
       CASE WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT')
            THEN pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname))
            ELSE 'No Access'
       END as "Size"
  FROM pg_catalog.pg_database d
  JOIN pg_catalog.pg_tablespace t on d.dattablespace = t.oid
 WHERE d.datname not in ('template0','template1','postgres','rdsadmin')
 ORDER BY pg_database_size(d.datname) desc) LOOP
	RETURN next dblist;
	END LOOP;
	ELSIF obj = 'tab' THEN
	FOR tablist IN (SELECT c.relname as "Name",n.nspname::text as "Owner",
  pg_catalog.pg_size_pretty(pg_catalog.pg_table_size(c.oid)) as "Size"
FROM pg_catalog.pg_class c
     LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r','')
      AND n.nspname <> 'pg_catalog'
      AND n.nspname <> 'information_schema'
      AND n.nspname !~ '^pg_toast'
  AND pg_catalog.pg_table_is_visible(c.oid)
ORDER BY pg_table_size(c.oid) desc limit 30) LOOP
	RETURN next tablist;
	END LOOP;
	ELSE
	FOR tablist IN (SELECT c.relname as "Name",n.nspname::text as "Owner",
   pg_catalog.pg_size_pretty(pg_catalog.pg_table_size(c.oid)) as "Size"
FROM pg_catalog.pg_class c
     LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r','')
      AND n.nspname <> 'pg_catalog'
      AND n.nspname <> 'information_schema'
      AND n.nspname !~ '^pg_toast'
      AND c.relname LIKE 'transaction_live%'
      AND pg_catalog.pg_table_is_visible(c.oid)
ORDER BY pg_table_size(c.oid) desc limit 30) LOOP
	RETURN next tablist;
	END LOOP;
	END IF;
	RETURN;
END; $$ LANGUAGE PLPGSQL;


-- 调用

select * from list_obj_size('db') as tbl("Name" name, "Owner" text, "Size" text);
select * from list_obj_size('tab')as tbl("Name" name, "Owner" text, "Size" text);
select * from list_obj_size('tablist')as tbl("Name" name, "Owner" text, "Size" text);


vim list_obj_size.sh
#!/bin/bash

export PGHOST='rtdkn1pcs70.cuuxvcxw3hrr.rds.cn-north-1.amazonaws.com.cn'
export PGUSER='posdata'
export PGPASSWORD='ackdoiwe_!djfn'
export PGPORT=60901

cmd='/usr/bin/psql'

case $1 in
    db)
        $cmd -d $PGUSER -c "select * from list_obj_size('db') as tbl("Name" name, "Owner" text, "Size" text);"
    ;;
    tab)
        $cmd -d $PGUSER -c "select * from list_obj_size('tab') as tbl("Name" name, "Owner" text, "Size" text);"
    ;;
    tablist)
        $cmd -d $PGUSER -c "select * from list_obj_size('tablist') as tbl("Name" name, "Owner" text, "Size" text);"
    ;;
    *)
        echo "The options should be [db|tab|tablist]"
    ;;
esac