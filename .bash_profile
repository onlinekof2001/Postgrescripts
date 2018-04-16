# .bash_profile

# Get the aliases and functions
[ -f $HOME/.bashrc ] && . $HOME/.bashrc

# PostgreSQL SID chooser
[ -f $HOME/bin/choosesid ] &&. $HOME/bin/choosesid



alias cdpgdata="cd $PGDATA"
alias cdpgreco="cd /u01/app/postgres/recovery"

day=$(date '+%a')
postgres_log_file="$PGDATA/pg_log/postgresql-$day.log"
alias pg_reload="pg_ctl reload && tail -n10 $postgres_log_file"
alias pg_ctl="echo Please use systemctl instead of pg_ctl"

alias psqlpp="$HOME/bin/psqlpp"
alias oxycreatedb="$HOME/oxycreatedb.sh"
alias pg_view="pg_view -c /etc/pg_service.conf"

alias cdsup="cd /usr/local/sbin/supervision"
alias cdsuplog="cd /var/log/supervision"
alias sup="/usr/local/sbin/supervision/supervision_postgres.sh all"
alias suplog="grep -v ' OK$' /var/log/supervision/supervision_degradee.log"

cd $PGDATA

## History extended logging
## We keep 2000 lines of history
## History file : .bash_history-login
export HISTSIZE=2000
export HISTFILESIZE=2000
export HISTTIMEFORMAT="%d/%m/%y %T "
SRCLOGIN=$(who am i 2>/dev/null | awk '{print $1}' 2>/dev/null; exit)
export HISTFILE="${HOME}/.bash_history-${SRCLOGIN}"
#sudo chattr +a $HISTFILE 2>/dev/null
export PROMPT_COMMAND='history -a'
readonly HISTSIZE
readonly HISTFILESIZE
readonly HISTTIMEFORMAT
readonly HISTFILE
readonly PROMPT_COMMMAND

# Load psql autocomplete
[ -f $HOME/bin/psql.complete ] && . $HOME/bin/psql.complete

# Load local file
[ -f $HOME/.bash_profile_local ] && . $HOME/.bash_profile_local
