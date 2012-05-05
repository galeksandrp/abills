#!/bin/sh


#Freebsd version
SUDO=/usr/local/bin/sudo
IPFW=/sbin/ipfw
DEBUG=""

#Check neg deposit speed
CHECK_NEG_DEPOSIT_SPEED=`grep abills_neg_deposit_speed /etc/rc.conf`


if [ x${CHECK_NEG_DEPOSIT_SPEED} = x ]; then
  echo "Content-Type: text/plain";
  echo "Neg deposit speed disable"
  exit;
fi;

if [ x${DEBUG} != x ]; then
echo "Content-Type: text/plain";
echo ""
CMD="${SUDO} ${IPFW} table 32 delete ${REMOTE_ADDR}"
echo ${CMD}
echo
env
fi;

${CMD}

if [ x${HTTP_REFERER} != x ]; then
   if [ x${QUERY_STRING} != x ]; then
     REDIRECT_LINK=`echo "${QUERY_STRING}" | sed 's/redirect=//'`    
     echo "Location: http://${REDIRECT_LINK}";
     echo
   else 
     echo "Content-Type: text/html";
     echo ""
   
     echo "Limited mode activated";
  fi;
fi;


