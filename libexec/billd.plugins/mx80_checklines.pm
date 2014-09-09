# billd plugin
#
# DESCRIBE: Check MX80 lines
#
# http://www.oidview.com/mibs/2636/JUNIPER-SUBSCRIBER-MIB.html
#
#**********************************************************

mx80_checklines();


#**********************************************************
#
#
#**********************************************************
sub mx80_checklines {
  my ($attr)=@_;
  print "mx80_checklines\n" if ($debug > 1);

  my $SNMP_COMMUNITY = $conf{MX80_SNMP_COMMUNITY} || 'public';
  use SNMP_Session;
  use SNMP_util;
  use BER;


  my %connectin_types = ( 1 => 'IPoE',
  	                      2 => 'PPPoE'    	
   	                     );
 
  my @state_staus     = (
                          'init',
                          'configured',
                          'active',
                          'terminating',
                          'terminated',
                          'unknown'                           
                        );

  my @connect_types   = ( 'none',
                          'dhcp',
                          'vlan',
                          'generic',
                          'mobileIp',
                          'vplsPw',
                          'ppp',
                          'ppppoe',
                          'l2tp',
                          'static',
                          'mlppp'
                        );

  $env{'MAX_LOG_LEVEL'}='none';
  $ENV{'MAX_LOG_LEVEL'}='none';
  $SNMP::Util::Max_log_level = 'none'; 
  $SNMP_Session::suppress_warnings=2;

  my $list       = $Nas->list({%LIST_PARAMS,
                               NAS_TYPE  => 'mx80',
                               COLS_NAME => 1,
                               DISABLE   => 0
                             });

  my %mx_extended_info = ( 
                           USER_NAME       => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.3',
                           CLIENT_TYPE     => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.4',
                           INTERFACE_TYPE  => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.10',
                           MAC 	           => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.11',
                           STATE           => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.12',
                           LOGIN_TIME      => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.13',
                           ACCT_SESSION_ID => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.14',
                          );

  foreach my $nas_info (@$list) {
    # check ips
    if ($debug > 2) {
      print "NAS: $nas_info->{nas_id} MNG IP: $nas_info->{nas_mng_ip_port} MNG_PASS: $nas_info->{nas_mng_password}\n";
    }

    my ($nas_ip, $nas_port)=split(/:/, $nas_info->{nas_mng_ip_port});

    my  $jnxSubscriberIpAddress='1.3.6.1.4.1.2636.3.64.1.1.1.3.1.5';
    my @result_ports = &snmpwalk("$SNMP_COMMUNITY".'@'."$nas_ip", "$jnxSubscriberIpAddress");

    my %active_mx_ip = ();
    foreach my $line (@result_ports) {
    	if ($debug > 5) {
    		print "$line\n";
    	}
      next if (! $line);
      my ($id, $ip) = split(/:/, $line);
      
      if ($ip ne '0.0.0.0') {
        $active_mx_ip{$ip}=$id;
        #print "$ip\n";
      }
    }

    # check billing
    $Sessions->online({ USER_NAME    => '_SHOW', 
      NAS_PORT_ID  => '_SHOW', 
      CONNECT_INFO => '_SHOW',
      TP_ID        => '_SHOW', 
      SPEED        => '_SHOW', 
      UID          => '_SHOW', 
      JOIN_SERVICE => '_SHOW', 
      CLIENT_IP    => '_SHOW',
      DURATION_SEC => '_SHOW',
      STARTED      => '_SHOW',
      CID          => '_SHOW',
      NAS_ID       => $LIST_PARAMS{nas_id},
      %LIST_PARAMS
    });

    my $online      = $Sessions->{nas_sorted};
    my $l = $online->{ $nas_info->{nas_id} };
    next if ($#{$l} < 0);
    foreach my $o (@$l) {
      if (! $active_mx_ip{$o->{client_ip}}) {
        print "Not found $o->{user_name} IP: $o->{client_ip}\n";
      }
      else {
        delete $active_mx_ip{$o->{client_ip}};
      }
    }

    while(my($ip, $id)=each %active_mx_ip) {
      print "===================\nMX80 Unknown ip: $ip .$id\n" if ($debug > 1 || $ARGV->{SHOW});
      my $user_name       =  eval{ return &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip", "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.3.".$id) };
      
      if (! $user_name) {
      	next;
      }
      
      #my $client_type     = &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip", "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.4.".$id);
      #my $acct_session_id = &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip", "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.14.".$id);
      my $login_time      =  eval{ return &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip", "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.13.".$id) };
      my $state           =  eval{ return &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip", "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.12.".$id) };
      #my $mac 	          = &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip", "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.11.".$id);
      my $connect_type 	  =  eval{ return &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip", "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.10.".$id) };

      if ($debug > 1 || defined($ARGV->{SHOW})) {
        print "User: $user_name\n".
        " Connect: $connectin_types{$connect_type} Type:  STATE: $state_staus[$state]\n".
        #" ACCT_SESSION_ID: $acct_session_id\n".
        #MAC: ". sprintf("%x", $mac). ".
        " Login time: $login_time\n";
      }
    }


  }

}



#**********************************************************
#
#**********************************************************
sub hex2bin {
  my ($digit) = shift;

  print $no_revb
  ? unpack("B4", pack("H", $digit))
  : substr(unpack("b8", pack("H", $digit)), -4);

  return "$char";
}

1
