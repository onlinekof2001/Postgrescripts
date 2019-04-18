/*
Reindex all index under a schema

*/

DO $$
DECLARE
  ind RECORD;
  schname VARCHAR := lower('your_schema');
  ownname VARCHAR := lower('obj_owner');
BEGIN
  for ind in (SELECT n.nspname, c.relname
  FROM pg_catalog.pg_class c
  LEFT JOIN pg_catalog.pg_namespace n
    ON n.oid = c.relnamespace
 WHERE c.relkind IN ('i')
   AND n.nspname = schname
   AND pg_catalog.pg_get_userbyid(c.relowner) = ownname
   AND pg_catalog.pg_table_is_visible(c.oid)
 ORDER BY 1, 2)
  LOOP
    RAISE NOTICE 'REINDEX INDEX %."%"', ind.nspname, ind.relname;
    EXECUTE 'REINDEX INDEX '||ind.nspname||'."'||ind.relname||'"';
  end loop;
end
$$;



select xmin,id from personne group by id having count(0) <> 1;
alter TABLE "optin_histo" add CONSTRAINT "optin_histo_personne_fk_personne_id" FOREIGN KEY (personne_id) REFERENCES personne_bak2019(id) DEFERRABLE;

BEGIN TRANSACTION;

CREATE TABLE edb_corrupted_rows(schemaname TEXT, tablename TEXT,t_ctid TID, sqlstate TEXT,sqlerrm TEXT);

CREATE OR REPLACE FUNCTION check_table_row_corruption(schemaname TEXT, tablename TEXT) RETURNS VOID AS $$
DECLARE
    rec RECORD;
    tmp RECORD;
    t_ctid TID;
    tmp_text TEXT;
BEGIN
    FOR rec IN EXECUTE 'SELECT ctid
                        FROM ' || quote_ident(schemaname) || '.' || quote_ident(tablename)
        LOOP
    BEGIN
        t_ctid := rec.ctid;
        BEGIN
            EXECUTE 'SELECT * FROM '
                    || quote_ident(schemaname) || '.' || quote_ident(tablename)
                    || ' WHERE ctid = ''' || t_ctid || '''::tid'
                INTO STRICT tmp;

            tmp_text := tmp::text;
        EXCEPTION WHEN OTHERS THEN
            INSERT INTO edb_corrupted_rows VALUES(schemaname, tablename, t_ctid, SQLSTATE::text, SQLERRM::text);
        END;
    END;
    END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMIT TRANSACTION;



