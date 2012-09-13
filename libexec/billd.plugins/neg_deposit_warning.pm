# billd plugin
#
# DESCRIBE: Check run programs and run if they shutdown
#
#**********************************************************

neg_deposit_warning();


#**********************************************************
#
#
#**********************************************************
sub neg_deposit_warning {
  my ($attr)=@_;
  print "neg_deposit_warning\n" if ($debug > 1);

  if ($debug > 7) {
    $nas->{debug}= 1 ;
    $Dv->{debug} = 1 ;
    $sessions->{debug}=1;
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
                        'CID',
                        'DEPOSIT',
                        'CREDIT',
                        'PAYMENT_METHOD'
                      ],
      FILTER       => "<0",                
      FILTER_FIELD => '20',
      COLS_NAME    => 1
    }
  );

  #my $online      = $sessions->{nas_sorted};

  foreach my $info (@{ $sessions->{list} }) {
  print "Login: $info->{user_name} IP: $info->{ip} DEPOSIT: $info->{deposit} CREDIT: $info->{credit}\n" if ($debug);
    if ($info->{deposit} + $info->{credit} <= 0 && $info->{payment_type} == 0) {
    	mk_redirect({ IP => $info->{ip} });
    }
  }
}


#**********************************************************
#
#**********************************************************
sub mk_redirect {
  my ($attr)=@_;
	
	my $cmd = '';
	
	if ($conf{NEG_DEPOSIT_WARNING_CMD}) {
		$cmd = $conf{NEG_DEPOSIT_WARNING_CMD};
		$cmd =~ s/IP/$attr->{IP}/g;
	}
	elsif ($OS eq 'FreeBSD') {
		$cmd = "/usr/local/bin/sudo /sbin/ipfw table 32 add $attr->{IP}";
		#/usr/local/bin/sudo /sbin/ipfw table 10 delete $attr->{IP};
		#/usr/local/bin/sudo /sbin/ipfw table 11 delete $attr->{IP};";
	}
	elsif($OS eq 'Linux') {
		
	}
	
	if ($debug) {
		print "$cmd\n";
	}
	
	if ($debug<5) {
	  my $result = `$cmd`;
	}
	
}

1
