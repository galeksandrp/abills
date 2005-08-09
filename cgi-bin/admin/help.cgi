#!/usr/bin/perl
# Help systems
#
BEGIN {
 my $libpath = '../../';
 
 $sql_type='mysql';
 unshift(@INC, $libpath ."Abills/$sql_type/");
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



require "config.pl";
require "Abills/defs.conf";
#
#==== End config


















#use FindBin '$Bin2';
use Abills::SQL;
use Abills::HTML;

my $html = Abills::HTML->new();
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};
require "../../language/$html->{language}.pl";


print $html->header();
help();


sub help {
print << "[END]";
<center>
<form action=$PHP_SELF METHOD=post>
<input type=hidden name=index value=$FORM{index}

<table border=1>
<tr><td>$_SUBJECT: </td><td><input type=text name=caption value='$caption' size=40></td></tr>
<tr><th colspan=2><textarea name=text cols=50 rows=4>$FORM</textarea></th></tr>
<tr><th colspan=2><input type=submit name=add></th></tr>
</table>
[END]


}

