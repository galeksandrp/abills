package Auth;
# Auth functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = ();
%EXPORT_TAGS = ();

# User name expration
#my $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$"; # configurable;
use main;
@ISA  = ("main");
my $db;
my $conf;

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $conf) = @_;
  my $self = { };
  bless($self, $class);
  #$self->{debug}=1;

  if (! defined($conf->{KBYTE_SIZE})) {
  	 $conf->{KBYTE_SIZE}=1024;
  	}

  return $self;
}


#**********************************************************
# User authentication
# authentication($RAD_HASH_REF, $NAS_HASH_REF, $attr)
#
# return ($r, $RAD_PAIRS_REF);
#**********************************************************
sub authentication {
  my $self = shift;
  my ($RAD, $NAS, $attr) = @_;
  
 
  my $SECRETKEY = (defined($attr->{SECRETKEY})) ? $attr->{SECRETKEY} : '';
  my %RAD_PAIRS = ();
  
#  $self->query($db, "select
#  u.uid,
#  if (u.logins=0, tp.logins, u.logins) AS logins,
#  if(u.filter_id != '', u.filter_id, tp.filter_id),
#  if(u.ip>0, INET_NTOA(u.ip), 0),
#  INET_NTOA(u.netmask),
#  u.tp_id,
#  DECODE(password, '$SECRETKEY'),
#  u.speed,
#  u.cid,
#  tp.day_time_limit,
#  tp.week_time_limit,
#  tp.month_time_limit,
#  if(tp.day_time_limit=0 and tp.dt='0:00:00' AND tp.ut='24:00:00',
#   UNIX_TIMESTAMP(DATE_FORMAT(DATE_ADD(curdate(), INTERVAL 1 MONTH), '%Y-%m-01')) - UNIX_TIMESTAMP(),
#  if(curtime() < tp.ut, TIME_TO_SEC(tp.ut)-TIME_TO_SEC(curtime()), TIME_TO_SEC('23:00:00')-TIME_TO_SEC(curtime())) 
#    ) as today_limit,
#  day_traf_limit,
#
#  week_traf_limit,
#  month_traf_limit,
#  tp.octets_direction,
# 
#  if (count(un.uid) + count(tp_nas.tp_id) = 0, 0,
#    if (count(un.uid)>0, 1, 2)),
#  count(tt.id),
#  tp.hourp,
#  UNIX_TIMESTAMP(),
#  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
#  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
#  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())),
#  u.account_id,
#  u.disable,
#  
#  u.deposit,
#  u.credit,
#  tp.credit_tresshold,
#  if(tp.hourp + tp.day_fee + tp.month_fee=0 and (sum(tt.in_price + tt.out_price)=0 or sum(tt.in_price + tt.out_price)IS NULL), 0, 1),
#  tp.max_session_duration,
#  if(v.dt < v.ut,
#    if(v.dt < CURTIME() and v.ut > CURTIME(), 1, 0),
#      if((v.dt < CURTIME() or (CURTIME() > '0:00:00' and CURTIME() < v.ut ))
#       and
#       (CURTIME() < '23:00:00' or v.ut > CURTIME()  ),
#     1, 0 ))
#
#     FROM users u, tarif_plans tp
#     LEFT JOIN  trafic_tarifs tt ON (tt.tp_id=u.tp_id)
#     LEFT JOIN users_nas un ON (un.uid = u.uid)
#     LEFT JOIN tp_nas ON (tp_nas.tp_id = tp.id)
#     WHERE u.tp_id=tp.id
#        AND u.id='$RAD->{USER_NAME}'
#        AND (u.expire='0000-00-00' or u.expire > CURDATE())
#        AND (u.activate='0000-00-00' or u.activate <= CURDATE())
#        AND tp.dt < CURTIME()
#        AND CURTIME() < tp.ut
#       GROUP BY u.id;");



  $self->query($db, "select
  u.uid,
  if (u.logins=0, tp.logins, u.logins) AS logins,
  if(u.filter_id != '', u.filter_id, tp.filter_id),
  if(u.ip>0, INET_NTOA(u.ip), 0),
  INET_NTOA(u.netmask),
  u.tp_id,
  DECODE(password, '$SECRETKEY'),
  u.speed,
  u.cid,
  tp.day_time_limit,
  tp.week_time_limit,
  tp.month_time_limit,

  if(tp.day_time_limit=0 and tp.dt='0:00:00' AND tp.ut='24:00:00',
   UNIX_TIMESTAMP(DATE_FORMAT(DATE_ADD(curdate(), INTERVAL 1 MONTH), '%Y-%m-01')) - UNIX_TIMESTAMP(),
  if(curtime() < tp.ut, TIME_TO_SEC(tp.ut)-TIME_TO_SEC(curtime()), TIME_TO_SEC('23:00:00')-TIME_TO_SEC(curtime()))
    ) as today_limit,
  day_traf_limit,

  week_traf_limit,
  month_traf_limit,
  tp.octets_direction,

  if (count(un.uid) + count(tp_nas.tp_id) = 0, 0,
    if (count(un.uid)>0, 1, 2)),
  tp.hourp,
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  u.account_id,
  u.disable,

  u.deposit,
  u.credit,
  tp.credit_tresshold,
  if(tp.hourp + tp.day_fee + tp.month_fee=0 and (sum(tt.in_price + tt.out_price)=0 or sum(tt.in_price + tt.out_price)IS NULL), 0, 1),
  tp.max_session_duration,
  UNIX_TIMESTAMP(DATE_FORMAT(DATE_ADD(curdate(), INTERVAL 1 MONTH), '%Y-%m-01')) - UNIX_TIMESTAMP()
     FROM users u, tarif_plans tp
     LEFT JOIN trafic_tarifs tt ON (tt.tp_id=u.tp_id)
     LEFT JOIN users_nas un ON (un.uid = u.uid)
     LEFT JOIN tp_nas ON (tp_nas.tp_id = tp.id)
     WHERE u.tp_id=tp.id
        AND u.id='$RAD->{USER_NAME}'
        AND (u.expire='0000-00-00' or u.expire > CURDATE())
        AND (u.activate='0000-00-00' or u.activate <= CURDATE())
        AND tp.dt < CURTIME()
        AND CURTIME() < tp.ut
       GROUP BY u.id;

");


  if($self->{errno}) {
  	$RAD_PAIRS{'Reply-Message'}='SQL error';
  	return 1, \%RAD_PAIRS;
   }
  elsif ($self->{TOTAL} < 1) {
    $RAD_PAIRS{'Reply-Message'}="Login Not Exist";
    return 1, \%RAD_PAIRS;
   }

  my $a_ref = $self->{list}->[0];

  ($self->{UID}, 
     $self->{LOGINS}, 
     $self->{FILTER}, 
     $self->{IP}, 
     $self->{NETMASK}, 
     $self->{TP_ID}, 
     $self->{PASSWD}, 
     $self->{USER_SPEED}, 
     $self->{CID},
     $self->{DAY_TIME_LIMIT},  $self->{WEEK_TIME_LIMIT},   $self->{MONTH_TIME_LIMIT},
     $self->{DAY_TRAF_LIMIT},  $self->{WEEK_TRAF_LIMIT},   $self->{MONTH_TRAF_LIMIT}, $self->{OCTETS_DIRECTION},
     $self->{NAS}, 
     $self->{COUNT_TRAF_TARIFS},
     $self->{TIME_TARIF},
     $self->{SESSION_START}, 
     $self->{DAY_BEGIN}, 
     $self->{DAY_OF_WEEK}, 
     $self->{DAY_OF_YEAR},
     $self->{ACCOUNT_ID},
     $self->{DISABLE},
     
     
     $self->{DEPOSIT},
     $self->{CREDIT},
     $self->{CREDIT_TRESSHOLD},
     $self->{TP_PAYMENT},
     $self->{MAX_SESSION_DURATION},
     $self->{TIME_LIMIT},
    ) = @$a_ref;




#return 0, \%RAD_PAIRS;

#DIsable
print $self->{DISABLE};
if ($self->{DISABLE}) {
  $RAD_PAIRS{'Reply-Message'}="Account Disable";
  return 1, \%RAD_PAIRS;
}


#Chack Company account if ACCOUNT_ID > 0
if ($self->{ACCOUNT_ID} > 0) {
  $self->query($db, "SELECT deposit + credit, disable FROM accounts WHERE id='$self->{ACCOUNT_ID}';");
  if($self->{errno}) {
  	$RAD_PAIRS{'Reply-Message'}="SQL error";
  	return 1, \%RAD_PAIRS;
   }
  elsif ($self->{TOTAL} < 1) {
    $RAD_PAIRS{'Reply-Message'}="Company Not Exist";
    return 1, \%RAD_PAIRS;
   }

  my $a_ref = $self->{list}->[0];

  ($self->{DEPOSIT},
   $self->{DISABLE},
    ) = @$a_ref;

}

$self->{DEPOSIT}=$self->{DEPOSIT}+$self->{CREDIT}-$self->{CREDIT_TRESSHOLD};

#Check allow nas server
# $nas 1 - See user nas
#      2 - See tp nas
 if ($self->{NAS} > 0) {
   my $sql;
   if ($self->{NAS} == 1) {
      $sql = "SELECT un.uid FROM users_nas un WHERE un.uid='$self->{UID}' and un.nas_id='$NAS->{NID}'";
     }
   else {
      $sql = "SELECT nas_id FROM tp_nas WHERE tp_id='$self->{TP_ID}' and nas_id='$NAS->{NID}'";
     }

   $self->query($db, "$sql");
   if ($self->{TOTAL} < 1) {
     $RAD_PAIRS{'Reply-Message'}="You are not authorized to log in $NAS->{NID} ($RAD->{NAS_IP_ADDRESS})";
     return 1, \%RAD_PAIRS;
    }
  }

#Check CID (MAC) 
if ($self->{CID} ne '') {
   if ($self->{CID} =~ /:/ && $self->{CID} !~ /\//) {
      my @MAC_DIGITS_NEED=split(/:/, $self->{CID});
      my @MAC_DIGITS_GET=split(/:/, $RAD->{CALLING_STATION_ID});
      for(my $i=0; $i<=5; $i++) {
        if(hex($MAC_DIGITS_NEED[$i]) != hex($MAC_DIGITS_GET[$i])) {
          $RAD_PAIRS{'Reply-Message'}="Wrong MAC '$RAD->{CALLING_STATION_ID}'";
          return 1, \%RAD_PAIRS, "Wrong MAC '$RAD->{CALLING_STATION_ID}'";
         }
       }
    }
   elsif($self->{CID} =~ /\//) {
     $RAD->{CALLING_STATION_ID} =~ s/ //g;
     my ($cid_ip, $cid_mac, $trash) = split(/\//, $RAD->{CALLING_STATION_ID}, 3);
     if ("$cid_ip/$cid_mac" ne $self->{CID}) {
       $RAD_PAIRS{'Reply-Message'}="Wrong CID '$cid_ip/$cid_mac'";
       return 1, \%RAD_PAIRS;
      }
    }
   elsif($self->{CID} ne $RAD->{CALLING_STATION_ID}) {
     $RAD_PAIRS{'Reply-Message'}="Wrong CID '$RAD->{CALLING_STATION_ID}'";
     return 1, \%RAD_PAIRS;
    }
}







#Auth chap
if (defined($RAD->{CHAP_PASSWORD}) && defined($RAD->{CHAP_CHALLENGE})) {
  if (check_chap("$RAD->{CHAP_PASSWORD}", "$self->{PASSWD}", "$RAD->{CHAP_CHALLENGE}", 0) == 0) {
    $RAD_PAIRS{'Reply-Message'}="Wrong CHAP password '$self->{PASSWD}'";
    return 1, \%RAD_PAIRS;
   }      	 	
 }
#Auth MS-CHAP v1,v2
elsif(defined($RAD->{MS_CHAP_CHALLENGE})) {
  # Its an MS-CHAP V2 request
  # See draft-ietf-radius-ms-vsa-01.txt,
  # draft-ietf-pppext-mschap-v2-00.txt, RFC 2548, RFC3079
  $RAD->{MS_CHAP_CHALLENGE} =~ s/^0x//;
  my $challenge = pack("H*", $RAD->{MS_CHAP_CHALLENGE});
  my ($usersessionkey, $lanmansessionkey, $ms_chap2_success);

  if (defined($RAD->{MS_CHAP2_RESPONSE})) {
     $RAD->{MS_CHAP2_RESPONSE} =~ s/^0x//; 
     my $rad_response = pack("H*", $RAD->{MS_CHAP2_RESPONSE});
     my ($ident, $flags, $peerchallenge, $reserved, $response) = unpack('C C a16 a8 a24', $rad_response);

     if (check_mschapv2("$RAD->{USER_NAME}", $self->{PASSWD}, $challenge, $peerchallenge, $response, $ident,
 	     \$usersessionkey, \$lanmansessionkey, \$ms_chap2_success) == 0) {
         $RAD_PAIRS{'MS-CHAP-Error'}="\"Wrong MS-CHAP2 password\"";
         $RAD_PAIRS{'Reply-Message'}=$RAD_PAIRS{'MS-CHAP-Error'};
         return 1, \%RAD_PAIRS;
	    }

     $RAD_PAIRS{'MS-CHAP2-SUCCESS'} = '0x' . bin2hex($ms_chap2_success);
     my ($send, $recv) = Radius::MSCHAP::mppeGetKeys($usersessionkey, $response, 16);


# MPPE Sent/Recv Key Not realizet now.
#        print "\n--\n'$usersessionkey'\n'$response'\n'$send'\n'$recv'\n--\n";
#        $RAD_PAIRS{'MS-MPPE-Send-Key'}="0x".bin2hex( substr(encode_mppe_key($send, $radsecret, $challenge), 0, 16));
#	       $RAD_PAIRS{'MS-MPPE-Recv-Key'}="0x".bin2hex( substr(encode_mppe_key($recv, $radsecret, $challenge), 0, 16));

#        my $radsecret = 'test';
#         $RAD_PAIRS{'MS-MPPE-Send-Key'}="0x".bin2hex(encode_mppe_key($send, $radsecret, $challenge));
#	       $RAD_PAIRS{'MS-MPPE-Recv-Key'}="0x".bin2hex(encode_mppe_key($recv, $radsecret, $challenge));

#        $RAD_PAIRS{'MS-MPPE-Send-Key'}='0x4f835a2babe6f2600a731fd89ef25a38';
#	       $RAD_PAIRS{'MS-MPPE-Recv-Key'}='0x27ac8322247937ad3010161f1d5bbe5c';
	       
        }
       else {
         my $message;
         if (check_mschap("$self->{PASSWD}", "$RAD->{MS_CHAP_CHALLENGE}", "$RAD->{MS_CHAP_RESPONSE}", 
	           \$usersessionkey, \$lanmansessionkey, \$message) == 0) {
           $message = "Wrong MS-CHAP password";
           $RAD_PAIRS{'MS-CHAP-Error'}="\"$message\"";
           $RAD_PAIRS{'Reply-Message'}=$message;
           return 1, \%RAD_PAIRS;
          }
        }

       $RAD_PAIRS{'MS-CHAP-MPPE-Keys'} = '0x' . unpack("H*", (pack('a8 a16', $lanmansessionkey, 
														$usersessionkey))) . "0000000000000000";

       # 1      Encryption-Allowed 
       # 2      Encryption-Required 
       $RAD_PAIRS{'MS-MPPE-Encryption-Policy'} = '0x00000001';
       $RAD_PAIRS{'MS-MPPE-Encryption-Types'} = '0x00000006';      
 }
#End MSchap auth
elsif($NAS->{NAS_AUTH_TYPE} == 1) {
  if (check_systemauth("$RAD->{USER_NAME}", "$RAD->{USER_PASSWORD}") == 0) { 
    $RAD_PAIRS{'Reply-Message'}="Wrong password '$RAD->{USER_PASSWORD}' $NAS->{NAS_AUTH_TYPE}";
    return 1, \%RAD_PAIRS;
   }
 } 
#If don't athorize any above methods auth PAP password
else {
  if($self->{PASSWD} ne "$RAD->{USER_PASSWORD}") {
    $RAD_PAIRS{'Reply-Message'}="Wrong password '$RAD->{USER_PASSWORD}'";
    return 1, \%RAD_PAIRS;
   }
}

#Check deposit
if($self->{TP_PAYMENT} > 0 && $self->{DEPOSIT}  <= 0) {
  $RAD_PAIRS{'Reply-Message'}="Negativ deposit '$self->{DEPOSIT}'. Rejected!";
  return 1, \%RAD_PAIRS;
 }

#Check  simultaneously logins if needs
if ($self->{LOGINS} > 0) {
  $self->query($db, "SELECT count(*) FROM calls WHERE user_name='$RAD->{USER_NAME}' and status <> 2;");
  
  my $a_ref = $self->{list}->[0];
  my($active_logins) = @$a_ref;
  if ($active_logins >= $self->{LOGINS}) {
    $RAD_PAIRS{'Reply-Message'}="More then allow login ($self->{LOGINS}/$active_logins)";
    return 1, \%RAD_PAIRS;
   }
}





my @time_limits = ();
my ($remaining_time, $ATTR) = remaining_time2($self->{TP_ID}, $self->{DEPOSIT}, 
                                      $self->{SESSION_START}, 
                                      $self->{DAY_BEGIN}, 
                                      $self->{DAY_OF_WEEK}, 
                                      $self->{DAY_OF_YEAR},
                                      { mainh_tarif => $self->{TIME_TARIF},
                                        time_limit  => $self->{TODAY_LIMIT}  } 
                                      );

if (defined($ATTR->{TT})) {
  $self->{TT_INTERVAL} = $ATTR->{TT};
}
else {
  $self->{TT_INTERVAL} = 0;
}

#check allow period and time out
 if ($remaining_time == -1) {
 	  $RAD_PAIRS{'Reply-Message'}="Not Allow day";
    return 1, \%RAD_PAIRS;
  }
 elsif ($remaining_time == -2) {
    $RAD_PAIRS{'Reply-Message'}="Not Allow time";
    return 1, \%RAD_PAIRS;
  }
 elsif($remaining_time > 0) {
    push (@time_limits, $remaining_time);
  }

#Periods Time and traf limits
# 0 - Total limit
# 1 - Day limit
# 2 - Week limit
# 3 - Month limit
my @traf_limits = ();
my $time_limit  = $self->{TIME_LIMIT}; 
my $traf_limit  = $attr->{MAX_SESSION_TRAFFIC};

push @time_limits, $self->{MAX_SESSION_DURATION} if ($self->{MAX_SESSION_DURATION} > 0);

my @periods = ('DAY', 'WEEK', 'MONTH');

foreach my $line (@periods) {
     if (($self->{$line . '_TIME_LIMIT'} > 0) || ($self->{$line . '_TRAF_LIMIT'} > 0)) {
        $self->query($db, "SELECT if(". $self->{$line . '_TIME_LIMIT'} ." > 0, ". $self->{$line . '_TIME_LIMIT'} ." - sum(duration), 0),
                                  if(". $self->{$line . '_TRAF_LIMIT'} ." > 0, ". $self->{$line . '_TRAF_LIMIT'} ." - sum(sent + recv) / 1024 / 1024, 0) 
            FROM log
            WHERE uid='$self->{UID}' and DATE_FORMAT(start, '%Y-%m-%d')=curdate()
            GROUP BY DATE_FORMAT(start, '%Y-%m-%d');");

        if ($self->{TOTAL} == 0) {
          push (@time_limits, $self->{$line . '_TIME_LIMIT'}) if ($self->{$line . '_TIME_LIMIT'} > 0);
          push (@traf_limits, $self->{$line . '_TRAF_LIMIT'}) if ($self->{$line . '_TRAF_LIMIT'} > 0);
         } 
        else {
        	$a_ref = $self->{list}->[0];
          my ($time_limit, $traf_limit) = @$a_ref;
          push (@time_limits, $time_limit) if ($self->{$line . '_TIME_LIMIT'} > 0);
          push (@traf_limits, $traf_limit) if ($self->{$line . '_TRAF_LIMIT'} > 0);
         }
       }
}


#set traffic limit
#push (@traf_limits, $prepaid_traff) if ($prepaid_traff > 0);

 for(my $i=0; $i<=$#traf_limits; $i++) {
 	 #print $traf_limits[$i]. "------\n";
   if ($traf_limit > $traf_limits[$i]) {
     $traf_limit = int($traf_limits[$i]);
    }
  }

 if($traf_limit < 0) {
   $RAD_PAIRS{'Reply-Message'}="Rejected! Traffic limit utilized '$traf_limit Mb'";
   return 1, \%RAD_PAIRS;
  }



#set time limit
 for(my $i=0; $i<=$#time_limits; $i++) {
   if ($time_limit > $time_limits[$i]) {
     $time_limit = $time_limits[$i];
    }
  }

 if ($time_limit > 0) {
   $RAD_PAIRS{'Session-Timeout'} = "$time_limit";
  }
 elsif($time_limit < 0) {
   $RAD_PAIRS{'Reply-Message'}="Rejected! Time limit utilized '$time_limit'";
   return 1, \%RAD_PAIRS;
  }

# Return radius attr    
 if ($self->{IP} ne '0') {
   $RAD_PAIRS{'Framed-IP-Address'} = "$self->{IP}";
  }
 else {
   my $ip = $self->get_ip($NAS->{NID}, "$RAD->{NAS_IP_ADDRESS}");
   if ($ip eq '-1') {
     $RAD_PAIRS{'Reply-Message'}="Rejected! There is no free IPs in address pools ($NAS->{NID})";
     return 1, \%RAD_PAIRS;
    }
   elsif($ip eq '0') {
     $RAD_PAIRS{'Reply-Message'}="$self->{errstr} ($NAS->{NID})";
     return 1, \%RAD_PAIRS;
    }
   else {
     $RAD_PAIRS{'Framed-IP-Address'} = "$ip";
    }
  }

  $RAD_PAIRS{'Framed-IP-Netmask'} = "$self->{NETMASK}";
  $RAD_PAIRS{'Filter-Id'} = "$self->{FILTER}" if (length($self->{FILTER}) > 0); 



####################################################################
# Vendor specific return
# ExPPP

if ($NAS->{NAS_TYPE} eq 'exppp') {
  #$traf_tarif 
  my $EX_PARAMS = $self->ex_traffic_params( { 
  	                                        traf_limit => $traf_limit, 
                                            deposit => $self->{DEPOSIT},
                                            MAX_SESSION_TRAFFIC => $attr->{MAX_SESSION_TRAFFIC} });

  #global Traffic
  if ($EX_PARAMS->{traf_limit} > 0) {
    $RAD_PAIRS{'Exppp-Traffic-Limit'} = $EX_PARAMS->{traf_limit} * 1024 * 1024;
   }

  #Local traffic
  if ($EX_PARAMS->{traf_limit_lo} > 0) {
    $RAD_PAIRS{'Exppp-LocalTraffic-Limit'} = $EX_PARAMS->{traf_limit_lo} * 1024 * 1024 ;
   }
       
  #Local ip tables
  if (defined($EX_PARAMS->{nets})) {
    $RAD_PAIRS{'Exppp-Local-IP-Table'} = "\"$attr->{NETS_FILES_PATH}$self->{TT_INTERVAL}.nets\"";
   }

  #Shaper
  if ($self->{USER_SPEED} > 0) {
    $RAD_PAIRS{'Exppp-Traffic-Shape'} = int($self->{USER_SPEED});
   }
  else {
    if ($EX_PARAMS->{speed}  > 0) {
      $RAD_PAIRS{'Exppp-Traffic-Shape'} = $EX_PARAMS->{speed};
     }
   }
=comments
        print "Exppp-Traffic-In-Limit = $trafic_inlimit,";
        print "Exppp-Traffic-Out-Limit = $trafic_outlimit,";
        print "Exppp-LocalTraffic-In-Limit = $trafic_lo_inlimit,";
        print "Exppp-LocalTraffic-Out-Limit = $trafic_lo_outlimit,";
=cut
 }
###########################################################
# MPD
elsif ($NAS->{NAS_TYPE} eq 'mpd') {
  my $EX_PARAMS = $self->ex_traffic_params({ 
  	                                        traf_limit => $traf_limit, 
                                            deposit => $self->{DEPOSIT},
                                            MAX_SESSION_TRAFFIC => $attr->{MAX_SESSION_TRAFFIC} });

  #global Traffic
  if ($EX_PARAMS->{traf_limit} > 0) {
    $RAD_PAIRS{'Exppp-Traffic-Limit'} = $EX_PARAMS->{traf_limit} * 1024 * 1024;
   }
       
#Shaper
#  if ($uspeed > 0) {
#    $RAD_PAIRS{'mpd-rule'} = "\"1=pipe %p1 ip from any to any\"";
#    $RAD_PAIRS{'mpd-pipe'} = "\"1=bw ". $uspeed ."Kbyte/s\"";
#   }
#  else {
#    if ($v_speed > 0) {
#      $RAD_PAIRS{'Exppp-Traffic-Shape'} = $v_speed;
#      $RAD_PAIRS{'mpd-rule'} = "1=pipe %p1 ip from any to any";
#      $RAD_PAIRS{'mpd-pipe'} = "1=bw ". $v_speed ."Kbyte/s";
#     }
#   }
 }
###########################################################
# pppd + RADIUS plugin (Linux) http://samba.org/ppp/
elsif ($NAS->{NAS_TYPE} eq 'pppd') {
  my $EX_PARAMS = $self->ex_traffic_params( { 
  	                                        traf_limit => $traf_limit, 
                                            deposit => $self->{DEPOSIT},
                                            MAX_SESSION_TRAFFIC => $attr->{MAX_SESSION_TRAFFIC} });

  #global Traffic
  if ($EX_PARAMS->{traf_limit} > 0) {
    $RAD_PAIRS{'Session-Octets-Limit'} = $EX_PARAMS->{traf_limit} * 1024 * 1024;
    $RAD_PAIRS{'Octets-Direction'} = 0;
   }
 }

#Auto assing MAC in first connect
if( defined($conf->{MAC_AUTO_ASSIGN}) && 
       $conf->{MAC_AUTO_ASSIGN}==1 && 
       $self->{CID} eq '' && 
       ( $RAD->{CALLING_STATION_ID} =~ /:/ && $RAD->{CALLING_STATION_ID} !~ /\// )
      ) {
#  print "ADD MAC___\n";
  $self->query($db, "UPDATE users SET cid='$RAD->{CALLING_STATION_ID}'
     WHERE uid='$self->{UID}';", 'do');
}


#OK
  return 0, \%RAD_PAIRS, '';
}


#*******************************************************************
# Extended traffic parameters
# ex_params($tp_id)
#*******************************************************************
sub ex_traffic_params {
 my ($self, $attr) = @_;	

 my $traf_limit = $attr->{traf_limit};
 my $deposit = (defined($attr->{deposit})) ? $attr->{deposit} : 0;

 my %EX_PARAMS = ();
 $EX_PARAMS{speed}=0;
 $EX_PARAMS{traf_limit}=0;
 $EX_PARAMS{traf_limit_lo}=0;

 my %prepaids = ();
 my %speeds = ();
 my %in_prices = ();
 my %out_prices = ();
 my %trafic_limits = ();
 
 
 #get traffic limits
# if ($traf_tarif > 0) {
   my $nets = 0;
#$self->{debug}=1;
   $self->query($db, "SELECT id, in_price, out_price, prepaid, speed, LENGTH(nets) FROM trafic_tarifs
             WHERE interval_id='$self->{TT_INTERVAL}';");

   if ($self->{TOTAL} < 1) {
     return \%EX_PARAMS;	
    }

   my $list = $self->{list};
   foreach my $line (@$list) {
     $prepaids{$line->[0]}=$line->[3];
     $in_prices{$line->[0]}=$line->[1];
     $out_prices{$line->[0]}=$line->[2];
     $speeds{$line->[0]}=$line->[4];
     $nets+=$line->[5];
    }

   $EX_PARAMS{nets}=$nets if ($nets > 20);
   $EX_PARAMS{speed}=int($speeds{0}) if (defined($speeds{0}));

#  }
# else {
#   return %EX_PARAMS;	
#  }


if ((defined($prepaids{0}) || defined($prepaids{0})) && ($prepaids{0}+$prepaids{1}>0)) {
  $self->query($db, "SELECT sum(sent+recv) / 1024 / 1024, sum(sent2+recv2) / 1024 / 1024 FROM log 
     WHERE uid='$self->{UID}' and DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')
     GROUP BY DATE_FORMAT(start, '%Y-%m');");

  if ($self->{TOTAL} == 0) {
    $trafic_limits{0}=$prepaids{0};
    $trafic_limits{1}=$prepaids{1};
   }
  else {
    my $used = $self->{list}->[0];

    if ($used->[0] < $prepaids{0}) {
      $trafic_limits{0}=$prepaids{0} - $used->[0];
     }
    elsif($in_prices{0} + $out_prices{0} > 0) {
      $trafic_limits{0} = ($deposit / (($in_prices{0} + $out_prices{0}) / 2));
     }

    if ($used->[1]  < $prepaids{1}) {
      $trafic_limits{1}=$prepaids{1} - $used->[1];
     }
    elsif($in_prices{1} + $out_prices{1} > 0) {
      $trafic_limits{1} = ($deposit / (($in_prices{1} + $out_prices{1}) / 2));
     }
   }
   
 }
else {
  if ($in_prices{0}+$out_prices{0} > 0) {
    $trafic_limits{0} = ($deposit / (($in_prices{0} + $out_prices{0}) / 2));
   }

  if ($in_prices{1}+$out_prices{1} > 0) {
    $trafic_limits{1} = ($deposit / (($in_prices{1} + $out_prices{1}) / 2));
   }
  else {
    $trafic_limits{1} = 0;
   }
}

#Traffic limit


my $trafic_limit = 0;
if ($trafic_limits{0} > 0 || $traf_limit > 0) {
  if($trafic_limits{0} > $traf_limit && $traf_limit > 0) {
    $trafic_limit = $traf_limit;
   }
  elsif($trafic_limits{0} > 0) {
    #$trafic_limit = $trafic_limit * 1024 * 1024;
    #2Gb - (2048 * 1024 * 1024 ) - global traffic session limit
    $trafic_limit = ($trafic_limits{0} > $attr->{MAX_SESSION_TRAFFIC}) ? $attr->{MAX_SESSION_TRAFFIC} :  $trafic_limits{0};
   }
  else {
  	$trafic_limit = $traf_limit;
   }

  $EX_PARAMS{traf_limit} = int($trafic_limit);
}

#Local Traffic limit
if ($trafic_limits{1} > 0) {
  #10Gb - (10240 * 1024 * 1024) - local traffic session limit
  $trafic_limit = ($trafic_limits{1} > 10240) ? 10240 :  $trafic_limits{1};
  $EX_PARAMS{traf_limit_lo} = int($trafic_limit);
 }

 return \%EX_PARAMS;
}



#*******************************************************************
# returns:
#   -1 - No free adddress
#    0 - No address pool using nas servers ip address
#   192.168.101.1 - assign ip address
#
# get_ip($self, $nas_num, $nas_ip)
#*******************************************************************
sub get_ip {
 my $self = shift;
 my ($nas_num, $nas_ip) = @_;

 use IO::Socket;
 
#get ip pool
 $self->query($db, "SELECT ippools.ip, ippools.counts 
  FROM ippools
  WHERE ippools.nas='$nas_num';");

 if ($self->{TOTAL} < 1)  {
     $self->{errno}=1;
     $self->{errstr}='No ip pools';
     return 0;	
  }

 my %pools = ();
 my $list = $self->{list};
 foreach my $line (@$list) {
    my $sip   = $line->[0]; 
    my $count = $line->[1];

    for(my $i=$sip; $i<=$sip+$count; $i++) {
       $pools{$i}=undef;
     }
   }

#get active address and delete from pool

 $self->query($db, "SELECT framed_ip_address
  FROM calls 
  WHERE nas_ip_address=INET_ATON('$nas_ip') and (status=1 or status>=3);");

 $list = $self->{list};
 my %used_ips = ();
 while(my($ip) = each %$list) {
   if(exists($pools{$ip})) {
      delete($pools{$ip});
     }
   }
 
 my ($assign_ip, undef) = each(%pools);
 if ($assign_ip) {
   $assign_ip = inet_ntoa(pack('N', $assign_ip));
   return $assign_ip; 	
  }
 else { # no addresses available in pools
   return -1;
  }

 return 0;
}



#********************************************************************
# System auth function
# check_systemauth($user, $password)
#********************************************************************
sub check_systemauth {
 my ($user, $password)= @_;

 if ($< != 0) {
   log_print('LOG_ERR', "For system Authentification you need root privileges");
   exit 1;
  }

 my @pw = getpwnam("$user");

 if ($#pw < 0) {
    return 0;
  }
 
 my $salt = "$pw[1]";
 my $ep = crypt($password, $salt);

 if ($ep eq $pw[1]) {
    return 1;
  }
 else {
    return 0;
  }
}


#*******************************************************************
# Check chap password
# check_chap($given_password,$want_password,$given_chap_challenge,$debug) 
#*******************************************************************
sub check_chap {
 eval { require Digest::MD5; };
 if (! $@) {
    Digest::MD5->import();
   }
 else {
    log_print('LOG_ERR', "Can't load 'Digest::MD5' check http://www.cpan.org");
  }

my ($given_password,$want_password,$given_chap_challenge,$debug) = @_;

        $given_password =~ s/^0x//;
        $given_chap_challenge =~ s/^0x//;
        my $chap_password = pack("H*", $given_password);
        my $chap_challenge = pack("H*", $given_chap_challenge);
        my $md5 = new Digest::MD5;
        $md5->reset;
        $md5->add(substr($chap_password, 0, 1));
        $md5->add($want_password);
        $md5->add($chap_challenge);
        my $digest = $md5->digest();
        if ($digest eq substr($chap_password, 1)) { 
           return 1; 
          }
        else {
           return 0;
          }

}



#********************************************************************
# remaining_time
#  returns
#    -1 = access deny not allow day
#    -2 = access deny not allow hour
#********************************************************************
sub remaining_time2 {
  my ($tp_id, $deposit, $session_start, 
  $day_begin, $day_of_week, $day_of_year,
  $attr) = @_;
  
  my %ATTR = ();

  my $debug = 0;
 
  my $time_limit = (defined($attr->{time_limit})) ? $attr->{time_limit} : 0;
  my $mainh_tarif = (defined($attr->{mainh_tarif})) ? $attr->{mainh_tarif} : 0;
  my $remaining_time = 0;

  use Billing;
  my $Billing = Billing->new($db);
  my ($time_intervals, $periods_time_tarif, $periods_traf_tarif) = $Billing->time_intervals($tp_id);

 if ($time_intervals == 0) {
    return 0;
    #return $deposit / $mainh_tarif * 60 * 60;	
  }
 
 my %holidays = ();
 if (defined($time_intervals->{8})) {
   use Tariffs;
   my $tariffs = Tariffs->new($db);
   my $list = $tariffs->holidays_list({ format => 'daysofyear' });
   foreach my $line (@$list) {
     $holidays{$line->[0]} = 1;
    }
  }


 my $tarif_day = 0;
 my $count = 0;
 $session_start = $session_start - $day_begin;

# print "$session_start 
#  $day_of_week, 
#  $day_of_year,\n";

 while(($deposit > 0 && $count < 50)) {
  
   if ($time_limit != 0 && $time_limit < $remaining_time) {
     $remaining_time = $time_limit;
     last;
    }

   if(defined($holidays{$day_of_year}) && defined($time_intervals->{8})) {
    	#print "Holliday tarif '$day_of_year' ";
    	$tarif_day = 8;
    }
   elsif (defined($time_intervals->{$day_of_week})) {
    	#print "Day tarif '$day_of_week'";
    	$tarif_day = $day_of_week;
    }
   elsif(defined($time_intervals->{0})) {
      #print "Global tarif";
      $tarif_day = 0;
    }
   elsif($count > 0) {
      last;
    }
   else {
   	  return -1;
    }


  print "Count:  $count Remain Time: $remaining_time\n" if ($debug == 1);

  # Time check
  # $session_start

     $count++;
     #print "$count) Tariff day: $tarif_day ($day_of_week / $day_of_year)\n";
     #print "Session start: $session_start\n";
     #print "Deposit: $deposit\n--------------\n";

     my $cur_int = $time_intervals->{$tarif_day};
     my $i;
     
     TIME_INTERVALS:

     my @intervals = sort keys %$cur_int; 
     $i = -1;

     #while(my($int_begin, $int_end)=each ) {
     foreach my $int_begin (@intervals) {
       my ($int_id, $int_end) = split(/:/, $cur_int->{$int_begin}, 2);
       $i++;

       my $price = 0;
       my $int_prepaid = 0;
       my $int_duration = 0;

       print "Day: $tarif_day Session_start: $session_start => Int Begin: $int_begin End: $int_end Int ID: $int_id\n" if ($debug == 1);

       if ($int_begin <= $session_start && $session_start < $int_end) {
          $int_duration = $int_end-$session_start;
          
          if ($periods_time_tarif->{$int_id} =~ /%$/) {
             my $tp = $periods_time_tarif->{$int_id};
             $tp =~ s/\%//;
             $price = $mainh_tarif  * ($tp / 100);
           }
          else {
             $price = $periods_time_tarif->{$int_id};
           }

          if($periods_traf_tarif->{$int_id} > 0 && $remaining_time == 0) {
            print "This tarif with traffic counts\n" if ($debug == 1);
            $ATTR{TT}=$int_id;
            return int($int_duration), \%ATTR;
           }
          elsif($periods_traf_tarif->{$int_id} > 0) {
            print "Next tarif with traffic counts  $int_end {$tarif_day} {$int_begin}\n" if ($debug == 1);
            return int($remaining_time), \%ATTR;
           }
          elsif ($price > 0) {
            $int_prepaid = $deposit / $price * 3600;
           }
          else {
            $int_prepaid = $int_duration;	
           }
          #print "Int Begin: $int_begin Int duration: $int_duration Int prepaid: $int_prepaid Prise: $price\n";



          if ($int_prepaid >= $int_duration) {
            $deposit -= ($int_duration / 3600 * $price);
            $session_start += $int_duration;
            $remaining_time += $int_duration;
            #print "DP $deposit ($int_prepaid > $int_duration) $session_start\n";
           }
          elsif($int_prepaid <= $int_duration) {
            $deposit =  0;    	
            $session_start += $int_prepaid;
            $remaining_time += $int_prepaid;
            #print "DL '$deposit' ($int_prepaid <= $int_duration) $session_start\n";
           }
        }
       elsif($i == $#intervals) {
       	  print "!! LAST@@@@ $i == $#intervals\n" if ($debug == 1);
       	  if (defined($time_intervals->{0}) && $tarif_day != 0) {
       	    $tarif_day = 0;
       	    $cur_int = $time_intervals->{$tarif_day};
       	    print "Go to\n" if ($debug == 1);
       	    goto TIME_INTERVALS;
       	   }
       	  elsif($session_start < 86400) {
      	  	 if ($remaining_time > 0) {
      	  	   return int($remaining_time);
      	  	  }
             else {
             	 # Not allow hour
             	 # return -2;
              }
      	   }
       	  #return $remaining_time;
       	  next;
        }
      }

  return -2 if ($remaining_time == 0);
  
  if ($session_start >= 86400) {
    $session_start=0;
    $day_of_week = ($day_of_week + 1 > 7) ? 1 : $day_of_week+1;
    $day_of_year = ($day_of_year + 1 > 365) ? 1 : $day_of_year + 1;
   }
#  else {
#  	return int($remaining_time), \%ATTR;
#   }
 
 }

return int($remaining_time), \%ATTR;
}



#***********************************************************
# bin2hex()
#***********************************************************
sub bin2hex ($) {
 my $bin = shift;
 my $hex = '';
 
 for my $c (unpack("H*",$bin)){
   $hex .= $c;
 }

 return $hex;
}



#*******************************************************************
# Authorization module
# pre_auth()
#*******************************************************************
sub pre_auth {
  my ($self, $login, $RAD, $attr)=@_;

if (! $RAD->{MS_CHAP_CHALLENGE}) {
  print "Auth-Type := Accept\n";
  exit 0;
 }

  $self->query('db', "SELECT DECODE(password, '$attr->{SECRETKEY}') FROM users WHERE id='$login';");

  if ($self->{TOTAL} > 0) {
  	my $list = $self->{list}->[0];
    my $password = $list->[0];
    print "User-Password == \"$password\"";
    exit 0;
   }

  $self->{errno} = 1;
  $self->{errstr} = "USER: '$login' not exist";
  exit 1;
}



















1
