: 'Barman configuration 
Global'
[barman]
barman_home = /barman
barman_user = barman
log_file = /var/log/barman/barman.log
log_level = INFO
backup_options = concurrent_backup
compression = gzip
archiver = on
minimum_redundancy = 0
retention_policy = RECOVERY WINDOW OF 1 DAYS
retention_policy_mode = auto
wal_retention_policy = main
configuration_files_directory = /etc/barman.conf.d
check_timeout = 5

# Server configuration
# Steaming backup
[pg_streaming_backup]
description =  "Example of PostgreSQL Database (Streaming-Only)"
# Which barman connect to postgres to fetch data file from postgres
conninfo = host=pg user=barman dbname=postgres port=5432
# Streaming connection strings which can transit the WAL from source DB to barman
streaming_conninfo = host=pg user=streaming_barman dbname=postgres port=5432
streaming_archiver = on
archiver = on
backup_method = postgres
# check pg_slot_replication on source DB
slot_name = barman
streaming_wals_directory=/barman/path/to/streaming
minimum_redundancy = 3
retention_policy = RECOVERY WINDOW OF 1 WEEK
path_prefix=/usr/pgsql-10/bin

# SSH backup
[pg_ssh_backup]
description = "Example of PostgreSQL Database (SSH-Only)"
ssh_command = ssh postgres@localhost
conninfo = user=postgres host=localhost port=5432
archiver = true
active = true
backup_options = exclusive_backup
compression = gzip
minimum_redundancy = 0
retention_policy = REDUNDANCY 1
retention_policy_mode = auto
wal_retention_policy = main




