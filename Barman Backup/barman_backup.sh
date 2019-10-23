#!/bin/bash

# barman backup script

bkp_owner=barman
brm_dir='/barman'
brm_cfg='/etc/barman.conf'
brm_cmd='/usr/bin/barman'
bkp_hst='/barman/barmap'


if [ -x $brm_cmd ]
then
    vers = $($brm_cmd --version)
    echo -e "barman version is $vers \nIf the version is earlier than 1.3.1,diagnose option could not used. \nAslo see: https://www.pgbarman.org/barman-1-3-1-released/"
    $($brm_cmd --list-server --minimal) > $bkp_hst
fi



function bkp_act() {
    if [ -z $1 ]
    then 
        echo "backup instances are $bkp_hst" | tee -a $brm_dir/barman.list
    else
    	barman backup $1 >> $brm_dir/$1/base/barman.log
		if [ $? -eq 0 ]
		then
		    bkp_set=$($brm_cmd --list-backup --minimal)
			transfer_backup.sh $2 container $brm_dir/$1/base/$bkp_set Accesskeyfile
			transfer_backup.sh $2 container $brm_dir/$1/base/wal Accesskeyfile
		else   
		fi
    fi
}

case $2 in
    aws)
	bkp_act $1 $2
	;;
	az)
	bkp_act $1 $2
	;;
	*)
	;;
esac