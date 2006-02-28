package main;
use strict;
#Main SQL function

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
  $db
  $admin
  $CONF
  %DATA
  $OLD_DATA
  @WHERE_RULES
  $WHERE
  
  $SORT
  $DESC
  $PG
  $PAGE_ROWS

);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw(
  $db
  $admin
  $CONF
  @WHERE_RULES
  $WHERE
  %DATA
  %OLD_DATA
  
  $SORT
  $DESC
  $PG
  $PAGE_ROWS
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();


$db    = undef;
$admin = undef;
$CONF  = undef;
@WHERE_RULES = ();
$WHERE = '';
%DATA  = ();
$OLD_DATA   = (); #all data

$SORT      = 1;
$DESC      = '';
$PG        = 0;
$PAGE_ROWS = 25;




use DBI;

#**********************************************************
# Connect to DB
#**********************************************************
sub connect {
  my $class = shift;
  my $self = { };
  my ($dbhost, $dbname, $dbuser, $dbpasswd) = @_;
  bless($self, $class);
   #$self->{debug}=1;
   $self->{db} = DBI->connect("DBI:mysql:database=$dbname;host=$dbhost", "$dbuser", "$dbpasswd") or die 
       "Unable connect to server '$dbhost:$dbname'\n";

   #   print "---- $! --\n";
   #if ($db->err) {
   #  print "---------1!1lj2lk\n";
   #  $self->{errno}=3;
   #  $self->{errstr}=;
   #}

  return $self;
}


sub disconnect {
  my $self = shift;


  $self->{db}->disconnect;
  return $self;
}


#**********************************************************
#  do
# type. do 
#       list
#**********************************************************
sub query {
	my $self = shift;
  my ($db, $query, $type, $attr)	= @_;

  print "<p>$query</p>\n" if ($self->{debug});

  if (defined($attr->{test})) {
  	 return $self;
   }

my $q;
#print $query;

if (defined($type) && $type eq 'do') {
  
#  print $query;

  $q = $db->do($query);
  $self->{TOTAL} = 0;

  if (defined($db->{'mysql_insertid'})) {
  	 $self->{INSERT_ID} = $db->{'mysql_insertid'};
   }
}
else {
  #print $query;
  $self->{TOTAL}=0;
  $q = $db->prepare($query) || die $db->errstr;;
  if($db->err) {
     

     
     $self->{errno} = 3;
     $self->{sql_errno}=$db->err;
     $self->{sql_errstr}=$db->errstr;
     $self->{errstr}=$db->errstr;
#     print "-----------------------111";
     
     return $self->{errno};
   }
  #print $query;
  $q ->execute(); 
  if($db->err) {
     $self->{errno} = 3;

     $self->{sql_errno}=$db->err;
     $self->{sql_errstr}=$db->errstr;
     $self->{errstr}=$db->errstr;
     return $self->{errno};
   }
  $self->{Q}=$q;
  $self->{TOTAL} = $q->rows;
}



if($db->err) {

  if ($db->err == 1062) {
    $self->{errno} = 7;
    $self->{errstr} = 'ERROR_DUBLICATE';
    return $self;
   }

  $self->{errno} = 3;
  $self->{errstr} = 'SQL_ERROR';
  return $self;
 }

if ($self->{TOTAL} > 0) {
  my @rows;
  while(my @row = $q->fetchrow()) {
#   print "---$row[0] -";
   push @rows, \@row;
  }
  $self->{list} = \@rows;
}
else {
	delete $self->{list};
}
  return $self;
}



#**********************************************************
# get_data
#**********************************************************
sub get_data {
	my $self=shift;
	my ($params, $attr) = @_;
  my %DATA;
  
  if(defined($attr->{default})) {
  	 my $dhr = $attr->{default};
  	 %DATA = %$dhr;
   }


  
  while(my($k, $v)=each %$params) {
  	 next if (! $params->{$k} && defined($DATA{$k})) ;
  	 $DATA{$k}=$v;
#    print "--$k, $v<br>\n";
   }

#  while(my($k, $v)=each %DATA) {
#  	print "$k, $v<br>\n";
#  }

  
	return %DATA;
}


#**********************************************************
# search_expr($self, $value, $type)
#
# type of fields
# IP -  IP Address
# INT - integer
# STR - string
#**********************************************************
sub search_expr {
	my $self=shift;
 	my ($value, $type)=@_;

  my $expr = '=';
  
  if($type eq 'INT' && $value =~ s/\*//g) {
  	$expr = '>';
   }
  elsif ($value =~ tr/>//d) {
    $expr = '>';
   }
  elsif($value =~ tr/<//d) {
    $expr = '<';
   }
  
  if ($type eq 'IP') {
  	$value = "INET_ATON('$value')";
   }
 
  $value = $expr . $value;
  return $value;
}


#**********************************************************
# change_constructor($self, $uid, $attr)
# $attr 
#  CHANGE_PARAM - chenging param
#  TABLE        - changing table
#  \%FIELDS     - fields of table
#  ...          - data
#  OLD_INFO     - OLD infomation for compare
#**********************************************************
sub changes {
  my $self = shift;
  my ($admin, $attr) = @_;

  
  my $TABLE        = $attr->{TABLE};
  my $CHANGE_PARAM = $attr->{CHANGE_PARAM};
  my $FIELDS       = $attr->{FIELDS};
  my %DATA         = $self->get_data($attr->{DATA}); 

  $DATA{DISABLE} = (defined($DATA{DISABLE})) ? 1 : 0;

  if(defined($DATA{EMAIL}) && $DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }

  $OLD_DATA = $attr->{OLD_INFO}; #  $self->info($uid);
  if($OLD_DATA->{errno}) {
     $self->{errno}  = $OLD_DATA->{errno};
     $self->{errstr} = $OLD_DATA->{errstr};
     return $self;
   }

  my $CHANGES_QUERY = "";
  my $CHANGES_LOG = "";

  while(my($k, $v)=each(%DATA)) {
    if (defined($FIELDS->{$k}) && $OLD_DATA->{$k} ne $DATA{$k}){
        if ($k eq 'PASSWORD' || $k eq 'NAS_MNG_PASSWORD') {
          $CHANGES_LOG .= "$k *->*;";
          $CHANGES_QUERY .= "$FIELDS->{$k}=ENCODE('$DATA{$k}', '$CONF->{secretkey}'),";
         }
        elsif($k eq 'IP' || $k eq 'NETMASK') {
          $CHANGES_LOG .= "$k $OLD_DATA->{$k}->$DATA{$k};";
          $CHANGES_QUERY .= "$FIELDS->{$k}=INET_ATON('$DATA{$k}'),";
         }
        else {
          $CHANGES_LOG .= "$k $OLD_DATA->{$k}->$DATA{$k};";
          $CHANGES_QUERY .= "$FIELDS->{$k}='$DATA{$k}',";
         }
     }
   }




if ($CHANGES_QUERY eq '') {
  return $self->{result};	
}

# print $CHANGES_LOG;
  chop($CHANGES_QUERY);
  $self->query($db, "UPDATE $TABLE SET $CHANGES_QUERY WHERE $FIELDS->{$CHANGE_PARAM}='$DATA{$CHANGE_PARAM}'", 'do');

  if($self->{errno}) {
     return $self;
   }

  if (defined($DATA{UID}) && $DATA{UID} > 0 && defined($admin)) { 
     $admin->action_add($DATA{UID}, "$CHANGES_LOG");
   }

  return $self->{result};
}



1