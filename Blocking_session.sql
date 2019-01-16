/*
https://yq.aliyun.com/articles/86631
https://yq.aliyun.com/ask/184?order=ctime
*/

-- Query 1
with t_wait as
 (select a.mode,
         a.locktype,
         a.database,
         a.relation,
         a.page,
         a.tuple,
         a.classid,
         a.granted,
         a.objid,
         a.objsubid,
         a.pid,
         a.virtualtransaction,
         a.virtualxid,
         a.transactionid,
         a.fastpath,
         b.state,
         b.query,
         b.xact_start,
         b.query_start,
         b.usename,
         b.datname,
         b.client_addr,
         b.client_port,
         b.application_name
    from pg_locks a, pg_stat_activity b
   where a.pid = b.pid
     and not a.granted),
t_run as
 (select a.mode,
         a.locktype,
         a.database,
         a.relation,
         a.page,
         a.tuple,
         a.classid,
         a.granted,
         a.objid,
         a.objsubid,
         a.pid,
         a.virtualtransaction,
         a.virtualxid,
         a.transactionid,
         a.fastpath,
         b.state,
         b.query,
         b.xact_start,
         b.query_start,
         b.usename,
         b.datname,
         b.client_addr,
         b.client_port,
         b.application_name
    from pg_locks a, pg_stat_activity b
   where a.pid = b.pid
     and a.granted),
t_overlap as
 (select r.*
    from t_wait w
    join t_run r
      on (r.locktype is not distinct from
          w.locktype and r.database is not distinct from
          w.database and r.relation is not distinct from
          w.relation and r.page is not distinct from
          w.page and r.tuple is not distinct from
          w.tuple and r.virtualxid is not distinct from
          w.virtualxid and r.transactionid is not distinct from
          w.transactionid and r.classid is not distinct from
          w.classid and r.objid is not distinct from
          w.objid and r.objsubid is not distinct from
          w.objsubid and r.pid <> w.pid)),
t_unionall as
 (select r.* from t_overlap r union all select w.* from t_wait w)
select locktype,
       datname,
       relation ::regclass,
       page,
       tuple,
       virtualxid,
       transactionid ::text,
       classid ::regclass,
       objid,
       objsubid,
       string_agg('Pid: ' || case
                    when pid is null then
                     'NULL'
                    else
                     pid ::text
                  end || chr(10) || 'Lock_Granted: ' || case
                    when granted is null then
                     'NULL'
                    else
                     granted ::text
                  end || ' , Mode: ' || case
                    when mode is null then
                     'NULL'
                    else
                     mode ::text
                  end || ' , FastPath: ' || case
                    when fastpath is null then
                     'NULL'
                    else
                     fastpath ::text
                  end || ' , VirtualTransaction: ' || case
                    when virtualtransaction is null then
                     'NULL'
                    else
                     virtualtransaction ::text
                  end || ' , Session_State: ' || case
                    when state is null then
                     'NULL'
                    else
                     state ::text
                  end || chr(10) || 'Username: ' || case
                    when usename is null then
                     'NULL'
                    else
                     usename ::text
                  end || ' , Database: ' || case
                    when datname is null then
                     'NULL'
                    else
                     datname ::text
                  end || ' , Client_Addr: ' || case
                    when client_addr is null then
                     'NULL'
                    else
                     client_addr ::text
                  end || ' , Client_Port: ' || case
                    when client_port is null then
                     'NULL'
                    else
                     client_port ::text
                  end || ' , Application_Name: ' || case
                    when application_name is null then
                     'NULL'
                    else
                     application_name ::text
                  end || chr(10) || 'Xact_Start: ' || case
                    when xact_start is null then
                     'NULL'
                    else
                     xact_start ::text
                  end || ' , Query_Start: ' || case
                    when query_start is null then
                     'NULL'
                    else
                     query_start ::text
                  end || ' , Xact_Elapse: ' || case
                    when (now() - xact_start) is null then
                     'NULL'
                    else
                     (now() - xact_start) ::text
                  end || ' , Query_Elapse: ' || case
                    when (now() - query_start) is null then
                     'NULL'
                    else
                     (now() - query_start) ::text
                  end || chr(10) || 'SQL (Current SQL in Transaction): ' ||
                  chr(10) || case
                    when query is null then
                     'NULL'
                    else
                     query ::text
                  end,
                  chr(10) || '--------' || chr(10) order
                  by(case mode
                       when 'INVALID' then
                        0
                       when 'AccessShareLock' then
                        1
                       when 'RowShareLock' then
                        2
                       when 'RowExclusiveLock' then
                        3
                       when 'ShareUpdateExclusiveLock' then
                        4
                       when 'ShareLock' then
                        5
                       when 'ShareRowExclusiveLock' then
                        6
                       when 'ExclusiveLock' then
                        7
                       when 'AccessExclusiveLock' then
                        8
                       else
                        0
                     end) desc,
                  (case
                    when granted then
                     0
                    else
                     1
                  end)) as lock_conflict
  from t_unionall
 group by locktype,
          datname,
          relation,
          page,
          tuple,
          virtualxid,
          transactionid ::text,
          classid,
          objid,
          objsubid;

-- Query 2
SELECT blocked_locks.pid         AS blocked_pid,
       blocked_activity.usename  AS blocked_user,
       blocking_locks.pid        AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query    AS blocked_statement,
       blocking_activity.query   AS current_statement_in_blocking_process
  FROM pg_catalog.pg_locks blocked_locks
  JOIN pg_catalog.pg_stat_activity blocked_activity
    ON blocked_activity.pid = blocked_locks.pid
  JOIN pg_catalog.pg_locks blocking_locks
    ON blocking_locks.locktype = blocked_locks.locktype
   AND blocking_locks.DATABASE IS NOT DISTINCT FROM
 blocked_locks.DATABASE
   AND blocking_locks.relation IS NOT DISTINCT FROM
 blocked_locks.relation
   AND blocking_locks.page IS NOT DISTINCT FROM
 blocked_locks.page
   AND blocking_locks.tuple IS NOT DISTINCT FROM
 blocked_locks.tuple
   AND blocking_locks.virtualxid IS NOT DISTINCT FROM
 blocked_locks.virtualxid
   AND blocking_locks.transactionid IS NOT DISTINCT FROM
 blocked_locks.transactionid
   AND blocking_locks.classid IS NOT DISTINCT FROM
 blocked_locks.classid
   AND blocking_locks.objid IS NOT DISTINCT FROM
 blocked_locks.objid
   AND blocking_locks.objsubid IS NOT DISTINCT FROM
 blocked_locks.objsubid
   AND blocking_locks.pid != blocked_locks.pid
  JOIN pg_catalog.pg_stat_activity blocking_activity
    ON blocking_activity.pid = blocking_locks.pid
 WHERE NOT blocked_locks.GRANTED;

-- Query 3
create or replace function f_lock_level(i_mode text) returns int as $$
declare
begin
  case i_mode
    when 'INVALID' then return 0;
    when 'AccessShareLock' then return 1;
    when 'RowShareLock' then return 2;
    when 'RowExclusiveLock' then return 3;
    when 'ShareUpdateExclusiveLock' then return 4;
    when 'ShareLock' then return 5;
    when 'ShareRowExclusiveLock' then return 6;
    when 'ExclusiveLock' then return 7;
    when 'AccessExclusiveLock' then return 8;
    else return 0;
  end case;
end; 
$$ language plpgsql strict;

with t_wait as
 (select a.mode,
         a.locktype,
         a.database,
         a.relation,
         a.page,
         a.tuple,
         a.classid,
         a.objid,
         a.objsubid,
         a.pid,
         a.virtualtransaction,
         a.virtualxid,
         a,
         transactionid,
         b.query,
         b.xact_start,
         b.query_start,
         b.usename,
         b.datname
    from pg_locks a, pg_stat_activity b
   where a.pid = b.pid
     and not a.granted),
t_run as
 (select a.mode,
         a.locktype,
         a.database,
         a.relation,
         a.page,
         a.tuple,
         a.classid,
         a.objid,
         a.objsubid,
         a.pid,
         a.virtualtransaction,
         a.virtualxid,
         a.transactionid,
         b.query,
         b.xact_start,
         b.query_start,
         b.usename,
         b.datname
    from pg_locks a, pg_stat_activity b
   where a.pid = b.pid
     and a.granted)
select r.locktype,
       r.mode r_mode,
       r.usename r_user,
       r.datname r_db,
       r.relation ::regclass,
       r.pid r_pid,
       r.page r_page,
       r.tuple r_tuple,
       r.xact_start r_xact_start,
       r.query_start r_query_start,
       now() - r.query_start r_locktime,
       r.query r_query,
       w.mode w_mode,
       w.pid w_pid,
       w.page w_page,
       w.tuple w_tuple,
       w.xact_start w_xact_start,
       w.query_start w_query_start,
       now() - w.query_start w_locktime,
       w.query w_query
  from t_wait w, t_run r
 where r.locktype is not distinct from w.locktype
   and r.database is not distinct from w.database
   and r.relation is not distinct from w.relation
   and r.page is not distinct from w.page
   and r.tuple is not distinct from w.tuple
   and r.classid is not distinct from w.classid
   and r.objid is not distinct from w.objid
   and r.objsubid is not distinct from
 w.objsubid
   and r.transactionid is not distinct from w.transactionid
   and r.pid <> w.pid
 order by f_lock_level(w.mode) + f_lock_level(r.mode) desc, r.xact_start;
 



