select rpad(relname,(select max(length(relname)) from pg_class),' ') as tablename,reltuples::bigint as rows
  from pg_class 
 where relkind='r' 
   and relowner = (select nspowner 
                     from pg_namespace 
                    where nspname=:sch::text) 
 order by relname,reltuples desc;
