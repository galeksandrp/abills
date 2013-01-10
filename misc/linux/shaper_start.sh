#!/bin/sh
#
#
#***********************************************************************

VERSION=1.01 
. /etc/rc.conf

name="abills_shaper" 
if [ x${abills_shaper_enable} = x ]; then
  name="abills_nat"
  abills_nat_enable=YES; 
fi;

TC="/sbin/tc"
IPT=/sbin/iptables 
SED=/bin/sed 
BILLING_DIR=/usr/abills


#Negative deposit forward (default: )
FWD_WEB_SERVER_IP=127.0.0.1;
#Your user portal IP 
USER_PORTAL_IP=${abills_portal_ip} 
EXTERNAL_INTERFACE=`/sbin/ip r | awk '/default/{print $5}'`



#**********************************************************
#
#**********************************************************

abills_shaper_start(){
  ACTION=start 

abills_iptables
abills_shaper 
abills_ipn 
abills_nat 
neg_deposit

}

#**********************************************************
#
#**********************************************************

abills_shaper_stop() {
  ACTION=stop 
abills_iptables
abills_shaper 
abills_ipn 
abills_nat 
neg_deposit
}


#**********************************************************
#IPTABLES RULES
#**********************************************************
abills_iptables() {

echo "ABillS Iptables ${ACTION}"

if [ x${ACTION} = xstart ];then
$IPT -P INPUT DROP
$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD DROP

# Включить на сервере интернет
$IPT -A INPUT -i lo -j ACCEPT
# Разрешить ping к серверу доступа
$IPT -A INPUT -p icmp -m icmp -j ACCEPT
# Разрешить SSH запросы к серверу
$IPT -A INPUT -p TCP -s 0/0  --dport 22 -j ACCEPT
# Разрешить DNS запросы к серверу
$IPT -A INPUT -p TCP -s 0/0  --sport 53 -j ACCEPT
$IPT -A INPUT -p TCP -s 0/0  --dport 53 -j ACCEPT
# Разрешить DHCP запросы к серверу
$IPT -A INPUT -p TCP -s 0/0  --sport 67 -j ACCEPT
$IPT -A INPUT -p TCP -s 0/0  --dport 67 -j ACCEPT
# Доступ к странице авторизации 
$IPT -A INPUT -p TCP -s 0/0  --sport 80 -j ACCEPT
$IPT -A INPUT -p TCP -s 0/0  --dport 80 -j ACCEPT
$IPT -A INPUT -p TCP -s 0/0  --sport 9443 -j ACCEPT
$IPT -A INPUT -p TCP -s 0/0  --dport 9443 -j ACCEPT
$IPT -A FORWARD -p tcp -m tcp -s 0/0 --dport 80 -j ACCEPT
$IPT -A FORWARD -p tcp -m tcp -s 0/0 --dport 9443 -j ACCEPT

if [ x${abills_ipn_if} != x ]; then
  IPN_INTERFACE=`echo ${abills_ipn_if} | sed 's/,/ /g'`

  # Перенаправление IPN клиентов
  for REDIRECT_IPN in ${IPN_INTERFACE}; do
    REDIRECT_POOL=`ip r |grep " ${REDIRECT_IPN} " | awk '{ print $1 }'`
    $IPT -t nat -A PREROUTING -s ${REDIRECT_POOL} -p tcp --dport 80 -j REDIRECT --to-ports 80
    $IPT -t nat -A PREROUTING -s ${REDIRECT_POOL} -p tcp --dport 443 -j REDIRECT --to-ports 80
    echo "Redirect UP ${REDIRECT_POOL}"
  done
else
 echo "unknown ABillS IPN IFACES"
fi;


elif [ x${ACTION} = xstop ]; then
  # Разрешаем всё и всем
  $IPT -P INPUT ACCEPT
  $IPT -P OUTPUT ACCEPT
  $IPT -P FORWARD ACCEPT

  # Чистим все правила
  $IPT -F
  $IPT -F -t nat
  $IPT -F -t mangle
  $IPT -X
  $IPT -X -t nat
  $IPT -X -t mangle
fi;
}



#**********************************************************
# Abills Shapper
#**********************************************************
abills_shaper() { 

  if [ x${abills_shaper_enable} = xNO ]; then
    return 0;
  elif [ x${abills_shaper_enable} = xNAT ]; then
    return 0;
  fi;

echo "ABillS Shapper ${ACTION}"

if [ x${ACTION} = xstart ];then
  for INTERFACE in ${IPN_INTERFACE}; do
    TCQA="${TC} qdisc add dev ${INTERFACE}"
    TCQD="${TC} qdisc del dev ${INTERFACE}"

    $TCQD root &>/dev/null
    $TCQD ingress &>/dev/null

    $TCQA root handle 1: htb
    $TCQA handle ffff: ingress

    echo "Shaper UP ${INTERFACE}"
  done

elif [ x${ACTION} = xstop ]; then
  for INTERFACE in ${IPN_INTERFACE}; do
    TCQA="${TC} qdisc add dev ${INTERFACE}"
    TCQD="${TC} qdisc del dev ${INTERFACE}"

    $TCQD root &>/dev/null
    $TCQD ingress &>/dev/null

    echo "Shaper DOWN ${INTERFACE}"
  done
fi;
}

#**********************************************************
#Ipn Sections
# Enable IPN
#**********************************************************
abills_ipn() {

if [ x${abills_ipn_nas_id} = x ]; then
  echo "unknown ABillS IPN NAS id"
  return 0;
fi;

if [ w${ACTION} = wstart ]; then
  echo "Enable users IPN"
  ${BILLING_DIR}/libexec/periodic monthly MODULES=Ipn SRESTART=1 NO_ADM_REPORT=1 NAS_IDS="${abills_ipn_nas_id}"
fi;

}

#**********************************************************
#
#**********************************************************

#**********************************************************
# Start custom shapper rules
#**********************************************************


#**********************************************************
#NAT Section
#**********************************************************
abills_nat() {
  if [ x"${abills_nat}" = x ]; then
    return 0;
  fi;

  echo "ABillS NAT ${ACTION}"
  # NAT External IP
  NAT_IPS=`echo ${abills_nat} | awk -F: '{ print $1 }'`;
  # Fake net
  FAKE_NET=`echo ${abills_nat} | awk -F: '{ print $2 }' | sed 's/,/ /g'`;
  #NAT IF
  NAT_IF=`echo ${abills_nat} | awk -F: '{ print $3 }'`;
  echo  "$NAT_IPS $FAKE_NET $NAT_IF"

  if [ w${ACTION} = wstart ]; then 
    echo "Enable NAT"
  elif [ x${ACTION} = xstop ]; then 
    echo "Disable NAT" 
  fi;
}
#**********************************************************
#Neg deposit FWD Section
#**********************************************************
neg_deposit() {
  echo "NEG_DEPOSIT in the development"
}

#############################Скрипт################################
case "$1" in start) echo -n "START : $name"
            echo ""
	    abills_shaper_start
	    echo "."
	    ;; 
	stop) echo -n "STOP : $name"
	    echo ""
	    abills_shaper_stop
	    echo "."
	    ;; 
	restart) echo -n "RESTART : $name"
	    echo ""
	    abills_shaper_stop
	    abills_shaper_start
	    echo "."
	    ;;
    *) echo "Usage: /etc/init.d/rc.iptables
 start|stop|restart|clear"
    exit 1
    ;; 
    esac 
    exit 0
