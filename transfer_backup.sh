#!/bin/bash

#########################################################
#      Version 1.0                                      #
#      Transfer the backup to S3/BLOB                   #
#########################################################

function etime() {
    exec_time=$(date +'%Y-%m-%d %H:%M:%S')
}

awscmd='/usr/bin/aws'
upld_logs='/tmp/upload_backupset.log'

NAME=`basename $0`
if [ ${NAME:0:1} = "S" -o ${NAME:0:1} = "K" ]
    then
    NAME=${NAME:3}
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
    if [ -e $4 ]
	then
        awski=$(awk -F';' '{print $1}' $4)
	    awsak=$(awk -F';' '{print $2}' $4)
	    awsr=$(awk -F';' '{print $3}' $4)
        export AWS_ACCESS_KEY_ID = "$awski"
        export AWS_SECRET_ACCESS_KEY = "$awsak"
	    export AWS_DEFAULT_REGION = "$awsr"
	    export AWS_DEFAULT_OUTPUT = json
	else
	    echo -e "You need to point the S3 Access key file. \nMore environment variables please see https://docs.aws.amazon.com/cli/latest/userguide/cli-environment.html"
    fi
}

function blob_verify() {
    if [ -e $4 ]
	then
        depp=$(awk -F';' '{print $1}' $4)
	    azac=$(awk -F';' '{print $2}' $4)
	    azak=$(awk -F';' '{print $3}' $4)
	    azes=$(awk -F';' '{print $4}' $4)
	    export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=$depp;AccountName=$azac;AccountKey=$azak;EndpointSuffix=$azes"
    else
	    echo -e "You need to point the Blob Access Key file."
	fi
}

function aws_s3() {
    etime
    echo "$exec_time Uploading the backupset $3" | tee -a $upld_logs
	aws s3 sync $3 $2
	etime
	echo "$exec_time Upload to S3 Done" | tee -a $upld_logs
}

function az_blob() {
    etime
    echo "$exec_time Uploading the backupset $3" | tee -a $upld_logs
    az storage blob upload --container-name "$2" --file "$3" --name "$3"
    etime	
	echo " $exec_timeUpload to Blob Done" | tee -a $upld_logs
}

case $1 in
    -h|--help)
	help
	;;
    aws)
	s3_verify $4   # Review the Access keys for the Azure Blob/AWS S3
	aws_s3 $2 $3
	;;
	az)
	blob_verify $4
	az_blob $2 $3
	;;
esac


