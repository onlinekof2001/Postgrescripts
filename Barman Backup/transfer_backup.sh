#!/bin/bash

#########################################################
#      Version 1.0                                      #
#      Transfer the backup to S3/BLOB                   #
#########################################################

function etime() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1\n"
}


awscmd='/usr/bin/aws'
upld_logs='/tmp/upload_backupset.log'
bkp_dir='/barman/backup_comp'
del_dat=$(date +%F -d'15 days ago')
bkp_con='barman-respertory-prod'

if [[ $1='az' ]]
then 
    acs_keyf='/opt/az_access_keyfile.ac'
else
    acs_keyf='/opt/aws_access_keyfile.ac'
fi

NAME=`basename $0`
if [ ${NAME:0:1} = "S" -o ${NAME:0:1} = "K" ]
    then
    NAME=${NAME:3}
fi

if [ ! -f $acs_keyf ]
then
    etime "WARN access key file doesn\'t exist, you need to also fill the access key inside $acs_keyf"
    touch $acs_keyf
else
    cat $acs_keyf
fi

function help() {
    echo -e "\e[1;37mNAME\e[0m"
    echo "      $NAME"
    echo ""
    echo -e "\e[1;37mSYNOPSIS\e[0m"
    echo "      $NAME <cloud-env> <container-name> <backupset> <Accesskeyfile>"
    echo ""
    echo -e "\e[1;37mDESCRIPTION\e[0m"
    echo "      This script is work for transfer the backup sets to AWS S3/AZURE BLOB ."
    echo ""
    echo -e "\e[1;37mOPTIONS\e[0m"
    echo "      -h | --help                                        Print help"
    echo ""
    echo "      <cloud-env> should be aws or az"
    echo ""
    echo "      <container-name> will define in your backup script, if it is aws, it should be <bucket-name>"
	echo ""
    echo "      <backupset> it will also define in your backup script"
    echo ""
	echo "      <Accesskeyfile> the location of the Accesskey file"
    echo ""
    exit 0;
}

function s3_verify() {
    acsf=$1
    if [ -e ${acsf} ]
    then
        awski=$(awk -F';' '{print $1}' ${acsf})
	awsak=$(awk -F';' '{print $2}' ${acsf} )
	awsr=$(awk -F';' '{print $3}' ${acsf})
        export AWS_ACCESS_KEY_ID = "$awski"
        export AWS_SECRET_ACCESS_KEY = "$awsak"
	export AWS_DEFAULT_REGION = "$awsr"
	export AWS_DEFAULT_OUTPUT = json
    else
	echo -e "You need to point the S3 Access key file. \nMore environment variables please see https://docs.aws.amazon.com/cli/latest/userguide/cli-environment.html"
    fi
}

function blob_verify() {
    acsf=$1
    if [[ -z ${AZURE_STORAGE_CONNECTION_STRING} ]]
    then
        depp=$(awk -F';' '{print $1}' ${acsf})
        azac=$(awk -F';' '{print $2}' ${acsf})
        azak=$(awk -F';' '{print $3}' ${acsf})
        azes=$(awk -F';' '{print $4}' ${acsf})
        export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=$depp;AccountName=$azac;AccountKey=$azak;EndpointSuffix=$azes"
    else
	echo -e "You need to point the Blob Access Key file."
    fi
}

function aws_s3() {
    ctn=$1
    fln=$2
    etime "INFO Uploading the backupset $3" | tee -a $upld_logs
    aws s3 sync $ctn $fln
    etime "INFO Upload to S3 Done" | tee -a $upld_logs
}

function az_blob() {
    ctn=$1
    fln=$2
    bna=$3
    etime "INFO Uploading the backupset $3" | tee -a $upld_logs
    az storage blob upload --container-name ${ctn} --file ${fln} --name ${bna}
    etime "INFO Upload to Blob Done" | tee -a $upld_logs
}

function az_del(){
    ctn=$1
    fln=$2
    etime "INFO deleting the backupset $2" | tee -a $upld_logs
    az storage blob delete --container-name ${ctn} --name ${fln}
    if [ $? -eq 0 ]
    then
    etime "INFO delete $2 from Blob Done" | tee -a $upld_logs
    else
    etime "INFO delete $2 from Blob is not finish" | tee -a $upld_logs
    fi
}

#shell call
trnf_bar() {
source /var/lib/barman/monit_barman.sh bkps
while read bkphst bkpid
do
    if [[ ! -f ${bkp_dir}/${bkphst}_${bkpday}.tar.gz ]]
	then
        barman list-files ${bkphst} ${bkpid} | tar czvf ${bkp_dir}/${bkphst}_${bkpday}.tar.gz -T -
	barman list-files --target wal ${bkphst} ${bkpid} | tar czvf ${bkp_dir}/${bkphst}_${bkpday}_wal.tar.gz -T -
	az_blob ${bkp_con} ${bkp_dir}/${bkphst}_${bkpday}.tar.gz ${bkphst}_${bkpday}
        az_blob ${bkp_con} ${bkp_dir}/${bkphst}_${bkpday}_wal.tar.gz ${bkphst}_${bkpday}_wal
        az_del ${bkp_con} ${bkphst}_${del_dat}
        az_del ${bkp_con} ${bkphst}_${del_dat}_wal
    elif [[ $(az storage blob show --container-name ${bkp_con} --name ${bkpid} | grep -c state) -gt 1 ]]
    then
        az_blob ${bkp_con} ${bkp_dir}/${bkphst}_${bkpday}.tar.gz ${bkphst}_${bkpday}
        az_blob ${bkp_con} ${bkp_dir}/${bkphst}_${bkpday}_wal.tar.gz ${bkphst}_${bkpday}_wal
        az_del ${bkp_con} ${bkphst}_${del_dat}
        az_del ${bkp_con} ${bkphst}_${del_dat}_wal
    fi
    if [ $? = 0 ]
    then
        rm -f ${bkp_dir}/${bkphst}_${bkpday}.tar.gz
    fi
done < ${bkpsid}
}

trnf_xtr() {
    xtrbkp_path=$1
    xtrbkp_file=$2
    xtrbkp_del_file=$(date +%y%m%d -d'15 days ago')_full
    az_blob ${xtrpp_con} ${xtrbkp_path} ${xtrbkp_file}
    if [[ $? -eq 0 ]]
    then
        echo ${xtrbkp_path}
        az_del ${xtrpp_con} ${xtrbkp_del_file}
    fi
}


case $1 in
    -h|--help)
	help
    ;;
    aws)
	s3_verify ${acs_keyf}   # Review the Access keys for the Azure Blob/AWS S3
	aws_s3 ${awsc} ${awsf}
    ;;
    az)
	blob_verify ${acs_keyf}
	if [[ $2 = 'barman' ]]
    	then
            trnf_bar
    	elif [[ $2 = 'xtrbkp' ]]
    	then
            trnf_xtr $3 $4
    	else
            echo 'Your should choose [barman | xtrbkp]'
    	fi
    ;;
    *)
        echo 'noaction'
    ;;
esac
