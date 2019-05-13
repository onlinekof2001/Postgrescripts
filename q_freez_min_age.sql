/*
DB freeze min age
https://www.postgresql.org/docs/9.5/routine-vacuuming.html 
*/

SELECT freez, txns, ROUND(100*(txns/freez::float)) AS perc, datname
FROM (
    SELECT foo.freez::int, age(datfrozenxid) AS txns, datname
    FROM pg_database d
    JOIN (
        SELECT setting AS freez
        FROM pg_settings
        WHERE name = 'autovacuum_freeze_max_age'
    ) AS foo
    ON (true)
    WHERE d.datallowconn
) AS foo2
ORDER BY 3 DESC, 4 ASC;