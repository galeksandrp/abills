package Billing;
# Main billing functions
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
@ISA  = ("main");
my $db;

my ($tariffs, $time_intervals, $periods_time_tarif, $periods_traf_tarif);


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db) = @_;
  my $self = { };
  bless($self, $class);
#  $self->{debug}=1;
  return $self;
}


#**********************************************************
#
#**********************************************************
sub traffic_calculations {
	my $self = shift;
	my ($RAD, $conf)=@_;
	
  my $sent = $RAD->{OUTBYTE} || 0; #from server
  my $recv = $RAD->{INBYTE} || 0;  #to server
  my $sent2 = $RAD->{OUTBYTE2} || 0; 
  my $recv2 = $RAD->{INBYTE2} || 0;

	
=comments
#local Prepaid Traffic
# Separated local prepaid and global prepaid
#
#####################################################################
# Local and global in one prepaid tarif
#
 if ($prepaid{gl} + $prepaid{lo} > 0) {

    my %prepaid_price = ();

    $prepaid_price{'lo'} = $month_abon / $prepaid{lo} || 0; #  if ($prepaid{lo} > 0);
    $prepaid_price{'gl'} = $month_abon / $prepaid{gl} || 0; #  if ($prepaid{gl} > 0);

    #Get traffic from begin of month
    $sql = "SELECT sum(sent + recv) / 1024 / 1024, 
                   sum(sent2 + recv2) / 1024 / 1024
       FROM log 
       WHERE uid='$self->{UID}' and (start>=DATE_FORMAT(curdate(), '%Y-%m-00'))
       GROUP BY uid";

    my $q = $db->prepare($sql) || die $db->errstr;
    $q ->execute();

    if ($q->rows() > 1) {
       my($used_traffic, $used_traffic2)=$q->fetchrow() 
       
       if (($used_traffic   / 1024 / 1024) * $prepaid_price{'gl'} + ($used_traffic2  / 1024 / 1024) * $prepaid_price{'lo'} 
         + (($sent + $recv) / 1024 / 1024) * $prepaid_price{'gl'} + (($sent2 + $recv2) / 1024 / 1024) * $prepaid_price{'lo'} 
          < $month_abon) {
           return $uid, 0, $account_id, $TP_ID, 0, 0;
        }

     }
    elsif((($sent + $recv) / 1024 / 1024) * $prepaid_price{'lg'} + (($sent2 + $recv2) / 1024 / 1024) * $prepaid_price{'lo'} 
          < $month_abon) {
       return $uid, 0, $account_id, $TP_ID, 0, 0;
     }
    elsif((($sent + $recv) / 1024 / 1024) * $prepaid_price{'lg'} + (($sent2 + $recv2) / 1024 / 1024) * $prepaid_price{'lo'} 
          > $month_abon) {
       $sent = 0;
       $recv = 0;
       $sent2 = 0;
       $recv2  = 0;
     }


  }


####################################################################
# Global prepaid traffic
# And local calculate traffic

 if ($prepaid_traffic > 0) {
    $sql = "SELECT (sent + recv) / 1024 / 1024, (sent2 + recv2) / 1024 / 1024  
     FROM log WHERE uid='$self->{UID}' and start>'$self->{ACTIVATE}'";

    my $q = $db->prepare($sql) || die $db->errstr;
    $q ->execute();


    if ($q->rows() > 1) {
       my($used_traffic, $used_traffic2)=$q->fetchrow();
       if ($prepaid_traffic > ($used_traffic + $sent + $recv) / 1024 / 1024 ) {
          return $uid, 0, $account_id, $TP_ID, 0, 0;
          # $sent = 0;
          # $recv = 0;
         }
       elsif(($prepaid_traffic > $used_traffic / 1024 / 1024) && 
         ($prepaid_traffic < ($used_traffic + $sent + $recv) / 1024 / 1024)) {
    	  my  $not_prepaid = ($used_traffic + $sent + $recv - $prepaid_traffic * 1024 * 1024) / 2;
    	  $sent = $not_prepaid;
          $recv = $not_prepaid;
#          my $sent2 = $trafic->{sent2} || 0; 
#          my $recv2 = $trafic->{recv2} || 0;
         }
     }
    elsif (($sent + $recv) / 1024 / 1024 < $prepaid_traffic) {
       	  return $uid, 0, $account_id, $TP_ID, 0, 0;
       	  #$sent = 0;
          #$recv = 0;
     }
    elsif($prepaid_traffic < ($sent + $recv) / 1024 / 1024) {
    	  my  $not_prepaid = ($sent + $recv - $prepaid_traffic * 1024 * 1024) / 2;
    	  $sent = $not_prepaid;
        $recv = $not_prepaid;
#          my $sent2 = $trafic->{sent2} || 0; 
#          my $recv2 = $trafic->{recv2} || 0;
     }

  }
=cut
	

####################################################################
# Prepaid local and global traffic separately



my %traf_price = ();
my %prepaid = ();
my %used_traffic=( 0 => 0, 
                   1 => 0);

my $list = $tariffs->tt_list(TP_ID => $self->{TP_ID});
#id, in_price, out_price, prepaid, speed, descr, nets
foreach my $line (@$list) {
   $traf_price{in}{$line->[0]}  =	$line->[1];
   $traf_price{out}{$line->[0]} =	$line->[2];
   $prepaid{$line->[0]}         = $line->[3];
}


if ($prepaid{0} + $prepaid{1} > 0) {
   #Get traffic from begin of month
   $self->query($db, "SELECT sum(sent + recv), sum(sent2 + recv2)
       FROM log WHERE uid='$self->{UID}' and (DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m'))
       GROUP BY uid;");

   if ($self->{TOTAL} > 0) {
     my $a_ref = $self->{list}->[0];
     ($used_traffic{0}, $used_traffic{1})=@$a_ref;
    }
    
   # If left global prepaid traffic set traf price to 0
   if (($used_traffic{0} + $sent + $recv) / 1024 / 1024 < $prepaid{0}) {
     $traf_price{in}{0} = 0;
     $traf_price{out}{0} = 0;
    }
   # 
   elsif (($used_traffic{0} + $sent + $recv) / 1024 / 1024 > $prepaid{0} 
            && $used_traffic{0} / 1024 / 1024 < $prepaid{0}) {
     my $not_prepaid = ($used_traffic{0} + $sent + $recv) - $prepaid{0} * 1024 * 1024;
     $sent = $not_prepaid / 2;
     $recv = $not_prepaid / 2;
    }

   # If left local prepaid traffic set traf price to 0
   if (($used_traffic{1} + $sent2 + $recv2) / 1024 / 1024 < $prepaid{1}) { 
     $traf_price{in}{1} = 0;
     $traf_price{out}{1} = 0;
    }
   elsif ( (($used_traffic{1} + $sent2 + $recv2) / 1024 / 1024 > $prepaid{1}) 
      && ( $used_traffic{1} / 1024 / 1024 < $prepaid{1}) ) {
     my $not_prepaid = ($used_traffic{1} + $sent2 + $recv2) - $prepaid{1} * 1024 * 1024;
     $sent2 = $not_prepaid / 2;
     $recv2 = $not_prepaid / 2;
    }
 }


#####################################################################
# TRafic payments
 my $traf_sum = 0;

 my $gl_in  = $recv / 1024 / 1024 * $traf_price{in}{0};
 my $gl_out = $sent / 1024 / 1024 * $traf_price{out}{0};
 my $lo_in  = $recv2 / 1024 / 1024 * $traf_price{in}{1};
 my $lo_out = $sent2 / 1024 / 1024 * $traf_price{out}{1};
 $traf_sum  = $lo_in + $lo_out + $gl_in + $gl_out;

 return $traf_sum;

}

#**********************************************************
# Calculate session sum
# Return 
# >= 0 - session sum
# -1 Less than minimun session trafic and time
# -2 Not found user in users db
# -3 Not allow start period
#
# session_sum($USER_NAME, $SESSION_START, $SESSION_DURATION, $RAD_HASH_REF);
#**********************************************************
sub session_sum2 {
 my $self = shift;
 my ($USER_NAME, $SESSION_START, $SESSION_DURATION, $RAD, $conf) = @_;

 my $sum = 0;
 my ($TP_ID);

 my $sent = $RAD->{OUTBYTE} || 0; #from server
 my $recv = $RAD->{INBYTE} || 0;  #to server
 my $sent2 = $RAD->{OUTBYTE2} || 0; 
 my $recv2 = $RAD->{INBYTE2} || 0;

 if ((defined($conf->{MINIMUM_SESSION_TIME}) && $SESSION_DURATION < $conf->{MINIMUM_SESSION_TIME}) || 
    (defined($conf->{MINIMUM_SESSION_TRAF}) && $sent + $recv < $conf->{MINIMUM_SESSION_TRAF})) {
    
    return -1, 0, 0, 0, 0, 0;
  }



 $self->query($db, "SELECT 
   u.uid,
   tp.id, 
   tp.hourp,
   UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME($SESSION_START), '%Y-%m-%d')),
   DAYOFWEEK(FROM_UNIXTIME($SESSION_START)),
   DAYOFYEAR(FROM_UNIXTIME($SESSION_START)),
   u.reduction,
   u.account_id,
   u.activate,
   tp.day_fee
 FROM users u, tarif_plans tp
 WHERE u.tp_id=tp.id and u.id='$USER_NAME';");

 if($self->{errno}) {
   return -3, 0, 0, 0, 0, 0;
  }
 #user not found
 elsif ($self->{TOTAL} < 1) {
   return -2, 0, 0, 0, 0, 0;	
  }



  my $ar = $self->{list}->[0];
  
  ($self->{UID}, 
   $self->{TP_ID}, 
   $self->{MAIN_TIME_TARIF}, 
   $self->{DAY_BEGIN}, 
   $self->{DAY_OF_WEEK}, 
   $self->{DAY_OF_YEAR}, 
   $self->{REDUCTION},
   $self->{ACCOUNT_ID}, 
   $self->{ACTIVATE},
   $self->{DAY_FEE}
  ) = @$ar;

  use Tariffs;
  $tariffs = Tariffs->new($db);


 $self->session_splitter2($SESSION_START,
                   $SESSION_DURATION,
                   $self->{DAY_BEGIN},
                   $self->{DAY_OF_WEEK}, 
                   $self->{DAY_OF_YEAR},
                   { TP_ID => $self->{TP_ID} }
                  );
 
 #session devisions
 
 my $sd = $self->{TIME_DIVISIONS};
 my $interval_count =  keys %$sd;
 
 if($interval_count < 1) {
 	#print "NOt allow start period";
 	return -3, 0, 0, 0, 0, 0;	
 }
 
 print "$interval_count\n";
 
 while(my($k, $v)=each(%$sd)) {
 	 print "> $k, $v\n";
   if(defined($periods_time_tarif->{$k})) {
   	   $sum += ($v * $periods_time_tarif->{$k}) / 60 / 60;
     }

   if($periods_traf_tarif->{$k} > 0) {
   	  $sum  += $self->traffic_calculations($k, $RAD, $conf);
    }
  }






$sum = $sum * (100 - $self->{REDUCTION}) / 100 if ($self->{REDUCTION} > 0);
#$sum = $conf->{MINIMUM_SESSION_COST} if ($sum < $conf->{MINIMUM_SESSION_COST} && $time_tarif + $traf_price{in}{1} + $traf_price{out}{1} + $traf_price{out}{0} + $traf_price{in}{0} > 0);


print "SUM: $sum /\n";
return $self->{UID}, $sum, $self->{ACCOUNT_ID}, $self->{TP_ID}, 0, 0;




#  return $uid, $sum, $account_id, $TP_ID, $time_tarif, 0;
}




#********************************************************************
# Calculate session sum
# Return 
# >= 0 - session sum
# -1 Less than minimun session trafic and time
# -2 Not found user in users db
#
# session_sum($USER_NAME, $SESSION_START, $SESSION_DURATION, $RAD_HASH_REF);
#**********************************************************
sub session_sum {
 my $self = shift;
 my ($USER_NAME, $SESSION_START, $SESSION_DURATION, $RAD, $conf) = @_;
 my $sum = 0;
 my ($TP_ID);
 my $sent = $RAD->{OUTBYTE} || 0; #from server
 my $recv = $RAD->{INBYTE} || 0;  #to server
 my $sent2 = $RAD->{OUTBYTE2} || 0; 
 my $recv2 = $RAD->{INBYTE2} || 0;


#minimal session time or traff
 if ((defined($conf->{MINIMUM_SESSION_TIME}) && $SESSION_DURATION < $conf->{MINIMUM_SESSION_TIME}) || 
    (defined($conf->{MINIMUM_SESSION_TRAF}) && $sent + $recv < $conf->{MINIMUM_SESSION_TRAF})) {
    return -1, 0, 0, 0, 0, 0;
  }

 $self->query($db, "select 
   u.uid,
   tp.id, 
   tp.hourp,
   if (traft.id IS NULL, 0, traft.id),
   if (traft.in_price IS NULL, 0, traft.in_price),
   if (traft.out_price IS NULL, 0, traft.out_price),
   traft.prepaid,

   UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME($SESSION_START), '%Y-%m-%d')),
   DAYOFWEEK(FROM_UNIXTIME($SESSION_START)),
   DAYOFYEAR(FROM_UNIXTIME($SESSION_START)),
   
   u.reduction,
   u.account_id,

   u.activate,
   tp.abon
      
 FROM users u, tarif_plans tp
 LEFt JOIN trafic_tarifs traft on traft.tp_id=tp.id
 WHERE u.tp_id=tp.id and u.id='$USER_NAME';");

 if($self->{errno}) {
   return -3;
  }
 elsif ($self->{TOTAL} < 1) {
   return -2;	
  }




 my $time_tarif = 0;
 my $trafic_tarif = 0;
 my %traf_price = ();       # TRaffic  price
 my $account_id = 0;

 $traf_price{in}{1} = 0;
 $traf_price{out}{1} = 0;
 $traf_price{in}{0} = 0;
 $traf_price{out}{0} = 0;

 my %prepaid = ();          # Prepaid traffic Mb
  $prepaid{0} = 0;
  $prepaid{1} = 0;

 my $reduction = 0;
 my $uid = -2;
 my $day_begin = 0; 
 my $day_of_week = 0;
 my $day_of_year = 0;

 my $list = $self->{list};

 foreach my $line (@$list) {
   $uid = $line->[0];
   $TP_ID = $line->[1];
   $time_tarif=$line->[2] if ($line->[2] > 0);
   
   $traf_price{in}{$line->[3]} = $line->[4] || 0;
   $traf_price{out}{$line->[3]} = $line->[5] || 0;
   $prepaid{$line->[3]} = $line->[6] || 0;

   $day_begin = $line->[7] || 0;
   $day_of_week = $line->[8] || 0;
   $day_of_year = $line->[9] || 0;
   

   $reduction = $line->[10];
   $account_id = $line->[11];
  }

#print "///$reduction, $account_id //\n\n";

=comments
#local Prepaid Traffic
# Separated local prepaid and global prepaid
#


#####################################################################
# Local and global in one prepaid tarif
#
 if ($prepaid{gl} + $prepaid{lo} > 0) {

    my %prepaid_price = ();

    $prepaid_price{'lo'} = $month_abon / $prepaid{lo} || 0; #  if ($prepaid{lo} > 0);
    $prepaid_price{'gl'} = $month_abon / $prepaid{gl} || 0; #  if ($prepaid{gl} > 0);

    # start>'$activate'
    #Get traffic from begin of month
    $sql = "SELECT sum(sent + recv) / 1024 / 1024, sum(sent2 + recv2) / 1024 / 1024
       FROM log WHERE uid='$uid' and (start>=DATE_FORMAT(curdate(), '%Y-%m-00'))
       GROUP BY uid";


    my $q = $db->prepare($sql) || die $db->errstr;
    $q ->execute();

    if ($q->rows() > 1) {
       my($used_traffic, $used_traffic2)=$q->fetchrow() 
       
       if (($used_traffic   / 1024 / 1024) * $prepaid_price{'gl'} + ($used_traffic2  / 1024 / 1024) * $prepaid_price{'lo'} 
         + (($sent + $recv) / 1024 / 1024) * $prepaid_price{'gl'} + (($sent2 + $recv2) / 1024 / 1024) * $prepaid_price{'lo'} 
          < $month_abon) {
           return $uid, 0, $account_id, $TP_ID, 0, 0;
        }

     }
    elsif((($sent + $recv) / 1024 / 1024) * $prepaid_price{'lg'} + (($sent2 + $recv2) / 1024 / 1024) * $prepaid_price{'lo'} 
          < $month_abon) {
       return $uid, 0, $account_id, $TP_ID, 0, 0;
     }
    elsif((($sent + $recv) / 1024 / 1024) * $prepaid_price{'lg'} + (($sent2 + $recv2) / 1024 / 1024) * $prepaid_price{'lo'} 
          > $month_abon) {
       $sent = 0;
       $recv = 0;
       $sent2 = 0;
       $recv2  = 0;
     }


  }


####################################################################
# Global prepaid traffic
# And local calculate traffic

 if ($prepaid_traffic > 0) {
    $sql = "SELECT (sent + recv) / 1024 / 1024, (sent2 + recv2) / 1024 / 1024  
     FROM log WHERE uid='$uid' and start>'$activate'";

    my $q = $db->prepare($sql) || die $db->errstr;
    $q ->execute();


    if ($q->rows() > 1) {
       my($used_traffic, $used_traffic2)=$q->fetchrow();
       if ($prepaid_traffic > ($used_traffic + $sent + $recv) / 1024 / 1024 ) {
          return $uid, 0, $account_id, $TP_ID, 0, 0;
          # $sent = 0;
          # $recv = 0;
         }
       elsif(($prepaid_traffic > $used_traffic / 1024 / 1024) && 
         ($prepaid_traffic < ($used_traffic + $sent + $recv) / 1024 / 1024)) {
    	  my  $not_prepaid = ($used_traffic + $sent + $recv - $prepaid_traffic * 1024 * 1024) / 2;
    	  $sent = $not_prepaid;
          $recv = $not_prepaid;
#          my $sent2 = $trafic->{sent2} || 0; 
#          my $recv2 = $trafic->{recv2} || 0;
         }
     }
    elsif (($sent + $recv) / 1024 / 1024 < $prepaid_traffic) {
       	  return $uid, 0, $account_id, $TP_ID, 0, 0;
       	  #$sent = 0;
          #$recv = 0;
     }
    elsif($prepaid_traffic < ($sent + $recv) / 1024 / 1024) {
    	  my  $not_prepaid = ($sent + $recv - $prepaid_traffic * 1024 * 1024) / 2;
    	  $sent = $not_prepaid;
        $recv = $not_prepaid;
#          my $sent2 = $trafic->{sent2} || 0; 
#          my $recv2 = $trafic->{recv2} || 0;
     }

  }
=cut


####################################################################
# Prepaid local and global traffic separately

 my %used_traffic = ();
 if ($prepaid{0} + $prepaid{1} > 0) {
   $used_traffic{0}=0;
   $used_traffic{1}=0;

   # start>'$activate'
   #Get traffic from begin of month
   $self->query($db, "SELECT sum(sent + recv), sum(sent2 + recv2)
       FROM log WHERE uid='$uid' and (DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m'))
       GROUP BY uid;");

   #$a = `echo "$sql,\n $used_traffic, $used_traffic2,  $prepaid{gl}, $prepaid{lo} \n---\n" > /tmp/test`;

   if ($self->{TOTAL} > 0) {
     my $a_ref = $self->{list}->[0];
     ($used_traffic{0}, $used_traffic{1})=@$a_ref;
    }
    
   # If left global prepaid traffic set traf price to 0
   if (($used_traffic{0} + $sent + $recv) / 1024 / 1024 < $prepaid{0}) {
     $traf_price{in}{0} = 0;
     $traf_price{out}{0} = 0;
    }
   # 
   elsif (($used_traffic{0} + $sent + $recv) / 1024 / 1024 > $prepaid{0} 
            && $used_traffic{0} / 1024 / 1024 < $prepaid{0}) {
     my $not_prepaid = ($used_traffic{0} + $sent + $recv) - $prepaid{0} * 1024 * 1024;
     $sent = $not_prepaid / 2;
     $recv = $not_prepaid / 2;
    }

   # If left local prepaid traffic set traf price to 0
   if (($used_traffic{1} + $sent2 + $recv2) / 1024 / 1024 < $prepaid{1}) { 
     $traf_price{in}{1} = 0;
     $traf_price{out}{1} = 0;
    }
   elsif ( (($used_traffic{1} + $sent2 + $recv2) / 1024 / 1024 > $prepaid{1}) 
      && ( $used_traffic{1} / 1024 / 1024 < $prepaid{1}) ) {
     my $not_prepaid = ($used_traffic{1} + $sent2 + $recv2) - $prepaid{1} * 1024 * 1024;
     $sent2 = $not_prepaid / 2;
     $recv2 = $not_prepaid / 2;
    }
 }



##################################################################### 
# Time tarif payments

 my $time_sum = 0;
 if ($time_tarif > 0) {
   
   my ($intervals, $time_prices, $traf_price) = $self->time_intervals($TP_ID);   

   if (ref($intervals) eq 'HASH') {
     my $division_time = session_splitter("$SESSION_START", "$SESSION_DURATION", $day_begin, $day_of_week, 
     $day_of_year, $intervals);

     my $secsum = 0;
     while(my($tarif_day, $params)=each %$division_time) {
       my $period_sum = 0;
       while(my($interval, $secs)=each %$params) {
   	     $secsum += $secs;
         if ($time_prices->{$tarif_day}{$interval} =~ /%$/) {
           my $price = $time_prices->{$tarif_day}{$interval};
           $price =~ tr/\%//d;
           $period_sum = ($time_tarif  / 60 / 60) * $secs * ($price / 100);
          }
         else {
           $period_sum = $time_prices->{$tarif_day}{$interval} * ($secs / 60 / 60);
          }
         $time_sum += $period_sum;
        }
      }
    }
   else {
     $time_sum = $time_tarif * ($SESSION_DURATION / 60 / 60);
    }
  }


#####################################################################
# TRafic payments
    my $traf_sum = 0;

    if ($traf_price{in}{0} + $traf_price{out}{0} + $traf_price{out}{1} + $traf_price{in}{1} > 0) {
       my $gl_in = $recv / 1024 / 1024 * $traf_price{in}{0};
       my $gl_out  = $sent / 1024 / 1024 * $traf_price{out}{0};
       my $lo_in = $recv2 / 1024 / 1024 * $traf_price{in}{1};
       my $lo_out  = $sent2 / 1024 / 1024 * $traf_price{out}{1};
       $traf_sum = $lo_in + $lo_out + $gl_in + $gl_out;
     }

   $sum = $time_sum + $traf_sum;
   $sum = $sum * (100 - $reduction) / 100 if ($reduction > 0);
   $sum = $conf->{MINIMUM_SESSION_COST} if ($sum < $conf->{MINIMUM_SESSION_COST} && $time_tarif + $traf_price{in}{1} + $traf_price{out}{1} + $traf_price{out}{0} + $traf_price{in}{0} > 0);

 
 


  return $uid, $sum, $account_id, $TP_ID, $time_tarif, 0;
}




#********************************************************************
# Get Time intervals
# time intervals($TP_ID, $attr)
#********************************************************************
sub time_intervals {
 my $self = shift;
 my ($TP_ID, $attr) = @_;

 $self->query($db, "SELECT i.day, TIME_TO_SEC(i.begin),
   TIME_TO_SEC(i.end),
   i.tarif,
   if(sum(tt.in_price+tt.out_price) IS NULL || sum(tt.in_price+tt.out_price)=0, 0, sum(tt.in_price+tt.out_price)),
   i.id
   FROM intervals i
   LEFT JOIN  trafic_tarifs tt ON (tt.interval_id=i.id)
   WHERE i.tp_id='$TP_ID'
   GROUP BY i.id
   ORDER BY 1;");

 if ($self->{TOTAL} < 1) {
     return 0;	
   }

 my %time_periods = ();
 my %periods_time_tarif = (); 
 my %periods_traf_tarif = ();
 
 my $list = $self->{list};

 foreach my $line (@$list) {
   $time_periods{$line->[0]}{$line->[1]} = "$line->[5]:$line->[2]";
   $periods_time_tarif{$line->[5]} = $line->[3];
   $periods_traf_tarif{$line->[5]} = int($line->[4]);
  }


 return (\%time_periods, \%periods_time_tarif, \%periods_traf_tarif); 
}




#********************************************************************
# Split session to intervals
# session_splitter($start, $duration, $day_begin, $day_of_week, 
#                  $day_or_year, $intervals)
#********************************************************************
sub session_splitter2 {
 my $self = shift;
 my ($start, $duration, $day_begin, $day_of_week, $day_of_year, $attr) = @_;
 my $debug = 1;


 ($time_intervals, $periods_time_tarif, $periods_traf_tarif) = $self->time_intervals($attr->{TP_ID});

 my %division_time = (); #return division time
 my %holidays = ();
 if (defined($time_intervals->{8})) {
   my $list = $tariffs->holidays_list({ format => 'daysofyear' });
   foreach my $line (@$list) {
     $holidays{$line->[0]} = 1;
    }
  }

my $tarif_day = 0;
my $count = 0;
$start = $start - $day_begin;

require Abills::Base;
Abills::Base->import(); 
 
 print "$day_of_week / $day_of_year\n" if ($debug == 1);
 
 while($duration > 0 && $count < 10) {

   if(defined($holidays{$day_of_year}) && defined($time_intervals->{8})) {
    	$tarif_day = 8;
    }
   elsif (defined($time_intervals->{$day_of_week})) {
    	$tarif_day = $day_of_week;
    }
   elsif(defined($time_intervals->{0})) {
      $tarif_day = 0;
    }
   else {
   	  err();
   	  return -1;
    }

   $count++;
   print "Count: $count / $tarif_day\n" if ($debug == 1);
   print "\t> Start: $start (". sec2time($start, { str => 'yes' }) .") Duration: $duration\n" if ($debug == 1);

   my $cur_int = $time_intervals->{$tarif_day};
   my $i;
   my $prev_tarif = '';

   TIME_INTERVALS:
     my @intervals = sort keys %$cur_int; 
     $i = -1;

     
     
     foreach my $int_begin (@intervals) {
       my ($int_id, $int_end) = split(/:/, $cur_int->{$int_begin}, 2);
       $i++;
	
	      print "\t Start: $start (". sec2time($start, { str => 'yes' }) .") Duration: $duration ==> $int_begin / $int_end | ". sec2time($int_begin, { str => 'yes' }) if ($debug == 1);
        if ($start >= $int_begin && $start < $int_end) {
            print " <<=\n" if ($debug == 1);    

            # if defined prev_tarif
            if ($prev_tarif ne '') {
            	my ($p_day, $p_begin)=split(/:/, $prev_tarif, 2);
            	$int_end=$p_begin  if ($p_begin > $start);
            	print "Prev tarif $prev_tarif / INT end: $int_end \n" if ($debug == 1);
             }
            
            if ($start + $duration < $int_end) {
            	if (defined($division_time{$int_id})) {
            	  $division_time{$int_id}+=$duration;
               }
              else {
                $division_time{$int_id}=$duration;
               }
            	$duration = 0;
            	last;
             }
            else {
              my $int_time = $int_end - $start;

              if (defined($division_time{$int_id})) {
            	  $division_time{$int_id}+=$int_time;
               }
              else {
                $division_time{$int_id}=$int_time;
               }

             	$duration = $duration - $int_time;
             	$start = $start + $int_time;
             	if ($start == 86400) {
             	  $day_of_week = ($day_of_week + 1 > 7) ? 1 : $day_of_week+1;
             	  $day_of_year = ($day_of_year + 1 > 365) ? 1 : $day_of_year + 1;
             	  $start = 0;
             	  last;
            	 }
             }

            print "$int_id $division_time{$int_id}" . "\n";

            next;
          }
        elsif($i == $#intervals) {
       	  print "\n!! LAST@@@@ $i == $#intervals\n" if ($debug == 1);

       	  $prev_tarif = "$tarif_day:$int_begin";
       	  if(($tarif_day == 9) && defined($time_intervals->{$day_of_week})) {
            $tarif_day = $day_of_week;
       	    $cur_int = $time_intervals->{$tarif_day};
       	    print "Go to >> $tarif_day\n" if ($debug == 1);
       	   }
       	  elsif (defined($time_intervals->{0}) && $tarif_day != 0) {
       	    $tarif_day = 0;
       	    $cur_int = $time_intervals->{$tarif_day};
       	    print "Go to >> $tarif_day\n" if ($debug == 1);

       	    goto TIME_INTERVALS;
       	   }


#       	  elsif($session_start < 86400) {
#      	  	 if ($remaining_time > 0) {
#      	  	   return int($remaining_time);
#      	  	  }
#             else {
#             	 # Not allow hour
#             	 # return -2;
#              }
      	   }

        print "\n";    
      }
  }
 
 $self->{TIME_DIVISIONS} = \%division_time;
 $self->{SUM}=0;
 
 return $self;
}


#********************************************************************
# Split session to intervals
# session_splitter($start, $duration, $day_begin, $day_of_week, 
#                  $day_or_year, $intervals)
#********************************************************************
sub session_splitter {
 my ($start, $duration, $day_begin, $day_of_week, $day_of_year, $time_intervals) = @_;

 my %division_time = (); #return division time

 my %holidays = ();
 if (defined($time_intervals->{8})) {
   use Tariffs;
   my $tariffs = Tariffs->new($db);
   my $list = $tariffs->holidays_list({ format => 'daysofyear' });
   foreach my $line (@$list) {
     $holidays{$line->[0]} = 1;
    }
  }

# Test intervals
# while(my($day, $params)=each %$time_intervals) {
#     print "$day\n";
#     while(my($key, $v)=each %$params) {
#          print " $key $v\n";
#        }
#   }
 
 my $tarif_day = 0;
 my $count = 0;
 $start = $start - $day_begin;
 
 while($duration > 0 && $count < 200) {

   if (defined($time_intervals->{$day_of_week})) {
    	#print "Day tarif '$day_of_week'";
    	$tarif_day = $day_of_week;
    }
   elsif(defined($holidays{$day_of_year}) && defined($time_intervals->{8})) {
    	#print "Holliday tarif '$day_of_year' ";
    	$tarif_day = 8;
    }
   elsif(defined($time_intervals->{0})) {
      #print "Global tarif";
      $tarif_day = 0;
    }
   elsif($count > 0) {
      err();
      last;
    }
   else {
   	  err();
   	  return -1;
    }

    $count++;
#     print ": $tarif_day ($day_of_week / $day_of_year)\n";
#     print "------------- $start : $duration\n";
#     reset $int{$tarif_day};

     my $cur_int = $time_intervals->{$tarif_day};

     while(my($int_begin, $int_end)=each %$cur_int) {
     	#print "--";
     	
        if ($start >= $int_begin && $start < $int_end) {
            #print "\t==>$int_begin - $int_end: ($start)\n";
            if ($start + $duration < $int_end) {
            	if (defined($division_time{$tarif_day}{$int_begin})) {
            	  $division_time{$tarif_day}{$int_begin}+=$duration;
               }
              else {
                $division_time{$tarif_day}{$int_begin}=$duration;
               }

            	$duration = 0;
            	last;
             }
            else {
              my $int_time = $int_end - $start;

              if (defined($division_time{$tarif_day}{$int_begin})) {
            	  $division_time{$tarif_day}{$int_begin}+=$int_time;
               }
              else {
                $division_time{$tarif_day}{$int_begin}=$int_time;
               }

             	$duration = $duration - $int_time;
             	$start = $start + $int_time;
             	if ($start == 86400) {
             	  $day_of_week = ($day_of_week + 1 > 7) ? 1 : $day_of_week+1;
             	  $day_of_year = ($day_of_year + 1 > 365) ? 1 : $day_of_year + 1;
             	  $start = 0;
             	  last;
            	 }
             }
            next;
          }
        #print "\t$int_begin - $int_end\n";    
      }
  }

 return \%division_time;
}

#*******************************************************************
#
#
#*******************************************************************
sub err {
	print "##############\n# ERROR \n##############\n";
}


#*******************************************************************
# Make session log file
# mk_session_log(\$acct_info, $conf)
#*******************************************************************
sub mk_session_log  {
 my ($acct_info, $conf) = @_;
 #my $filename="1"; # "$acct_info->{USER_NAME}.$acct_info->{ACCT_SESSION_ID}";

# open(FILE, ">$conf->{SPOOL_DIR}/$filename") || die "Can't open file '$conf->{SPOOL_DIR}/$filename' $!";
  while(my($k, $v)=each(%$acct_info)) {
     print FILE "$k:$v\n";
   }
# close(FILE);
}



1