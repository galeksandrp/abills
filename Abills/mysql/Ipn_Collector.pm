package Ipn_Collector;

# Ipn Collector functions

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 5.00;
@ISA     = ('Exporter');
@EXPORT  = qw(
&ip_in_zone
&is_exist
);

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

require Billing;
Billing->import();
my $Billing;

require Abills::Base;
Abills::Base->import(qw( int2ip ip2int check_time));

require Dv;
Dv->import();
my $Dv;

require Tariffs;
Tariffs->import();
my $Tariffs;

my %ips = ();
my $CONF;
my $debug = 0;

my %intervals   = ();
my %tp_interval = ();
my %ip_range    = ();
my %ip_user_hash= ();
my @zoneids;
my %ip_class_tables = ();

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($CONF)   = @_;

  my $self = {};
  bless($self, $class);

  if ($CONF->{DELETE_USER}) {
    return $self;
  }

  if (!defined($CONF->{KBYTE_SIZE})) {
    $CONF->{KBYTE_SIZE} = 1024;
  }

  $self->{db}=$db;

  $CONF->{IPN_DETAIL_MIN_SIZE}  = 0 if (!$CONF->{IPN_DETAIL_MIN_SIZE});
  $CONF->{MB_SIZE}              = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};
  $self->{TRAFFIC_ROWS}         = 0;
  $self->{UNKNOWN_TRAFFIC_ROWS} = 0;
  $Billing = Billing->new($self->{db}, $CONF);

  return $self;
}

#**********************************************************
# user_ips
#**********************************************************
sub user_ips {
  my $self = shift;
  my ($DATA) = @_;

  my $sql;

  if ($DATA->{NAS_ID} =~ /(\d+)-(\d+)/) {
    my $first   = $1;
    my $last    = $2;
    my @nas_arr = ();
    for (my $i = $1 ; $i <= $2 ; $i++) {
      push @nas_arr, $i;
    }
    $DATA->{NAS_ID} = join(',', @nas_arr);
  }

  if ($CONF->{IPN_STATIC_IP}) {
    $sql = "select u.uid, dv.ip, u.id AS login, 
     if(calls.acct_session_id, calls.acct_session_id, '') AS acct_session_id,
     dv.tp_id, 
     if (u.company_id > 0, cb.id, b.id) AS bill_id,
     if (c.name IS NULL, b.deposit, cb.deposit)+u.credit AS deposit,
     tp.payment_type,
     tp.octets_direction,
     u.reduction,
     u.activate,
     dv.netmask,
     dv.ip AS dv_ip,
     calls.acct_input_gigawords,
     calls.acct_output_gigawords,
     dv.join_service
     FROM (users u, dv_main dv)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
     LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id)
     LEFT JOIN dv_calls calls ON (u.id=calls.user_name)
     LEFT JOIN users_nas un ON(u.uid=un.uid)
     WHERE u.uid=dv.uid and u.domain_id=0
      and dv.ip > 0 and u.disable=0 and dv.disable=0
      and (un.nas_id IN ($DATA->{NAS_ID}) or un.nas_id IS NULL)
     GROUP BY u.uid;";
  }
  elsif ($CONF->{IPN_DEPOSIT_OPERATION}) {
    $sql = "select u.uid, calls.framed_ip_address AS ip, 
      calls.user_name AS login,
      calls.acct_session_id,
      calls.acct_input_octets,
      calls.acct_output_octets,
      dv.tp_id,
      if(u.company_id > 0, cb.id, b.id) AS bill_id,
      if(c.name IS NULL, b.deposit, cb.deposit)+u.credit AS deposit,
      tp.payment_type,
      UNIX_TIMESTAMP() - calls.lupdated AS interim_time,
      calls.nas_id,
      tp.octets_direction,
      u.reduction,
      CONNECT_INFO,
      u.activate,
      dv.netmask,
      dv.ip  AS dv_ip,
      calls.acct_input_gigawords,
      calls.acct_output_gigawords,
      dv.join_service
    FROM (dv_calls calls, users u)
      LEFT JOIN companies c ON (u.company_id=c.id)
      LEFT JOIN bills b ON (u.bill_id=b.id)
      LEFT JOIN bills cb ON (c.bill_id=cb.id)
      LEFT JOIN dv_main dv ON (u.uid=dv.uid)
      LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id)
    WHERE u.id=calls.user_name and u.domain_id=0 and calls.status<11
    and calls.nas_id IN ($DATA->{NAS_ID}) ;";
  }
  else {
    $sql = "SELECT u.uid, 
    calls.framed_ip_address AS ip, 
    calls.user_name AS login, 
    calls.acct_session_id,
    calls.acct_input_octets,
    calls.acct_output_octets,
    calls.tp_id,
    UNIX_TIMESTAMP() - calls.lupdated AS interim_time,
    calls.nas_id,
    u.reduction,
    CONNECT_INFO,
    u.activate,
    dv.netmask,
    dv.ip  AS dv_ip,
    dv.join_service
    FROM (dv_calls calls, users u)
    LEFT JOIN dv_main dv ON (u.uid=dv.uid)
   WHERE u.id=calls.user_name and u.domain_id=0 and calls.status<11
   and calls.nas_id IN ($DATA->{NAS_ID});";
  }

  $self->query2($sql, undef, { COLS_NAME => 1 });

  if ($self->{errno}) {
    print "SQL Error: Get online users\n";
    exit;
  }

  my $list          = $self->{list};
  my %session_ids   = ();
  my %users_info    = ();
  my %interim_times = ();
  my %connect_info  = ();

  $ips{0}         = '0';
  $self->{0}{IN}  = 0;
  $self->{0}{OUT} = 0;

  foreach my $line (@$list) {
    my $ip = $line->{ip};

    #Get IP/mask
    if ($line->{netmask} && $line->{netmask} < 4294967295) {
      my $count = 4294967295 - $line->{netmask};
      my $ip2hash = $ip;
      $ip = pack('N4N4', $ip, $count);
      $ip_range{ $line->{uid} } = $ip;
      for (my $i =0; $i <= $count; $i++) {
        $ip_user_hash{$ip2hash+$i} = $line->{uid};
      }
    }
    $ips{$ip} = $line->{uid};

    #IN / OUT octets
    $self->{$ip}{IN}  = $line->{acct_input_octets} || 0;
    $self->{$ip}{OUT} = $line->{acct_output_octets} || 0;

    $self->{$ip}{ACCT_INPUT_GIGAWORDS}  = $line->{acct_input_gigawords} || 0;
    $self->{$ip}{ACCT_OUTPUT_GIGAWORDS} = $line->{acct_output_gigawords} || 0;

    #user NAS
    $self->{$ip}{NAS_ID} = $line->{nas_id} || 0;

    #Octet direction
    $self->{$ip}{OCTET_DIRECTION} = $line->{octets_direction} || 0;

    $users_info{TPS}{ $line->{uid} } = $line->{tp_id};

    #User login
    $users_info{LOGINS}{ $line->{uid} } = $line->{login} || '';

    #Session ID
    $session_ids{$ip}             = $line->{acct_session_id} || '';
    $interim_times{ $line->{ip} } = $line->{interim_time} || 0;
    $connect_info{ $line->{ip} }  = $line->{CONNECT_INFO} || '';

    #$self->{INTERIM}{$line->[3]}{TIME}=$line->[10];
    $users_info{PAYMENT_TYPE}{ $line->{uid} } = $line->{payment_type};
    $users_info{DEPOSIT}{ $line->{uid} }      = $line->{deposit};
    $users_info{REDUCTION}{ $line->{uid} }    = $line->{reduction};
    $users_info{ACTIVATE}{ $line->{uid} }     = $line->{activate};
    $users_info{BILL_ID}{ $line->{uid} }      = $line->{bill_id};
    $users_info{JOIN_SERVICE}{ $line->{uid} } = $line->{join_service}  if ( $line->{join_service} );
  }

  $self->{USERS_IPS}    = \%ips;
  $self->{USERS_INFO}   = \%users_info;
  $self->{SESSIONS_ID}  = \%session_ids;
  $self->{INTERIM_TIME} = \%interim_times;
  $self->{CONNECT_INFO} = \%connect_info;

  return $self;
}

#**********************************************************
#
#**********************************************************
sub traffic_agregate_clean {
  my $self = shift;

  delete $self->{AGREGATE_USERS};
  delete $self->{INTERIM};
  delete $self->{IN};
}

#**********************************************************
# traffic_agregate_users
# Get Data and agregate it by users
#**********************************************************
sub traffic_agregate_users {
  my $self = shift;
  my ($DATA) = @_;

  my $users_ips = $self->{USERS_IPS};
  my $y         = 0;
  if (defined($users_ips->{ $DATA->{SRC_IP} })) {
    my $uid = $users_ips->{ $DATA->{SRC_IP} };
    if (defined($DATA->{TRAFFIC_CLASS})) {
      $self->{INTERIM}{ $DATA->{SRC_IP} }{ $DATA->{TRAFFIC_CLASS} }{OUT} += $DATA->{SIZE};
    }
    else {
      push @{ $self->{AGREGATE_USERS}{$uid}{OUT} }, {%$DATA};
    }

    $DATA->{UID} = $uid;
    $y++;
  }
  else {
    if ($ip_user_hash{$DATA->{SRC_IP}}) {
      my $uid = $ip_user_hash{$DATA->{SRC_IP}};  
      push @{ $self->{AGREGATE_USERS}{$uid}{OUT} }, {%$DATA};
      $DATA->{UID} = $uid;
      $y++;
    }
  }

  if (defined($users_ips->{ $DATA->{DST_IP} })) {
    if (defined($DATA->{TRAFFIC_CLASS})) {
      $self->{INTERIM}{ $DATA->{DST_IP} }{ $DATA->{TRAFFIC_CLASS} }{IN} += $DATA->{SIZE};
    }
    else {
      push @{ $self->{AGREGATE_USERS}{ $users_ips->{ $DATA->{DST_IP} } }{IN} }, {%$DATA};
    }
    $DATA->{UID} = $users_ips->{ $DATA->{DST_IP} };

    $y++;
  }
  else {
    if (defined($ip_user_hash{$DATA->{DST_IP}})) {
      my $uid = $ip_user_hash{$DATA->{DST_IP}};
      push @{ $self->{AGREGATE_USERS}{$uid}{IN} }, {%$DATA};
      $DATA->{UID} = $uid;
      $y++;
    }

    #Unknown Ips
    if ($y < 1) {
      $DATA->{UID} = 0;
      if ($CONF->{UNKNOWN_IP_LOG}) {
        $self->{INTERIM}{ $DATA->{UID} }{OUT} += $DATA->{SIZE};
        push @{ $self->{IN} }, "$DATA->{SRC_IP}/$DATA->{DST_IP}/$DATA->{SIZE}";
      }

      if ($DATA->{DEBUG}) {
        $self->{UNKNOWN_TRAFFIC_ROWS}++;
        $self->{UNKNOWN_TRAFFIC_SUM} += $DATA->{SIZE};
      }
      return $self;
    }
  }

  if ($DATA->{DEBUG}) {
    $self->{TRAFFIC_ROWS}++;
    $self->{TRAFFIC_SUM} += $DATA->{SIZE};
  }

  #Make user detalization
  if ($CONF->{IPN_DETAIL} && $DATA->{UID} > 0) {
    return $self if ($CONF->{IPN_DETAIL_MIN_SIZE} > $DATA->{SIZE});

    $self->traffic_add(
      {
        SRC_IP   => $DATA->{SRC_IP},
        DST_IP   => $DATA->{DST_IP},
        SRC_PORT => $DATA->{SRC_PORT} || 0,
        DST_PORT => $DATA->{DST_PORT} || 0,
        PROTOCOL => $DATA->{PROTOCOL} || 0,
        SIZE     => $DATA->{SIZE},
        NAS_ID   => $DATA->{NAS_ID} || 0,
        UID      => $DATA->{UID},
        START    => $DATA->{START},
        STOP     => $DATA->{STOP}
      }
    );
  }

  return $self;
}

#**********************************************************
#
#**********************************************************
sub traffic_agregate_nets {
  my $self = shift;
  my ($DATA) = @_;

  my $AGREGATE_USERS = $self->{AGREGATE_USERS};

  #my $ips             = $self->{USERS_IPS};
  my $user_info = $self->{USERS_INFO};
  $Dv = Dv->new($self->{db}, undef, $CONF);

  #Get user and session TP
  while (my ($uid, $session_tp) = each(%{ $user_info->{TPS} })) {
    my $TP_ID = 0;
    my $user  = $Dv->info($uid);

    if ($Dv->{TOTAL} > 0) {
      $TP_ID = $user->{TP_NUM} || 0;
      $self->{USERS_INFO}->{TPS}->{$uid} = $TP_ID;
    }

    my ($remaining_time, $ret_attr);
    if (!defined($tp_interval{$TP_ID})) {
      ($user->{TIME_INTERVALS}, $user->{INTERVAL_TIME_TARIF}, $user->{INTERVAL_TRAF_TARIF}) = $Billing->time_intervals($TP_ID);

      ($remaining_time, $ret_attr) = $Billing->remaining_time(
        0,
        {
          TIME_INTERVALS      => $user->{TIME_INTERVALS},
          INTERVAL_TIME_TARIF => $user->{INTERVAL_TIME_TARIF},
          INTERVAL_TRAF_TARIF => $user->{INTERVAL_TRAF_TARIF},
          SESSION_START       => $user->{SESSION_START},
          DAY_BEGIN           => $user->{DAY_BEGIN},
          DAY_OF_WEEK         => $user->{DAY_OF_WEEK},
          DAY_OF_YEAR         => $user->{DAY_OF_YEAR},
          REDUCTION           => $user->{REDUCTION},
          POSTPAID            => 1
        }
      );
      $tp_interval{$TP_ID} = ($ret_attr->{FIRST_INTERVAL}) ? $ret_attr->{FIRST_INTERVAL} : 0;
      $intervals{ $tp_interval{$TP_ID} }{TIME_TARIFF} = ($ret_attr->{TIME_PRICE}) ? $ret_attr->{TIME_PRICE} : 0;
    }

    print "\nUID: $uid\n####TP $TP_ID Interval: $tp_interval{$TP_ID}  ####\n" if ($self->{debug});

    if (!defined($intervals{ $tp_interval{$TP_ID} }{ZONES})) {
      $self->get_zone({ TP_INTERVAL => $tp_interval{$TP_ID} });
    }
    else {
      $self->{ZONES} = $intervals{ $tp_interval{$TP_ID} }{ZONES};
    }

    my $data_hash;

    #Get agrigation data
    if (defined($AGREGATE_USERS->{$uid})) {
      $data_hash = $AGREGATE_USERS->{$uid};
    }

    # Go to next user
    else {
      next;
    }

    my %zones;
    @zoneids = @{ $intervals{ $tp_interval{$TP_ID} }{ZONEIDS} };
    my $user_ip = $ip_range{$uid} if ($ip_range{$uid});

    if (defined($data_hash->{OUT})) {

      #Get User data array
      my $DATA_ARRAY_REF = $data_hash->{OUT};

      foreach my $DATA (@$DATA_ARRAY_REF) {
        if ($#zoneids > -1) {
          foreach my $zid (@zoneids) {
            if (ip_in_zone($DATA->{DST_IP}, $DATA->{DST_PORT}, $self->{ZONES}{$zid}{TRAFFIC_CLASS}, \%ip_class_tables)) {
              $self->{INTERIM}{ (($user_ip) ? $user_ip : $DATA->{SRC_IP}) }{"$zid"}{OUT} += $DATA->{SIZE};
              print " $zid " . int2ip($DATA->{SRC_IP}) . ":$DATA->{SRC_PORT} -> " . int2ip($DATA->{DST_IP}) . ":$DATA->{DST_PORT}  $DATA->{SIZE} / " . (($zones{$zid}{PriceOut}) ? $zones{$zid}{PriceOut} : 0.00) . "\n" if ($self->{debug});
              last;
            }
          }
        }
        else {
          print " < $DATA->{SIZE} " . int2ip($DATA->{SRC_IP}) . ":$DATA->{SRC_PORT} -> " . int2ip($DATA->{DST_IP}) . ":$DATA->{DST_PORT}\n" if ($self->{debug});
          $self->{INTERIM}{ $DATA->{SRC_IP} }{"0"}{OUT} += $DATA->{SIZE};
        }
      }
    }

    if (defined($data_hash->{IN})) {

      #Get User data array
      my $DATA_ARRAY_REF = $data_hash->{IN};
      foreach my $DATA (@$DATA_ARRAY_REF) {
        if ($#zoneids > -1) {
          foreach my $zid (@zoneids) {
            if (ip_in_zone($DATA->{SRC_IP}, $DATA->{SRC_PORT}, $self->{ZONES}{$zid}{TRAFFIC_CLASS}, \%ip_class_tables)) {
              $self->{INTERIM}{ (($user_ip) ? $user_ip : $DATA->{DST_IP}) }{"$zid"}{IN} += $DATA->{SIZE};
              print " $zid " . int2ip($DATA->{DST_IP}) . ":$DATA->{DST_PORT} <- " . int2ip($DATA->{SRC_IP}) . ":$DATA->{SRC_PORT}  $DATA->{SIZE} / $zones{$zid}{PriceIn}\n" if ($self->{debug});
              last;
            }
          }
        }
        else {
          print " > $DATA->{SIZE} " . int2ip($DATA->{SRC_IP}) . ":$DATA->{SRC_PORT} -> " . int2ip($DATA->{DST_IP}) . ":$DATA->{DST_PORT}\n" if ($self->{debug});
          $self->{INTERIM}{ $DATA->{DST_IP} }{"0"}{IN} += $DATA->{SIZE};
        }
      }
    }
  }

}

#**********************************************************
#
#**********************************************************
sub get_interval_params {
  my $self = shift;

  return \%intervals, \%tp_interval;
}

#**********************************************************
# Get zones from db
#**********************************************************
sub get_zone {
  my $self = shift;
  my ($attr) = @_;

  my $zoneid  = 0;
  my %zones   = ();
  my @zoneids = ();

  my $begin_time = check_time();

  my $tariff = $attr->{TP_INTERVAL} || 0;

  #Get traffic classes and prices
  $Tariffs = Tariffs->new($self->{db}, undef, $CONF);
  my $list = $Tariffs->tt_list({ TI_ID => $tariff });

  foreach my $line (@$list) {
    $zoneid                        = $line->[0];
    $zones{$zoneid}{PriceIn}       = $line->[1] + 0;
    $zones{$zoneid}{PriceOut}      = $line->[2] + 0;
    $zones{$zoneid}{PREPAID_TSUM}  = $line->[3] + 0;
    $zones{$zoneid}{TRAFFIC_CLASS} = $line->[9];
    push @zoneids, $zoneid;
  }

  @{ $intervals{$tariff}{ZONEIDS} } = @zoneids;
  %{ $intervals{$tariff}{ZONES} }   = %zones;

  $self->{ZONES_IDS} = $intervals{$tariff}{ZONEIDS};
  $self->{ZONES}     = $intervals{$tariff}{ZONES};

  #Get IP addresse for each traffic zones
  if (!%ip_class_tables) {
    $self->query2("SELECT id, nets FROM traffic_classes;");
    foreach my $line (@{ $self->{list} }) {
      my $zoneid = $line->[0];
      $line->[1] =~ s/\n//g;
      my @ip_list_array = split(/;/, $line->[1]);

      my $i = 0;

      foreach my $ip_full (@ip_list_array) {
        if ($ip_full =~ /([!]{0,1})(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(\/{0,1})(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\d{1,2})(:{0,1})(\S{0,100})/) {
          my $NEG = $1 || '';
          my $IP = unpack("N", pack("C4", split(/\./, $2)));
          my $NETMASK = (length($4) < 3) ? unpack "N", pack("B*", ("1" x $4 . "0" x (32 - $4))) : unpack("N", pack("C4", split(/\./, "$4")));

          print "REG $i ID: $zoneid NEGATIVE: $NEG IP: " . int2ip($IP) . " MASK: " . int2ip($NETMASK) . " Ports: $6\n" if ($self->{debug});

          $ip_class_tables{$zoneid}[$i]{IP}   = $IP;
          $ip_class_tables{$zoneid}[$i]{Mask} = $NETMASK;
          $ip_class_tables{$zoneid}[$i]{Neg}  = $NEG;

          #Get ports
          @{ $ip_class_tables{$zoneid}[$i]{'Ports'} } = ();
          if ($6 ne '') {
            my @PORTS_ARRAY = split(/,/, $6);
            foreach my $port (@PORTS_ARRAY) {
              push @{ $ip_class_tables{$zoneid}[$i]{Ports} }, $port;
            }
          }
          $i++;
        }
      }
    }

    $self->{ZONES_IPS} = \%ip_class_tables;
  }

  print " Tariff Interval: $tariff\n" . " Zone Ids:" . @{ $intervals{$tariff}{ZONEIDS} } . "\n" . " Zones:" . %{ $intervals{$tariff}{ZONES} } . "\n" if ($self->{debug});

  return $self;
}

#**********************************************************
# Check ip in zone
#**********************************************************
sub ip_in_zone($$$$) {
  my $self;
  my ($ip_num, $port, $zoneid, $zone_data) = @_;

  my $res = 0;

  # debug
  my %zones = %$zone_data;

  if ($self->{debug}) { print "--- CALL ip_in_zone($ip_num, $port, $zoneid) -> \n"; }

  return 0 if (!$zones{$zoneid});

  for (my $i = 0 ; $i <= $#{ $zones{$zoneid} } ; $i++) {
    my $adr_hash    = \%{ $zones{$zoneid}[$i] };
    my $a_ip        = $$adr_hash{'IP'};
    my $a_msk       = $$adr_hash{'Mask'};
    my $a_neg       = $$adr_hash{'Neg'};
    my $a_ports_ref = \@{ $$adr_hash{'Ports'} };
    if ( (($a_ip & $a_msk) == ($ip_num & $a_msk))
      && (is_exist($a_ports_ref, $port))) {
      if ($a_neg) {
        $res = 0;
      }
      else {
        $res = 1;
        next;
      }
    }
  }
  return $res;
}

#**********************************************************
# traffic_add_log
#**********************************************************
sub traffic_add_user {
  my $self = shift;
  my ($DATA) = @_;

  my $start = (!$DATA->{START}) ? 'now()' : "'$DATA->{START}'";
  my $stop  = (!$DATA->{STOP})  ? 0       : "'$DATA->{STOP}'";

  if ($DATA->{INBYTE} + $DATA->{OUTBYTE} > 0) {
    $self->query2("insert into ipn_log (
         uid,
         start,
         stop,
         traffic_class,
         traffic_in,
         traffic_out,
         nas_id,
         ip,
         interval_id,
         sum,
         session_id
       )
     VALUES (
       '$DATA->{UID}',
        $start,
        $stop,
       '$DATA->{TARFFIC_CLASS}',
       '$DATA->{INBYTE}',
       '$DATA->{OUTBYTE}',
       '$DATA->{NAS_ID}',
       '$DATA->{IP}',
       '$DATA->{INTERVAL}',
       '$DATA->{SUM}',
       '$DATA->{SESSION_ID}'
      );", 'do'
    );
  }

  return $self;
}

#**********************************************************
# traffic_user_get2
# Get used traffic from DB
#**********************************************************
sub traffic_user_get2 {
  my $self = shift;
  my ($attr) = @_;

  my $uid    = $attr->{UID};
  my $from   = $attr->{FROM} || '';
  my %result = ();


  if ($attr->{JOIN_SERVICE}) {
    my @uids_arr = ();
    if ($attr->{JOIN_SERVICE} == 1) {
      push @uids_arr, $uid;
      $attr->{JOIN_SERVICE} = $uid;
    }

    $self->query2("SELECT uid FROM dv_main WHERE join_service='$attr->{JOIN_SERVICE}'");
     
    foreach my $line (@{ $self->{list} }) {
      push @uids_arr, $line->[0];
    }
          
    $WHERE = "uid IN (". join(', ', @uids_arr) .") AND ";
  }
  else {
    $WHERE = " uid='$uid' and ";
  }


  if ($attr->{DATE_TIME}) {
    $WHERE = "start>=$attr->{DATE_TIME}";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL});
    $from = ($from eq '0000-00-00') ? 'DATE_FORMAT(started, \'%Y-%m\')>=DATE_FORMAT(curdate(), \'%Y-%m\')' : "DATE_FORMAT(started, '\%Y-\%m-\%d')>='$from'";
    $WHERE = "( $from AND started<'$to') ";
  }
  elsif ($attr->{ACTIVATE}) {

    if ($attr->{ACTIVATE} eq '0000-00-00') {
      $attr->{ACTIVATE} = "DATE_FORMAT(curdate(), '%Y-%m-01')";
    }
    else {
      $attr->{ACTIVATE} = "'$attr->{ACTIVATE}'";
    }
    $WHERE = "DATE_FORMAT(started, '%Y-%m-%d')>=$attr->{ACTIVATE}";

  }
  else {
    $WHERE = "DATE_FORMAT(started, '%Y-%m')>=DATE_FORMAT(curdate(), '%Y-%m')";
  }

  if (defined($attr->{TRAFFIC_ID})) {
    $WHERE .= "and traffic_class='$attr->{TRAFFIC_ID}'";
  }

  $self->query2("SELECT    started,
   uid,
   traffic_class,
   traffic_in / $CONF->{MB_SIZE},
   traffic_out / $CONF->{MB_SIZE}
    FROM traffic_prepaid_sum
        WHERE $WHERE;"
  );

  if ($self->{TOTAL} < 1) {
    $self->query2("INSERT INTO traffic_prepaid_sum (uid, started, traffic_class, traffic_in, traffic_out)
        VALUES ('$uid', $attr->{ACTIVATE}, '$attr->{TRAFFIC_ID}', '$attr->{TRAFFIC_IN}', '$attr->{TRAFFIC_OUT}')", 'do'
    );

    $result{ $attr->{TRAFFIC_ID} }{TRAFFIC_IN}  = 0;
    $result{ $attr->{TRAFFIC_ID} }{TRAFFIC_OUT} = 0;

    return \%result;
  }

  foreach my $line (@{ $self->{list} }) {

    #Trffic class
    $result{ $line->[2] }{TRAFFIC_IN}  = $line->[3];
    $result{ $line->[2] }{TRAFFIC_OUT} = $line->[4];
  }

  $self->query2("UPDATE traffic_prepaid_sum SET 
     traffic_in=traffic_in+$attr->{TRAFFIC_IN},
     traffic_out=traffic_out+$attr->{TRAFFIC_OUT}
    WHERE uid='$uid'
        and $WHERE;", 'do'
  );

  return \%result;
}

#**********************************************************
# traffic_user_get
# Get used traffic from DB
#**********************************************************
sub traffic_user_get {
  my $self = shift;
  my ($attr) = @_;

  my $uid        = $attr->{UID};
  my $traffic_id = $attr->{TRAFFIC_ID} || 0;
  my $from       = $attr->{FROM} || '';
  my %result     = ();

  if ($attr->{JOIN_SERVICE}) {
    my @uids_arr = ();
    if ($attr->{JOIN_SERVICE} == 1) {
      push @uids_arr, $uid;
      $attr->{JOIN_SERVICE} = $uid;
    }

    $self->query2("SELECT uid FROM dv_main WHERE join_service='$attr->{JOIN_SERVICE}'");
     
    foreach my $line (@{ $self->{list} }) {
      push @uids_arr, $line->[0];
    }
          
    $WHERE = " uid IN (". join(', ', @uids_arr) .") AND ";
  }
  else {
    $WHERE = " uid='$uid' and ";
  }

  if ($attr->{DATE_TIME}) {
    $WHERE .= "start>=$attr->{DATE_TIME}";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL});
    $from = ($from eq '0000-00-00') ? 'DATE_FORMAT(start, \'%Y-%m\')>=DATE_FORMAT(curdate(), \'%Y-%m\')' : "DATE_FORMAT(start, '\%Y-\%m-\%d')>='$from'";
    $WHERE .= "( $from AND start<'$to') ";
  }
  elsif ($attr->{ACTIVATE} && $attr->{ACTIVATE} ne '0000-00-00') {
    $WHERE .= "DATE_FORMAT(start, '%Y-%m-%d')>='$attr->{ACTIVATE}'";
  }
  else {
    $WHERE .= "DATE_FORMAT(start, '%Y-%m')>=DATE_FORMAT(curdate(), '%Y-%m')";
  }

  $self->query2("SELECT traffic_class, sum(traffic_in) / $CONF->{MB_SIZE}, sum(traffic_out) / $CONF->{MB_SIZE} 
    FROM ipn_log
        WHERE $WHERE
        GROUP BY uid, traffic_class;", undef, $attr
  );

  foreach my $line (@{ $self->{list} }) {
    #Trffic class
    $result{ $line->[0] }{TRAFFIC_IN}  = $line->[1];
    $result{ $line->[0] }{TRAFFIC_OUT} = $line->[2];
  }

  return \%result;
}

#**********************************************************
# traffic_add
#**********************************************************
sub traffic_add {
  my $self = shift;
  my ($DATA) = @_;

  #my $table_name = 'ipn_traf_detail';
  my $UID = $DATA->{UID} || 0;

  $DATA->{START} = (!$DATA->{START}) ? 'now()' : "'$DATA{START}'";
  $DATA->{STOP}  = (!$DATA->{STOP})  ? 'now()' : "'$DATA{STOP}'";

  $self->query2("insert into ipn_traf_detail (src_addr,
       dst_addr,
       src_port,
       dst_port,
       protocol,
       size,
       s_time,
       f_time,
       nas_id,
       uid)
     VALUES (
        $DATA->{SRC_IP},
        $DATA->{DST_IP},
       '$DATA->{SRC_PORT}',
       '$DATA->{DST_PORT}',
       '$DATA->{PROTOCOL}',
       '$DATA->{SIZE}',
        $DATA->{START},
        $DATA->{STOP},
        '$DATA->{NAS_ID}',
        '$UID'
      );", 'do'
  );

  return $self;
}

#**********************************************************
# Acct_update
#**********************************************************
sub acct_update {
  my $self = shift;
  my ($DATA) = @_;

  $self->query2("UPDATE dv_calls SET
      sum=sum+$DATA->{SUM},
      acct_input_octets=acct_input_octets+$DATA->{INTERIUM_INBYTE},
      acct_output_octets=acct_output_octets+$DATA->{INTERIUM_OUTBYTE},
      ex_input_octets=ex_input_octets + $DATA->{INBYTE2},
      ex_output_octets=ex_output_octets + $DATA->{OUTBYTE2},
      acct_input_gigawords='$DATA->{ACCT_INPUT_GIGAWORDS}',
      acct_output_gigawords='$DATA->{ACCT_OUTPUT_GIGAWORDS}',
      status='3',
      acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
      framed_ip_address=INET_ATON('$DATA->{FRAMED_IP_ADDRESS}'),
      lupdated=UNIX_TIMESTAMP()
    WHERE
      acct_session_id='$DATA->{ACCT_SESSION_ID}' and 
      uid='$DATA->{UID}' and
      nas_id='$DATA->{NAS_ID}';", 'do'
  );

  if ($self->{USERS_INFO}->{DEPOSIT}->{ $DATA->{UID} }) {

    #Take money from bill
    if ($DATA->{SUM} > 0) {
      $self->query2("UPDATE bills SET deposit=deposit-$DATA->{SUM} WHERE id='$self->{USERS_INFO}->{BILL_ID}->{$DATA->{UID}}';", 'do');
    }

    #If negative deposit hangup
    if ($self->{USERS_INFO}->{DEPOSIT}->{ $DATA->{UID} } - $DATA->{SUM} < 0) {
      $self->{USERS_INFO}->{DEPOSIT}->{ $DATA->{UID} } = $self->{USERS_INFO}->{DEPOSIT}->{ $DATA->{UID} } - $DATA->{SUM};
    }
  }

  return $self;
}

#**********************************************************
# Acct_stop
#**********************************************************
sub acct_stop {
  my $self = shift;
  my ($attr) = @_;
  my $session_id;

  if (defined($attr->{SESSION_ID})) {
    $session_id = $attr->{SESSION_ID};
  }
  else {
    return $self;
  }

  my $ACCT_TERMINATE_CAUSE = (defined($attr->{ACCT_TERMINATE_CAUSE})) ? $attr->{ACCT_TERMINATE_CAUSE} : 0;

  my $sql = "select u.uid, calls.framed_ip_address, 
      calls.user_name,
      calls.acct_session_id,
      calls.acct_input_octets AS input_octets,
      calls.acct_output_octets AS output_octets,
      acct_input_gigawords, 
      acct_output_gigawords,
      dv.tp_id,
      if(u.company_id > 0, cb.id, b.id) AS bill_id,
      if(c.name IS NULL, b.deposit, cb.deposit)+u.credit AS deposit,
      calls.started AS start,
      UNIX_TIMESTAMP()-UNIX_TIMESTAMP(calls.started) AS acct_session_time,
      nas_id,
      nas_port_id AS nas_port
    FROM (dv_calls calls, users u)
      LEFT JOIN companies c ON (u.company_id=c.id)
      LEFT JOIN bills b ON (u.bill_id=b.id)
      LEFT JOIN bills cb ON (c.bill_id=cb.id)
      LEFT JOIN dv_main dv ON (u.uid=dv.uid)
    WHERE u.id=calls.user_name and acct_session_id='$session_id';";

  $self->query2($sql, undef, { INFO => 1 });

#  $self->query2("SELECT sum(l.traffic_in) AS traffic_in, 
#   sum(l.traffic_out) AS traffic_out,
#   sum(l.sum) AS sum,
#   l.nas_id
#   from ipn_log l
#   WHERE session_id='$session_id'
#   GROUP BY session_id  ;",
#   undef,
#   { INFO => 1 }
#  );

  if ($self->{TOTAL} < 1) {
    $self->query2("DELETE from dv_calls WHERE acct_session_id='$self->{ACCT_SESSION_ID}';", 'do');
    return $self;
  }

  if ($self->{OUTPUT_OCTETS} && $self->{OUTPUT_OCTETS} > 4294967296) {
    $self->{ACCT_OUTPUT_GIGAWORDS} = int($self->{OUTPUT_OCTETS} / 4294967296);
    $self->{OUTPUT_OCTETS} = $self->{OUTPUT_OCTETS} - ($self->{ACCT_OUTPUT_GIGAWORDS} * 4294967296);
  }
  elsif(! $self->{OUTPUT_OCTETS}) {
    $self->{OUTPUT_OCTETS}=0;
  }
  
  if ($self->{INPUT_OCTETS} && $self->{INPUT_OCTETS} > 4294967296) {
    $self->{ACCT_INPUT_GIGAWORDS} = int($self->{INPUT_OCTETS} / 4294967296);
    $self->{INPUT_OCTETS} = $self->{INPUT_OCTETS} - ($self->{ACCT_INPUT_GIGAWORDS} * 4294967296);
  } 
  elsif(! $self->{INPUT_OCTETS}) {
    $self->{INPUT_OCTETS}=0;
  }

  $self->query2("INSERT INTO dv_log (uid, 
    start, 
    tp_id, 
    duration, 
    sent, 
    recv, 
    acct_output_gigawords,
    acct_input_gigawords, 
    sum, 
    nas_id, 
    port_id,
    ip, 
    CID, 
    sent2, 
    recv2, 
    acct_session_id, 
    bill_id,
    terminate_cause) 
        VALUES ('$self->{UID}', '$self->{START}', '$self->{TP_ID}', 
          '$self->{ACCT_SESSION_TIME}', 
          '$self->{OUTPUT_OCTETS}', '$self->{INPUT_OCTETS}', 
          '$self->{ACCT_OUTPUT_GIGAWORDS}', '$self->{ACCT_INPUT_GIGAWORDS}',
          '$self->{SUM}', '$self->{NAS_ID}',
          '$self->{NAS_PORT}', 
          '$self->{FRAMED_IP_ADDRESS}', 
          '',
          '0', 
          '0',
          '$self->{ACCT_SESSION_ID}', 
          '$self->{BILL_ID}',
          '$ACCT_TERMINATE_CAUSE');", 'do'
  );

  $self->query2("DELETE from dv_calls WHERE acct_session_id='$self->{ACCT_SESSION_ID}';", 'do');
}

#**********************************************************
#
#**********************************************************
sub is_exist($$) {
  my ($arrayref, $elem) = @_;
  if ($#{$arrayref} == -1) { return 1; }

  foreach my $e (@$arrayref) {
    if ($e eq $elem) { return 1; }
  }
  return 0;
}

#**********************************************************
#
#**********************************************************
sub unknown_add {
  my $self = shift;
  my ($from, $to, $size, $nas_id, $attr) = @_;

  $self->query2("INSERT INTO ipn_unknow_ips (src_ip, dst_ip, size, nas_id, datetime)
        VALUES ($from, $to, $size, $nas_id, now());", 'do'
  );

  return $self;
}

1
