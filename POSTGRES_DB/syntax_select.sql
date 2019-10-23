-- 翻页问题
\timing on
create table t2(id int primary key, info text, crt_time timestamp);
insert into t2 select generate_series(1,10000000),'abc',clock_timestamp();

=# select * from t2 where info='abc' limit 10 offset 0;
 id | info |          crt_time          
----+------+----------------------------
  1 | abc  | 2019-07-10 07:45:35.203732
  2 | abc  | 2019-07-10 07:45:35.203867
  3 | abc  | 2019-07-10 07:45:35.203873
  4 | abc  | 2019-07-10 07:45:35.203876
  5 | abc  | 2019-07-10 07:45:35.203878
  6 | abc  | 2019-07-10 07:45:35.20388
  7 | abc  | 2019-07-10 07:45:35.203882
  8 | abc  | 2019-07-10 07:45:35.203883
  9 | abc  | 2019-07-10 07:45:35.203886
 10 | abc  | 2019-07-10 07:45:35.203888
(10 rows)

Time: 0.712 ms

=# select * from t2 where info='abc' limit 10 offset 100000;
   id   | info |          crt_time          
--------+------+----------------------------
 100001 | abc  | 2019-07-10 07:45:35.470294
 100002 | abc  | 2019-07-10 07:45:35.470296
 100003 | abc  | 2019-07-10 07:45:35.470298
 100004 | abc  | 2019-07-10 07:45:35.4703
 100005 | abc  | 2019-07-10 07:45:35.470303
 100006 | abc  | 2019-07-10 07:45:35.470305
 100007 | abc  | 2019-07-10 07:45:35.470307
 100008 | abc  | 2019-07-10 07:45:35.470309
 100009 | abc  | 2019-07-10 07:45:35.470311
 100010 | abc  | 2019-07-10 07:45:35.470313
(10 rows)

Time: 12.317 ms

=# select * from t2 where info='abc' limit 10 offset 1000000;
   id    | info |          crt_time          
---------+------+----------------------------
 1097681 | abc  | 2019-07-10 07:45:38.564629
 1097682 | abc  | 2019-07-10 07:45:38.564631
 1097683 | abc  | 2019-07-10 07:45:38.564633
 1097684 | abc  | 2019-07-10 07:45:38.564636
 1097685 | abc  | 2019-07-10 07:45:38.564638
 1097686 | abc  | 2019-07-10 07:45:38.56464
 1097687 | abc  | 2019-07-10 07:45:38.564643
 1097688 | abc  | 2019-07-10 07:45:38.564645
 1097689 | abc  | 2019-07-10 07:45:38.564647
 1097690 | abc  | 2019-07-10 07:45:38.564658
(10 rows)

Time: 120.079 ms


create or replace function paginate_for_t2(refcursor,row_num integer) returns setof refcursor as
$$
BEGIN
   open $1 for select * from public.t2 offset row_num;
   return next $1;
END;
$$
LANGUAGE 'plpgsql';

begin;
select * from paginate_for_t2('a',1000000)
fetch 10 from a;
end;

