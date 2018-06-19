pgcmd='/usr/bin/psql'
read -p "scripts locations: " scpth


for fn in $(ls $scpth)
do
    constr=${fn%%.*}    #
    if [[ ${fn%%.*} =~ '_' ]]
    then
        constr=${constr%%_*}
    fi
    constr=$(echo $constr | tr '[A-Z]' '[a-z]')
    echo "$pgcmd -U$constr $constr -f $fn"
    #$pgcmd -U$constr $constr -f $fn
done