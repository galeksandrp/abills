#!/usr/bin/perl



require "libexec/config.pl";

use DBI;

my $db = DBI -> connect("DBI:mysql:database=$conf{dbname};host=$conf{dbhost}", "$conf{dbuser}", "$conf{dbpasswd}") 
  or die "Unable connect to server '$conf{dbhost}'\n" . $DBI::errstr;


log_convert();

sub log_convert {
  my  @sql_array = (
   "ALTER TABLE log add column uid integer(11) unsigned not null default 0",
   "ALTER TABLE log change login start datetime NOT NULL default '0000-00-00 00:00:00';",
   "ALTER TABLE log change variant tp_id smallint(5) unsigned NOT NULL default '0'",
   "ALTER TABLE log drop index id;",  
   "ALTER TABLE log drop index login;",
   "ALTER TABLE log add index uid;",
   "ALTER TABLE log add index (uid, start);");
  
  my $user_ids = get_user_ids();
  my $not_found = "";

  $q = $db -> prepare("SELECT id from log GROUP BY id;") || die $db->strerr;
  $q->execute ();
  while(my($id)=$q->fetchrow()) {
    if (defined($user_ids->{"$id"})) {
      push @sql_array,  "UPDATE log SET uid='$user_ids->{$id}' WHERE id='$id';";
     }  
    else {   
      $not_found .= "$id, ";
     }
   }

  push @sql_array,  "ALTER TABLE log drop column id";
  push @sql_array,  "ALTER TABLE log drop column login";

  foreach my $l (@sql_array) {
    $q2 = $db->do($l);
    print "$l\n";
   }

  print "\n\n$not_found";
 
}

sub get_user_ids {
 my %user_ids = ();
 my  $q = $db -> prepare("SELECT id, uid from users;") || die $db->strerr;
 $q->execute ();
  while(my($login, $id)=$q->fetchrow()) {
    $user_ids{"$login"}=$id;
   }

  return \%user_ids;
}
