#!/usr/bin/perl -w
# PaySys Console
# Console interface for payments and fees import


use vars qw($begin_time %FORM %LANG
$DATE $TIME
$CHARSET
@MODULES);



BEGIN {
 my $libpath = '../../../';
 $sql_type='mysql';
 unshift(@INC, './');
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, "/usr/abills/Abills/$sql_type/");
 unshift(@INC, "/usr/abills/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');

 eval { require Time::HiRes; };
 if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
   }
 else {
    $begin_time = 0;
  }
}

use FindBin '$Bin';

require $Bin . '/../../../libexec/config.pl';


use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Users;
use Paysys;
use Finance;
use Admins;

my $html = Abills::HTML->new();
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};
#Operation status

my $admin    = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $payments = Finance->payments($db, $admin, \%conf);
my $fees     = Finance->fees($db, $admin, \%conf);
my $Paysys   = Paysys->new($db, $admin, \%conf);
my $Users    = Users->new($db, $admin, \%conf);
my $debug    = 0;
my $error_str= '';
%PAYSYS_PAYMENTS_METHODS=%{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };

#Arguments
my $ARGV = parse_arguments(\@ARGV);

if (defined($ARGV->{help})) {
	help();
	exit;
}

if ($ARGV->{DEBUG}) {
	$debug=$ARGV->{DEBUG};
	print "DEBUG: $debug\n";
}

$DATE = $ARGV->{DATE} if ($ARGV->{DATE});

qiwi_check();

#**********************************************************
#
#**********************************************************
sub qiwi_check {
	my ($attr)=@_;
	require "Abills/modules/Paysys/Qiwi.pm";
	my $payment_system    = 'QIWI';
	my $payment_system_id = 59;

  
  $Paysys->{debug}=1 if ($debug > 6);
  my ($Y, $M, $D)=split(/-/, $DATE, 3);
  
my $list = $Paysys->list( { %LIST_PARAMS, 
	                          PAYMENT_SYSTEM => $payment_system_id, 
	                          INFO           => '-',
	                          PAGE_ROWS      => $ARGV->{ROWS} || 1000,
	                          MONTH          => "$Y-$M"
	                        } );	

my %status_hash = (
10 => '�� ����������',
20 => '��������� ������ ����������',
25 => '������������',
30 => '������������',
48 => '�������� ���������� ��������',
49 => '�������� ���������� ��������',
50 => '����������',
51 => '��������� (51)',
58 => '��������������',
59 => '������� � ������',
60 => '���������',
61 => '���������',
125 => '�� ������ ��������� ����������',
130 => '����� �� ����������',
148 => '�� ������ ���. ��������',
149 => '�� ������ ���. ��������',
150 => '������ �� ���������',
160 => '�� ���������',
161 => '������� (������� �����)'
);



my @ids_arr = ();
foreach my $line (@$list) {
  push @ids_arr, $line->[5];
  if ($debug > 5) {
  	print "Unregrequest: $line->[5]\n";
   }
}

my $result = qiwi_status({ IDS   => \@ids_arr,
	                         DEBUG => $debug });


if ($result->{'result-code'}->[0]->{fatal} && $result->{'result-code'}->[0]->{fatal} eq 'true') {
	print "Error: ".  $result->{'result-code'}->[0]->{content} ."\n";
	exit;
} 

my %res_hash = ();
foreach my $id ( keys %{ $result->{'bills-list'}->[0]->{bill} } ) {
  if ($debug > 5) {
         print "$id / ". $result->{'bills-list'}->[0]->{bill}->{$id}->{status} ."\n";
   }

	$res_hash{$id}=$result->{'bills-list'}->[0]->{bill}->{$id}->{status};
}

foreach my $line (@$list) {
  print "$line->[1] LOGIN: $line->[8]:$line->[2] SUM: $line->[3] PAYSYS: $line->[4] PAYSYS_ID: $line->[5]  $line->[6] STATUS: $res_hash{$line->[5]}\n" if ($debug > 0);
  if ($res_hash{$line->[5]} == 50) {
  	
   }
  elsif ( $res_hash{$line->[5]} == 60 ||  $res_hash{$line->[5]} == 61 || $res_hash{$line->[5]} == 51) {
  	 my $user = $Users->info($line->[8]);
  	 
  	 if ($Users->{TOTAL}<1) {
  	 	 print "$line->[1] LOGIN: $line->[8] $line->[2] $line->[5] Not exists\n";
  	 	 next;
  	  }
  	 elsif($Users->{errno}) {
  	 	 print "$line->[1] LOGIN: $line->[8] $line->[2] $line->[5] [$Users->{error}] $Users->{errstr}\n";
  	 	 next;
  	  }
  	 
     $payments->add($user, {SUM         => $line->[3],
    	                     DESCRIBE     => "$payment_system", 
    	                     METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',  
  	                       EXT_ID       => "$payment_system:$line->[5]",
  	                       CHECK_EXT_ID => "$payment_system_id:$line->[5]" } );  

     if($payments->{error}) {
     	  print "Payments: $line->[1] LOGIN: $line->[8]:$line->[2] $line->[5] [$payments->{error}] $payments->{errstr}\n";
     	  next;
      }

     $Paysys->change({ ID        => $line->[0],
     	                 PAYSYS_IP => $ENV{'REMOTE_ADDR'},
 	                     INFO      => "$_DATE: $DATE $TIME $res_hash{$line->[5]} - $status_hash{$res_hash{$line->[5]}}",
 	                     STATUS    => 2
      	            });
   }
  elsif (in_array($res_hash{$line->[5]}, [ 160, 161 ])) {
     $Paysys->change({ ID        => $line->[0],
     	                 PAYSYS_IP => $ENV{'REMOTE_ADDR'},
 	                     INFO      => "$_DATE: $DATE $TIME $res_hash{$line->[5]} - $status_hash{$res_hash{$line->[5]}}",
 	                     STATUS    => 2
      	            });
   }
}
	
	return 0;
}

#**********************************************************
#
#**********************************************************
sub	help {

print << "[END]";	
  QIWI checker:
    DEBUG=... - debug mode
    ROWS=..   - Rows for analise
    help      - this help
[END]

}



#**********************************************************
# Calls function for all registration modules if function exist
#
# cross_modules_call(function_sufix, attr)
#**********************************************************
sub cross_modules_call  {
  my ($function_sufix, $attr) = @_;

eval {
  my %full_return  = ();
  my @skip_modules = ();
 
  if ($attr->{SKIP_MODULES}) {
  	$attr->{SKIP_MODULES}=~s/\s+//g;
  	@skip_modules=split(/,/, $attr->{SKIP_MODULES});
   }
 
  foreach my $mod (@MODULES) {
  	if (in_array($mod, \@skip_modules)) {
  		next;
  	 }
    require "Abills/modules/$mod/webinterface";
    my $function = lc($mod).$function_sufix;
    my $return;
    if (defined(&$function)) {
     	$return = $function->($attr);
     }
    $full_return{$mod}=$return;
   }
};

  return \%full_return;
}



#**********************************************************
# load_module($string, \%HASH_REF);
#**********************************************************
sub load_module {
	my ($module, $attr) = @_;

	my $lang_file = '';
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
1
