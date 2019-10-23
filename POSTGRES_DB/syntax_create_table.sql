Time data type
https://www.postgresql.org/docs/9.5/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT
-- 创建带有时区属性字段的表，比对函数now(),clock_timestamp()
create table t1(id int,
	create_time timestamp with time zone default (now() at time zone 'Asia/Shanghai'), 
	updated_time timestamp with time zone default (now() at time zone 'Asia/Shanghai'),
	create_time2 timestamp with time zone default (clock_timestamp() at time zone 'Asia/Shanghai'),
	updated_time2 timestamp with time zone default (clock_timestamp() at time zone 'Asia/Shanghai')
);

insert into t1(id) values (1) returning (create_time,updated_time,create_time2,updated_time2);
                                                                row                                                                
-----------------------------------------------------------------------------------------------------------------------------------
 ("2019-07-10 14:51:41.709038+00","2019-07-10 14:51:41.709038+00","2019-07-10 14:51:41.709293+00","2019-07-10 14:51:41.709294+00")
(1 row)