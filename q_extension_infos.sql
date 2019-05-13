-- 查看数据库扩展包信息

select name, 
	default_version, 
	installed_version, 
	left(comment,30) as comment 
  from pg_available_extensions
 where installed_version is not null order by name;