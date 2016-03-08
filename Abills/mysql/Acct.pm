package Acct;
# Accounting functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION     = 2.00;
@ISA         = ('Exporter');
@EXPORT      = qw();
@EXPORT_OK   = ();
%EXPORT_TAGS = ();

# User name expration
use main;
use Billing;
use Abills::Base qw(in_array);

@ISA = ("main");

my ($conf);
my $Billing;
my %NAS_INFO = ();
my @SWITCH_MAC_AUTH = ();


my %ACCT_TYPES = (
  'Start'          => 1,
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
  my $db    = shift;
  ($conf)   = @_;
  my $self = {};
  bless($self, $class);
  
  $self->{db}=$db;
  $Billing = Billing->new($db, $conf);

  if ($conf->{DHCPHOSTS_SWITCH_MAC_AUTH}) {
    @SWITCH_MAC_AUTH = ();
    my @arr_switch_ids = split(/,/, $conf->{DHCPHOSTS_SWITCH_MAC_AUTH});
    foreach my $ids (@arr_switch_ids) {
      if ($ids =~ /^(\d+)-(\d+)$/) {
         for (my $i=$1; $i <= $2 ; $i++) {
           push @SWITCH_MAC_AUTH, $i;
         }
      }
      else {
        push @SWITCH_MAC_AUTH, $ids;
      }
    }
  }

  return $self;
}

#**********************************************************
# Accounting Work_
#**********************************************************
sub accounting {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  $self->{SUM} = 0 if (!$self->{SUM});
  my $acct_status_type = $ACCT_TYPES{ $RAD->{ACCT_STATUS_TYPE} };
  my $SESSION_START = (defined($RAD->{SESSION_START}) && $RAD->{SESSION_START} > 0) ? "FROM_UNIXTIME($RAD->{SESSION_START})" : "FROM_UNIXTIME(UNIX_TIMESTAMP())";

  $RAD->{ACCT_INPUT_GIGAWORDS}  = 0 if (!$RAD->{ACCT_INPUT_GIGAWORDS});
  $RAD->{ACCT_OUTPUT_GIGAWORDS} = 0 if (!$RAD->{ACCT_OUTPUT_GIGAWORDS});

  $RAD->{FRAMED_IP_ADDRESS} = '0.0.0.0' if (!defined($RAD->{FRAMED_IP_ADDRESS}));

  if (length($RAD->{ACCT_SESSION_ID}) > 32) {
    $RAD->{ACCT_SESSION_ID} = substr($RAD->{ACCT_SESSION_ID}, 0, 32);
  }

  if ($NAS->{NAS_TYPE} eq 'cid_auth') {
    $self->query2("SELECT u.uid, u.id
     FROM users u, dv_main dv
     WHERE dv.uid=u.uid AND dv.CID='$RAD->{CALLING_STATION_ID}'
     FOR UPDATE;"
    );

    if ($self->{TOTAL} < 1) {
      $RAD->{USER_NAME} = $RAD->{CALLING_STATION_ID};
    }
    else {
      $RAD->{USER_NAME} = $self->{list}->[0]->[1];
    }
  }
  elsif($NAS->{NAS_TYPE} eq 'accel_ipoe') {
    ($self->{NAS_MAC},
     $self->{NAS_PORT},
     $self->{VLAN},
     $self->{AGENT_REMOTE_ID},
     $self->{CIRCUIT_ID}
     ) = parse_opt82($RAD, $NAS);

    $self->get_nas_info($self, $NAS);
#    if ($self->{error}) {
#      $RAD_PAIRS{'Reply-Message'} = $self->{error_str};
#      return 1, \%RAD_PAIRS;
#    }

    my @WHERE_RULES = ();

    if ($NAS->{DOMAIN_ID}) {
      push @WHERE_RULES, "u.domain_id='$NAS->{DOMAIN_ID}'";
    }
    else {
      push @WHERE_RULES, "u.domain_id='0'";
    }

    $self->{USER_MAC} = $RAD->{CALLING_STATION_ID};
    if ($conf->{DHCPHOSTS_PORT_BASE} && ! in_array($NAS->{SUB_NAS_ID}, \@SWITCH_MAC_AUTH) && $NAS->{SUB_NAS_ID} != 0) {
      push @WHERE_RULES, "(n.mac='$self->{NAS_MAC}' AND dh.ports='$self->{NAS_PORT}')";
    }
    elsif ($conf->{DHCPHOSTS_AUTH_PARAMS} && ! in_array($NAS->{SUB_NAS_ID}, \@SWITCH_MAC_AUTH) && $NAS->{SUB_NAS_ID} != 0) {
      push @WHERE_RULES, "((n.mac='$self->{NAS_MAC}' OR n.mac IS null)
        AND (dh.mac='$RAD->{CALLING_STATION_ID}' OR dh.mac='00:00:00:00:00:00')
        AND (dh.vid='$self->{VLAN}' OR dh.vid='')
        AND (dh.ports='$self->{NAS_PORT}' OR dh.ports=''))";
    }
    elsif ($RAD->{CALLING_STATION_ID}) {
      push @WHERE_RULES, "dh.mac='$RAD->{CALLING_STATION_ID}'";
    }

    my $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';

    my $sql = "SELECT u.uid, u.id AS user_name
     FROM dhcphosts_hosts dh
     INNER JOIN users u ON (u.uid=dh.uid)
     LEFT JOIN nas n ON (dh.nas=n.id)
     WHERE $WHERE
     FOR UPDATE;";

    $self->query2("$sql",  
     undef,
     { COLS_NAME => 1,
       COLS_UPPER=> 1
     }
    );
    if ($self->{TOTAL} > 1) {
      my $i = 0;
      foreach my $host (@{ $self->{list} }) {
        if (uc($RAD->{CALLING_STATION_ID}) eq uc($host->{MAC})) {
          foreach my $p ( keys %{ $self->{list}->[$i] }) {
            $self->{$p} = $self->{list}->[$i]->{$p};
          }
        }
        $i++;
      }
    }
    elsif($self->{TOTAL}==1) {
      foreach my $p ( keys %{ $self->{list}->[0] }) {
        $self->{$p} = $self->{list}->[0]->{$p};
      }
    }
    $self->{IP} = $RAD->{FRAMED_IP_ADDRESS};
    $self->leases_update($NAS);
    if ($self->{USER_NAME}) {
      $RAD->{USER_NAME} = $self->{USER_NAME};
    }
    else {
      return $self;
    }
  }
  #Call back function
  elsif ($RAD->{USER_NAME} =~ /(\d+):(\S+)/) {
    $RAD->{USER_NAME}          = $2;
    $RAD->{CALLING_STATION_ID} = $1;
  }

  #Start
  if ($acct_status_type == 1) {
    $self->query2("SELECT acct_session_id FROM dv_calls 
    WHERE user_name='$RAD->{USER_NAME}' AND nas_id='$NAS->{NAS_ID}' AND (framed_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}') OR framed_ip_address=0) FOR UPDATE;"
    );
    #Get connection speed
    if ($RAD->{X_ASCEND_DATA_RATE} && $RAD->{X_ASCEND_XMIT_RATE}) {
      $RAD->{CONNECT_INFO} = "$RAD->{X_ASCEND_DATA_RATE} / $RAD->{X_ASCEND_XMIT_RATE}";
    }
    elsif ($RAD->{CISCO_SERVICE_INFO}) {
      $RAD->{CONNECT_INFO} = "$RAD->{CISCO_SERVICE_INFO}";
    }
    if ($self->{TOTAL} > 0) {
      foreach my $line (@{ $self->{list} }) {
        if ($line->[0] eq 'IP' || $line->[0] eq	"$RAD->{ACCT_SESSION_ID}") {

          my $sql = "UPDATE dv_calls SET
         status='$acct_status_type',
         started=$SESSION_START, 
         lupdated=UNIX_TIMESTAMP(), 
         nas_port_id='$RAD->{NAS_PORT}', 
         acct_session_id='$RAD->{ACCT_SESSION_ID}', 
         CID='$RAD->{CALLING_STATION_ID}', 
         CONNECT_INFO='$RAD->{CONNECT_INFO}'
         WHERE user_name='$RAD->{USER_NAME}' AND nas_id='$NAS->{NAS_ID}' 
           AND (acct_session_id='IP' OR acct_session_id='$RAD->{ACCT_SESSION_ID}')
           AND (framed_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}') OR framed_ip_address=0) 
         ORDER BY started
         LIMIT 1;";
          $self->query2("$sql", 'do');
          last;
        }
      }
    }
    # If not found auth records and session > 2 sec
    else { #if($RAD->{ACCT_SESSION_TIME} && $RAD->{ACCT_SESSION_TIME} > 2) {
      #Get TP_ID
      $self->query2("SELECT u.uid, dv.tp_id, dv.join_service FROM (users u, dv_main dv)
       WHERE u.uid=dv.uid and u.id='$RAD->{USER_NAME}' FOR UPDATE;"
      );
      if ($self->{TOTAL} > 0) {
        ($self->{UID},
         $self->{TP_ID},
         $self->{JOIN_SERVICE}) = @{ $self->{list}->[0] };

        if ($self->{JOIN_SERVICE}) {
          if ($self->{JOIN_SERVICE} == 1) {
            $self->{JOIN_SERVICE} = $self->{UID};
          }
          else {
            $self->{TP_ID} = '0';
          }
        }
      }
      else {
        $RAD->{USER_NAME} = '! ' . $RAD->{USER_NAME};
      }

      my $sql = "REPLACE INTO dv_calls
       (status, user_name, started, lupdated, nas_ip_address, nas_port_id, acct_session_id, framed_ip_address, CID, CONNECT_INFO,   nas_id, tp_id,
        uid, join_service)
         values ('$acct_status_type', 
        '$RAD->{USER_NAME}', 
        $SESSION_START, 
        UNIX_TIMESTAMP(), 
        INET_ATON('$RAD->{NAS_IP_ADDRESS}'),
        '$RAD->{NAS_PORT}', 
        '$RAD->{ACCT_SESSION_ID}',
        INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), 
        '$RAD->{CALLING_STATION_ID}', 
        '$RAD->{CONNECT_INFO}', 
        '$NAS->{NAS_ID}',
        '$self->{TP_ID}', '$self->{UID}',
        '$self->{JOIN_SERVICE}');";
      $self->query2("$sql", 'do');

      $self->query2("DELETE FROM dv_calls WHERE nas_id='$NAS->{NAS_ID}' AND acct_session_id='IP' AND (framed_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}') or UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started) > 120 );", 'do');
    }
    # Ignoring quick alive rad packets
    #else {
    #	
    #}
  }

  # Stop status
  elsif ($acct_status_type == 2) {
    #IPN Service
    if ($NAS->{NAS_EXT_ACCT} || $NAS->{NAS_TYPE} eq 'ipcad') {
      $self->query2("SELECT 
       dv.acct_input_octets AS inbyte,
       dv.acct_output_octets AS outbyte,
       dv.acct_input_gigawords,
       dv.acct_output_gigawords,
       dv.ex_input_octets AS inbyte2,
       dv.ex_output_octets AS outbyte2,
       dv.tp_id AS tarif_plan,
       dv.sum,
       dv.uid,
       u.bill_id,
       u.company_id
    FROM (dv_calls dv, users u)
    WHERE dv.uid=u.uid AND dv.user_name='$RAD->{USER_NAME}' AND dv.acct_session_id='$RAD->{ACCT_SESSION_ID}';",
    undef,
    { INFO => 1 }
      );

      if ($self->{errno}) {
        if ($self->{errno} == 2) {
          $self->{errno}  = 2;
          $self->{errstr} = "Session account Not Exist '$RAD->{ACCT_SESSION_ID}'";
          return $self;
        }
        return $self;
      }

      if ($self->{COMPANY_ID} > 0) {
        $self->query2("SELECT bill_id FROM companies WHERE id='$self->{COMPANY_ID}';");
        if ($self->{TOTAL} < 1) {
          $self->{errno}  = 2;
          $self->{errstr} = "Company not exists '$self->{COMPANY_ID}'";
          return $self;
        }
        ($self->{BILL_ID}) = @{ $self->{list}->[0] };
      }

      if ($RAD->{INBYTE} > 4294967296) {
        $RAD->{ACCT_INPUT_GIGAWORDS} = int($RAD->{INBYTE} / 4294967296);
        $RAD->{INBYTE}               = $RAD->{INBYTE} - $RAD->{ACCT_INPUT_GIGAWORDS} * 4294967296;
      }

      if ($RAD->{OUTBYTE} > 4294967296) {
        $RAD->{ACCT_OUTPUT_GIGAWORDS} = int($RAD->{OUTBYTE} / 4294967296);
        $RAD->{OUTBYTE}               = $RAD->{OUTBYTE} - $RAD->{ACCT_OUTPUT_GIGAWORDS} * 4294967296;
      }

      if ($self->{UID} > 0) {
        $self->query2("INSERT INTO dv_log (uid, start, tp_id, duration, sent, recv,  
        sum, nas_id, port_id,
        ip, CID, sent2, recv2, acct_session_id, 
        bill_id,
        terminate_cause,
        acct_input_gigawords,
        acct_output_gigawords) 
        VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}), '$self->{TARIF_PLAN}', '$RAD->{ACCT_SESSION_TIME}', 
        '$RAD->{OUTBYTE}', '$RAD->{INBYTE}', '$self->{SUM}', '$NAS->{NAS_ID}',
        '$RAD->{NAS_PORT}', INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), '" . 
         (($RAD->{CALLING_STATION_ID}) ? $RAD->{CALLING_STATION_ID} :  '')
        ."',
        '$RAD->{OUTBYTE2}', '$RAD->{INBYTE2}', '$RAD->{ACCT_SESSION_ID}', 
        '$self->{BILL_ID}',
        '$RAD->{ACCT_TERMINATE_CAUSE}',
        '$RAD->{ACCT_INPUT_GIGAWORDS}',
        '$RAD->{ACCT_OUTPUT_GIGAWORDS}');", 'do'
        );
      }
    }
    elsif ($conf->{rt_billing}) {
      $self->rt_billing($RAD, $NAS);

      if (! $self->{errno}) {
        #return $self;
        $self->query2("INSERT INTO dv_log (uid, start, tp_id, duration, sent, recv, sum, nas_id, port_id,
        ip, CID, sent2, recv2, acct_session_id, 
        bill_id,
        terminate_cause,
        acct_input_gigawords,
        acct_output_gigawords) 
        VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}), '$self->{TARIF_PLAN}', '$RAD->{ACCT_SESSION_TIME}', 
        '$RAD->{OUTBYTE}', '$RAD->{INBYTE}', $self->{CALLS_SUM}+$self->{SUM}, '$NAS->{NAS_ID}',
        '$RAD->{NAS_PORT}', 
        INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), '$RAD->{CALLING_STATION_ID}',
        '$RAD->{OUTBYTE2}', '$RAD->{INBYTE2}',  '$RAD->{ACCT_SESSION_ID}', 
        '$self->{BILL_ID}',
        '$RAD->{ACCT_TERMINATE_CAUSE}',
        '$RAD->{ACCT_INPUT_GIGAWORDS}',
        '$RAD->{ACCT_OUTPUT_GIGAWORDS}');", 'do'
        );

        if ($self->{errno}) {
          
        }
      }
      else {
        #DEbug only
        if ($conf->{ACCT_DEBUG}) {
          use POSIX qw(strftime);
          my $DATE_TIME = strftime "%Y-%m-%d %H:%M:%S", localtime(time);
          my $r = `echo "$DATE_TIME $self->{UID} - $RAD->{USER_NAME} / $RAD->{ACCT_SESSION_ID} / Time: $RAD->{ACCT_SESSION_TIME} / $self->{errstr}" >> /tmp/unknown_session.log`;

          #DEbug only end
        }

        #      return $self;
      }
    }
    else {
      my %EXT_ATTR = ();

      #Get connected TP
      $self->query2("SELECT uid, tp_id, CONNECT_INFO FROM dv_calls WHERE
          acct_session_id='$RAD->{ACCT_SESSION_ID}' and nas_id='$NAS->{NAS_ID}';"
      );

      ($EXT_ATTR{UID}, $EXT_ATTR{TP_NUM}, $EXT_ATTR{CONNECT_INFO}) = @{ $self->{list}->[0] } if ($self->{TOTAL} > 0);

      ($self->{UID}, $self->{SUM}, $self->{BILL_ID}, $self->{TARIF_PLAN}, $self->{TIME_TARIF}, $self->{TRAF_TARIF}) = $Billing->session_sum("$RAD->{USER_NAME}", $RAD->{SESSION_START}, $RAD->{ACCT_SESSION_TIME}, $RAD, \%EXT_ATTR);

      #  return $self;
      if ($self->{UID} == -2) {
        $self->{errno}  = 1;
        $self->{errstr} = "ACCT [$RAD->{USER_NAME}] Not exist";
      }
      elsif ($self->{UID} == -3) {
        my $filename = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
        $RAD->{SQL_ERROR} = "$Billing->{errno}:$Billing->{errstr}";
        $self->{errno}    = 1;
        $self->{errstr}   = "SQL Error ($Billing->{errstr}) SESSION: '$filename'";
        $Billing->mk_session_log($RAD);
        return $self;
      }
      elsif ($self->{SUM} < 0) {
        $self->{LOG_DEBUG} = "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE})";
      }
      elsif ($self->{UID} <= 0) {
        $self->{LOG_DEBUG} = "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE}), $self->{UID}";
      }
      else {
        $self->query2("INSERT INTO dv_log (uid, start, tp_id, duration, sent, recv, sum, nas_id, port_id,
          ip, CID, sent2, recv2, acct_session_id, 
          bill_id,
          terminate_cause,
          acct_input_gigawords,
          acct_output_gigawords ) 
          VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}), '$self->{TARIF_PLAN}', '$RAD->{ACCT_SESSION_TIME}', 
          '$RAD->{OUTBYTE}', '$RAD->{INBYTE}', '$self->{SUM}', '$NAS->{NAS_ID}',
          '$RAD->{NAS_PORT}', INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), '$RAD->{CALLING_STATION_ID}',
          '$RAD->{OUTBYTE2}', '$RAD->{INBYTE2}',  '$RAD->{ACCT_SESSION_ID}', 
          '$self->{BILL_ID}',
          '$RAD->{ACCT_TERMINATE_CAUSE}',
          '$RAD->{ACCT_INPUT_GIGAWORDS}',
          '$RAD->{ACCT_OUTPUT_GIGAWORDS}');", 'do'
        );

        if ($self->{errno}) {
          my $filename = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
          $self->{LOG_WARNING} = "ACCT [$RAD->{USER_NAME}] Making accounting file '$filename'";
          $Billing->mk_session_log($RAD);
        }

        # If SQL query filed
        else {
          if ($self->{SUM} > 0) {
            $self->query2("UPDATE bills SET deposit=deposit-$self->{SUM} WHERE id='$self->{BILL_ID}';", 'do');
          }
        }
      }
    }

    # Delete from session
    $self->query2("DELETE FROM dv_calls WHERE acct_session_id='$RAD->{ACCT_SESSION_ID}' and nas_id='$NAS->{NAS_ID}';", 'do');
  }

  #Alive status 3
  elsif ($acct_status_type eq 3) {
    $self->{SUM} = 0 if (!$self->{SUM});
    if ($NAS->{NAS_EXT_ACCT}) {
      my $ipn_fields = '';
      if ($NAS->{IPN_COLLECTOR}) {
        $ipn_fields = "sum=sum+$self->{SUM},
      acct_input_octets='$RAD->{INBYTE}',
      acct_output_octets='$RAD->{OUTBYTE}',
      ex_input_octets=ex_input_octets + $RAD->{INBYTE2},
      ex_output_octets=ex_output_octets + $RAD->{OUTBYTE2},
      acct_input_gigawords='$RAD->{ACCT_INPUT_GIGAWORDS}',
      acct_output_gigawords='$RAD->{ACCT_OUTPUT_GIGAWORDS}',";
      }

      $self->query2("UPDATE dv_calls SET
        $ipn_fields
        status='$acct_status_type',
        acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
        framed_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'),
        lupdated=UNIX_TIMESTAMP()
      WHERE
        acct_session_id='$RAD->{ACCT_SESSION_ID}' and 
        user_name='$RAD->{USER_NAME}' and
        nas_id='$NAS->{NAS_ID}';", 'do');
      return $self;
    }
    elsif ($NAS->{NAS_TYPE} eq 'ipcad') {
      return $self;
    }
    elsif ($conf->{rt_billing}) {
      $self->rt_billing($RAD, $NAS);
      
      if ($self->{errno}  && $self->{errno}  == 2 && ($RAD->{ACCT_SESSION_TIME} && $RAD->{ACCT_SESSION_TIME} > 2)) {
        $self->query2("SELECT u.uid, dv.tp_id, dv.join_service 
         FROM users u, dv_main dv 
         WHERE u.uid=dv.uid AND u.id='$RAD->{USER_NAME}';", 
         undef,
         { INFO  => 1 });

         my $sql = "REPLACE INTO dv_calls
         (status, user_name, started, lupdated, nas_ip_address, nas_port_id, acct_session_id, framed_ip_address, CID, CONNECT_INFO, nas_id, tp_id,
         uid, join_service, guest)
           values ('$acct_status_type', 
           '$RAD->{USER_NAME}', 
           now(), 
           UNIX_TIMESTAMP(), 
           INET_ATON('$RAD->{NAS_IP_ADDRESS}'),
           '$RAD->{NAS_PORT}', 
           '$RAD->{ACCT_SESSION_ID}',
           INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), 
           '$RAD->{CALLING_STATION_ID}', 
           '$RAD->{CONNECT_INFO}', 
           '$NAS->{NAS_ID}',
           '$self->{TP_ID}', '$self->{UID}',
          '$self->{JOIN_SERVICE}',
          '$self->{GUEST}');";
        $self->query2("$sql", 'do');
        return $self;
      }
    }

    my $ex_octets = '';
    if ($RAD->{INBYTE2} || $RAD->{OUTBYTE2}) {
      $ex_octets = "ex_input_octets='$RAD->{INBYTE2}',  ex_output_octets='$RAD->{OUTBYTE2}', ";
    }

    $self->query2("UPDATE dv_calls SET
    status='$acct_status_type',
    acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
    acct_input_octets='$RAD->{INBYTE}',
    acct_output_octets='$RAD->{OUTBYTE}',
    $ex_octets
    framed_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'),
    lupdated=UNIX_TIMESTAMP(),
    sum=sum+$self->{SUM},
    acct_input_gigawords='$RAD->{ACCT_INPUT_GIGAWORDS}',
    acct_output_gigawords='$RAD->{ACCT_OUTPUT_GIGAWORDS}'
   WHERE
    acct_session_id='$RAD->{ACCT_SESSION_ID}' and 
    user_name='$RAD->{USER_NAME}' and
    nas_id='$NAS->{NAS_ID}';", 'do'
    );
  }
  else {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [$RAD->{USER_NAME}] Unknown accounting status: $RAD->{ACCT_STATUS_TYPE} ($RAD->{ACCT_SESSION_ID})";
    return $self;
  }

  if ($self->{errno}) {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT $RAD->{ACCT_STATUS_TYPE} SQL Error '$RAD->{ACCT_SESSION_ID}'";
    return $self;
  }

  #detalization for Exppp
  if ($conf->{s_detalization}) {
    my $INBYTES  = $RAD->{INBYTE} +  (($RAD->{ACCT_INPUT_GIGAWORDS})  ? $RAD->{ACCT_INPUT_GIGAWORDS} * 4294967296  : 0);
    my $OUTBYTES = $RAD->{OUTBYTE} + (($RAD->{ACCT_OUTPUT_GIGAWORDS}) ? $RAD->{ACCT_OUTPUT_GIGAWORDS} * 4294967296 : 0);
    $RAD->{INTERIUM_INBYTE2}  = $RAD->{INBYTE2}  || 0;
    $RAD->{INTERIUM_OUTBYTE2} = $RAD->{OUTBYTE2} || 0;

    $self->query2("INSERT into s_detail (acct_session_id, nas_id, acct_status, last_update, sent1, recv1, sent2, recv2, id, sum)
   VALUES ('$RAD->{ACCT_SESSION_ID}', '$NAS->{NAS_ID}',
    '$acct_status_type', UNIX_TIMESTAMP(),
    '$INBYTES', '$OUTBYTES',
    '$RAD->{INTERIUM_INBYTE2}', '$RAD->{INTERIUM_OUTBYTE2}',
    '$RAD->{USER_NAME}', '$self->{SUM}');", 'do'
    );

  }
  return $self;
}

#**********************************************************
# Alive accounting
#**********************************************************
sub rt_billing {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  if (! $RAD->{ACCT_SESSION_ID}) {
    $self->{errno}  = 2;
    $self->{errstr} = "Session account rt Not Exist '$RAD->{ACCT_SESSION_ID}'";
    return $self;
  }

#  $self->query2("SELECT lupdated, UNIX_TIMESTAMP()-lupdated,
#   if($RAD->{INBYTE}   >= acct_input_octets AND $RAD->{ACCT_INPUT_GIGAWORDS}=acct_input_gigawords,
#        $RAD->{INBYTE} - acct_input_octets,
#        4294967296-acct_input_octets+4294967296*($RAD->{ACCT_INPUT_GIGAWORDS}-acct_input_gigawords-1)+$RAD->{INBYTE}),
#   if($RAD->{OUTBYTE}  >= acct_output_octets AND $RAD->{ACCT_OUTPUT_GIGAWORDS}=acct_output_gigawords,
#        $RAD->{OUTBYTE} - acct_output_octets,
#        4294967296-acct_output_octets+4294967296*($RAD->{ACCT_OUTPUT_GIGAWORDS}-acct_output_gigawords-1)+$RAD->{OUTBYTE}),
#   if($RAD->{INBYTE2}  >= ex_input_octets, $RAD->{INBYTE2}  - ex_input_octets, ex_input_octets),
#   if($RAD->{OUTBYTE2} >= ex_output_octets, $RAD->{OUTBYTE2} - ex_output_octets, ex_output_octets),
#   sum,
#   tp_id,
#   uid
#   FROM dv_calls
#  WHERE nas_id='$NAS->{NAS_ID}' and acct_session_id='$RAD->{ACCT_SESSION_ID}';"
#  );

  $self->query2("SELECT lupdated, UNIX_TIMESTAMP()-lupdated,
   if($RAD->{INBYTE}   >= acct_input_octets AND ". $RAD->{ACCT_INPUT_GIGAWORDS} ."=acct_input_gigawords,
        $RAD->{INBYTE} - acct_input_octets,
        if(". $RAD->{ACCT_INPUT_GIGAWORDS} ." - acct_input_gigawords > 0, 4294967296 * (". $RAD->{ACCT_INPUT_GIGAWORDS} ." - acct_input_gigawords) - acct_input_octets + $RAD->{INBYTE}, 0)),
   if($RAD->{OUTBYTE}  >= acct_output_octets AND ".$RAD->{ACCT_OUTPUT_GIGAWORDS} ."=acct_output_gigawords,
        $RAD->{OUTBYTE} - acct_output_octets,
        if(". $RAD->{ACCT_OUTPUT_GIGAWORDS} ." - acct_output_gigawords > 0, 4294967296 * (". $RAD->{ACCT_OUTPUT_GIGAWORDS} ." - acct_output_gigawords) - acct_output_octets + $RAD->{OUTBYTE}, 0)),
   if($RAD->{INBYTE2}  >= ex_input_octets, $RAD->{INBYTE2}  - ex_input_octets, ex_input_octets),
   if($RAD->{OUTBYTE2} >= ex_output_octets, $RAD->{OUTBYTE2} - ex_output_octets, ex_output_octets),
   sum,
   tp_id,
   uid
   FROM dv_calls
  WHERE nas_id='$NAS->{NAS_ID}' and acct_session_id='". $RAD->{ACCT_SESSION_ID} ."';");

  if ($self->{errno}) {
    if ($conf->{ACCT_DEBUG}) {
      $self->query2("SELECT $RAD->{INBYTE}, acct_input_octets, ". $RAD->{ACCT_INPUT_GIGAWORDS} .", acct_input_gigawords,
         $RAD->{OUTBYTE}, acct_output_octets, ".$RAD->{ACCT_OUTPUT_GIGAWORDS} .", acct_output_gigawords
      FROM dv_calls 
      WHERE nas_id='$NAS->{NAS_ID}' and acct_session_id='". $RAD->{ACCT_SESSION_ID} ."';");

      my $line = $self->{list}->[0];
      my $echo_ = `echo  "$RAD->{ACCT_SESSION_ID} - rad: $line->[0], $line->[1], rad: $line->[2], $line->[3] \n rad: $line->[4], $line->[5], rad: $line->[6], $line->[7]" >> /tmp/dv_calls_error`; 
    }
    
    return $self;
  }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = "Session account rt Not Exist '$RAD->{ACCT_SESSION_ID}'";
    return $self;
  }

  ($RAD->{INTERIUM_SESSION_START},
  $RAD->{INTERIUM_ACCT_SESSION_TIME},
  $RAD->{INTERIUM_INBYTE},
  $RAD->{INTERIUM_OUTBYTE},
  $RAD->{INTERIUM_INBYTE1},
  $RAD->{INTERIUM_OUTBYTE1},
  $self->{CALLS_SUM},
  $self->{TP_NUM},
  $self->{UID}) = @{ $self->{list}->[0] };

  my $out_byte = $RAD->{OUTBYTE} + $RAD->{ACCT_OUTPUT_GIGAWORDS} * 4294967296;
  my $in_byte  = $RAD->{INBYTE} + $RAD->{ACCT_INPUT_GIGAWORDS} * 4294967296;


  ($self->{UID}, 
  $self->{SUM}, 
  $self->{BILL_ID}, 
  $self->{TARIF_PLAN}, 
  $self->{TIME_TARIF}, 
  $self->{TRAF_TARIF}) = $Billing->session_sum(
    "$RAD->{USER_NAME}",
    $RAD->{INTERIUM_SESSION_START},
    $RAD->{INTERIUM_ACCT_SESSION_TIME},
    {
      OUTBYTE  => ($out_byte == $RAD->{INTERIUM_OUTBYTE}) ? $RAD->{INTERIUM_OUTBYTE} : $out_byte - $RAD->{INTERIUM_OUTBYTE},
      INBYTE   => ($in_byte  == $RAD->{INTERIUM_INBYTE}) ? $RAD->{INTERIUM_INBYTE} : $in_byte - $RAD->{INTERIUM_INBYTE},
      OUTBYTE2 => $RAD->{OUTBYTE2} - $RAD->{INTERIUM_OUTBYTE1},
      INBYTE2  => $RAD->{INBYTE2} - $RAD->{INTERIUM_INBYTE1},

      #OUTBYTE  => $RAD->{INTERIUM_OUTBYTE},
      #INBYTE   => $RAD->{INTERIUM_INBYTE},
      #OUTBYTE2 => $RAD->{INTERIUM_OUTBYTE1},
      #INBYTE2  => $RAD->{INTERIUM_INBYTE1},

      INTERIUM_OUTBYTE  => $RAD->{INTERIUM_OUTBYTE},
      INTERIUM_INBYTE   => $RAD->{INTERIUM_INBYTE},
      INTERIUM_OUTBYTE1 => $RAD->{INTERIUM_INBYTE1},
      INTERIUM_INBYTE1  => $RAD->{INTERIUM_OUTBYTE1},
    },
    {
      FULL_COUNT => 1,
      TP_NUM     => $self->{TP_NUM},
      UID        => ($self->{TP_NUM}) ? $self->{UID} : undef,
      DOMAIN_ID  => ($NAS->{DOMAIN_ID}) ? $NAS->{DOMAIN_ID} : 0,
    }
  );

  $self->query2("SELECT traffic_type FROM dv_log_intervals 
     WHERE acct_session_id='$RAD->{ACCT_SESSION_ID}' 
           AND interval_id='$Billing->{TI_ID}'
           AND uid='$self->{UID}' FOR UPDATE;"
  );

  my %intrval_traffic = ();
  foreach my $line (@{ $self->{list} }) {
    $intrval_traffic{ $line->[0] } = 1;
  }

  my @RAD_TRAFF_SUFIX = ('', '1');
  $self->{SUM} = 0 if ($self->{SUM} < 0);

  for (my $traffic_type = 0 ; $traffic_type <= $#RAD_TRAFF_SUFIX ; $traffic_type++) {
    next if ($RAD->{ 'INTERIUM_OUTBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] } + $RAD->{ 'INTERIUM_INBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] } < 1);

    if ($intrval_traffic{$traffic_type}) {
      $self->query2("UPDATE dv_log_intervals SET  
                sent=sent+'" . $RAD->{ 'INTERIUM_OUTBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] } . "', 
                recv=recv+'" . $RAD->{ 'INTERIUM_INBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] } . "', 
                duration=duration+'$RAD->{INTERIUM_ACCT_SESSION_TIME}', 
                sum=sum+'$self->{SUM}'
              WHERE interval_id='$Billing->{TI_ID}' and acct_session_id='$RAD->{ACCT_SESSION_ID}' and traffic_type='$traffic_type' AND uid='$self->{UID}';", 'do'
      );
    }
    else {
      $self->query2("INSERT INTO dv_log_intervals (interval_id, sent, recv, duration, traffic_type, sum, acct_session_id, uid, added)
        values ('$Billing->{TI_ID}', 
          '" . $RAD->{ 'INTERIUM_OUTBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] } . "', 
          '" . $RAD->{ 'INTERIUM_INBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] } . "', 
        '$RAD->{INTERIUM_ACCT_SESSION_TIME}', '$traffic_type', '$self->{SUM}', '$RAD->{ACCT_SESSION_ID}', '$self->{UID}', now());", 'do'
      );
    }
  }

  #  return $self;
  if ($self->{UID} == -2) {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [$RAD->{USER_NAME}] Not exist";
  }
  elsif ($self->{UID} == -3) {
    my $filename = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [$RAD->{USER_NAME}] Not allow start period '$filename'";
    $Billing->mk_session_log($RAD);
  }
  elsif ($self->{UID} == -5) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{USER_NAME}] Can't find TP: $self->{TP_NUM} Session id: $RAD->{ACCT_SESSION_ID}";
    $self->{errno}     = 1;
    print "ACCT [$RAD->{USER_NAME}] Can't find TP: $self->{TP_NUM} Session id: $RAD->{ACCT_SESSION_ID}\n";
  }
  elsif ($self->{SUM} < 0) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE})";
  }
  elsif ($self->{UID} <= 0) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE}), $self->{UID}";
    $self->{errno}     = 1;

    #print "ACCT [$RAD->{USER_NAME}] /$RAD->{ACCT_STATUS_TYPE}/ small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE}), ! $self->{UID}\n";
  }
  else {
    if ($self->{SUM} > 0) {
      $self->query2("UPDATE bills SET deposit=deposit-$self->{SUM} WHERE id='$self->{BILL_ID}';", 'do');
    }
  }
}
#**********************************************************
# http://tools.ietf.org/html/rfc4243
# http://tools.ietf.org/html/rfc3046#section-7
#**********************************************************
sub parse_opt82 {
  my ($RAD, $NAS, $attr) = @_;
  my ($switch_mac, $port, $vlan);
  my %result      =  ();
  my $hex2ansii   = '';
  my @o82_expr_arr = ();
  if ($conf->{DHCPHOSTS_EXPR}) {
    $conf->{DHCPHOSTS_EXPR} =~ s/\n//g;
    @o82_expr_arr    = split(/;/, $conf->{DHCPHOSTS_EXPR});
  }
  if ($#o82_expr_arr > -1 && $RAD->{DHCP_OPTION82}) {
    my $expr_debug  =  "";
    foreach my $expr (@o82_expr_arr) {
      my ($parse_param, $expr_, $values, $attribute)=split(/:/, $expr);
      $parse_param = 'DHCP_OPTION82' if ($parse_param eq 'DHCP-Relay-Agent-Information');
      my @EXPR_IDS = split(/,/, $values);
      if ($RAD->{$parse_param}) {
        my $input_value = $RAD->{$parse_param};
        if ($attribute && $attribute eq 'hex2ansii') {
          $hex2ansii   = 1;
          $input_value =~ s/^0x//;
          $input_value = pack 'H*', $input_value;
        }

        if ($conf->{ACCEL_IPOE_DEBUG} && $conf->{ACCEL_IPOE_DEBUG} > 3) {
          $expr_debug  .=  "$RAD->{CALLING_STATION_ID}: $parse_param, $expr_, $RAD->{$parse_param}\n";
        }

        if (my @res = ($input_value =~ /$expr_/i)) {
          for (my $i=0; $i <= $#res ; $i++) {
            if ($conf->{ACCEL_IPOE_DEBUG}  && $conf->{ACCEL_IPOE_DEBUG} > 2) {
              $expr_debug .= "$EXPR_IDS[$i] / $res[$i]\n";
            }

            $result{$EXPR_IDS[$i]}=$res[$i];
          }
          if ($attribute eq 'bdcom'){
            if ($result{PORT} =~ /([0-9]{2})([0-9a-f]{2})([0-9a-f]{2})/) {
              $result{PORT_DEC} = hex($1) . "/" . (hex($2)-6) . ":" . hex($3);
              $expr_debug .= "PORT / $result{PORT_DEC}\n";
            }
          }
          if ($hex2ansii) {
            $result{VLAN_DEC}        = $result{VLAN};
            $result{PORT_DEC}        = $result{PORT};
          }
          $hex2ansii = 0;
        }
      }

      if ($parse_param eq 'DHCP_OPTION82') {
        $result{AGENT_REMOTE_ID} = substr($RAD->{$parse_param},0,25);
        $result{CIRCUIT_ID} = substr($RAD->{$parse_param},25,25);
      }
      else {
        $result{AGENT_REMOTE_ID}='-';
        $result{CIRCUIT_ID}='-';
      }
    }

    if ($result{MAC} && $result{MAC} =~ /([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})/i) {
      $result{MAC} = "$1:$2:$3:$4:$5:$6";
    }

    if ($conf->{ACCEL_IPOE_DEBUG} && $conf->{ACCEL_IPOE_DEBUG} > 2) {
       my $zz = `echo "$expr_debug" >> /tmp/dhcphosts_accel_expr`;
    }
  }
  # FreeRadius DHCP default
  elsif($RAD->{DHCP_OPTION82}) {
    my @relayid = unpack('a10 a4 a2 a2 a4 a16 (a2)*', $RAD->{DHCP_OPTION82});
    $result{VLAN}            = $relayid[1];
    $result{PORT}            = $relayid[3];
    $result{MAC}             = $relayid[5];
    $result{AGENT_REMOTE_ID} = substr($RAD->{DHCP_OPTION82},0,25);
    $result{CIRCUIT_ID}      = substr($RAD->{DHCP_OPTION82},25,25);
  }
  $result{VLAN} = $result{VLAN_DEC} || hex($result{VLAN} || 0);
  $result{PORT} = $result{PORT_DEC} || hex($result{PORT} || 0);
  $result{MAC} =  $result{MAC} || 0;
  $result{AGENT_REMOTE_ID} = $result{AGENT_REMOTE_ID} || '-';
  $result{CIRCUIT_ID} = $result{CIRCUIT_ID} || '-';
  return $result{MAC}, $result{PORT}, $result{VLAN}, $result{AGENT_REMOTE_ID}, $result{CIRCUIT_ID};
}
#**********************************************************
#
#**********************************************************
sub get_nas_info {
  my $self = shift;
  my ($attr, $NAS) = @_;
  my $nas;
  my @WHERE_RULES = ();
  my $EXT_TABLE   = '';
  $conf->{DHCPHOSTS_SESSSION_TIMEOUT} = $conf->{DHCPHOSTS_SESSSION_TIMEOUT} || $NAS->{NAS_ALIVE} || 300;
  # Do nothing if port is magistral, i.e. 25.26.27.28
  # Apply only for reserv ports
  delete ($self->{error});
  if ($attr->{NAS_MAC} && ! $NAS_INFO{ $attr->{NAS_MAC} } ) {
    my $nas_pm = Nas->new($self->{db}, $conf);
    my $list = $nas_pm->list({ MAC => $attr->{NAS_MAC}, COLS_NAME => 1, COLS_UPPER => 1 });
    if ($nas_pm->{TOTAL} >= 1) {
      foreach my $line (@$list) {
        $line->{NAS_TYPE} = $NAS->{NAS_TYPE};
        $NAS_INFO{ $attr->{NAS_MAC} } = $line;
        $NAS_INFO{ $attr->{NAS_MAC}  . '_' . $line->{NAS_IP} } = $line;
      }
    }
  }

  if ($attr->{NAS_MAC} && $NAS_INFO{$attr->{NAS_MAC}}) {
    $NAS->{SUB_NAS_ID} = $NAS_INFO{$attr->{NAS_MAC}}->{NAS_ID};
    $NAS->{SUB_NAS_RAD_PAIRS} = $NAS_INFO{$attr->{NAS_MAC}}->{NAS_RAD_PAIRS};
    %{ $nas } = %{ $NAS_INFO{$attr->{NAS_MAC}} };
    $NAS->{NAS_ALIVE} = $conf->{DHCPHOSTS_SESSSION_TIMEOUT} if (! $NAS->{NAS_ALIVE});
  }
  elsif($attr->{NAS_MAC}) {
#    $NAS->{NAS_ID}=0;
    $self->{error}=3;
    $self->{error_str}="NOT EXIST NAS_MAC: $attr->{NAS_MAC}";
    return $self;
  }
  else {
    $NAS->{SUB_NAS_ID} = '0';
  }

  if ($attr->{NAS_PORT} && $NAS->{SUB_NAS_RAD_PAIRS} && $NAS->{SUB_NAS_RAD_PAIRS} =~ /Assign-Ports=\"(.+)\"/) {
    my @allow_ports = split(/,/, $1);
    if (! in_array($attr->{NAS_PORT}, \@allow_ports)) {
      $self->{error}=3;
      $self->{error_str}="Unallow port '$attr->{NAS_PORT}'";
      return $self;
    }
  }
  return $self;
}
#**********************************************************
#
#**********************************************************
sub leases_update {
  my $self   = shift;
  my ($NAS) = @_;
  $self->{UID}=0 if (! $self->{UID});
  $self->query2("DELETE FROM dhcphosts_leases WHERE ip=INET_ATON('$self->{IP}') AND ends < now()", 'do');
  my $leases_time = $conf->{DHCPHOSTS_SESSSION_TIMEOUT} || $NAS->{NAS_ALIVE} || 300;
  $WHERE   = '';
  if ($conf->{DHCPHOSTS_PORT_BASE} && ! in_array($NAS->{SUB_NAS_ID}, \@SWITCH_MAC_AUTH) && $NAS->{SUB_NAS_ID} != 0) {
    $WHERE = ($self->{NAS_PORT}) ? " AND port='$self->{NAS_PORT}'" : '';
    $WHERE .= " AND switch_mac='$self->{NAS_MAC}'";
  }

#  if (defined($self->{GUEST_MODE})) {
#    $WHERE .= " AND flag=". (($self->{GUEST_MODE}) ? 1 : 0);
#  }

  # check work IP

  $self->query2("SELECT flag FROM dhcphosts_leases
      WHERE ip=INET_ATON('$self->{IP}')
      AND hardware='$self->{USER_MAC}' $WHERE
      ORDER BY 1;",
    undef, { COLS_NAME => 1 });
  if ($self->{TOTAL} > 0) {
    $self->{GUEST} = $self->{list}->[0]->{flag};
    $self->query2("UPDATE dhcphosts_leases SET
        ends=now() + interval " . ($leases_time + 30) . " second, uid='$self->{UID}',
        hardware='$self->{USER_MAC}',  nas_id='$NAS->{SUB_NAS_ID}',
        switch_mac='$self->{NAS_MAC}',  port='$self->{NAS_PORT}',  vlan='$self->{VLAN}'
        WHERE ends > now() AND ip=INET_ATON('$self->{IP}')
        AND hardware='$self->{USER_MAC}' AND (uid='$self->{UID}' OR uid='0') $WHERE LIMIT 1;", 'do');
  }
  else {
    #add to dhcp table
    $self->query2("INSERT INTO dhcphosts_leases
        (start, ends, state, next_state, hardware, uid,
         circuit_id, remote_id,
         nas_id, ip, port, vlan, switch_mac)
      VALUES (now(),
        now() + interval " . ($leases_time + 30) . " second, 2, 1,
        '$self->{USER_MAC}',
        '$self->{UID}',
        '$self->{CIRCUIT_ID}',
        '$self->{AGENT_REMOTE_ID}',
        '$NAS->{SUB_NAS_ID}',
        INET_ATON('$self->{IP}'),
        '$self->{NAS_PORT}',
        '$self->{VLAN}',
        '$self->{NAS_MAC}')", 'do'
    );
  }
  return $self;
}

1
