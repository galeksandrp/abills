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
  my ($attr)=@_;
  print "mx80_change_profile\n" if ($debug > 1);

  #Get speed
  if (! $LIST_PARAMS{NAS_IDS}) {
    $LIST_PARAMS{TYPE} = 'mx80';
  }

  if ($debug > 7) {
    $nas->{debug}= 1 ;
    $Dv->{debug} = 1 ;
    $sessions->{debug}=1;
  }
  
  #Tps  speeds
  my %TPS_SPEEDS = ();
  my $tp_speed_list = $Dv->get_speed({ COLS_NAME => 1, DESC => 'DESC' });
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
                        'STARTED' ,
                        'CID'
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
    	my $profile_sufix = 'pppoe';
      
      if ( $online->{'CONNECT_INFO'}  !~ /demux/) {
        $profile_sufix = 'ipoe';
        $online->{'user_name'}=$online->{CID};
      }
      
      if  ($TPS_SPEEDS{$online->{tp_num}}) {
      	my $num = 3;
    		my %RAD_REPLY_DEACTIVATE = ();
    		my %RAD_REPLY_ACTIVATE   = ();

      	foreach my $tt_id ( keys %{ $TPS_SPEEDS{$online->{tp_num}} } ) {
      		print "$tt_id -> ". $TPS_SPEEDS{$online->{tp_num}}{$tt_id} . "\n" if ($debug > 1);
 		  	  my $traffic_class_name = ($tt_id >0) ? "local_$tt_id" : 'global';
    	    if ($TPS_SPEEDS{$online->{tp_num}}{$tt_id}) {
            push @{ $RAD_REPLY_DEACTIVATE{'ERX-Service-Deactivate'} }, "svc-$traffic_class_name-$profile_sufix";
            push @{ $RAD_REPLY_ACTIVATE{'ERX-Service-Activate:'.$tt_id} },  "svc-$traffic_class_name-$profile_sufix(". $TPS_SPEEDS{$online->{tp_num}}{$tt_id} .")";
          }
      	}

        if ($debug > 2) {
#          while(my($k, $v)=each %{ \%RAD_REPLY_DEACTIVATE, \%RAD_REPLY_ACTIVATE }) {
#      	    print "$k -> \n";
#      	    foreach my $val (@$v) {
#      	    	print "       $val\n";
#      	    }
#          }
        }

        hangup_radius($nas_info, $online->{'nas_port_id'}, $online->{'user_name'}, 
          	  { FRAMED_IP_ADDRESS => $online->{ip},
          	  	COA               => 1,
          	  	RAD_PAIRS         => \%RAD_REPLY_DEACTIVATE, 
          	    DEBUG             => (($debug > 2) ? 1 : 0)
          	  });


        my $rad_vals = '';
        while(my($k, $v)=each %{ \%RAD_REPLY_DEACTIVATE, \%RAD_REPLY_ACTIVATE }) {
      	  foreach my $val (@$v) {
      	    $rad_vals .=  "$k=\\\"$v\\\",";
   	      }
        }
        
        my $run = "echo \"$rad_vals User-Name=\\\"$online->{'user_name'}\\\"\" | /usr/local/bin/radclient $nas_info->{NAS_MNG_IP_PORT} coa $nas_info->{NAS_MNG_PASSWORD}";
        if ($debug > 2 ) {
        	print $run;
        }
        my $cmd = `$run`;

#        hangup_radius($nas_info, $online->{'nas_port_id'}, $online->{'user_name'}, 
#          	  { FRAMED_IP_ADDRESS => $online->{ip},
#          	  	COA               => 1,
#          	  	RAD_PAIRS         => \%RAD_REPLY_ACTIVATE,
#          	  	DEBUG             => (($debug > 2) ? 1 : 0)
#          	  	});

        

      }
    }
    
  }

=comments
�������:

���������:
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
