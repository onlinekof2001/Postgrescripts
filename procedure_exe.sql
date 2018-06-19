do language plpgsql $$
declare
id_int int;
begin
  for id_int in select id from pggroupby loop
    perform sum(bills) from pggroupby where id=id_int group by id;
  end loop;
end;
$$;
DO