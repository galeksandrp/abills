package main;
use strict;

#Main SQL function



use DBI;

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

if (defined($type) && $type eq 'do') {
  $q = $db->do($query);
  $self->{TOTAL} = 0;
  if (defined($db->{'mysql_insertid'})) {
  	 $self->{INSERT_ID} = $db->{'mysql_insertid'};
   }
}
else {
  #print $query;
  $q = $db->prepare($query) || die $db->errstr;;
  if($db->err) {
     $self->{errno} = 3;
     $self->{sql_errno}=$db->err;
     $self->{sql_errstr}=$db->errstr;
     $self->{errstr}=$db->errstr;
#     print "-----------------------111";
     
     return $self->{errno};
   }

  $q ->execute(); 
  if($db->err) {
     $self->{errno} = 3;

     $self->{sql_errno}=$db->err;
     $self->{sql_errstr}=$db->errstr;
     $self->{errstr}=$db->errstr;

#     print "-----------------------111-". $db->err . "-\n";
     return $self->{errno};
   }

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
  	$DATA{$k}=$v;
#    print "--$k, $v<br>\n";
   }
  
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

1