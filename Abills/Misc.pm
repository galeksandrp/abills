# Misc functions


#**********************************************************
# load_module($string, \%HASH_REF);
#**********************************************************
sub load_module {
	my ($module, $attr) = @_;

	my $lang_file = '';
	$attr->{language} = 'english' if (! $attr->{language});

  foreach my $prefix (@INC) {
    my $realfilename = "$prefix/Abills/modules/$module/lng_$attr->{language}.pl";

    if (-f $realfilename) {
      $lang_file =  $realfilename;
      last;
    }
    elsif (-f "$prefix/Abills/modules/$module/lng_english.pl") {
    	$lang_file = "$prefix/Abills/modules/$module/lng_english.pl";
    }
  }

  if ($lang_file ne '') {
    require $lang_file;
  }

 	require "Abills/modules/$module/webinterface";

	return 0;
}


#**********************************************************
# Calls function for all registration modules if function exist 
#
# HASH_REF = cross_modules_call(function_sufix, attr) 
#
# return HASH_REF
#   MODULE -> return
#**********************************************************
sub cross_modules_call {
  my ($function_sufix, $attr) = @_;

  my %full_return = ();
  my @skip_modules = ();
  
  if ($attr->{SKIP_MODULES}) {
  	$attr->{SKIP_MODULES}=~s/\s+//g;
  	@skip_modules=split(/,/, $attr->{SKIP_MODULES});
   }

  foreach my $mod (@MODULES) {
  	if (in_array($mod, \@skip_modules)) {
  		next;
  	}
    
    if ($attr->{DEBUG}) {
    	print " $mod -> ". lc($mod).$function_sufix ."\n";
    }

    load_module("$mod", $html);
    my $function = lc($mod).$function_sufix;
    
    my $return;
    
    if (defined(&$function)) {
     	$return = $function->($attr);
    }

    $full_return{$mod}=$return;
  }

  return \%full_return;
}


#**********************************************************
# Get function index
#
# get_function_index($function_name, $attr)
#**********************************************************
sub get_function_index {
  my ($function_name, $attr) = @_;
  my $function_index = 0;

  foreach my $k (keys %functions) {
    my $v = $functions{$k};
    if ($v eq "$function_name") {
      $function_index = $k;
      if ($attr->{ARGS} && $attr->{ARGS} ne $menu_args{$k}) {
        next;
      }
      last;
    }
  }

  return $function_index;
}


#**********************************************************
# get_period_dates
# 
# get_period_dates
#
#   TYPE              0 - day, 1 - month  
#   START_DATE
#   ACCOUNT_ACTIVATE
#   PERIOD_ALIGNMENT
#**********************************************************
sub get_period_dates {
	my ($attr)=@_;
	
  my $START_PERIOD = $attr->{START_DATE} || $DATE;
  
  my ($start_date, $end_date);

  if ($attr->{ACCOUNT_ACTIVATE} && $attr->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
    $START_PERIOD = $attr->{ACTIVATE};
  }

  my ($start_y, $start_m, $start_d)=split(/-/, $START_PERIOD);

  if ($attr->{TYPE}) {
  	if ($attr->{TYPE}==1) {
      my $days_in_month = ($start_m != 2 ? (($start_m % 2) ^ ($start_m > 7)) + 30 : (!($start_y % 400) || !($start_y % 4) && ($start_y % 25) ? 29 : 28));

      #start date
     	$end_date   = "$start_y-$start_m-$days_in_month";
      if ($attr->{PERIOD_ALIGNMENT}) {
      	$start_date = $START_PERIOD;
      }
      else {
        $start_date = "$start_y-$start_m-01";
        if ($attr->{ACCOUNT_ACTIVATE}) {
          my $end_date = strftime "%Y-%m-%d", localtime((mktime(0, 0, 0, $start_d, ($start_m - 1), ($start_y - 1900), 0, 0, 0) + 30 * 86400));
        }        
      }

      return " ($start_date-$end_date)";
  	}
  }
	
	return '';
}

1