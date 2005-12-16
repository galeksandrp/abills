#!/bin/sh

AUTH_LOG=/usr/abills/var/log/abills.log
ACCT_LOG=/usr/abills/var/log/acct.log


echo $1 

echo `pwd -P`;

if [ t$1 = 'tauth' ] ; then

  ./rauth.pl \
        USER_NAME="aa1" \
        USER_PASSWORD="test123" \
        CALLED_STATION_ID="00-09-E8-62-B3-4D" \
        CALLING_STATION_ID="00-07-E9-19-72-1B" \
        SERVICE_TYPE="Login-User"\
        NAS_PORT_TYPE=Wireless-802.11 \
        NAS_PORT=66\
        NAS_IP_ADDRESS=192.168.101.17 \
        NAS_IDENTIFIER="ap" \
        ACCT_MULTI_SESSION_ID="" 

#     USER_NAME="aa1" \
#     NAS_IP_ADDRESS=192.168.101.17 \
#     SERVICE_TYPE=Framed-User \
#     CALLING_STATION_ID="192.168.101.4" \
#     MS_CHAP_CHALLENGE=0x36303131333831363438383235383730 \
#     MS_CHAP2_RESPONSE=0x010043e7c3db656fb14dc7546f9f0e4b9c810000000000000000ae86198b1adcfc9a092469d5073c7595de1b6e784c8b7bc7 \
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
        ACCT_INPUT_OCTETS=13409 \
        ACCT_INPUT_GIGAWORDS=0 \
        ACCT_INPUT_PACKETS=25 \
        ACCT_OUTPUT_OCTETS=0 \
        ACCT_OUTPUT_GIGAWORDS=0 \
        ACCT_OUTPUT_PACKETS=0 \
        ACCT_SESSION_TIME=113975 \



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


elif [ t$1 = 'tvoip' ] ; then 

 echo "Voip";
  if [ t$2 = 'tauth' ] ; then
   echo Auth;
   ./rauth.pl NAS_IP_ADDRESS="192.168.101.17" \
     CHAP_PASSWORD="0x06a8f3fb0ab5f4a8e90a590686c845c456" \
     NAS_PORT_TYPE="Virtual" \
     NAS_IDENTIFIER="ASMODEUSGK" \
     CLIENT_IP_ADDRESS="192.168.101.17" \
     CISCO_AVPAIR="h323-ivr-out=terminal-alias:100;" \
     SERVICE_TYPE="Login-User" \
     CHAP_CHALLENGE="0x43a28c01" \
     USER_NAME="100" \ 
     FRAMED_IP_ADDRESS="192.168.101.23" \
     HUNTGROUP_NAME="voips"   

  elif [ t$2 = 'tstart' ] ; then
    echo "Start\n";
   ./racct.pl  ACCT_UNIQUE_SESSION_ID=e5a1624d4211242c \
   H323_CONF_ID=h323-conf-id="FF8E71DC 7FF41810 93FA0001 6CC7CC03"\
   NAS_PORT_TYPE=Virtual \
   H323_CALL_ORIGIN="h323-call-origin=proxy" \
   NAS_IDENTIFIER=ASMODEUSGK \
   CLIENT_IP_ADDRESS=192.168.101.17 \
   CISCO_AVPAIR=h323-ivr-out="h323-call-id:FF8E71DC 7FF41810 93F90001 6CC7CC03"\
   ACCT_STATUS_TYPE=Start \
   SERVICE_TYPE=Login-User \
   H323_SETUP_TIME="h323-setup-time=14:24:55.000 EET Mon Nov 28 2005"\
   USER_NAME=600 \
   NAS_IP_ADDRESS=192.168.101.17 \
   H323_GW_ID="h323-gw-id=ASMODEUSGK" \
   CALLING_STATION_ID=600 \
   H323_REMOTE_ADDRESS="h323-remote-address=192.168.101.23"\
   ACCT_SESSION_ID=438af3510000000b \
   FRAMED_IP_ADDRESS=192.168.101.4 \
   ACCT_DELAY_TIME=0 \
   H323_CALL_TYPE="h323-call-type=VoIP" \
   CALLED_STATION_ID=101 \
   ACCT_SESSION_TIME=200 

   elif [ t$2 = 'tstop' ] ; then
    echo "Voip Stop"
   ./racct.pl ACCT_UNIQUE_SESSION_ID="f7989e8399e9ea8f" \
    H323_CONF_ID="h323-conf-id=513F6C41 96F41810 862E0001 6CC7CC03" \
    NAS_PORT_TYPE="Virtual"\
    H323_CALL_ORIGIN="h323-call-origin=proxy"\
    NAS_IDENTIFIER="ASMODEUSGK"\
    CLIENT_IP_ADDRESS="192.168.101.17" \
    CISCO_AVPAIR="h323-ivr-out=h323-call-id:513F6C41 96F41810 862D0001 6CC7CC03" \
    H323_DISCONNECT_CAUSE="h323-disconnect-cause=10"\
    ACCT_STATUS_TYPE="Stop"\
    SERVICE_TYPE="Login-User"\
    H323_SETUP_TIME="h323-setup-time=17:34:51.000 EET Fri Dec 09 2005"\
    H323_DISCONNECT_TIME="h323-disconnect-time=17:35:03.000 EET Fri Dec 09 2005"\
    USER_NAME="600"  \
    NAS_IP_ADDRESS="192.168.101.17"\
    ACCT_SESSION_TIME="9"\
    H323_GW_ID="h323-gw-id=ASMODEUSGK"\
    CALLING_STATION_ID="600"\
    H323_CONNECT_TIME="h323-connect-time=17:34:54.000 EET Fri Dec 09 2005"\
    H323_REMOTE_ADDRESS="h323-remote-address=192.168.101.23"\
    ACCT_SESSION_ID="438c20f800000015"\
    FRAMED_IP_ADDRESS="192.168.101.4"\
    H323_CALL_TYPE="h323-call-type=VoIP"\
    CALLED_STATION_ID="101"\
    ACCT_DELAY_TIME="0"

 fi

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

