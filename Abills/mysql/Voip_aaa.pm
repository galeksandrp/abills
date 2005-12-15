package Voip_aaa;
# VoIP Accounting functions
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



my %ACCT_TYPES = ('Start', 1,
               'Stop', 2,
               'Alive', 3,
               'Accounting-On', 7,
               'Accounting-Off', 8);





#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $conf) = @_;
  my $self = { };
  bless($self, $class);
  #$self->{debug}=1;
  return $self;
}


#**********************************************************
# Accounting Work_
#**********************************************************
sub auth {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  my $WHERE = '';

  if($RAD->{CHAP_PASSWORD}) {  
    $WHERE = " and uid.phone='$RAD->{USER_NAME}'";
   }

  $self->query($db, "SELECT 
   voip.uid, 
   voip.number,
   voip.tp_id, 
   INET_NTOA(voip.ip),
   DECODE(password, '$conf->{secretkey}'),
   0,
   voip.disable,
   u.disable
   FROM voip_main voip, 
        users u
   WHERE 
    and u.uid=voip.uid
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{UID},
   $self->{NUMBER},
   $self->{TP_ID}, 
   $self->{IP},
   self->{PASSWORD},
   $self->{SIMULTANEOUSLY}
   $self->{VOIP_DISABLE},
   $self->{USER_DISABLE},
  )= @$ar;
  
   $self->{SIMULTANEOUSLY} = 0;
  
  
  return $self;
}

#**********************************************************
# Accounting Work_
#**********************************************************
sub accounting {
 my $self = shift;
 my ($RAD, $NAS)=@_;
 

 my $acct_status_type = $ACCT_TYPES{$RAD->{ACCT_STATUS_TYPE}};
 my $SESSION_START = (defined($RAD->{SESSION_START}) && $RAD->{SESSION_START} > 0) ?  "FROM_UNIXTIME($RAD->{SESSION_START})" : 'now()';

#   print "aaa $acct_status_type '$RAD->{ACCT_STATUS_TYPE}'  /$RAD->{SESSION_START}/"; 
#my $a=`echo "test $acct_status_type = $ACCT_TYPES{$RAD->{ACCT_STATUS_TYPE}}"  >> /tmp/12211 `;
 

#Start
if ($acct_status_type == 1) { 


  $self->query($db, "INSERT INTO voip_calls 
   (  status,
      user_name,
      started,
      lupdated,
      acct_session_id,
      calling_station_id,
      called_station_id,
      nas_id,
      client_ip_address
   )
   values ('$acct_status_type', \"$RAD->{USER_NAME}\", $SESSION_START, UNIX_TIMESTAMP(), 
     '$RAD->{ACCT_SESSION_ID}', 
      '$RAD->{CALLING_STATION_ID}', '$RAD->{CALLED_STATION_ID}', '$NAS->{NID}',
      INET_ATON('$RAD->{CLIENT_IP_ADDRESS}'));", 'do');
      
 }
# Stop status
elsif ($acct_status_type == 2) {


  my $Billing = Billing->new($db);	


#  ($self->{UID}, 
#  $self->{SUM}, 
#  $self->{BILL_ID}, 
#  $self->{TARIF_PLAN}, 
#  $self->{TIME_TARIF}, 
#  $self->{TRAF_TARIF}) = $Billing->session_sum("$RAD->{USER_NAME}", 
#                                                 $RAD->{SESSION_START}, 
#                                                 $RAD->{ACCT_SESSION_TIME}, 
#                                                 $RAD, 
#                                                 $conf);

  
  my $PERIODS     = '';
  my $TIME_PRICES = '';

  #%TARIFFS = ($ID => 
  #$self->{};
  
  require Voip;
  my $Voip = Voip->new($db, undef, $conf);
  
  
  
  
  my %PARAMS = (IP     => $RAD->{FRAMED_IP_ADDRESS},
                NUMBER => $RAD->{CALLING_STATION_ID} );
  
  $Voip->user_info(0, { %PARAMS });

  
  if($Voip->{TOTAL} < 1) {
  	$self->{errno}=1;
  	$self->{errstr}="Not exists";
  	return $self;
   }
  elsif ($Voip->{errno}) {
  	$self->{errno}=1;
  	$self->{errstr}="Some error";
  	return $self;
   }

  
  $self->{UID}=$Voip->{UID};
  $self->{BILL_ID}=11; 
  $self->{TARIF_PLAN}=$Voip->{TP_ID}; 



  $self->{SUM}=10; 

  $Billing->time_calculation({ START       => $RAD->{SESSION_START},
  	                           DURATION    => $RAD->{ACCT_SESSION_TIME},
  	                           PERIODS     => $PERIODS,
  	                           TIME_PRICES => $TIME_PRICES });


 
#  return $self;
  if ($self->{UID} == -2) {
    $self->{errno}=1;   
    $self->{errstr} = "ACCT [$RAD->{USER_NAME}] Not exist";
   }
  elsif($self->{UID} == -3) {
    my $filename = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
    $self->{errno}=1;
    $self->{errstr}="ACCT [$RAD->{USER_NAME}] Not allow start period '$filename'";
    $Billing->mk_session_log($RAD, $conf);
   }
  elsif ($self->{SUM} < 0) {
    $self->{LOG_DEBUG} =  "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE})";
   }
  else {
    $self->query($db, "INSERT INTO voip_log (uid, start, duration, calling_station_id, called_station_id,
              nas_id, client_ip_address, acct_session_id, 
              tp_id, bill_id, sum) 
        VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}),  '$RAD->{ACCT_SESSION_TIME}', 
        '$RAD->{CALLING_STATION_ID}', '$RAD->{CALLED_STATION_ID}', 
        '$NAS->{NID}', INET_ATON('$RAD->{CLIENT_IP_ADDRESS}'), '$RAD->{ACCT_SESSION_ID}', 
        '$self->{TARIF_PLAN}', '$self->{BILL_ID}', '$self->{SUM}');", 'do');

    if ($self->{errno}) {
      my $filename = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
      $self->{LOG_WARNING}="ACCT [$RAD->{USER_NAME}] Making accounting file '$filename'";
      $Billing->mk_session_log($RAD, $conf);
     }
# If SQL query filed
    else {
      if ($self->{SUM} > 0) {
         $self->query($db, "UPDATE bills SET deposit=deposit-$self->{SUM} WHERE id='$self->{BILL_ID}';", 'do');
       }
     }
   }

  # Delete from session wtmp
#  $self->{debug}=1;
  $self->query($db, "DELETE FROM voip_calls WHERE acct_session_id='$RAD->{ACCT_SESSION_ID}' 
     and user_name=\"$RAD->{USER_NAME}\" 
     and nas_id='$NAS->{NID}';", 'do');
     
}
#Alive status 3
elsif($acct_status_type eq 3) {

## Experemental Linux alive hangup
## Author: Wanger
#if ($conf{experimentsl} eq 'yes') {
#  my ($sum, $variant, $time_t, $traf_t) = session_sum("$RAD{USER_NAME}", $ACCT_INFO{SESSION_START}, $ACCT_INFO{ACCT_SESSION_TIME}, \%ACCT_INFO);
#  if ($sum > 0) {
#     $sql = "SELECT deposit, credit FROM users WHERE id=\"$RAD{USER_NAME}\";";
#     log_print('LOG_SQL', "ACCT [$RAD{USER_NAME}] SQL: $sql");
#     $q = $db->prepare("$sql") || die $db->errstr;
#     $q -> execute();
#     my ($deposit, $credir) = $q -> fetchrow();
#      if (($deposit + $credir) - $sum) < 0) {
#        log_print('LOG_WARNING', "ACCT [$RAD{USER_NAME}] Negative balance ($d - $sum) - kill session($RAD{ACCT_SESSION_ID})");
#        system ($Bin ."/modules/hangup.pl $RAD{ACCT_SESSION_ID}");
#       }
#  }
#}
###

  $self->query($db, "UPDATE calls SET
    status='$acct_status_type',
    acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
    client_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'),
    lupdated=UNIX_TIMESTAMP()
   WHERE
    acct_session_id=\"$RAD->{ACCT_SESSION_ID}\" and 
    user_name=\"$RAD->{USER_NAME}\" and
    client_ip_address=INET_ATON('$RAD->{CLIENT_IP_ADDRESS}');", 'do');
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



 return $self;
}




=comments
# Cisco Values

VALUE           h323-disconnect-cause        Local-Clear                    0
VALUE           h323-disconnect-cause        Local-No-Accept                1
VALUE           h323-disconnect-cause        Local-Decline                  2
VALUE           h323-disconnect-cause        Remote-Clear                   3
VALUE           h323-disconnect-cause        Remote-Refuse                  4
VALUE           h323-disconnect-cause        Remote-No-Answer               5
VALUE           h323-disconnect-cause        Remote-Caller-Abort            6
VALUE           h323-disconnect-cause        Transport-Error                7
VALUE           h323-disconnect-cause        Transport-Connect-Fail         8
VALUE           h323-disconnect-cause        Gatekeeper-Clear               9
VALUE           h323-disconnect-cause        Fail-No-User                   10
VALUE           h323-disconnect-cause        Fail-No-Bandwidth              11
VALUE           h323-disconnect-cause        No-Common-Capabilities         12
VALUE           h323-disconnect-cause        FACILITY-Forward               13
VALUE           h323-disconnect-cause        Fail-Security-Check            14
VALUE           h323-disconnect-cause        Local-Busy                     15
VALUE           h323-disconnect-cause        Local-Congestion               16
VALUE           h323-disconnect-cause        Remote-Busy                    17
VALUE           h323-disconnect-cause        Remote-Congestion              18
VALUE           h323-disconnect-cause        Remote-Unreachable             19
VALUE           h323-disconnect-cause        Remote-No-Endpoint             20
VALUE           h323-disconnect-cause        Remote-Off-Line                21
VALUE           h323-disconnect-cause        Remote-Temporary-Error         22

=cut
1