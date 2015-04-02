#!/bin/bash
while getopts ":m:o:p:r:s:t:u:v:" opt; do
	case $opt in
            m) BACKUP_TYPE="$OPTARG" ;;
            o) LOCAL_USER="$OPTARG" ;;
            p) LOCAL_PATH="$OPTARG" ;;
            r) XFER_PORT="$OPTARG" ;;
            s) XFER_HOST="$OPTARG" ;;
            t) XFER_METHOD="$OPTARG" ;;
            u) XFER_USER="$OPTARG" ;;
            v) XFER_PATH="$OPTARG" ;;
	esac
done

LOG_FILE="/var/log/kt-backup.log"
DATE_NOW=$(date +"%Y-%m-%d %H:%M")

if [[ "$LOCAL_USER" == "" ]]; then
        LOCAL_USER="root"
fi

if [[ "$XFER_PORT" == "" ]]; then
        XFER_PORT="22"
fi

if [ $BACKUP_TYPE = "file" ]; then
        BACKUP_NAME=$(basename $LOCAL_PATH)
fi

if [ $BACKUP_TYPE = "sql" ]; then
        BACKUP_NAME=$BACKUP_TYPE
fi

BACKUP_FILE="$(hostname)-$BACKUP_NAME-$(date +"%Y-%m-%d").tar.gz"
BACKUP_FILE="/tmp/$BACKUP_FILE"

if [ $BACKUP_TYPE = "file" ]; then
        tar -czf $BACKUP_FILE $LOCAL_PATH &> /dev/null
fi

if [ $BACKUP_TYPE = "sql" ]; then
        mysqldump -u $LOCAL_USER --all-databases | gzip > $BACKUP_FILE
fi

if [ $XFER_METHOD = "scp" ]; then
        scp -P $XFER_PORT $BACKUP_FILE $XFER_USER@$XFER_HOST:/$XFER_PATH &> /dev/null
fi

if [ $XFER_METHOD = "sftp" ]; then
sftp $XFER_USER@$XFER_HOST &> /dev/null <<END_XFER
lcd $LOCAL_PATH
cd $XFER_PATH
put $BACKUP_FILE
END_XFER
fi

if [ $XFER_METHOD = "cp" ]; then
        cp $BACKUP_FILE $XFER_PATH &> /dev/null
fi

echo "$DATE_NOW: Backup of server $(hostname) (Type: $BACKUP_TYPE)" >> $LOG_FILE
echo "$DATE_NOW: Backup File Name $(basename $BACKUP_FILE)" >> $LOG_FILE
echo "$DATE_NOW: Backup File Size $(ls -lah $BACKUP_FILE | awk '{ print $5}')"  >> $LOG_FILE

rm -f $BACKUP_FILE &> /dev/null
