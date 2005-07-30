package Users;
# Users manage functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

# User name expration
my $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$"; # configurable;

my %conf = ();
$conf{max_username_length} = 10;


use main;
@ISA  = ("main");


my $db;
my $uid;
my $admin;
my $CONF;
my %DATA = ();

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
#  $self->{debug}=1;
  return $self;
}


#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($uid) = shift;
  my ($attr) = @_;

  my $WHERE;
  #my $PASSWORD = '0'; 
  
  if (defined($attr->{LOGIN}) && defined($attr->{PASSWORD})) {
    $WHERE = "WHERE u.id='$attr->{LOGIN}' and DECODE(u.password, '$CONF->{secretkey}')='$attr->{PASSWORD}'";
    #$PASSWORD = "if(DECODE(password, '$SECRETKEY')='$attr->{PASSWORD}', 0, 1)";
   }
  elsif(defined($attr->{LOGIN})) {
    $WHERE = "WHERE u.id='$attr->{LOGIN}'";
   }
  else {
    $WHERE = "WHERE u.uid='$uid'";
   }



  $self->query($db, "SELECT u.id, u.fio, u.phone, u.address, u.email, u.activate, u.expire, u.credit, u.reduction, 
            u.tp_id, tp.name, u.logins, u.registration, u.disable,
            INET_NTOA(u.ip), INET_NTOA(u.netmask), u.speed, u.filter_id, u.cid, u.comments, u.account_id,
            if(acct.name IS NULL, 'N/A', acct.name), if(acct.name IS NULL, u.deposit, acct.deposit), tp.name, u.gid, g.name, u.uid
     FROM users u
     LEFT JOIN accounts acct ON (u.account_id=acct.id)
     LEFT JOIN tarif_plans tp ON (u.tp_id=tp.id)
     LEFT JOIN groups g ON (u.gid=g.gid)
     $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{LOGIN}, 
   $self->{FIO}, 
   $self->{PHONE}, 
   $self->{ADDRESS}, 
   $self->{EMAIL}, 
   $self->{ACTIVATE}, $self->{EXPIRE}, 
   $self->{CREDIT}, 
   $self->{REDUCTION}, 
   $self->{TARIF_PLAN}, 
   $self->{TARIF_PLAN_NAME}, 
   $self->{SIMULTANEONSLY}, 
   $self->{REGISTRATION}, 
   $self->{DISABLE}, 
   $self->{IP}, 
   $self->{NETMASK}, 
   $self->{SPEED}, 
   $self->{FILTER_ID}, 
   $self->{CID}, 
   $self->{COMMENTS}, 
   $self->{ACCOUNT_ID},
   $self->{ACCOUNT_NAME},
   $self->{DEPOSIT},
   $self->{TP_NAME},
   $self->{GID},
   $self->{G_NAME},
   $self->{UID} )= @$ar;
  
  
  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = ( LOGIN => '', 
   FIO => '', 
   PHONE => '', 
   ADDRESS => '', 
   EMAIL => '', 
   ACTIVATE => '0000-00-00', 
   EXPIRE => '0000-00-00', 
   CREDIT => 0, 
   REDUCTION => '0.00', 
   TARIF_PLAN => 0, 
   SIMULTANEONSLY => 0, 
   DISABLE => 0, 
   IP => '0.0.0.0', 
   NETMASK => '255.255.255.255', 
   SPEED => 0, 
   FILTER_ID => '', 
   CID => '', 
   COMMENTS => '', 
   ACCOUNT_ID => 0,
   DEPOSIT => 0,
   GID => 0 );

 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# groups_list()
#**********************************************************
sub groups_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 $self->query($db, "select g.gid, g.name, g.descr, count(u.uid) FROM groups g
        LEFT JOIN users u ON  (u.gid=g.gid) 
        GROUP BY g.gid
        ORDER BY $SORT $DESC");

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*) FROM groups");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

 return $list;
}


#**********************************************************
# group_info()
#**********************************************************
sub group_info {
 my $self = shift;
 my ($gid) = @_;
 
 $self->query($db, "select g.name, g.descr FROM groups g WHERE g.gid='$gid';");

 return $self if ($self->{errno});

 my $a_ref = $self->{list}->[0];

 ($self->{G_NAME},
 	$self->{G_DESCRIBE}) = @$a_ref;
 
 $self->{GID}=$gid;

 return $self;
}

#**********************************************************
# group_info()
#**********************************************************
sub group_change {
 my $self = shift;
 my ($gid, $attr) = @_;
 
 %DATA = $self->get_data($attr); 
 my %FIELDS = (GID => 'gid',
               G_NAME => 'name',
               G_DESCRIBE => 'descr');
 
 my $CHANGES_QUERY = "";
 my $CHANGES_LOG = "";
  
 my $OLD = $self->group_info($gid);

 if($OLD->{errno}) {
   $self->{errno} = $OLD->{errno};
   $self->{errstr} = $OLD->{errstr};
   return $self;
  }

 while(my($k, $v)=each(%DATA)) {
   if (defined($FIELDS{$k}) && $OLD->{$k} ne $DATA{$k}){
     $CHANGES_LOG .= "$k $OLD->{$k}->$DATA{$k};";
     $CHANGES_QUERY .= "$FIELDS{$k}='$DATA{$k}',";
    }
  }


if ($CHANGES_QUERY eq '') {
  return $self->{result};	
}

chop($CHANGES_QUERY);
$self->query($db, "UPDATE groups SET $CHANGES_QUERY WHERE gid='$gid'", 'do');

  if($self->{errno}) {
     $self->{errno} = $OLD->{errno};
     $self->{errstr} = $OLD->{errstr};
     return $self;
   }

 return $self;
}



#**********************************************************
# group_add()
#**********************************************************
sub group_add {
 my $self = shift;
 my ($attr) = @_;

 %DATA = $self->get_data($attr); 
 $self->query($db, "INSERT INTO groups (gid, name, descr)
    values ('$DATA{GID}', '$DATA{G_NAME}', '$DATA{G_DESCRIBE}');", 'do');

 return $self;
}



#**********************************************************
# group_add()
#**********************************************************
sub group_del {
 my $self = shift;
 my ($id) = @_;

 $self->query($db, "DELETE FROM groups WHERE gid='$id';", 'do');
 return $self;
}


#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 my $WHERE  = '';
 my $search_fields = '';

 #
 
 if ($attr->{USERS_WARNINGS}) {
   $self->query($db, " SELECT u.id, u.email, u.tp_id, u.credit, u.deposit, tp.name, tp.uplimit
         FROM users u
         LEFT JOIN tarif_plans tp ON u.tp_id = tp.id
         WHERE u.deposit<tp.uplimit AND tp.uplimit > 0 AND u.deposit+u.credit>0
         ORDER BY u.id;");
   my $list = $self->{list};
   return $list;
  }
 elsif($attr->{CLOSED}) {
   $self->query($db, "SELECT u.id, u.fio, if(acct.id IS NULL, u.deposit, acct.deposit), u.credit, tp.name, u.disable, 
      u.uid, u.account_id, u.email, u.tp_id, if(l.start is NULL, '-', l.start)
     FROM users u
     LEFT JOIN  tarif_plans tp ON  (tp.id=u.tp_id) 
     LEFT JOIN  accounts acct ON  (u.account_id=acct.id) 
     LEFT JOIN  log l ON  (l.uid=u.uid) 
     WHERE  (u.deposit+u.credit-tp.credit_tresshold<=0
        and tp.hourp+tp.df+tp.abon>=0)
        or (
        (u.expire<>'0000-00-00' and u.expire < CURDATE())
        AND (u.activate<>'0000-00-00' and u.activate > CURDATE())
        )
        or u.disable=1
     GROUP BY u.uid
     ORDER BY $SORT $DESC;");
   my $list = $self->{list};
   return $list;
  }

 # Start letter 
 if ($attr->{FIRST_LETTER}) {
    $WHERE .= ($WHERE ne '') ?  " and u.id LIKE '$attr->{FIRST_LETTER}%' " : "WHERE u.id LIKE '$attr->{FIRST_LETTER}%' ";
  }
 elsif ($attr->{LOGIN}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    $WHERE .= ($WHERE ne '') ?  " and u.id='$attr->{LOGIN}' " : "WHERE u.id='$attr->{LOGIN}' ";
  }
 # Login expresion
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    $WHERE .= ($WHERE ne '') ?  " and u.id LIKE '$attr->{LOGIN_EXPR}' " : "WHERE u.id LIKE '$attr->{LOGIN_EXPR}' ";
  }
 

 if ($attr->{IP}) {
    if ($attr->{IP} =~ m/\*/g) {
      my ($i, $first_ip, $last_ip);
      my @p = split(/\./, $attr->{IP});
      for ($i=0; $i<4; $i++) {

         if ($p[$i] eq '*') {
         	 $first_ip .= '0';
         	 $last_ip .= '255';
          }
         else {
         	 $first_ip .= $p[$i];
         	 $last_ip .= $p[$i];
          }
         if ($i != 3) {
         	 $first_ip .= '.';
         	 $last_ip .= '.';
          }
       }
      $WHERE .= ($WHERE ne '') ?  " and (u.ip>=INET_ATON('$first_ip') and u.ip<=INET_ATON('$last_ip'))" : "WHERE (u.ip>=INET_ATON('$first_ip') and u.ip<=INET_ATON('$last_ip')) ";
     }
    else {
      my $value = $self->search_expr($attr->{IP}, 'IP');
      $WHERE .= ($WHERE ne '') ?  " and u.ip$value " : "WHERE u.ip$value ";
    }
  }

 if ($attr->{PHONE}) {
    my $value = $self->search_expr($attr->{PHONE}, 'INT');
    $WHERE .= ($WHERE ne '') ?  " and u.phone$value " : "WHERE u.phone$value ";
  }


 if ($attr->{DEPOSIT}) {
    my $value = $self->search_expr($attr->{DEPOSIT}, 'INT');
    $WHERE .= ($WHERE ne '') ?  " and u.deposit$value " : "WHERE u.deposit$value ";
  }

 if ($attr->{SPEED}) {
    my $value = $self->search_expr($attr->{SPEED}, 'INT');
    $WHERE .= ($WHERE ne '') ?  " and u.speed$value " : "WHERE u.speed$value ";
  }

 if ($attr->{CID}) {
    $attr->{CID} =~ s/\*/\%/ig;
    $WHERE .= ($WHERE ne '') ?  " and u.cid LIKE '$attr->{CID}' " : "WHERE u.cid LIKE '$attr->{CID}' ";
  }

 if ($attr->{COMMENTS}) {
 	$attr->{COMMENTS} =~ s/\*/\%/ig;
 	$WHERE .= ($WHERE ne '') ?  " and u.comments LIKE '$attr->{COMMENTS}' " : "WHERE u.comments LIKE '$attr->{COMMENTS}' ";
  }


 if ($attr->{FIO}) {
    $attr->{FIO} =~ s/\*/\%/ig;
    $WHERE .= ($WHERE ne '') ?  " and u.fio LIKE '$attr->{FIO}' " : "WHERE u.fio LIKE '$attr->{FIO}' ";
  }

 # Show users for spec tarifplan 
 if ($attr->{TP}) {
    $WHERE .= ($WHERE ne '') ?  " and u.tp_id='$attr->{TP}' " : "WHERE u.tp_id='$attr->{TP}' ";
  }

 # Show debeters
 if ($attr->{DEBETERS}) {
    $WHERE .= ($WHERE ne '') ?  " and u.id LIKE '$attr->{FIRST_LETTER}%' " : "WHERE u.id LIKE '$attr->{FIRST_LETTER}%' ";
  }

 # Show debeters
 if ($attr->{ACCOUNT_ID}) {
    $WHERE .= ($WHERE ne '') ?  " and u.account_id='$attr->{ACCOUNT_ID}' " : "WHERE u.account_id='$attr->{ACCOUNT_ID}' ";
  }

 # Show groups
 if ($attr->{GID}) {
    $WHERE .= ($WHERE ne '') ?  " and u.gid='$attr->{GID}' " : "WHERE u.gid='$attr->{GID}' ";
  }

#Activate
 if ($attr->{ACTIVATE}) {
   my $value = $self->search_expr("'$attr->{ACTIVATE}'", 'INT');
   $WHERE .= ($WHERE ne '') ?  " AND (u.activate='0000-00-00' or u.activate$value) " : "WHERE (u.activate='0000-00-00' or u.activate$value) "; 
 }

#Expire
 if ($attr->{EXPIRE}) {
   my $value = $self->search_expr("'$attr->{EXPIRE}'", 'INT');
   $WHERE .= ($WHERE ne '') ?  " AND (u.expire='0000-00-00' or u.expire$value) " : "WHERE (u.expire='0000-00-00' or u.expire$value) "; 
 }

#DIsable
 if ($attr->{DISABLE}) {
   $WHERE .= ($WHERE ne '') ?  " AND u.disable='$attr->{DISABLE}' " : "WHERE u.disable='$attr->{DISABLE} "; 
 }
 
 
 $self->query($db, "SELECT u.id, u.fio, if(acct.id IS NULL, u.deposit, acct.deposit), u.credit, tp.name, u.disable, 
      u.uid, u.account_id, u.email, u.tp_id, u.activate, u.expire
     FROM users u
     LEFT JOIN  tarif_plans tp ON  (tp.id=u.tp_id) 
     LEFT JOIN  accounts acct ON  (u.account_id=acct.id) 
     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});



 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(u.id) FROM users u $WHERE");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

  return $list;
}

#**********************************************************
# Add to deposit
#**********************************************************
sub add2deposit {
	my $self = shift;
	my ($sum) = @_;
	
 $self->query($db, "UPDATE users SET deposit=deposit+$sum 
     WHERE uid='$self->{UID}';");

  return $self;	
}

#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  
  my $LOGIN = (defined($attr->{LOGIN})) ? $attr->{LOGIN} : '';
  my $EMAIL = (defined($attr->{EMAIL})) ? $attr->{EMAIL} : '';
  my $FIO = (defined($attr->{FIO})) ? $attr->{FIO} : '';
  my $PHONE = (defined($attr->{PHONE})) ? $attr->{PHONE} : '';
  my $ADDRESS = (defined($attr->{ADDRESS})) ? $attr->{ADDRESS} : '';
  my $ACTIVATE = (defined($attr->{ACTIVATE})) ? $attr->{ACTIVATE} : '0000-00-00';
  my $EXPIRE = (defined($attr->{EXPIRE})) ? $attr->{EXPIRE} : '0000-00-00';
  my $CREDIT = (defined($attr->{CREDIT})) ? $attr->{CREDIT} : 0;
  my $REDUCTION  = (defined($attr->{REDUCTION})) ? $attr->{REDUCTION} : 0.00;
  my $SIMULTANEONSLY = (defined($attr->{SIMULTANEONSLY})) ? $attr->{SIMULTANEONSLY} : 0;
  my $COMMENTS = (defined($attr->{COMMENTS})) ? $attr->{COMMENTS} : '';
  my $ACCOUNT_ID = (defined($attr->{ACCOUNT_ID})) ? $attr->{ACCOUNT_ID} : 0;
  my $DISABLE = (defined($attr->{DISABLE})) ? $attr->{DISABLE} : 0;
  my $GID = (defined($attr->{GID})) ? $attr->{GID} : 65535;
  
  my $TARIF_PLAN = (defined($attr->{TARIF_PLAN})) ? $attr->{TARIF_PLAN} : '';
  my $IP = (defined($attr->{IP})) ? $attr->{IP} : '0.0.0.0';
  my $NETMASK  = (defined($attr->{NETMASK})) ? $attr->{NETMASK} : '255.255.255.255';
  my $SPEED = (defined($attr->{SPEED})) ? $attr->{SPEED} : 0;
  my $FILTER_ID = (defined($attr->{FILTER_ID})) ? $attr->{FILTER_ID} : '';
  my $CID = (defined($attr->{CID})) ? $attr->{CID} : '';


  if ($LOGIN eq '') {
     $self->{errno} = 8;
     $self->{errstr} = 'ERROR_ENTER_NAME';
     return $self;
   }
  elsif (length($LOGIN) > $conf{max_username_length}) {
     $self->{errno} = 9;
     $self->{errstr} = 'ERROR_SHORT_PASSWORD';
     return $self;
   }
  elsif($LOGIN !~ /$usernameregexp/) {
     $self->{errno} = 10;
     $self->{errstr} = 'ERROR_WRONG_NAME';
     return $self; 	
   }
  elsif($EMAIL ne '') {
    if ($EMAIL !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }
    
  $self->query($db,  "INSERT INTO users (id, fio, phone, address, email, activate, expire, credit, reduction, 
            tp_id, logins, registration, disable, ip, netmask, speed, filter_id, cid, comments, account_id, gid)
           VALUES ('$LOGIN', '$FIO', '$PHONE', \"$ADDRESS\", '$EMAIL', '$ACTIVATE', '$EXPIRE', '$CREDIT', '$REDUCTION', 
            '$TARIF_PLAN', '$SIMULTANEONSLY', now(),  '$DISABLE', INET_ATON('$IP'), INET_ATON('$NETMASK'), '$SPEED', '$FILTER_ID', LOWER('$CID'), '$COMMENTS', '$ACCOUNT_ID', '$GID');", 'do');
  
  return $self if ($self->{errno});
  
  $self->{UID} = $self->{INSERT_ID};
  $self->{LOGIN} = $LOGIN;

  $admin->action_add($uid, "ADD $LOGIN");

  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($uid, $attr) = @_;
  
  my %DATA = $self->get_data($attr); 
  $DATA{DISABLE} = (defined($attr->{DISABLE})) ? 1 : 0;
  my $secretkey = (defined($attr->{secretkey}))? $attr->{secretkey} : '';  

my %FIELDS = (LOGIN => 'id',
              EMAIL => 'email',
              FIO => 'fio',
              PHONE => 'phone',
              ADDRESS => 'address',
              ACTIVATE => 'activate',
              EXPIRE => 'expire',
              CREDIT => 'credit',
              REDUCTION => 'reduction',
              SIMULTANEONSLY => 'logins',
              COMMENTS => 'comments',
              ACCOUNT_ID => 'account_id',
              DISABLE => 'disable',
              GID => 'gid',
              PASSWORD => 'password',

              IP => 'ip',
              NETMASK => 'netmask',
              TARIF_PLAN=> 'tp_id',
              SPEED=> 'speed',
              CID=> 'cid'
             );

  if(defined($DATA{EMAIL}) && $DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }

  my $CHANGES_QUERY = "";
  my $CHANGES_LOG = "";
  
  my $OLD = $self->info($uid);
  if($OLD->{errno}) {
     $self->{errno} = $OLD->{errno};
     $self->{errstr} = $OLD->{errstr};
     return $self;
   }

  while(my($k, $v)=each(%DATA)) {
    if (defined($FIELDS{$k}) && $OLD->{$k} ne $DATA{$k}){
        if ($k eq 'PASSWORD') {
          $CHANGES_LOG .= "$k *->*;";
          $CHANGES_QUERY .= "$FIELDS{$k}=ENCODE('$DATA{$k}', '$secretkey'),";
         }
        elsif($k eq 'IP' || $k eq 'NETMASK') {
          $CHANGES_LOG .= "$k $OLD->{$k}->$DATA{$k};";
          $CHANGES_QUERY .= "$FIELDS{$k}=INET_ATON('$DATA{$k}'),";
         }
        else {
          $CHANGES_LOG .= "$k $OLD->{$k}->$DATA{$k};";
          $CHANGES_QUERY .= "$FIELDS{$k}='$DATA{$k}',";
         }
     }
   }


if ($CHANGES_QUERY eq '') {
  return $self->{result};	
}

# print $CHANGES_LOG;
  chop($CHANGES_QUERY);
  $self->query($db, "UPDATE users SET $CHANGES_QUERY WHERE uid='$uid'", 'do');

  if($self->{errno}) {
     $self->{errno} = $OLD->{errno};
     $self->{errstr} = $OLD->{errstr};
     return $self;
   }

  $admin->action_add($uid, "$CHANGES_LOG");
  return $self->{result};
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  my @clear_db = ('admin_actions', 
                  'fees', 
                  'payments', 
                  'users_nas', 
                  'messages',
                  'docs_acct',
                  'users',
                  'log');

  foreach my $table (@clear_db) {
     $self->query($db, "DELETE from $table WHERE uid='$self->{UID}';", 'do');
     $self->{info} .= "$table, ";
    }

  $admin->action_add($uid, "DELETE");
  return $self->{result};
}

#**********************************************************
# list_allow nass
#**********************************************************
sub nas_list {
  my $self = shift;

  my @nas_list ;
 
  my $sql="SELECT nas_id FROM users_nas WHERE uid='$self->{UID}';";
  my $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();

  if ($q->rows > 0) {
    while(my ($nas) = $q->fetchrow()) {
      push @nas_list, $nas;
     }
   }
  else {
    $sql="SELECT nas_id FROM vid_nas WHERE vid='$self->{TARIF_PLAN}';";
    $q = $db->prepare($sql) || die $db->strerr;
    $q ->execute();
    if ($q->rows > 0) {
      while(my($nas_id)=$q->fetchrow()) {
         push @nas_list, $nas_id;
       }
     }
   }

	return \@nas_list;
}


#**********************************************************
# list_allow nass
#**********************************************************
sub nas_add {
 my $self = shift;
 my ($nas) = @_;
 
 $self->nas_del();
 foreach my $line (@$nas) {
   my $sql = "INSERT INTO users_nas (nas_id, uid)
        VALUES ('$line', '$self->{UID}');";	
   my $q = $db->do($sql) || die $db->errstr;
  }
  
  $admin->action_add($uid, "NAS ". join(',', @$nas) );
  return $self;
}

#**********************************************************
# nas_del
#**********************************************************
sub nas_del {
  my $self = shift;
  
  $self->query($db, "DELETE FROM users_nas WHERE uid='$self->{UID}';", 'do');	
  return $self if($db->err > 0);

  $admin->action_add($uid, "DELETE NAS");
  return $self;
}

sub test {
 my  $self = shift;	

 print "test";
}


1