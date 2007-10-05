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

  my ($uid, $datetime, $user, $remote_addr, $alived) = $sth->fetchrow_array();
 }
else {
#check password
my $query = "SELECT if(DECODE(password, '$conf{secretkey}')='$passwd', 1,0)
   FROM (users u, sharing_main sharing)
    WHERE u.id='$user'  AND u.uid=sharing.uid  
                    AND (u.disable=0 AND sharing.disable=0)
                    AND (sharing.cid='' OR sharing.cid='$ip')";

$sth = $dbh->prepare($query);
$sth->execute();

my ($password, $deposit) = $sth->fetchrow_array();

if ($sth->rows() < 1) {
  print STDERR "User not found '$user' - Rejected\n";
  exit 1;
 }
elsif ($password == 0) {
  print STDERR "Wrong user password '$user' - Rejected\n";
  exit 1;
 }
}

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
