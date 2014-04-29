#!/bin/sh
# Message filter managment script
# Add, del filters

version=0.2
DEBUG=0;
IP=$1;
MYSQL_USER=root;
MYSQL_DB=abills;
MYSQL_HOST=localhost
MYSQL=`which mysql`

if [ x"${MYSQL}" = x ]; then
  MYSQL=/usr/local/bin/mysql
fi;

MSGS_TABLE_NUM=100

if [ w$1 = w ]; then
  echo "Add arguments";
  exit
fi;

ACTION=$1
UID=$2

#OS
OS=`uname`;

if [ x"${OS}" = "FreeBSD" ]; then

  #Add online filter
  if [ w"${ACTION}" = wadd ]; then
    SQL="select INET_NTOA(framed_ip_address) from dv_calls WHERE uid IN (${UID});";
    OUTPUT=`${MYSQL} -h ${MYSQL_HOST} -D ${MYSQL_DB} -u ${MYSQL_USER} -e "${SQL}"`;

    for LINE in ${OUTPUT}; do
  
      IP=`echo ${LINE} | awk '{ print $1 }'`;
   #   UID=`echo ${LINE} | awk '{ print $2 }'`;
   
      if [ "${IP}" != 'INET_NTOA(framed_ip_address)' ]; then
        if [ w${DEBUG} != w ]; then
          echo "/sbin/ipfw table ${MSGS_TABLE_NUM} add ${IP} ${UID}";
        fi;

        /sbin/ipfw table ${MSGS_TABLE_NUM} add ${IP} ${UID}
      fi;
    
    done;
  # Del redirect  
  else 
    if [ w${DEBUG} != w ]; then
      echo "IP deleted - ${IP}"
    fi;
    /sbin/ipfw table ${MSGS_TABLE_NUM} delete ${IP}
  fi;

else
#If OS linux



fi;
