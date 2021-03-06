package Acct;
# Accounting functions
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
use main;
use Billing;

@ISA  = ("main");
my ($db, $conf);



my %ACCT_TYPES = ('Start'          => 1,
                  'Stop'           => 2,
                  'Alive'          => 3,
                  'Interim-Update' => 3,
                  'Accounting-On'  => 7,
                  'Accounting-Off' => 8
                  ); 





#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $conf) = @_;
  my $self = { };
  bless($self, $class);

  return $self;
}


#**********************************************************
# Accounting Work_
#**********************************************************
sub accounting {
 my $self = shift;
 my ($RAD, $NAS)=@_;
 

 my $acct_status_type = $ACCT_TYPES{$RAD->{ACCT_STATUS_TYPE}};
 my $SESSION_START = (defined($RAD->{SESSION_START}) && $RAD->{SESSION_START} > 0) ?  "FROM_UNIXTIME($RAD->{SESSION_START})" : "FROM_UNIXTIME(UNIX_TIMESTAMP())";

#   print "aaa $acct_status_type '$RAD->{ACCT_STATUS_TYPE}'  /$RAD->{SESSION_START}/"; 
#my $a=`echo "test $acct_status_type = $ACCT_TYPES{$RAD->{ACCT_STATUS_TYPE}}"  >> /tmp/12211 `;
 
 $RAD->{FRAMED_IP_ADDRESS} = '0.0.0.0' if(! defined($RAD->{FRAMED_IP_ADDRESS}));
 if (length($RAD->{ACCT_SESSION_ID}) > 25) {
 	  $RAD->{ACCT_SESSION_ID} = substr($RAD->{ACCT_SESSION_ID}, 0, 1);
  }
 
if ($RAD->{USER_NAME} =~ /(\d+):(\S+)/) {
  $RAD->{USER_NAME}=$2;
  $RAD->{CALLING_STATION_ID}=$1;
}  

#Start
if ($acct_status_type == 1) { 

  $self->query($db, "SELECT count(user_name) FROM dv_calls 
    WHERE user_name='$RAD->{USER_NAME}' and acct_session_id='$RAD->{ACCT_SESSION_ID}';");
    
  if ($self->{list}->[0]->[0] < 1) {
    #Get TP_ID
    $self->query($db, "SELECT dv.tp_id FROM (users u, dv_main dv)
     WHERE u.uid=dv.uid and u.id='$RAD->{USER_NAME}';");
    ($self->{TP_ID})= @{ $self->{list}->[0] };
    
    #Get connection speed 
    if ($RAD->{X_ASCEND_DATA_RATE} && $RAD->{X_ASCEND_XMIT_RATE}) {
      $RAD->{CONNECT_INFO}="$RAD->{X_ASCEND_DATA_RATE} / $RAD->{X_ASCEND_XMIT_RATE}";
     }

    # 
    my $sql = "INSERT INTO dv_calls
     (status, user_name, started, lupdated, nas_ip_address, nas_port_id, acct_session_id, acct_session_time,
      acct_input_octets, acct_output_octets, framed_ip_address, CID, CONNECT_INFO, nas_id, tp_id)
       values ('$acct_status_type', 
      \"$RAD->{USER_NAME}\", 
      $SESSION_START, 
      UNIX_TIMESTAMP(), 
      INET_ATON('$RAD->{NAS_IP_ADDRESS}'),
      '$RAD->{NAS_PORT}', 
      \"$RAD->{ACCT_SESSION_ID}\", 0, 0, 0, 
      INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), 
      '$RAD->{CALLING_STATION_ID}', 
      '$RAD->{CONNECT_INFO}', 
      '$NAS->{NAS_ID}',
      '$self->{TP_ID}');";
    $self->query($db, "$sql", 'do');
  }
 }
# Stop status
elsif ($acct_status_type == 2) {

  my $Billing = Billing->new($db, $conf);	

  if ( $NAS->{NAS_EXT_ACCT} || $NAS->{NAS_TYPE} eq 'ipcad') {

    $self->query($db, "SELECT 
       acct_input_octets,
       acct_output_octets,
       ex_input_octets,
       ex_output_octets,
       tp_id,
       sum
    FROM dv_calls 
    WHERE user_name='$RAD->{USER_NAME}' and acct_session_id='$RAD->{ACCT_SESSION_ID}';");

    if($self->{errno}) {
 	    return $self;
     }
    elsif ($self->{TOTAL} < 1) {
      $self->{errno}=2;
      $self->{errstr}="Session account Not Exist '$RAD->{ACCT_SESSION_ID}'";
      return $self;
     }

    (
     $RAD->{INBYTE},
     $RAD->{OUTBYTE},
     $RAD->{INBYTE2},
     $RAD->{OUTBYTE2},
     $self->{TARIF_PLAN},
     $self->{SUM}
    ) = @{ $self->{list}->[0] };

    ($self->{UID}, 
     undef, 
     $self->{BILL_ID}, 
     $self->{TARIF_PLAN}, 
     $self->{TIME_TARIF}, 
     $self->{TRAF_TARIF}) = $Billing->session_sum("$RAD->{USER_NAME}", 
                                                   $RAD->{SESSION_START}, 
                                                   $RAD->{ACCT_SESSION_TIME}, 
                                                   $RAD, 
                                                   { USER_INFO => 1 } );

    $self->query($db, "INSERT INTO dv_log (uid, start, tp_id, duration, sent, recv, minp,  
        sum, nas_id, port_id,
        ip, CID, sent2, recv2, acct_session_id, 
        bill_id,
        terminate_cause) 
        VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}), '$self->{TARIF_PLAN}', '$RAD->{ACCT_SESSION_TIME}', 
        '$RAD->{OUTBYTE}', '$RAD->{INBYTE}', '$self->{TIME_TARIF}', '$self->{SUM}', '$NAS->{NAS_ID}',
        '$RAD->{NAS_PORT}', INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), '$RAD->{CALLING_STATION_ID}',
        '$RAD->{OUTBYTE2}', '$RAD->{INBYTE2}',  \"$RAD->{ACCT_SESSION_ID}\", 
        '$self->{BILL_ID}',
        '$RAD->{ACCT_TERMINATE_CAUSE}');", 'do');
   }
  elsif ($conf->{rt_billing}) {
    $self->rt_billing($RAD, $NAS);

    if (! $self->{errno} ) {
      $self->query($db, "INSERT INTO dv_log (uid, start, tp_id, duration, sent, recv, minp, kb, sum, nas_id, port_id,
        ip, CID, sent2, recv2, acct_session_id, 
        bill_id,
        terminate_cause) 
        VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}), '$self->{TARIF_PLAN}', '$RAD->{ACCT_SESSION_TIME}', 
        '$RAD->{OUTBYTE}', '$RAD->{INBYTE}', '$self->{TIME_TARIF}', '$self->{TRAF_TARIF}', $self->{CALLS_SUM}+$self->{SUM}, '$NAS->{NAS_ID}',
        '$RAD->{NAS_PORT}', INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), '$RAD->{CALLING_STATION_ID}',
        '$RAD->{OUTBYTE2}', '$RAD->{INBYTE2}',  \"$RAD->{ACCT_SESSION_ID}\", 
        '$self->{BILL_ID}',
        '$RAD->{ACCT_TERMINATE_CAUSE}');", 'do');
     }      
    else {
      #$self->{errstr}    = "ACCT [$RAD->{USER_NAME}] Can't find sessions $RAD->{ACCT_SESSION_ID}";
      #$self->{sql_errstr}= '';
      #$self->{errno}     = 1;   
      return $self;      
     }     
   }
  else {
    my %EXT_ATTR = ();
    
    #Get connected TP
    $self->query($db, "SELECT tp_id, CONNECT_INFO FROM dv_calls
      WHERE
      acct_session_id=\"$RAD->{ACCT_SESSION_ID}\" and 
      user_name=\"$RAD->{USER_NAME}\" and
      nas_id='$NAS->{NAS_ID}';");

    ($EXT_ATTR{TP_ID}, $EXT_ATTR{CONNECT_INFO}) = @{ $self->{list}->[0] } if ($self->{TOTAL} > 0);
  
    ($self->{UID}, 
     $self->{SUM}, 
     $self->{BILL_ID}, 
     $self->{TARIF_PLAN}, 
     $self->{TIME_TARIF}, 
     $self->{TRAF_TARIF}) = $Billing->session_sum("$RAD->{USER_NAME}", 
                                                   $RAD->{SESSION_START}, 
                                                   $RAD->{ACCT_SESSION_TIME}, 
                                                   $RAD, 
                                                   \%EXT_ATTR );
  #  return $self;
    if ($self->{UID} == -2) {
      $self->{errno}  = 1;   
      $self->{errstr} = "ACCT [$RAD->{USER_NAME}] Not exist";
     }
    elsif($self->{UID} == -3) {
      my $filename   = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
      $RAD->{SQL_ERROR}="$Billing->{errno}:$Billing->{errstr}";
      $self->{errno} = 1;
      $self->{errstr}= "SQL Error ($Billing->{errstr}) SESSION: '$filename'";

      $Billing->mk_session_log($RAD);
      return $self;
     }
    elsif ($self->{SUM} < 0) {
      $self->{LOG_DEBUG} =  "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE})";
     }
    elsif ($self->{UID} <= 0) {
      $self->{LOG_DEBUG} =  "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE}), $self->{UID}";
     }
    else {
      $self->query($db, "INSERT INTO dv_log (uid, start, tp_id, duration, sent, recv, minp, kb,  sum, nas_id, port_id,
          ip, CID, sent2, recv2, acct_session_id, 
          bill_id,
          terminate_cause) 
          VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}), '$self->{TARIF_PLAN}', '$RAD->{ACCT_SESSION_TIME}', 
          '$RAD->{OUTBYTE}', '$RAD->{INBYTE}', '$self->{TIME_TARIF}', '$self->{TRAF_TARIF}', '$self->{SUM}', '$NAS->{NAS_ID}',
          '$RAD->{NAS_PORT}', INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), '$RAD->{CALLING_STATION_ID}',
          '$RAD->{OUTBYTE2}', '$RAD->{INBYTE2}',  \"$RAD->{ACCT_SESSION_ID}\", 
          '$self->{BILL_ID}',
          '$RAD->{ACCT_TERMINATE_CAUSE}');", 'do');
 
      if ($self->{errno}) {
        my $filename = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
        $self->{LOG_WARNING}="ACCT [$RAD->{USER_NAME}] Making accounting file '$filename'";
        $Billing->mk_session_log($RAD);
       }
  # If SQL query filed
      else {
        if ($self->{SUM} > 0) {
          $self->query($db, "UPDATE bills SET deposit=deposit-$self->{SUM} WHERE id='$self->{BILL_ID}';", 'do');
         }
       }
    }
}


  # Delete from session
  $self->query($db, "DELETE FROM dv_calls WHERE acct_session_id=\"$RAD->{ACCT_SESSION_ID}\" 
     and user_name=\"$RAD->{USER_NAME}\" 
     and nas_id='$NAS->{NAS_ID}';", 'do');
     
}
#Alive status 3
elsif($acct_status_type eq 3) {
  $self->{SUM}=0 if (! $self->{SUM}); 
 
  if ($NAS->{NAS_EXT_ACCT}) {
    $self->query($db, "UPDATE dv_calls SET
      status='$acct_status_type',
      nas_port_id='$RAD->{NAS_PORT}',
      acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
      acct_input_octets='$RAD->{INBYTE}',
      acct_output_octets='$RAD->{OUTBYTE}',
      ex_input_octets='$RAD->{INBYTE2}',
      ex_output_octets='$RAD->{OUTBYTE2}',
      framed_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'),
      lupdated=UNIX_TIMESTAMP(),
      sum=sum+$self->{SUM}
    WHERE
      acct_session_id=\"$RAD->{ACCT_SESSION_ID}\" and 
      user_name=\"$RAD->{USER_NAME}\" and
      nas_id='$NAS->{NAS_ID}';", 'do');

  	return $self;
   }
  elsif ($NAS->{NAS_TYPE} eq 'ipcad') {
    return $self;
   }
  elsif ($conf->{rt_billing}) {
    $self->rt_billing($RAD, $NAS);
   }
  
  $self->query($db, "UPDATE dv_calls SET
    status='$acct_status_type',
    nas_port_id='$RAD->{NAS_PORT}',
    acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
    acct_input_octets='$RAD->{INBYTE}',
    acct_output_octets='$RAD->{OUTBYTE}',
    ex_input_octets='$RAD->{INBYTE2}',
    ex_output_octets='$RAD->{OUTBYTE2}',
    framed_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'),
    lupdated=UNIX_TIMESTAMP(),
    sum=sum+$self->{SUM}
   WHERE
    acct_session_id=\"$RAD->{ACCT_SESSION_ID}\" and 
    user_name=\"$RAD->{USER_NAME}\" and
    nas_id='$NAS->{NAS_ID}';", 'do');
 }
else {
  $self->{errno}=1;
  $self->{errstr}="ACCT [$RAD->{USER_NAME}] Unknown accounting status: $RAD->{ACCT_STATUS_TYPE} ($RAD->{ACCT_SESSION_ID})";
}

  if ($self->{errno}) {
  	$self->{errno}=1;
  	$self->{errstr}="ACCT $RAD->{ACCT_STATUS_TYPE} SQL Error";
  	return $self;
   }

#detalization for Exppp
if ($conf->{s_detalization} eq 'yes') {
   $RAD->{INTERIUM_INBYTE}=0 if (! defined($RAD->{INTERIUM_INBYTE}));
   $RAD->{INTERIUM_OUTBYTE}=0 if (! defined($RAD->{INTERIUM_OUTBYTE}));
   $RAD->{INTERIUM_INBYTE2}=0 if (! defined($RAD->{INTERIUM_INBYTE2}));
   $RAD->{INTERIUM_OUTBYTE2}=0 if (! defined($RAD->{INTERIUM_OUTBYTE2}));

  $self->query($db, "INSERT into s_detail (acct_session_id, nas_id, acct_status, last_update, 
    sent1, recv1, sent2, recv2, id)
  VALUES (\"$RAD->{ACCT_SESSION_ID}\", '$NAS->{NAS_ID}',
   '$acct_status_type', UNIX_TIMESTAMP(),
   '$RAD->{INTERIUM_INBYTE}', '$RAD->{INTERIUM_OUTBYTE}', 
   '$RAD->{INTERIUM_INBYTE2}', '$RAD->{INTERIUM_OUTBYTE2}', 
   '$RAD->{USER_NAME}');", 'do');
}



 return $self;
}


#**********************************************************
# Alive accounting
#**********************************************************
sub rt_billing {
	my $self = shift;
  my ($RAD, $NAS)=@_;
  

  $self->query($db, "SELECT lupdated, UNIX_TIMESTAMP()-lupdated, 
   if($RAD->{INBYTE} >= acct_input_octets, $RAD->{INBYTE} - acct_input_octets, acct_input_octets),
   if($RAD->{OUTBYTE} >= acct_output_octets, $RAD->{OUTBYTE}  - acct_output_octets, acct_output_octets),
   if($RAD->{INBYTE2}  >= ex_input_octets, $RAD->{INBYTE2}  - ex_input_octets, ex_input_octets),
   if($RAD->{OUTBYTE2} >= ex_output_octets, $RAD->{OUTBYTE2} - ex_output_octets, ex_output_octets),
   acct_session_id,
   sum
   FROM dv_calls 
  WHERE user_name='$RAD->{USER_NAME}' and acct_session_id='$RAD->{ACCT_SESSION_ID}';");

  if($self->{errno}) {
 	  return $self;
   }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno}=2;
    $self->{errstr}="Session account Not Exist '$RAD->{ACCT_SESSION_ID}'";
    return $self;
   }


  ($RAD->{INTERIUM_SESSION_START},
   $RAD->{INTERIUM_ACCT_SESSION_TIME},
   $RAD->{INTERIUM_INBYTE},
   $RAD->{INTERIUM_OUTBYTE},
   $RAD->{INTERIUM_INBYTE1},
   $RAD->{INTERIUM_OUTBYTE1},
   $RAD->{ACCT_SESSION_ID},
   $self->{CALLS_SUM}
   ) = @{ $self->{list}->[0] };

  # Giga word check  

  #if ($RAD->{INTERIUM_INBYTE} == -1) {
  #	 return 0;
  # }
  
  my $Billing = Billing->new($db, $conf);	

  ($self->{UID}, 
   $self->{SUM}, 
   $self->{BILL_ID}, 
   $self->{TARIF_PLAN}, 
   $self->{TIME_TARIF}, 
   $self->{TRAF_TARIF}) = $Billing->session_sum("$RAD->{USER_NAME}", 
                                                $RAD->{INTERIUM_SESSION_START}, 
                                                $RAD->{INTERIUM_ACCT_SESSION_TIME}, 
                                                {  
                                                	 OUTBYTE  => $RAD->{OUTBYTE} - $RAD->{INTERIUM_OUTBYTE},
                                                   INBYTE   => $RAD->{INBYTE} - $RAD->{INTERIUM_INBYTE},
                                                   OUTBYTE2 => $RAD->{OUTBYTE2} - $RAD->{INTERIUM_OUTBYTE1},
                                                   INBYTE2  => $RAD->{INBYTE2} - $RAD->{INTERIUM_INBYTE1},

                                                	 INTERIUM_OUTBYTE  => $RAD->{INTERIUM_OUTBYTE},
                                                   INTERIUM_INBYTE   => $RAD->{INTERIUM_INBYTE},
                                                   INTERIUM_OUTBYTE1 => $RAD->{INTERIUM_INBYTE1},
                                                   INTERIUM_INBYTE1  => $RAD->{INTERIUM_OUTBYTE1}

                                                	},
                                                { FULL_COUNT => 1 }
                                                );
  
  
#  my $a = `date >> /tmp/echoccc;
#   echo "
#   UID: $self->{UID}, 
#   SUM: $self->{SUM} / $self->{CALLS_SUM}, 
#   BILL_ID: $self->{BILL_ID}, 
#   TP: $self->{TARIF_PLAN}, 
#   TIME_TARRIF: $self->{TIME_TARIF}, 
#   TRAFF_TARRIF: $self->{TRAF_TARIF},
#   TIME INTERVAL ID: $Billing->{TI_ID}
#   
#   DURATION: $RAD->{INTERIUM_ACCT_SESSION_TIME},
#   IN: $RAD->{INTERIUM_INBYTE},
#   OUT: $RAD->{INTERIUM_OUTBYTE},
#   IN2: $RAD->{INTERIUM_INBYTE1},
#   OUT2: $RAD->{INTERIUM_OUTBYTE1}
#   \n" >> /tmp/echoccc`;

 
   $self->query($db, "SELECT traffic_type FROM dv_log_intervals 
     WHERE acct_session_id='$RAD->{ACCT_SESSION_ID}' 
           and interval_id='$Billing->{TI_ID}';"  );

   my %intrval_traffic = ();
   foreach my $line (@{ $self->{list} }) {
   	 $intrval_traffic{$line->[0]}=1;
    }

   my @RAD_TRAFF_SUFIX = ('', '1');
   $self->{SUM} = 0 if ($self->{SUM} < 0);
   
   for(my $traffic_type = 0; $traffic_type <= $#RAD_TRAFF_SUFIX; $traffic_type++) {
     next if ($RAD->{'INTERIUM_OUTBYTE'.$RAD_TRAFF_SUFIX[$traffic_type]} + $RAD->{'INTERIUM_INBYTE'.$RAD_TRAFF_SUFIX[$traffic_type]} < 1);

     if ($intrval_traffic{$traffic_type}) {
       $self->query($db, "UPDATE dv_log_intervals SET  
                                                    sent=sent+'". $RAD->{'INTERIUM_OUTBYTE'. $RAD_TRAFF_SUFIX[$traffic_type]} ."', 
                                                    recv=recv+'". $RAD->{'INTERIUM_INBYTE'. $RAD_TRAFF_SUFIX[$traffic_type]} ."', 
                                                    duration=duration+'$RAD->{INTERIUM_ACCT_SESSION_TIME}', 
                                                    sum=sum+'$self->{SUM}'
                         WHERE interval_id='$Billing->{TI_ID}' and acct_session_id='$RAD->{ACCT_SESSION_ID}' and traffic_type='$traffic_type';", 'do');
      }
     else {
       $self->query($db, "INSERT INTO dv_log_intervals (interval_id, sent, recv, duration, traffic_type, sum, acct_session_id)
        values ('$Billing->{TI_ID}', 
          '". $RAD->{'INTERIUM_OUTBYTE'. $RAD_TRAFF_SUFIX[$traffic_type]} ."', 
          '". $RAD->{'INTERIUM_INBYTE'. $RAD_TRAFF_SUFIX[$traffic_type]} ."', 
        '$RAD->{INTERIUM_ACCT_SESSION_TIME}', '$traffic_type', '$self->{SUM}', '$RAD->{ACCT_SESSION_ID}');", 'do');
      }
    }
 
#  return $self;
  if ($self->{UID} == -2) {
    $self->{errno}  = 1;   
    $self->{errstr} = "ACCT [$RAD->{USER_NAME}] Not exist";
   }
  elsif($self->{UID} == -3) {
    my $filename   = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
    $self->{errno} = 1;
    $self->{errstr}= "ACCT [$RAD->{USER_NAME}] Not allow start period '$filename'";
    $Billing->mk_session_log($RAD);
   }
  elsif ($self->{SUM} < 0) {
    $self->{LOG_DEBUG} =  "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE})";
   }
  elsif ($self->{UID} <= 0) {
    $self->{LOG_DEBUG} =  "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE}), $self->{UID}";
    
    print "ACCT [$RAD->{USER_NAME}] /$RAD->{ACCT_STATUS_TYPE}/ small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE}), $self->{UID}\n";;
   }
  else {
    if ($self->{SUM} > 0) {
      $self->query($db, "UPDATE bills SET deposit=deposit-$self->{SUM} WHERE id='$self->{BILL_ID}';", 'do');
     }
   }
	
}

#**********************************************************
# start
#**********************************************************
sub start {
	my ($RAD, $NAS)=@_;
	
}


#**********************************************************
# start
#**********************************************************
sub stop {
	my ($RAD, $NAS)=@_;
	
}

#**********************************************************
# start
#**********************************************************
sub alive {
	my ($RAD, $NAS)=@_;
	
}




1
