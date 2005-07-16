#!/bin/sh

AUTH_LOG=/usr/abills/var/log/abills.log
ACCT_LOG=/usr/abills/var/log/acct.log


echo $1 

echo `pwd -P`;

if [ t$1 = 'tauth' ] ; then

  ./rauth.pl \
     USER_NAME="aa1" \
     NAS_IP_ADDRESS=192.168.101.17 \
     SERVICE_TYPE=Framed-User \
     USER_PASSWORD="test123" \
     CALLING_STATION_ID="00:d:61:79:ed:d1"

#     MS_CHAP_CHALLENGE=0x32323738343134393536353333333635 \
#     MS_CHAP2_RESPONSE=0x010017550ce222cfa39d348b93e93cd26f1a000000000000000026fe1a5e39097393b8a4ade5a466790bbefab075383ec58b \
#     USER_PASSWORD="4vYE2vKM" \


#     CALLING_STATION_ID="00:20:ed:9c:c3:43"\
#     CALLED_STATION_ID=pppoe\
#     CHAP_CHALLENGE=0x31323331333337363130353537333539 \
#     CHAP_PASSWORD=0x01456e3b61d9102cb9985bc4bf995120c2 \
#     USER_PASSWORD="qPTvEwAE" \

   echo "\nAuth test end"


elif [ t$1 = 'tacct' ]; then
   echo "Accounting test";

  ./racct.pl \
        USER_NAME="aa1" \
        SERVICE_TYPE=Framed-User \
        FRAMED_PROTOCOL=PPP \
        FRAMED_IP_ADDRESS=10.0.0.1 \
        FRAMED_IP_NETMASK=0.0.0.0 \
        CALLING_STATION_ID="192.168.101.4" \
        NAS_IP_ADDRESS=192.168.101.17 \
        NAS_IDENTIFIER="media.intranet" \
        NAS_PORT_TYPE=Virtual \
        ACCT_STATUS_TYPE=Stop \
        ACCT_SESSION_ID="83419_AA11118757979" \
        USER_NAME="aa1" \
        ACCT_DELAY_TIME=0 \
        ACCT_INPUT_OCTETS=3409 \
        ACCT_INPUT_GIGAWORDS=0 \
        ACCT_INPUT_PACKETS=25 \
        ACCT_OUTPUT_OCTETS=0 \
        ACCT_OUTPUT_GIGAWORDS=0 \
        ACCT_OUTPUT_PACKETS=0 \
        ACCT_SESSION_TIME=175 \



#      ACCT_SESSION_ID=sessin_82762626 \
#      USER_NAME="aa1" \
#      FRAMED_IP_ADDRESS=192.168.101.200 \
#      NAS_IP_ADDRESS=192.168.101.132 \
#      ACCT_STATUS_TYPE=Alive \
#      ACCT_SESSION_TIME=1000 \
#      ACCT_TERMINATE_CAUSE=0 \
#      ACCT_INPUT_OCTETS=3000 \
#      ACCT_OUTPUT_OCTETS=231726 \
#      CALLING_STATION_ID="" \
#      SERVICE_TYPE="Framed-User" \

#      NAS_PORT=10 \
#      EXPPP_ACCT_ITERIUMIN_OCTETS=0 \
#      EXPPP_ACCT_ITERIUMOUT_OCTETS=0 \
#      EXPPP_ACCT_LOCALITERIUMIN_OCTETS=0 \
#      EXPPP_ACCT_LOCALITERIUMOUT_OCTETS=0 \
#      EXPPP_ACCT_LOCALINPUT_OCTETS=0 \
#      EXPPP_ACCT_LOCALOUTPUT_OCTETS=0 \


 

elif [ t$1 = 'tacctgt' ]; then

  echo "Account requirest GT: "
  cat $ACCT_LOG | grep GT | awk '{ print $11"  "$1" "$2" "$5" "$8" "$9 }' | sort -n


elif [ t$1 = 'tauthgt' ]; then

  cat $AUTH_LOG | grep GT | awk '{ print $10"  "$1" "$2" "$5" "$8 }' | sort -n

else 
 echo "Arguments (auth | acct | authgt | acctgt)"
 echo "       auth - test authentification
       acct - test accounting
       authgt - show authentification generation time
       acctgt - show account generation time
  "
fi

#   CHAP_PASSWORD=0x01f45d3646ef51e0b34dfca50f17f0d524 \
#   CHAP_CHALLENGE=0x36373035393933393135333537313734 \

