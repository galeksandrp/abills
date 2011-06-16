#!/bin/sh
# Shaper/NAT/Session upper for ABillS 
#
# PROVIDE: abills_shaper
# REQUIRE: NETWORKING mysql vlan_up 
#traffic Class numbers

. /etc/rc.subr

# Add the following lines to /etc/rc.conf to enable abills_shapper:
#
#   abills_shaper_enable="YES" - Enable abills shapper
#
#   abills_shaper_if="" - ABillS shepper interface default ng*
#
#   abills_nas_id="" - ABillS NAS ID default 1
#
#   abills_ip_sessions="" - ABIllS IP SEssions limit
#
#   abills_nat="EXTERNAL_IP:INTERNAL_IPS:NAT_IF" - Enable abills nat
#
#   abills_dhcp_shaper=""  (bool) :  Set to "NO" by default.
#                                    Enable ipoe_shaper
#

name="abills_shaper"
rcvar=`set_rcvar`
load_rc_config $name
run_rc_command "$1"


CLASSES_NUMS='2 3'
VERSION=5.2

if [ w${abills_shaper_enable} = w ]; then
  exit;
fi;

#Negative deposit forward (default: )
NEG_DEPOSIT_FWD=${abills_neg_deposit};
FWD_WEB_SERVER_IP=127.0.0.1;
#Your user portal IP (Default: me)
USER_PORTAL_IP=

#Session Limit per IP
SESSION_LIMIT=${abills_ip_sessions}

IPFW=/sbin/ipfw
SED=/usr/bin/sed
BILLING_DIR=/usr/abills

if [ w${abills_shaper_if} != w ]; then
  INTERNAL_INTERFACE=${abills_shaper_if}
else 
  EXTERNAL_INTERFACE=`/sbin/route get default | grep interface: | awk '{ print $2 }'`
  INTERNAL_INTERFACE="ng*"
fi;


#Octets direction
PKG_DIRECTION=`cat ${BILLING_DIR}/libexec/config.pl | grep octets_direction | ${SED} "s/\\$conf{octets_direction}='\(.*\)'.*/\1/"`

if [ w${PKG_DIRECTION} = wuser ] ; then
  IN_DIRECTION="in recv ${INTERNAL_INTERFACE}"
  OUT_DIRECTION="out xmit ${INTERNAL_INTERFACE}"
else
  IN_DIRECTION="out xmit ${EXTERNAL_INTERFACE}"
  OUT_DIRECTION="in recv ${EXTERNAL_INTERFACE}"
fi; 



#Enable NG shapper
if [ w != w`grep '^\$conf{ng_car}=1;' /usr/abills/libexec/config.pl` ]; then
  NG_SHAPPER=1
fi;

#Main users table num
USERS_TABLE_NUM=10
#First Class traffic users
USER_CLASS_TRAFFIC_NUM=10
ACTION=$1
echo -n ${ACTION}
if [ w${ACTION} = wfaststart ]; then
  ACTION=start
fi;

#NG Shaper enable
if [ w${ACTION} = wstart -a w$2 = w -a w${NG_SHAPPER} != w ]; then
  echo -n "ng_car shapper"
  #Load kernel modules
  kldload ng_ether
  kldload ng_car
  kldload ng_ipfw

for num in ${CLASSES_NUMS}; do
  #  FW_NUM=`expr  `;
    echo "Traffic: ${num} "

  #Shaped traffic
  ${IPFW} add ` expr 10000 - ${num} \* 10 ` skipto ` expr 10100 + ${num} \* 10 ` ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to table\(${num}\) ${IN_DIRECTION}
  ${IPFW} add ` expr 10000 - ${num} \* 10 + 5 ` skipto ` expr 10100 + ${num} \* 10 + 5 ` ip from table\(${num}\) to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) ${OUT_DIRECTION}


  ${IPFW} add ` expr 10100 + ${num} \* 10 ` netgraph tablearg ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to any ${IN_DIRECTION}
  ${IPFW} add ` expr 10100 + ${num} \* 10 + 5 ` netgraph tablearg ip from any to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) ${OUT_DIRECTION}

  #Unlim traffic
  ${IPFW} add ` expr 10200 + ${num} \* 10 ` allow ip from table\(9\) to table\(${num}\) ${IN_DIRECTION}
  ${IPFW} add ` expr 10200 + ${num} \* 10 + 5 ` allow ip from table\(${num}\) to table\(9\) ${OUT_DIRECTION}
done;

  echo "Global shaper"
  ${IPFW} add 10000 netgraph tablearg ip from table\(10\) to any ${IN_DIRECTION}
  ${IPFW} add 10010 netgraph tablearg ip from any to table\(11\) ${OUT_DIRECTION}
  ${IPFW} add 10020 allow ip from table\(9\) to any ${IN_DIRECTION}
  ${IPFW} add 10025 allow ip from any to table\(9\) ${OUT_DIRECTION}
  if [ ${INTERNAL_INTERFACE} = w"ng*" ]; then
    ${IPFW} add 10030 allow ip from any to any via ${INTERNAL_INTERFACE} 
  fi;
#done
#Stop ng_car shaper
else if [ w${ACTION} = wstop -a w$2 = w ]; then
  echo -n "ng_car shapper" 

  for num in ${CLASSES_NUMS}; do
    ${IPFW} delete ` expr 9100 + ${num} \* 10 + 5 ` ` expr 9100 + ${num} \* 10 `  ` expr 9000 + ${num} \* 10 ` ` expr 10100 + ${num} \* 10 ` ` expr 9000 + ${num} \* 10 + 5 ` ` expr 10100 + ${num} \* 10 + 5 ` 
  done;

  ${IPFW} delete 9000 9005 10000 10010 10015
else if [ w${ACTION} = w ]; then
    echo "(start|stop|start nat|stop nat)"
#Start DUMMYNET shaper
else   
  echo "DUMMYNET shaper"
  if [ w${abills_nas_id} = w ]; then
    abills_nas_id=1;
  fi;

  /usr/abills/libexec/billd checkspeed NAS_IDS=${abills_nas_id} RECONFIGURE=1 FW_DIRECTION_OUT="${OUT_DIRECTION}" FW_DIRECTION_IN="${IN_DIRECTION}";
  if [ ${firewall_type} = "/etc/fw.conf" ]; then
    ${IPFW} ${firewall_type}
  fi;
  fi;
 fi;
fi;



#IPoE Shapper for dhcp connections
if [ w${abills_dhcp_shaper} != w ]; then
  /usr/abills/libexec/ipoe_shapper.pl -d
fi;


#ipfw 10 add divert 8668 ip from 3.3.3.0/24 to any
#ipfw 20 add divert 8778 ip from 4.4.4.0/24 to any
#ipfw 30 add fwd 1.1.1.254 ip from 1.1.1.1 to any
#ipfw 40 add fwd 2.2.2.254 ip from 2.2.2.2 to any
#ipfw 50 add divert 8668 ip from any to 1.1.1.1
#ipfw 60 add divert 8778 ip from any to 2.2.2.2 

#NAT Section
# options         IPFIREWALL_FORWARD
# options         IPFIREWALL_NAT          #ipfw kernel nat support
# options         LIBALIAS

#Nat Section
if [ w"${abills_nat}" != w ] ; then
# NAT External IP
NAT_IPS=`echo ${abills_nat} | awk -F: '{ print $1 }'`;
# Fake net 
FAKE_NET=`echo ${abills_nat} | awk -F: '{ print $2 }'`;
#NAT IF
NAT_IF=`echo ${abills_nat} | awk -F: '{ print $3 }'`;



echo "NAT"
NAT_TABLE=20
NAT_FIRST_RULE=20
NAT_REAL_TO_FAKE_TABLE_NUM=33;
NAT_FAKE_IP_TABLE_NUM=33;

# nat configuration
for IP in ${NAT_IPS}; do
  if [ w${ACTION} = wstart ]; then
    ${IPFW} nat ` expr ${NAT_FIRST_RULE} + 1 ` config ip ${IP} log
    ${IPFW} table ${NAT_REAL_TO_FAKE_TABLE_NUM} add ${IP} ` expr ${NAT_FIRST_RULE} + 1 `

    for f_net in ${FAKE_NET}; do
      ${IPFW} table ` expr ${NAT_REAL_TO_FAKE_TABLE_NUM} + 1` add ${f_net} ` expr ${NAT_FIRST_RULE} + 1 `
    done;
  fi;
done;

  # ISP_GW2=1 For redirect to second way
  if [ w${ISP_GW2} != w ]; then
    #Second way
    GW2_IF_IP="192.168.0.2"
    GW2_IP="192.168.0.1"
    GW2_REDIRECT_IPS="10.0.0.0/24"
    NAT_ID=22
    #Fake IPS
    ${IPFW} table ${NAT_REAL_TO_FAKE_TABLE_NUM} add ${GW2_IF_IP} ${FWD_NAT_ID}
    #NAT configure
    ${IPFW} nat ${NAT_ID} config ip ${EXT_IP} log
    #Redirect to second net IPS
    for ip_mask in ${GW2_REDIRECT_IPS} ; do
      ${IPFW} table ` expr ${NAT_REAL_TO_FAKE_TABLE_NUM} + 1` add ${ip_mask} ${NAT_ID}
    done;

    #Forward traffic 2 second way
    ${IPFW}  add 60015 fwd ${GW2_IP} ip from ${GW2_IF_IP} to any
    #${IPFW} add 30 add fwd ${ISP_GW2} ip from ${NAT_IPS} to any
  fi;

# UP NAT
if [ w${ACTION} = wstart ]; then
  if [ w${NAT_IF} != w ]; then
    NAT_IF="via ${NAT_IF}"
  fi;

  ${IPFW} add 60010 nat tablearg ip from table\(` expr ${NAT_REAL_TO_FAKE_TABLE_NUM} + 1 `\) to any $NAT_IF
  ${IPFW} add 60020 nat tablearg ip from any to table\(${NAT_REAL_TO_FAKE_TABLE_NUM}\) $NAT_IF
else if [ w$1 = wstop ]; then
  ${IPFW} delete 60010 60020 60015
fi;
fi;

fi;


#FWD Section
if [ w${NEG_DEPOSIT_FWD} != w ]; then
  if [ w${WEB_SERVER_IP} = w ]; then
    FWD_WEB_SERVER_IP=127.0.0.1;
  fi;
  
  if [ w${DNS_IP} = w ]; then
    DNS_IP=`cat /etc/resolv.conf | grep nameserver | awk '{ print $2 }' | head -1`
  fi;

  if [ w${USER_PORTAL_IP} = w ]; then
    USER_PORTAL_IP=me
  fi;

FWD_RULE=10014;

#Forwarding start
if [ w${ACTION} = wstart ]; then
  echo "Negative Deposit Forward Section - start"; 
  ${IPFW} add ${FWD_RULE} fwd ${FWD_WEB_SERVER_IP},80 tcp from table\(32\) to any dst-port 80,443 via ${INTERNAL_INTERFACE}
  #If use proxy
  #${IPFW} add ${FWD_RULE} fwd ${FWD_WEB_SERVER_IP},3128 tcp from table\(32\) to any dst-port 3128 via ${INTERNAL_INTERFACE}
  ${IPFW} add `expr ${FWD_RULE} + 10` allow ip from table\(32\) to ${DNS_IP} dst-port 53 via ${INTERNAL_INTERFACE}
  ${IPFW} add `expr ${FWD_RULE} + 20` allow tcp from table\(32\) to ${USER_PORTAL_IP} dst-port 9443 via ${INTERNAL_INTERFACE}
  ${IPFW} add `expr ${FWD_RULE} + 30` deny ip from table\(32\) to any via ${INTERNAL_INTERFACE}
else if [ w${ACTION} = wstop ]; then
  echo "Negative Deposit Forward Section - stop:"; 
  ${IPFW} delete ${FWD_RULE} ` expr ${FWD_RULE} + 10 ` ` expr ${FWD_RULE} + 20 ` ` expr ${FWD_RULE} + 30 `
else if [ w${ACTION} = wshow ]; then
  echo "Negative Deposit Forward Section - status:"; 
  ${IPFW} show ${FWD_RULE}
fi;
fi;
fi;

fi;


#Session limit section
if [ w${SESSION_LIMIT} != w ]; then
  echo "Session limit ${SESSION_LIMIT}";
  if [ w${ACTION} = wstart ]; then
    ${IPFW} add 00400   skipto 65010 tcp from table\(34\) to any dst-port 80,443 via ${INTERNAL_INTERFACE}
    ${IPFW} add 00401   skipto 65010 udp from table\(34\) to any dst-port 53 via ${INTERNAL_INTERFACE}
    ${IPFW} add 00402   skipto 60010 tcp from table\(34\) to any via ${EXTERNAL_INTERFACE}
    ${IPFW} add 64001   allow tcp from table\(34\) to any setup via ${INTERNAL_INTERFACE} in limit src-addr ${SESSION_LIMIT}
    ${IPFW} add 64002   allow udp from table\(34\) to any via ${INTERNAL_INTERFACE} in limit src-addr ${SESSION_LIMIT}
    ${IPFW} add 64003   allow icmp from table\(34\) to any via ${INTERNAL_INTERFACE} in limit src-addr ${SESSION_LIMIT}
  else if [ w${ACTION} = wstop ]; then
    ${IPFW} delete 00400 00401 00402 64001 64002 64003
   fi; 
  fi;
fi;

