#!/bin/bash
if [ "$1" != "" ]; then
	DB_USER=$1
	DB_PASS=$2
	DB_NAME=$3
else
	DB_USER="exampleusr"
	DB_PASS="examplepw"
	DB_NAME="exampled"
fi

mysql -u root << EOF
create database $DB_NAME;
grant usage on *.* to $DB_USER@localhost identified by '$DB_PASS';
grant all privileges on $DB_NAME.* to $DB_USER@localhost ;
flush privileges;
EOF
