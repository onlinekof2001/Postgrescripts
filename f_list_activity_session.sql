-- list all

CREATE OR REPLACE FUNCTION f_lst_session(st varchar) RETURNS SETOF RECORD AS
$$
DECLARE
    pg_stat_act record;
BEGIN
    IF st='idle' or st='active' or st='iit' THEN
        FOR pg_stat_act IN (select pid, query_start, state_change, backend_xid, query from pg_stat_activity where state_change - query_start > interval '2 sec' and state=st) LOOP
	        RETURN NEXT pg_stat_act;
	    END LOOP;
    ELSE
	    RAISE EXCEPTION 'Your gave option is, %', st using hint='Please check your option, it should be [idle|active|iit(idle in transaction)]';
    END IF; RETURN;
END;
$$
LANGUAGE PLPGSQL;


select * from f_lst_session('idle')as tbl("pid" integer, "query_start" timestamp with time zone, "state_change" timestamp with time zone, "backend_xid" xid, "query" text);