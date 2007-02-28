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
use Tariffs;
@ISA  = ("main");
my $db;
my $CONF;

my $tariffs; 
my $time_intervals=0;
my $periods_time_tarif=0;
my $periods_traf_tarif=0;


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  $CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};
  #$self->{debug}=1;
  return $self;
}


#**********************************************************
#
#**********************************************************
sub traffic_calculations {
	my $self = shift;
	my ($RAD)=@_;
	
  my $sent = $RAD->{OUTBYTE} || 0; #from server
  my $recv = $RAD->{INBYTE} || 0;  #to server
  my $sent2 = $RAD->{OUTBYTE2} || 0; 
  my $recv2 = $RAD->{INBYTE2} || 0;

  my $traffic_period = ($self->{ACTIVATE} ne '0000-00-00') ? "DATE_FORMAT(start, '%Y-%m-%d')>='$self->{ACTIVATE}'" : "DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(FROM_UNIXTIME($RAD->{SESSION_START}), '%Y-%m')" ;
  
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
    $sql = "SELECT sum(sent + recv) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}, 
                   sum(sent2 + recv2) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE} 
       FROM dv_log 
       WHERE uid='$self->{UID}' and (start>=DATE_FORMAT(curdate(), '%Y-%m-00'))
       GROUP BY uid";

    my $q = $db->prepare($sql) || die $db->errstr;
    $q ->execute();

    if ($q->rows() > 1) {
       my($used_traffic, $used_traffic2)=$q->fetchrow() 
       
       if (($used_traffic   / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}) * $prepaid_price{'gl'} + ($used_traffic2  / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}) * $prepaid_price{'lo'} 
         + (($sent + $recv) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}) * $prepaid_price{'gl'} + (($sent2 + $recv2) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}) * $prepaid_price{'lo'} 
          < $month_abon) {
           return $uid, 0, $bill_id, $TP_ID, 0, 0;
        }

     }
    elsif((($sent + $recv) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}) * $prepaid_price{'lg'} + (($sent2 + $recv2) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}) * $prepaid_price{'lo'} 
          < $month_abon) {
       return $uid, 0, $bill_id, $TP_ID, 0, 0;
     }
    elsif((($sent + $recv) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}) * $prepaid_price{'lg'} + (($sent2 + $recv2) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}) * $prepaid_price{'lo'} 
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
    $sql = "SELECT (sent + recv) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}, (sent2 + recv2) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}  
     FROM dv_log WHERE uid='$self->{UID}' and start>'$self->{ACTIVATE}'";

    my $q = $db->prepare($sql) || die $db->errstr;
    $q ->execute();


    if ($q->rows() > 1) {
       my($used_traffic, $used_traffic2)=$q->fetchrow();
       if ($prepaid_traffic > ($used_traffic + $sent + $recv) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE} ) {
          return $uid, 0, $bill_id, $TP_ID, 0, 0;
          # $sent = 0;
          # $recv = 0;
         }
       elsif(($prepaid_traffic > $used_traffic / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}) && 
         ($prepaid_traffic < ($used_traffic + $sent + $recv) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE})) {
    	  my  $not_prepaid = ($used_traffic + $sent + $recv - $prepaid_traffic * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE}) / 2;
    	  $sent = $not_prepaid;
          $recv = $not_prepaid;
#          my $sent2 = $trafic->{sent2} || 0; 
#          my $recv2 = $trafic->{recv2} || 0;
         }
     }
    elsif (($sent + $recv) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE} < $prepaid_traffic) {
       	  return $uid, 0, $bill_id, $TP_ID, 0, 0;
       	  #$sent = 0;
          #$recv = 0;
     }
    elsif($prepaid_traffic < ($sent + $recv) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}) {
    	  my  $not_prepaid = ($sent + $recv - $prepaid_traffic * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE}) / 2;
    	  $sent = $not_prepaid;
        $recv = $not_prepaid;
#          my $sent2 = $trafic->{sent2} || 0; 
#          my $recv2 = $trafic->{recv2} || 0;
     }

  }
=cut
	

####################################################################
# Prepaid local and global traffic separately



my %traf_price  = ();
my %prepaid     = ( 0 => 0, 
                    1 => 0);

my $list = $tariffs->tt_list( { TI_ID => $self->{TI_ID} });
#id, in_price, out_price, prepaid, speed, descr, nets
foreach my $line (@$list) {
   $traf_price{in}{$line->[0]}  =	$line->[1];
   $traf_price{out}{$line->[0]} =	$line->[2];
   $prepaid{$line->[0]}         = $line->[3];
}

if ($prepaid{0} + $prepaid{1} > 0) {
   #Get traffic from begin of month
   
   my $used_traffic = $self->get_traffic({ UID    => $self->{UID},
   	                                       PERIOD => $traffic_period
   	                                    });
   
   print $used_traffic;
   $used_traffic->{TRAFFIC_SUM}=$used_traffic->{TRAFFIC_OUT} + $used_traffic->{TRAFFIC_IN};
    
   # If left global prepaid traffic set traf price to 0
   if ($used_traffic->{TRAFFIC_SUM} + ($sent + $recv) / $CONF->{MB_SIZE}  < $prepaid{0}) {
     $traf_price{in}{0} = 0;
     $traf_price{out}{0} = 0;
    }
   # 
   elsif ($used_traffic->{TRAFFIC_SUM} + ($sent + $recv) / $CONF->{MB_SIZE} > $prepaid{0} 
            && $used_traffic->{TRAFFIC_SUM} < $prepaid{0}) {
     my $not_prepaid = ($used_traffic->{TRAFFIC_SUM} * $CONF->{MB_SIZE} + $sent + $recv) - $prepaid{0} * $CONF->{MB_SIZE};
     $sent = $not_prepaid / 2;
     $recv = $not_prepaid / 2;
    }

   # If left local prepaid traffic set traf price to 0
   $used_traffic->{TRAFFIC_SUM_2} = $used_traffic->{TRAFFIC_OUT_2} + $used_traffic->{TRAFFIC_IN_2};
   if ($used_traffic->{TRAFFIC_SUM_2} + ($sent2 + $recv2) / $CONF->{MB_SIZE} < $prepaid{1}) {
     $traf_price{in}{1} = 0;
     $traf_price{out}{1} = 0;
    }
   elsif ( ($used_traffic->{TRAFFIC_SUM_2} + ($sent2 + $recv2) / $CONF->{MB_SIZE} > $prepaid{1}) 
      && ( $used_traffic->{TRAFFIC_SUM_2} / $CONF->{MB_SIZE} < $prepaid{1}) ) {
     my $not_prepaid = ($used_traffic->{TRAFFIC_SUM_2} * $CONF->{MB_SIZE} + $sent2 + $recv2) - $prepaid{1} * $CONF->{MB_SIZE};
     $sent2 = $not_prepaid / 2;
     $recv2 = $not_prepaid / 2;
    }
 }


#####################################################################
# TRafic payments
 my $traf_sum = 0;
 
 my $gl_in  = ($traf_price{in}{0}) ? $recv / $CONF->{MB_SIZE} * $traf_price{in}{0} : 0;
 my $gl_out = ($traf_price{out}{0}) ? $sent / $CONF->{MB_SIZE} * $traf_price{out}{0} : 0;
 my $lo_in  = (defined($traf_price{in}{1})) ?  $recv2 / $CONF->{MB_SIZE} * $traf_price{in}{1} : 0;
 my $lo_out = (defined($traf_price{out}{1})) ?  $sent2 / $CONF->{MB_SIZE} * $traf_price{out}{1} : 0;
 $traf_sum  = $lo_in + $lo_out + $gl_in + $gl_out;



 return $traf_sum;
}


#**********************************************************
# Get traffic from some period
# UID     - user id
# PERIOD  - start period
# 
# Return traffic recalculation by MB 
#
#**********************************************************
sub get_traffic {
	my ($self, $attr) = @_;

	my %result = (
	   TRAFFIC_OUT   => 0, 
     TRAFFIC_IN    => 0,
     TRAFFIC_OUT_2 => 0,
     TRAFFIC_IN_2  => 0
	);
  
  my $period = ($attr->{PERIOD}) ? $attr->{PERIOD} : "DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";

  $self->query($db, "SELECT sum(sent)  / $CONF->{MB_SIZE},  
                            sum(recv)  / $CONF->{MB_SIZE}, 
                            sum(sent2) / $CONF->{MB_SIZE}, 
                            sum(recv2) / $CONF->{MB_SIZE}
       FROM dv_log 
       WHERE uid='$attr->{UID}' and ($period)
       GROUP BY uid;");

  if ($self->{TOTAL} > 0) {
    ($result{TRAFFIC_OUT}, 
     $result{TRAFFIC_IN},
     $result{TRAFFIC_OUT_2},
     $result{TRAFFIC_IN_2}
    )=@{ $self->{list}->[0] };
  }
  
  $self->{PERIOD_TRAFFIC}=\%result;
  
	return \%result;
}


#**********************************************************
# Calculate session sum
# Return 
# >= 0 - session sum
# -1 Less than minimun session trafic and time
# -2 Not found user in users db
# -3 SQL Error
# -4 Company not found
# -5 TP not found
# -16 Not allow start period
#
# session_sum($USER_NAME, $SESSION_START, $SESSION_DURATION, $RAD_HASH_REF, $attr);
#**********************************************************
sub session_sum {
 my $self = shift;
 my ($USER_NAME, 
     $SESSION_START, 
     $SESSION_DURATION, 
     $RAD, 
     $attr) = @_;

 my $sum = 0;
 my ($TP_ID);

 my $sent  = $RAD->{OUTBYTE} || 0; #from server
 my $recv  = $RAD->{INBYTE}  || 0;  #to server
 my $sent2 = $RAD->{OUTBYTE2}|| 0; 
 my $recv2 = $RAD->{INBYTE2} || 0;

 # Don't calculate if session smaller then $CONF->{MINIMUM_SESSION_TIME} and  $CONF->{MINIMUM_SESSION_TRAF}
 if (! $attr->{FULL_COUNT} && 
     (
      (defined($CONF->{MINIMUM_SESSION_TIME}) && $SESSION_DURATION < $CONF->{MINIMUM_SESSION_TIME}) || 
      (defined($CONF->{MINIMUM_SESSION_TRAF}) && $sent + $recv < $CONF->{MINIMUM_SESSION_TRAF})
     )
     ) {
    return -1, 0, 0, 0, 0, 0;
  }


 #If defined TP_ID
 if ($attr->{TP_ID}) {
   $self->query($db, "SELECT 
    u.uid,
    UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME($SESSION_START), '%Y-%m-%d')),
    DAYOFWEEK(FROM_UNIXTIME($SESSION_START)),
    DAYOFYEAR(FROM_UNIXTIME($SESSION_START)),
    u.reduction,
    u.bill_id,
    u.activate,
    u.company_id
   FROM users u
   WHERE  u.id='$USER_NAME';");

   if($self->{errno}) {
     return -3, 0, 0, 0, 0, 0;
    }
   #user not found
   elsif ($self->{TOTAL} < 1) {
     return -2, 0, 0, 0, 0, 0;	
    }

  ($self->{UID}, 
   $self->{DAY_BEGIN}, 
   $self->{DAY_OF_WEEK}, 
   $self->{DAY_OF_YEAR}, 
   $self->{REDUCTION},
   $self->{BILL_ID}, 
   $self->{ACTIVATE},
   $self->{COMPANY_ID},
  ) = @{ $self->{list}->[0] };	
 	
 	$self->query($db, "SELECT 
    tp.min_session_cost,
    tp.payment_type
   FROM tarif_plans tp
   WHERE tp.id='$attr->{TP_ID}';");

   if($self->{errno}) {
     return -3, 0, 0, 0, 0, 0;
    }
   #TP not found
   elsif ($self->{TOTAL} < 1) {
     return -5, 0, 0, 0, 0, 0;	
    }

  ($self->{MIN_SESSION_COST},
   $self->{PAYMENT_TYPE}
  ) = @{ $self->{list}->[0] };
 	
  }
 else {
  $self->query($db, "SELECT 
    u.uid,
    tp.id, 
    tp.hourp,
    UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME($SESSION_START), '%Y-%m-%d')),
    DAYOFWEEK(FROM_UNIXTIME($SESSION_START)),
    DAYOFYEAR(FROM_UNIXTIME($SESSION_START)),
    u.reduction,
    u.bill_id,
    u.activate,
    tp.min_session_cost,
    u.company_id,
    tp.payment_type
   FROM (users u, 
      dv_main dv, 
      tarif_plans tp)
   WHERE dv.tp_id=tp.id 
   and dv.uid=u.uid
   and u.id='$USER_NAME';");
 
   if($self->{errno}) {
     return -3, 0, 0, 0, 0, 0;
    }
   #user not found
   elsif ($self->{TOTAL} < 1) {
     return -2, 0, 0, 0, 0, 0;	
    }
  
  ($self->{UID}, 
   $self->{TP_ID}, 
   $self->{MAIN_TIME_TARIF}, 
   $self->{DAY_BEGIN}, 
   $self->{DAY_OF_WEEK}, 
   $self->{DAY_OF_YEAR}, 
   $self->{REDUCTION},
   $self->{BILL_ID}, 
   $self->{ACTIVATE},
   $self->{MIN_SESSION_COST},
   $self->{COMPANY_ID},
   $self->{PAYMENT_TYPE}
  ) = @{ $self->{list}->[0] };
 }

 $self->{TP_ID}=$attr->{TP_ID} if (defined($attr->{TP_ID}));


 $tariffs = Tariffs->new($db, $CONF);

 $self->session_splitter($SESSION_START,
                         $SESSION_DURATION,
                         $self->{DAY_BEGIN},
                         $self->{DAY_OF_WEEK}, 
                         $self->{DAY_OF_YEAR},
                         { TP_ID => $self->{TP_ID} }
                        );
 
 #session devisions
 my @sd = @{ $self->{TIME_DIVISIONS_ARR} };
 $self->{TI_ID} = 0;

if(! defined($self->{NO_TPINTERVALS})) {
  if($#sd < 0) {
   	print "Not allow start period" if ($self->{debug});
 	  return -16, 0, 0, 0, 0, 0;	
   }
  
  for(my $i=0; $i<=$#sd; $i++) {
    my ($k, $v)=split(/,/,  $sd[$i]);
    print "> $k, $v\n" if ($self->{debug});
    $self->{TI_ID}=$k;
    if($periods_time_tarif->{$k} && $periods_time_tarif->{$k} > 0) {
   	   $sum += ($v * $periods_time_tarif->{$k}) / 60 / 60;
     }
   
    if( $i == 0 && defined($periods_traf_tarif->{$k}) && $periods_traf_tarif->{$k} > 0) {
   	    $sum  += $self->traffic_calculations({ %$RAD, SESSION_START => $SESSION_START });
   	    last;
     }
   }
}


$sum = $sum * (100 - $self->{REDUCTION}) / 100 if ($self->{REDUCTION} > 0);

if (! $attr->{FULL_COUNT}) {
  $sum = $self->{MIN_SESSION_COST} if ($sum < $self->{MIN_SESSION_COST} && $self->{MIN_SESSION_COST} > 0);
}

if ($self->{COMPANY_ID} > 0) {
  $self->query($db, "SELECT bill_id, vat
    FROM companies
    WHERE id='$self->{COMPANY_ID}';");

  if ($self->{TOTAL} < 1) {
 	  return -4, 0, 0, 0, 0, 0;	
 	 }

  ($self->{BILL_ID}, $self->{VAT})= @{ $self->{list}->[0] };
  $sum = $sum + ((100 + $self->{COMPANY_VAT}) / 100) if ($self->{COMPANY_VAT});
}

  return $self->{UID}, $sum, $self->{BILL_ID}, $self->{TP_ID}, 0, 0;
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
   #$time_periods{INTERVAL_DAY}{INTERVAL_START}="INTERVAL_ID:INTERVAL_END";
   $time_periods{$line->[0]}{$line->[1]} = "$line->[5]:$line->[2]";

   #$periods_time_tarif{INTERVAL_ID} = "INTERVAL_PRICE";
   $periods_time_tarif{$line->[5]} = $line->[3];

   # Trffic price
   
   $periods_traf_tarif{$line->[5]} = $line->[4]; # if ($line->[4] > 0);
  }


 return (\%time_periods, \%periods_time_tarif, \%periods_traf_tarif); 
}




#********************************************************************
# Split session to intervals
# session_splitter($start, $duration, $day_begin, $day_of_week, 
#                  $day_or_year, $intervals)
#********************************************************************
sub session_splitter {
 my $self = shift;
 my ($start, 
     $duration, 
     $day_begin, 
     $day_of_week, 
     $day_of_year, 
     $attr) = @_;
 
 my $debug = $self->{debug} || 0;
 my @division_time_arr = ();

 if (defined($attr->{TP_ID})) {
   ($time_intervals, $periods_time_tarif, $periods_traf_tarif) = $self->time_intervals($attr->{TP_ID});
  }
 else {
   $time_intervals      = $attr->{TIME_INTERVALS}  if (defined($attr->{TIME_INTERVALS}));
   $periods_time_tarif  = $attr->{PERIODS_TIME_TARIF} if (defined($attr->{PERIODS_TIME_TARIF}));
   $periods_traf_tarif  = $attr->{PERIODS_TIME_TARIF} if (defined($attr->{PERIODS_TRAF_TARIF}));
 }


 if ($time_intervals == 0)  {
   $self->{TIME_DIVISIONS_ARR} = \@division_time_arr;
   $self->{NO_TPINTERVALS} = 'y';
   $self->{SUM}=0;
   return $self;
  }
 else {
 	 delete $self->{NO_TPINTERVALS};
  }

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

if ($debug == 1) {
  require Abills::Base;
  Abills::Base->import(); 
} 

 print "DAY_OF_WEEK: $day_of_week DAY_OF_YEAR: $day_of_year\n" if ($debug == 1);
 
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
#   	err();
   	  return -1;
    }

   $count++;
   print "Count: $count TARRIF_DAY: $tarif_day\n" if ($debug == 1);
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

       print "\t Int Start: $start (". sec2time($start, { str => 'yes' }) .") Duration: $duration / FROM $int_begin TO $int_end | ". sec2time($int_begin, { str => 'yes' }) if ($debug == 1);
       if ($start >= $int_begin && $start < $int_end) {
         print " <<=USE\n" if ($debug == 1);    

         # if defined prev_tarif
         if ($prev_tarif ne '') {
           my ($p_day, $p_begin)=split(/:/, $prev_tarif, 2);
           $int_end=$p_begin  if ($p_begin > $start);
           print "Prev tarif $prev_tarif / INT end: $int_end \n" if ($debug == 1);
          }
         
         #IF Start + DUARATION < END period last the calculation 
         if ($start + $duration < $int_end) {
            #experimental division time arr
            push @division_time_arr, "$int_id,$duration";
            $duration = 0;
         	  last;
          }
         else {
              my $int_time = $int_end - $start;
              push @division_time_arr, "$int_id,$int_time";
             	$duration = $duration - $int_time;
             	$start = $start + $int_time;
             	if ($start == 86400) {
             	  $day_of_week = ($day_of_week + 1 > 7) ? 1   : $day_of_week + 1;
             	  $day_of_year = ($day_of_year + 1 > 365) ? 1 : $day_of_year + 1;
             	  $start = 0;
             	  last;
            	 }
          }

           print "  INT/TIME: $division_time_arr[$#division_time_arr]\n" if($debug==1);
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

        print "\n" if($debug == 1);    
      }
  }
 
 $self->{TIME_DIVISIONS_ARR} = \@division_time_arr;
 $self->{SUM}=0;
 
 return $self;
}



#*******************************************************************
#
#
#*******************************************************************
sub time_calculation() {
	my $self = shift;
	my ($attr) = @_;
  my $sum = 0;


  delete $self->{errno};
  delete $self->{errstr};

  $self->session_splitter($attr->{SESSION_START},
                   $attr->{ACCT_SESSION_TIME},
                   $attr->{DAY_BEGIN},
                   $attr->{DAY_OF_WEEK}, 
                   $attr->{DAY_OF_YEAR},
                   {  TIME_INTERVALS      => $attr->{TIME_INTERVALS},
                      PERIODS_TIME_TARIF  => $attr->{PERIODS_TIME_TARIF},
                    }
                  );
 
 
 my %PRICE_UNITS = (
  Hour => 3600,
  Min  => 60
 );
 
 my $PRICE_UNIT = (defined($PRICE_UNITS{$attr->{PRICE_UNIT}})) ? 60 : 3600;
 
  #session devisions
  my @sd = $self->{TIME_DIVISIONS_ARR};

$self->{debug} =1;

if(! defined($self->{NO_TPINTERVALS})) {
  if($#sd < 0) {
   	$self->{errno} = 3;
   	$self->{errstr} = "Not allow start period";
   }
  #$self->{debug}=1;

  foreach my $line (@sd) {
    my ($k, $v)=split(/,/,  $line);

 	  #print "> $k, $v\n" if ($self->{debug});
    if(defined($periods_time_tarif->{$k})) {
   	   $sum += ($v * $periods_time_tarif->{$k}) / $PRICE_UNIT;
     }
   }
}

$sum = $sum * (100 - $attr->{REDUCTION}) / 100 if (defined($attr->{REDUCTION}) && $attr->{REDUCTION} > 0);
#$sum = $CONF->{MIN_SESSION_COST} if ($sum < $self->{MIN_SESSION_COST} && $self->{MIN_SESSION_COST} > 0);

  

  $self->{SUM}=$sum;
  return $self;
}


#********************************************************************
# Get current time info
#   SESSION_START
#   DAY_BEGIN
#   DAY_OF_WEEK
#   DAY_OF_YEAR
#********************************************************************
sub get_timeinfo {
  my $self = shift;

  $self->query($db, "select
    UNIX_TIMESTAMP(),
    UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
    DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
    DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP()));");

  if($self->{errno}) {
    return $self;
   }
  my $a_ref = $self->{list}->[0];

 ($self->{SESSION_START},
  $self->{DAY_BEGIN},
  $self->{DAY_OF_WEEK},
  $self->{DAY_OF_YEAR})  = @$a_ref;

  return $self;
}


#********************************************************************
# remaining_time
#  returns
#    -1 = access deny not allow day
#    -2 = access deny not allow hour
#********************************************************************
sub remaining_time {
  my ($self)=shift;
  my ($deposit, 
      $attr) = @_;


  my %ATTR = ();
  my ($session_start,  
      $day_begin,
      $day_of_week,
      $day_of_year
     );

  

  if (! defined($attr->{SESSION_START})) {
  	 $self->get_timeinfo();
  	 $session_start = $self->{SESSION_START};
     $day_begin     = $self->{DAY_BEGIN};
     $day_of_week   = $self->{DAY_OF_WEEK};
     $day_of_year   = $self->{DAY_OF_YEAR};
   }
  else {
  	 $session_start = $attr->{SESSION_START};
     $day_begin     = $attr->{DAY_BEGIN};
     $day_of_week   = $attr->{DAY_OF_WEEK};
     $day_of_year   = $attr->{DAY_OF_YEAR};
   }


  my $REDUCTION = (defined($attr->{REDUCTION})) ? $attr->{REDUCTION} : 0;
  $deposit = $deposit + ($deposit * (100 - $REDUCTION) / 100) if ($REDUCTION > 0);

  $time_intervals = $attr->{TIME_INTERVALS} || 0; 
  $periods_time_tarif = $attr->{INTERVAL_TIME_TARIF};
  $periods_traf_tarif = $attr->{INTERVAL_TRAF_TARIF} || undef;

  my $debug = $attr->{debug} || 0;
 
  my $time_limit = (defined($attr->{time_limit})) ? $attr->{time_limit} : 0;
  my $mainh_tarif = (defined($attr->{mainh_tarif})) ? $attr->{mainh_tarif} : 0;
  my $remaining_time = 0;


 if ($time_intervals == 0) {
    return 0, \%ATTR;
  }
 
 my %holidays = ();
 if (defined($time_intervals->{8})) {
   my $tariffs = Tariffs->new($db, $CONF);
   my $list = $tariffs->holidays_list({ format => 'daysofyear' });
   foreach my $line (@$list) {
     $holidays{$line->[0]} = 1;
    }
  }


 my $tarif_day = 0;
 my $count = 0;
 $session_start = $session_start - $day_begin;
 
 #If use post paid service
 


 while(($deposit > 0 || (defined($attr->{POSTPAID}) && $attr->{POSTPAID}==1 )) && $count < 50) {

   if ($time_limit != 0 && $time_limit < $remaining_time) {
     $remaining_time = $time_limit;
     last;
    }

   if(defined($holidays{$day_of_year}) && defined($time_intervals->{8})) {
    	#print "Holliday tarif '$day_of_year' ";
    	$tarif_day = 8;
    }
   elsif (defined($time_intervals->{$day_of_week})) {
    	#print "Day tarif '$day_of_week'";
    	$tarif_day = $day_of_week;
    }
   elsif(defined($time_intervals->{0})) {
      #print "Global tarif";
      $tarif_day = 0;
    }
   elsif($count > 0) {
      last;
    }
   else {
      return -1, \%ATTR;
    }
  
  print "Count:  $count Remain Time: $remaining_time\n" if ($debug == 1);

  # Time check
  # $session_start

     $count++;

     my $cur_int = $time_intervals->{$tarif_day};
     my $i;
     my $prev_tarif = '';
     
     TIME_INTERVALS:

     my @intervals = sort keys %$cur_int; 
     $i = -1;
     
     #Check intervals
     foreach my $int_begin (@intervals) {
       my ($int_id, $int_end) = split(/:/, $cur_int->{$int_begin}, 2);
       $i++;

       my $price         = 0;
       my $traf_price    = 0;
       my $int_prepaid   = 0;
       my $int_duration  = 0;
       my $extended_time = 0;

       #begin > end / Begin: 22:00 => End: 3:00
       if ($int_begin > $int_end) {
       	 if( $session_start < 86400 && $session_start > $int_begin) {
       	   $extended_time = $int_end;
       	   $int_end = 86400;
       	  }
         elsif($session_start < $int_end) {
         	 $int_begin = 0;
          }
        } 
       
       print "Day: $tarif_day Session_start: $session_start => Int Begin: $int_begin End: $int_end Int ID: $int_id\n" if ($debug == 1);

       if (($int_begin <= $session_start) && ($session_start < $int_end)) {
          $int_duration = $int_end-$session_start;
          
          print " <<!=\n" if ($debug == 1);    

          # if defined prev_tarif
          if ($prev_tarif ne '') {
            	my ($p_day, $p_begin)=split(/:/, $prev_tarif, 2);
            	$int_end=$p_begin;
            	print "Prev tarif $prev_tarif / INT end: $int_end \n" if ($debug == 1);
            	
           }

          #Time calculations/ Time tariff price
          if ($periods_time_tarif->{$int_id} =~ /%$/) {
             my $tp = $periods_time_tarif->{$int_id};
             $tp =~ s/\%//;
             $price = $mainh_tarif  * ($tp / 100);
           }
          else {
             $price = $periods_time_tarif->{$int_id};
           }

          if (! $ATTR{FIRST_INTERVAL}) {
          	$ATTR{FIRST_INTERVAL} = $int_id;
          	$ATTR{TIME_PRICE} = $price;
           }
          
          
          #Traf calculation
          if(defined($periods_traf_tarif->{$int_id})
#30.11             && $periods_traf_tarif->{$int_id} > 0 
             && $remaining_time == 0 
             && ($attr->{GET_INTERVAL} || ! $CONF->{rt_billing})
             ) {

            $ATTR{TT}=$int_id if (! defined($ATTR{TT}));            
            if ($periods_traf_tarif->{$int_id} > 0) {
              print "This tarif with traffic counts\n" if ($debug == 1);
              if ($int_end - $int_begin < 86400) {
                
                return int($int_duration), \%ATTR 
               }
              #Traffic tarif price
              $traf_price = $periods_traf_tarif->{$int_id};
             }

            
            # 20.01.2007
            #$remaining_time += $int_duration;
            if ($price > 0) {
              $int_prepaid = int($deposit / $price * 3600);
             }
            else {
              $int_prepaid = $int_duration;		
             }
           }
          # Check next traffic interval if the price is same add this interval to session timeout
          elsif(defined($periods_traf_tarif->{$int_id}) 
            && $periods_traf_tarif->{$int_id} > 0 
            && ! $CONF->{rt_billing} 
            && (($int_end - $int_begin < 86400) && $periods_traf_tarif->{$int_id} != $traf_price)
            ) {
            print "Next tarif with traffic counts (Remaining: $remaining_time) Day: $tarif_day Int Begin: $int_begin End: $int_end ID: $int_id\n" if ($debug == 1);
            return int($remaining_time), \%ATTR;
           }
          elsif ($price > 0) {
            $int_prepaid = int($deposit / $price * 3600);
           }
          else {
            $int_prepaid = $int_duration;	
            $ATTR{TT}=$int_id if (! defined($ATTR{TT}) && defined($periods_traf_tarif));
           }

          #print "Int Begin: $int_begin Int duration: $int_duration Int prepaid: $int_prepaid Prise: $price\n";
          if ($int_prepaid >= $int_duration) {
            $deposit -= ($int_duration / 3600 * $price);
            $session_start += $int_duration;
            $remaining_time += $int_duration;
            #print "DP $deposit ($int_prepaid > $int_duration) $session_start\n";
           }
          elsif($int_prepaid <= $int_duration) {
            $deposit =  0;    	
            $session_start += int($int_prepaid);
            $remaining_time += int($int_prepaid);
            #print "DL '$deposit' ($int_prepaid <= $int_duration) $session_start\n";
           }

        }
       elsif($i == $#intervals) {
       	  print "!! LAST@@@@ $i == $#intervals\n" if ($debug == 1);
       	  $prev_tarif = "$tarif_day:$int_begin";



       	  if (defined($time_intervals->{0}) && $tarif_day != 0) {
       	    $tarif_day = 0;
       	    $cur_int = $time_intervals->{$tarif_day};
       	    print "Go to\n" if ($debug == 1);
       	    goto TIME_INTERVALS;
       	   }
       	  elsif($session_start < 86400) {
      	  	 if ($remaining_time > 0) {
      	  	   return int($remaining_time), \%ATTR;
      	  	  }
             else {
             	 #print "# Not allow hour $remaining_time";
             	 # return -2;
              }
      	   }
       	  #return $remaining_time;
       	  next;
        }
      }

  return -2, \%ATTR if ($remaining_time == 0);
 
  if ($session_start >= 86400) {
    $session_start=0;
    $day_of_week = ($day_of_week + 1 > 7) ? 1 : $day_of_week+1;
    $day_of_year = ($day_of_year + 1 > 365) ? 1 : $day_of_year + 1;
   }
#  else {
#  	return int($remaining_time), \%ATTR;
#   }
 }

return int($remaining_time), \%ATTR;
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
# mk_session_log(\$acct_info)
#*******************************************************************
sub mk_session_log  {
 my $self = shift;
 my ($acct_info) = @_;
 my $filename="$acct_info->{USER_NAME}.$acct_info->{ACCT_SESSION_ID}";

 open(FILE, ">$CONF->{SPOOL_DIR}/$filename") || die "Can't open file '$CONF->{SPOOL_DIR}/$filename' $!";
  while(my($k, $v)=each(%$acct_info)) {
     print FILE "$k:$v\n";
   }
 close(FILE);
}



#**********************************************************
# Get Interval Sum
# PARAMS: 
#   TP_ID         - Tarrif plan 
#   SESSION_START - Interval start 
#   DAY_BEGIN     - Day begin
#   DAY_OF_WEEK   - Day of Week
#   DAY_OF_YEAR   - Day Of Year
#   
#   SENT          - Sent octets
#   RECV          - Recive octets
#   DURATION      - Duration
#
# returns
# -1 - Other error
# -2 - No TP specify
#**********************************************************
sub interval_sum {
  my $self = shift;
	my ($attr) = @_;
	
	#NO TP spec
	return -2 if (! $attr->{TP_ID});

  #Get Availbs intervals
  $self->time_intervals($attr->{TP_ID});

  # recognize current interval

  
	
	
}


#**********************************************************
#
#**********************************************************
sub expression {
  my ($self, $UID, $expr, $attr) = @_;

  my $debug = $attr->{debug} || 0;
  my $RESULT;    

  #Expresion section
  if (scalar(keys %{ $expr }) > 0) {
    my $start_period = ($attr->{START_PERIOD} && $attr->{START_PERIOD} ne '0000-00-00') ? "DATE_FORMAT(start, '%Y-%m-%d')>='$attr->{START_PERIOD}'" : "DATE_FORMAT(start, '%Y-%m')>=DATE_FORMAT(curdate(), '%Y-%m')";

    my %ex = ();
    my $counters;


    while(my($id, $expresion_text) = each %{ $expr } ) {
  	  $expresion_text =~ s/\n|[\r]//g;
  	  my @expresions_array = split(/;/, $expresion_text);
  	  
  	  foreach my $expresion (@expresions_array) {
  	    print "$id, $expresion\n" if ($debug > 0);
  	    my($left, $right)=split(/=/, $expresion);
  	  
  	    if($left =~ /([A-Z0-9_]+)(<|>)([0-9\.]+)/) {
    	    $ex{ARGUMENT}=$1;
    	    $ex{EXPR}=$2;
  	      $ex{PARAMENTER}=$3;
  	      
          #$CONF->{KBYTE_SIZE} = 1;
  	      print "ARGUMENT: $ex{ARGUMENT} EXP: '$ex{EXPR}' PARAMENTER: $ex{PARAMENTER}\n" if ($debug > 0); 
  	      if ($ex{ARGUMENT} =~ /TRAFFIC/) {

  	      	
            if ($self->{PERIOD_TRAFFIC}) {
            	 $counters = $self->{PERIOD_TRAFFIC};
             }
            else {
  	      	  $counters = $self->get_traffic({ UID    => $UID,
     	                                       PERIOD => $start_period
   	                                          }) if (! $counters->{TRAFFIC_IN});
             }

            if ( $ex{ARGUMENT} eq 'TRAFFIC_SUM' && ! $counters->{TRAFFIC_SUM}) {
              $counters->{TRAFFIC_SUM}=$counters->{TRAFFIC_IN}+$counters->{TRAFFIC_OUT};
             }
            
            if($ex{EXPR} eq '<' && $counters->{$ex{ARGUMENT}}  <=  $ex{PARAMENTER}) {
             	print "--$ex{EXPR} $ex{RES}/$ex{RES_VAL}/ \n" if ($debug > 0);
             	$RESULT = get_result($right);
             }
            elsif($ex{EXPR} eq '>' && $counters->{$ex{ARGUMENT}} >=  $ex{PARAMENTER}) {
            	print "--$ex{EXPR} $counters->{$ex{ARGUMENT}} \n" if ($debug > 0);
            	$RESULT = get_result($right);
             }
            else {
            	print "No hits!\n" if ($debug > 0);
            	$RESULT->{TRAFFIC_LIMIT}=$ex{PARAMENTER};
            	last;
             }
  	       }

       }
     }
    }
   }
	
	return $RESULT;
}




#**********************************************************
# get expresion result
#**********************************************************
sub get_result {
  my ($right, $attr) = @_;

  my %RESULT = ();
  my @right_arr=split(/,/, $right);
  #print "RESULTS: " if ($debug > 0) ;
  foreach my $line (@right_arr) {
    if ($line =~ /([A-Z0-9_]+):([0-9\.]+)/) {
 	    $RESULT{$1}=$2;
      #print "$1/$RESULT{$1}\n" if ($self->{debug} > 0) ;
 	   }
	 }

  return \%RESULT;
}



1

