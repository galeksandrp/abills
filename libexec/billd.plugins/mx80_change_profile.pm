# billd plugin
#
# DESCRIBE: Check run programs and run if they shutdown
#
#**********************************************************

mx80_change_profile();


#**********************************************************
#
#
#**********************************************************
sub mx80_change_profile {

  print "mx80_change_profile\n" if ($debug > 1);

  #Get speed
  if ($attr->{NAS_IDS}) {
    $LIST_PARAMS{NAS_IDS} = $attr->{NAS_IDS};
  }
  else {
    $LIST_PARAMS{TYPE} = 'mx80';
  }

  if ($debug > 7) {
    $nas->{debug}= 1 ;
    $Dv->{debug} = 1 ;
  }

  #Tps  speeds
  my %TPS_SPEEDS = ();
  my $tp_speed_list = $Dv->get_speed({ COLS_NAME => 1 });
  foreach my $tp (@$tp_speed_list) {
  	if (defined($tp->{tt_id})) {
  	  $TPS_SPEEDS{$tp->{tp_num}}{$tp->{tt_id}}= ($tp->{out_speed} * 1024). "," . ($tp->{in_speed} * 1024);
      #print "// $tp->{tp_num}}{$tp->{tt_id}}= ($tp->{out_speed} * 1024). "," . ($tp->{in_speed} * 1024); //\n";
    }
  } 

  $sessions->online(
    {
      %LIST_PARAMS,
      NAS_ID       => $LIST_PARAMS{NAS_IDS},
      FIELDS_NAMES => [ 'USER_NAME', 
                        'NAS_PORT_ID', 
                        'CONNECT_INFO',
                        'TP_ID', 
                        'SPEED', 
                        'UID', 
                        'JOIN_SERVICE', 
                        'CLIENT_IP', 
                        'DURATION_SEC', 
                        'STARTED' 
                      ],
     COLS_NAME    => 1
    }
  );

  my $online      = $sessions->{nas_sorted};


  my %nas_speeds = ();
  my $list       = $nas->list({%LIST_PARAMS, 
  	                           COLS_NAME => 1,
  	                           COLS_UPPER=> 1 
  	                         });

  foreach my $nas_info (@$list) {
    my %info_hash = ();
    my %NAS       = ();

    $debug_output .= "NAS ID: $nas_info->{NAS_ID} MNG_INFO: $nas_info->{NAS_MNG_USER}\@$nas_info->{NAS_MNG_IP_PORT}\n" if ($debug > 2);

    #if don't have online users skip it
    my $l = $online->{ $nas_info->{NAS_ID} };
    next if ($#{$l} < 0);
    foreach my $online (@$l) {
    	print "$online->{user_name} TP: $online->{tp_num}\n" if ($debug > 0);
    	my $profile_sufix = ( $online->{'CONNECT_INFO'}  =~ /demux/) ? 'pppoe' : 'ipoe';
      if  ($TPS_SPEEDS{$online->{tp_num}}) {
      	my $num = 3;
      	foreach my $tt_id ( keys %{ $TPS_SPEEDS{$online->{tp_num}} } ) {
      		print "$tt_id -> ". $TPS_SPEEDS{$online->{tp_num}}{$tt_id} . "\n" if ($debug > 1);
      		my %RAD_REPLY = ();
 		  	  my $traffic_class_name = ($tt_id >0) ? "local_$tt_id" : 'global';
    	    if ($TPS_SPEEDS{$online->{tp_num}}{$tt_id}) {
            push @{ $RAD_REPLY{'ERX-Service-Deactivate'} }, "svc-$traffic_class_name-$profile_sufix",
            push @{ $RAD_REPLY{'ERX-Service-Activate:'.(3-$tt_id)} },  "svc-$traffic_class_name-$profile_sufix(". $TPS_SPEEDS{$online->{tp_num}}{$tt_id} .")";
          }

          if ($debug > 2) {
            while(my($k, $v)=each %RAD_REPLY) {
        	    print "$k -> $v->[0]\n";
            }
          }
          
          hangup_radius($nas_info, $online->{'nas_port_id'}, $online->{'user_name'}, 
          	  { FRAMED_IP_ADDRESS => $online->{ip},
          	  	COA               => 1,
          	  	RAD_PAIRS         => \%RAD_REPLY });
      	}
      }
    }
    
  }

=comments
Удалять:

Добавлять:
ERX-Service-Activate:3 = svc-global-ipoe(73400320,73400320)

        Acct-Interim-Interval = 90
        ERX-Service-Activate:2 = "svc-local_1-ipoe(5148672,4120576)"
        Framed-IP-Address = 192.168.109.189
        Framed-IP-Netmask = 255.255.255.255
        ERX-Service-Activate:3 = "svc-global-ipoe(2076672,1048576)"
=cut

  exit;
  print $debug_output;

  return \%nas_speeds;
}


1
