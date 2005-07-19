package Fees;
# Finance module
# Fees 

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw(
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();

my $db;
my $uid;
my $admin;
#my %DATA = ();
use main;
@ISA  = ("main");


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin) = @_;
  my $self = { };
  bless($self, $class);
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub get {
  my $self = shift;
  my ($user, $sum, $attr) = @_;
  
  my $DESCRIBE = (defined($attr->{DESCRIBE})) ? $attr->{DESCRIBE} : '';
  
  if ($sum <= 0) {
     $self->{errno} = 12;
     $self->{errstr} = 'ERROR_ENTER_SUM';
     return $self;
   }
  
  my $sql;

  if ($user->{ACCOUNT_ID} > 0) {
  	$sql = "SELECT deposit FROM accounts WHERE id='$user->{ACCOUNT_ID}';";
   }
  else {
    $sql = "SELECT deposit FROM users WHERE uid='$user->{UID}';";
   }
  my $q = $db -> prepare($sql)|| die $db->errstr;
  $q -> execute();

  if ($q->rows == 1) {
    my ($deposit)=$q -> fetchrow();

    if ($user->{ACCOUNT_ID} > 0) {
      $self->query($db, "UPDATE accounts SET deposit=deposit-$sum WHERE id='$user->{ACCOUNT_ID}';", 'do');
      }   
    else {
    	$self->query($db, "UPDATE users SET deposit=deposit-$sum WHERE uid='$user->{UID}';", 'do');
      }

    if($self->{errno}) {
       return $self;
      }


    $self->query($db, "INSERT INTO fees (uid, date, sum, dsc, ip, last_deposit, aid) 
           values ('$user->{UID}', now(), $sum, '$DESCRIBE', INET_ATON('$admin->{SESSION_IP}'), '$deposit', '$admin->{AID}');", 'do');

    if($self->{errno}) {
       return $self;
      }
  }


  if($self->{errno}) {
     return $self;
   }

  return $self;
}

#**********************************************************
# del $user, $id
#**********************************************************
sub del {
  my $self = shift;
  my ($user, $id) = @_;

  $self->query($db, "SELECT sum from fees WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }
  elsif($self->{errno}) {
     return $self;
   }

  my $a_ref = $self->{list}->[0];
  my($sum) = @$a_ref;

  my $sql;
  if ($user->{ACCOUNT_ID} > 0) {
    $sql = "UPDATE accounts SET deposit=deposit+$sum WHERE id='$user->{ACCOUNT_ID}';";	
   }
  else {
    $sql = "UPDATE users SET deposit=deposit+$sum WHERE uid='$user->{UID}';";	
   }

  $self->query($db, "$sql", 'do');

  $self->query($db, "DELETE FROM fees WHERE id='$id';", 'do');

  $admin->action_add($user->{UID}, "DELETE FEES SUM: $sum");
  return $self->{result};
}



#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 my $WHERE  = '';
 my @list = (); 


 if ($attr->{UID}) {
    $WHERE .= ($WHERE ne '') ?  " and f.uid='$attr->{UID}' " : "WHERE f.uid='$attr->{UID}' ";
  }
 # Start letter 
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    $WHERE .= ($WHERE ne '') ?  " and u.id LIKE '$attr->{LOGIN_EXPR}' " : "WHERE u.id LIKE '$attr->{LOGIN_EXPR}' ";
  }
 
 if ($attr->{AID}) {
    $WHERE .= ($WHERE ne '') ?  " and f.aid='$attr->{AID}' " : "WHERE f.aid='$attr->{AID}' ";
  }


 if ($attr->{A_LOGIN}) {
 	 $attr->{A_LOGIN} =~ s/\*/\%/ig;
 	 $WHERE .= ($WHERE ne '') ?  " and a.id LIKE '$attr->{A_LOGIN}' " : "WHERE a.id LIKE '$attr->{A_LOGIN}' ";
 }

 # Show debeters
 if ($attr->{DESCRIBE}) {
    $attr->{DESCRIBE} =~ s/\*/\%/g;
    $WHERE .= ($WHERE ne '') ?  " and f.dsc LIKE '$attr->{DESCRIBE}' " : "WHERE f.dsc LIKE '$attr->{DESCRIBE}' ";
  }

 # Show debeters
 if ($attr->{SUM}) {
    my $value = $self->search_expr($attr->{SUM}, 'INT');
    $WHERE .= ($WHERE ne '') ?  " and f.sum$value " : "WHERE f.sum$value ";
  }

 # Date
 if ($attr->{DATE}) {
    my $value = $self->search_expr("'$attr->{DATE}'", 'INT');
    $WHERE .= ($WHERE ne '') ?  " and date_format(f.date, '%Y-%m-%d')$value " : "WHERE date_format(f.date, '%Y-%m-%d')$value ";
  }



 $self->query($db, "SELECT f.id, u.id, f.date, f.sum, f.dsc, if(a.name is NULL, 'Unknown', a.name),  INET_NTOA(f.ip), f.last_deposit, f.uid 
    FROM fees f
    LEFT JOIN users u ON (u.uid=f.uid)
    LEFT JOIN admins a ON (a.aid=f.aid)
    $WHERE 
    GROUP BY f.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 $self->{SUM} = '0.00';
 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};


 $self->query($db, "SELECT count(*), sum(f.sum) FROM fees f 
 LEFT JOIN users u ON (u.uid=f.uid) 
 LEFT JOIN admins a ON (a.aid=f.aid)
 $WHERE");
 my $a_ref = $self->{list}->[0];

 ($self->{TOTAL}, 
  $self->{SUM}) = @$a_ref;

  return $list;
}

#**********************************************************
# report
#**********************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $WHERE = '' ;
 my $date = '';
 
 print $attr->{DATE};
 
 if(defined($attr->{DATE})) {
   $self->query($db, "select date_format(l.start, '%Y-%m-%d'), if(u.id is NULL, CONCAT('> ', l.uid, ' <'), u.id), count(l.uid), 
    sum(l.sent + l.recv), sum(l.sent2 + l.recv2), sec_to_time(sum(l.duration)), sum(l.sum), l.uid
      FROM log l
      LEFT JOIN users u ON (u.uid=l.uid)
      WHERE date_format(l.start, '%Y-%m-%d')='$attr->{DATE}'
      GROUP BY l.uid 
      ORDER BY $SORT $DESC");
   return $self->{list};
  }
 elsif (defined($attr->{MONTH})) {
 	 $WHERE = ($WHERE ne '') ? "and date_format(f.date, '%Y-%m')='$attr->{MONTH}'" : "WhERE date_format(f.date, '%Y-%m')='$attr->{MONTH}'" ;
   $date = "date_format(f.date, '%Y-%m-%d')";
  } 
 else {
 	 $date = "date_format(f.date, '%Y-%m')";
  }

 
 
 $self->query($db, "SELECT $date, count(*), sum(f.sum) 
      FROM fees f
      $WHERE 
      GROUP BY 1
      ORDER BY $SORT $DESC;");

 my $list = $self->{list}; 
	
 $self->query($db, "SELECT count(*), sum(f.sum) 
      FROM fees f
      $WHERE;");
 my $a_ref = $self->{list}->[0];

 ($self->{TOTAL}, 
  $self->{SUM}) = @$a_ref;

	
	return $list;
}




1