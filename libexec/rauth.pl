#!/usr/bin/perl -w

use vars  qw(%RAD %conf $db %AUTH
 %RAD_REQUEST %RAD_REPLY %RAD_CHECK 
 $begin_time
 $nas);

use strict;
use FindBin '$Bin';
require $Bin . '/config.pl';
unshift(@INC, $Bin . '/../', $Bin . "/../Abills/$conf{dbtype}");

require Abills::Base;
Abills::Base->import();
$begin_time = check_time();

# Max session tarffic limit  (Mb)
$conf{MAX_SESSION_TRAFFIC} = 2048; 
require Abills::SQL;
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
$db  = $sql->{db};
require Nas;
$nas = Nas->new($db, \%conf);	

my %auth_mod = ();
my $GT  = '';
my $rr  = '';

#my $t = "\n\n";
#while(my($k, $v)=each(%$RAD)) {
#	$t .= "$k=\\\"$v\\\"\n";
#}
##print $t;
#my $a = `echo "$t" >> /tmp/voip_test`;
#
# This the remapping of return values 
#
#        use constant  RLM_MODULE_REJECT=>    0;#  /* immediately reject the request */
#        use constant  RLM_MODULE_FAIL=>      1;#  /* module failed, don't reply */
#        use constant  RLM_MODULE_OK=>        2;#  /* the module is OK, continue */
#        use constant  RLM_MODULE_HANDLED=>   3;#  /* the module handled the request, so stop. */
#        use constant  RLM_MODULE_INVALID=>   4;#  /* the module considers therequest invalid. */
#        use constant  RLM_MODULE_USERLOCK=>  5;#  /* reject the request (useris locked out) */
#        use constant  RLM_MODULE_NOTFOUND=>  6;#  /* user not found */
#        use constant  RLM_MODULE_NOOP=>      7;#  /* module succeeded withoutdoing anything */
#        use constant  RLM_MODULE_UPDATED=>   8;#  /* OK (pairs modified) */
#        use constant  RLM_MODULE_NUMCODES=>  9;#  /* How many return codes there are */








my $RAD;
if (! defined(%RAD_REQUEST)) {
  $RAD = get_radius_params();
  if (defined($ARGV[0]) && $ARGV[0] eq 'pre_auth') {
    require Auth;
    Auth->import();
    my $Auth = Auth->new($db, \%conf);

    $Auth->pre_auth($RAD);
    if ($Auth->{errno}) {
      log_print('LOG_INFO', "AUTH [$RAD->{USER_NAME}] MS-CHAP PREAUTH FAILED$GT");
     }
    exit 0;
   }
  elsif (defined($ARGV[0]) && $ARGV[0] eq 'post_auth') {
    post_auth();
    exit 0;
   }

  my $ret = get_nas_info($RAD);
  if($ret == 0) {
    $ret = auth($RAD);
  }
  #$db->disconnect();
  
  if ($ret == 0) {
    print $rr;
   }
  else {
    print "Reply-Message = \"$RAD_REPLY{'Reply-Message'}\"\n";
   }

  exit $ret;
}

#*******************************************************************
# get_nas_info();
#*******************************************************************
sub get_nas_info {
 my ($RAD)=@_;



 $RAD->{NAS_IP_ADDRESS}='' if (!defined($RAD->{NAS_IP_ADDRESS}));
 $RAD->{USER_NAME}='' if (!defined($RAD->{USER_NAME}));

 my %NAS_PARAMS = ('IP' => "$RAD->{NAS_IP_ADDRESS}");
 $NAS_PARAMS{NAS_IDENTIFIER}=$RAD->{NAS_IDENTIFIER} if (defined($RAD->{NAS_IDENTIFIER}));
 $nas->info({ %NAS_PARAMS });

## print "$RAD->{NAS_IP_ADDRESS} $RAD->{'NAS-IP-Address'} /// $nas->{errno}) || $nas->{TOTAL}";
#
if (defined($nas->{errno}) || $nas->{TOTAL} < 1) {
  # (defined($RAD->{NAS_IDENTIFIER})) ? $RAD->{NAS_IDENTIFIER} : ''
  access_deny("$RAD->{USER_NAME}", "Unknow server '$RAD->{NAS_IP_ADDRESS}'", 0);
  return 1;
 }
elsif(! defined($RAD->{USER_NAME}) || $RAD->{USER_NAME} eq '') {
  #access_deny("$RAD->{USER_NAME}", "Disabled NAS server '$RAD->{NAS_IP_ADDRESS}'", 0);
  return 1;
 }
elsif($nas->{NAS_DISABLE} > 0) {
  access_deny("$RAD->{USER_NAME}", "Disabled NAS server '$RAD->{NAS_IP_ADDRESS}'", 0);
  return 1;
}


  $nas->{at} = 0 if (defined($RAD->{CHAP_PASSWORD}) && defined($RAD->{CHAP_CHALLENGE}));
  return 0;
}


#*******************************************************************
# auth();
#*******************************************************************
sub auth {
 my ($RAD)=@_;

 if(defined($conf{tech_works})) {
 	 $RAD_REPLY{'Reply-Message'}="$conf{tech_works}";
 	 return 1;
  }

 $rr = '';
 my ($r, $RAD_PAIRS);

if(defined($AUTH{$nas->{NAS_TYPE}})) {
  if (! defined($auth_mod{"$nas->{NAS_TYPE}"})) {
    require $AUTH{$nas->{NAS_TYPE}} . ".pm";
    $AUTH{$nas->{NAS_TYPE}}->import();
    $auth_mod{"$nas->{NAS_TYPE}"} = $AUTH{$nas->{NAS_TYPE}}->new($db, \%conf);
   }

  ($r, $RAD_PAIRS) = $auth_mod{"$nas->{NAS_TYPE}"}->auth($RAD, $nas);
}
else {
  require Auth;
  Auth->import();
  my $Auth = Auth->new($db, \%conf);
  ($r, $RAD_PAIRS) = $Auth->dv_auth($RAD, $nas, 
                                       { MAX_SESSION_TRAFFIC => $conf{MAX_SESSION_TRAFFIC}  } );
  %RAD_REPLY = %$RAD_PAIRS;
}


#If Access deny
 if($r == 1){
    access_deny("$RAD->{USER_NAME}", "$RAD_PAIRS->{'Reply-Message'}", $nas->{NAS_ID});
    return $r;
  }
 else {
 	 #GEt Nas rad pairs
 	 $nas->{NAS_RAD_PAIRS} =~ tr/\n\r//d;

   my @pairs_arr = split(/,/, $nas->{NAS_RAD_PAIRS});
   foreach my $line (@pairs_arr) {
   	 if ($line =~ /\+\=/ ) {
   	 	 my($left, $right)=split(/\+\=/, $line, 2);
       $right =~ s/"//g;
   	 	 if (defined($RAD_REPLY{"$left"})) {
   	 	 	 $RAD_REPLY{"$left"} =~ s/\"//g;
   	 	 	 $RAD_REPLY{"$left"}="\"". $RAD_REPLY{"$left"} .",$right\"";
   	 	  }
       else {
       	 $RAD_REPLY{"$left"}="$right";
        }
   	  }
   	 else {
   	   my($left, $right)=split(/=/, $line, 2);
   	   $RAD_REPLY{"$left"}="$right";
   	  }
    }
   
   #$RAD_REPLY{'cisco-avpair'}="\"tunnel-type=VLAN,tunnel-medium-type==IEEE-802,tunnel-private-group-id=1, ip:inacl#1=deny ip 10.10.10.10 0.0.255.255 20.20.20.20 255.255.0.0\"";

   #Show pairs
   while(my($rs, $ls)=each %RAD_REPLY) {
     $rr .= "$rs = $ls,\n";
    }

   
   log_print('LOG_DEBUG', "AUTH [$RAD->{USER_NAME}] $rr");
 }




 if ($begin_time > 0)  {
   Time::HiRes->import(qw(gettimeofday));
   my $end_time = gettimeofday();
   my $gen_time = $end_time - $begin_time;
   $GT = sprintf(" GT: %2.5f", $gen_time);
  }


  log_print('LOG_INFO', "AUTH [$RAD->{USER_NAME}] NAS: $nas->{NAS_ID} ($RAD->{NAS_IP_ADDRESS})$GT");

  return $r;
}



#*******************************************************************
# post_auth()
#*******************************************************************
sub post_auth {
  my $reject_info = '';
  if (defined($RAD->{CALLING_STATION_ID})) {
    $reject_info=" CID $RAD->{CALLING_STATION_ID}";
   }
  log_print('LOG_INFO', "AUTH [$RAD->{USER_NAME}] AUTH REJECT$reject_info$GT");

  # return RLM_MODULE_OK;
}



#*******************************************************************
# access_deny($user, $message);
#*******************************************************************
sub access_deny {
  my ($user, $message, $nas_num) = @_;

  log_print('LOG_WARNING', "AUTH [$user] NAS: $nas_num $message");

  return 1;
}




1