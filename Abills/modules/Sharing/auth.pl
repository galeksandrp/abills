#!/usr/bin/perl -w
# Sharing auth for Apache with mod_authnz_external (http://unixpapa.com/mod_authnz_external/)
#

use DBI;
use strict;
use vars qw(%conf);


#Main debug section
my $prog= join ' ',$0,@ARGV;
my $a = `echo "Begin" >> /tmp/sharing_env`;
my $aa = '';
while(my ($k, $v)=each %ENV) {
  $aa .= "$k - $v\n";
}

my $debug = " URI: $ENV{URI}
 USER:      $ENV{USER}
 Password:  $ENV{PASS}
 IP         $ENV{IP}
 HTTP_HOST: $ENV{HTTP_HOST}
 ===PIPE
 $prog
 ===EXT
 $aa
 === \n";
$a = `echo "$debug" >> /tmp/sharing_env`;
#***************************************************

my $user   = $ENV{USER} || '';
my $passwd = $ENV{PASS} || '';
my $ip     = $ENV{IP}   || '0.0.0.0';
my $COOKIE = $ENV{COOKIE} || '';

#**************************************************************
# DECLARE VARIABLES                                                           #
#**************************************************************
#DB configuration
#use FindBin '$Bin';
#require $Bin . '/../../../libexec/config.pl';

require '/usr/abills/libexec/config.pl';


#$conf{dbhost}='huan';
#$conf{dbname}='abills_dev';
#$conf{dbuser}='stats';
#$conf{dbpasswd}='45&34';
#$conf{dbtype}='mysql';
#$conf{secretkey}="test12345678901234567890";

# open database connection
my $dbh = DBI->connect("DBI:mysql:database=$conf{dbname};$conf{dbhost}",$conf{dbuser},$conf{dbpasswd}) 
  or die("Unable to connect to database. Aborting!\n");

if(!$dbh) {
  print STDERR "Could not connect to database - Rejected\n";
  exit 1;
}

#Get User ID and pass check in db
#Check cookie
my %cookies = ();
if ($COOKIE ne '') {
  my(@rawCookies) = split (/; /, $COOKIE);
  foreach(@rawCookies){
    my ($key, $val) = split (/=/,$_);
    $cookies{$key} = $val;
  }
 }

my $sth;
my ($uid, $datetime, $remote_addr, $alived, $password);

if ($cookies{sid}) {
	$cookies{sid} = s/'//g;
	$cookies{sid} = s/"//g;
	my $query = "SELECT uid, 
    datetime, 
    login, 
    INET_NTOA(remote_addr), 
    UNIX_TIMESTAMP() - datetime,
    sid
     FROM web_users_sessions
    WHERE sid='$cookies{sid}'";
	
	$sth = $dbh->prepare($query);
  $sth->execute();

  ($uid, $datetime, $user, $remote_addr, $alived) = $sth->fetchrow_array();
 }
else {
#check password
my $query = "SELECT if(DECODE(u.password, '$conf{secretkey}')='$passwd', 1,0), u.uid
   FROM (users u, sharing_main sharing)
    WHERE u.id='$user'  AND u.uid=sharing.uid  
                    AND (u.disable=0 AND sharing.disable=0)
                    AND (sharing.cid='' OR sharing.cid='$ip')";

$sth = $dbh->prepare($query);
$sth->execute();

($password, $uid) = $sth->fetchrow_array();

if ($sth->rows() < 1) {
  print STDERR "User not found '$user' - Rejected\n";
  exit 1;
 }
elsif ($password == 0) {
  print STDERR "Wrong user password '$user' - Rejected\n";
  exit 1;
 }
}


#Get user info and ballance
#check password
my $query = "select
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  u.company_id,
  u.disable,
  u.bill_id,
  u.credit,
  u.activate,
  u.reduction,
  sharing.tp_id,
  tp.payment_type,
  tp.month_traf_limit
     FROM (users u, sharing_main sharing, tarif_plans tp)
     WHERE
        u.uid=sharing.uid
        AND sharing.tp_id=tp.id
        AND u.uid='$uid'
        AND (u.expire='0000-00-00' or u.expire > CURDATE())
        AND (u.activate='0000-00-00' or u.activate <= CURDATE())
       GROUP BY u.id";

$sth = $dbh->prepare($query);
$sth->execute();

my (
  $unix_date, 
  $day_begin,
  $day_of_week,
  $day_of_year,
  $company_id,
  $disable,
  $bill_id,
  $credit,
  $activate,
  $reduction,
  $tp_id,
  $payment_type,
  $month_traf_limit
  ) = $sth->fetchrow_array();

#Get Deposit
$query = "select deposit 
     FROM bills
     WHERE
        id='$bill_id'";

$sth = $dbh->prepare($query);
$sth->execute();

my ( $deposit ) = $sth->fetchrow_array();

#Get used traffic
$query = "select sum(sent)
     FROM sharing_log
     WHERE username='$user'";

$sth = $dbh->prepare($query);
$sth->execute();
my ( $sent ) = $sth->fetchrow_array();


#Get file info
# это позволяет по ид новости определить имена файлов и открытость-закрытость их для всех
#SELECT typo3.tx_t3labtvarchive_slideshow,
#       typo3.tx_t3labtvarchive_fullversion,
#       typo3.tx_t3labtvarchive_openslide,
#       typo3.tx_t3labtvarchive_openfull
#FROM  typo3.tt_news
#WHERE  typo3.uid = $news_id;

#  14:21:35: это позволяет определить сервер скачивания и путь до файла 
#$select * FROM tx_t3labtvarchive_files WHERE filename = $filename
# Get month traffic

$sth->finish();
$dbh->disconnect();



exit 0;
