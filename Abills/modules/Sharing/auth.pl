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
my $query = "SELECT if(DECODE(password, '$conf{secretkey}')='$passwd', 1,0)
  FROM (users u, sharing_main sharing)
  WHERE u.id='$user'  AND u.uid=sharing.uid  
                    AND (u.disable=0 AND sharing.disable=0)
                    AND (sharing.cid='' OR sharing.cid='$ip')";



my $sth = $dbh->prepare($query);
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

#Get file info



# Get month traffic

$sth->finish();
$dbh->disconnect();



exit 0;
