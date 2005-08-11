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

# print "---------------------------- OUT: $RAD->{OUTBYTE}<br> 
#         IN: $RAD->{INBYTE}<br>\n";

	
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


my $list = $tariffs->tt_list( { TI_ID => $self->{TI_ID} });

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
   tp.day_fee,
   tp.min_session_cost
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
   $self->{DAY_FEE},
   $self->{MIN_SESSION_COST}
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
#$self->{debug}=1;
 while(my($k, $v)=each(%$sd)) {
 	 print "> $k, $v\n" if ($self->{debug});
   if(defined($periods_time_tarif->{$k})) {
   	   $sum += ($v * $periods_time_tarif->{$k}) / 60 / 60;
     }

   if($periods_traf_tarif->{$k} > 0) {
   	  $self->{TI_ID}=$k;
   	  $sum  += $self->traffic_calculations($RAD, $conf);
    }
  }






$sum = $sum * (100 - $self->{REDUCTION}) / 100 if ($self->{REDUCTION} > 0);
$sum = $self->{MIN_SESSION_COST} if ($sum < $self->{MIN_SESSION_COST} && $self->{MIN_SESSION_COST} > 0);

return $self->{UID}, $sum, $self->{ACCOUNT_ID}, $self->{TP_ID}, 0, 0;


#  return $uid, $sum, $account_id, $TP_ID, $time_tarif, 0;
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
   $periods_traf_tarif{$line->[5]} = $line->[4];
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
 my $debug = 0;
 my %division_time = (); #return division time


 ($time_intervals, $periods_time_tarif, $periods_traf_tarif) = $self->time_intervals($attr->{TP_ID});

 if($time_intervals == 0)  {
   $self->{TIME_DIVISIONS} = \%division_time;
   $self->{SUM}=0;
   return $self;
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
#   	  err();
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

            print "$int_id $division_time{$int_id}" . "\n" if($debug==1);

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
 
 $self->{TIME_DIVISIONS} = \%division_time;
 $self->{SUM}=0;
 
 return $self;
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
 my $self = shift;
 my ($acct_info, $conf) = @_;
 my $filename="$acct_info->{USER_NAME}.$acct_info->{ACCT_SESSION_ID}";

 open(FILE, ">$conf->{SPOOL_DIR}/$filename") || die "Can't open file '$conf->{SPOOL_DIR}/$filename' $!";
  while(my($k, $v)=each(%$acct_info)) {
     print FILE "$k:$v\n";
   }
 close(FILE);
}



1