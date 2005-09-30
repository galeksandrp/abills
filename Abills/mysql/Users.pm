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

use main;
@ISA  = ("main");


my $uid;
#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $CONF->{max_username_length} = 10;
  my $self = { };
  bless($self, $class);
  #$self->{debug}=1;
  return $self;
}





#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  my $WHERE;
  
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


  $self->query($db, "SELECT u.uid,
   u.gid, 
   g.name,
   u.id, u.activate, u.expire, u.credit, u.reduction, 
   u.registration, 
   u.disable,
   u.bill_id,
   if(c.name IS NULL, b.deposit, cb.deposit),
   u.company_id,
   if(c.name IS NULL, 'N/A', c.name), 
   if(c.name IS NULL, u.bill_id, c.bill_id)

     FROM users u
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN groups g ON (u.gid=g.gid)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
     $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{UID},
   $self->{GID},
   $self->{G_NAME},
   $self->{LOGIN}, 
   $self->{ACTIVATE}, 
   $self->{EXPIRE}, 
   $self->{CREDIT}, 
   $self->{REDUCTION}, 
   $self->{REGISTRATION}, 
   $self->{DISABLE}, 
   $self->{BILL_ID}, 
   $self->{DEPOSIT}, 
   $self->{COMPANY_ID},
   $self->{COMPANY_NAME},
 )= @$ar;
  
  
  return $self;
}


#**********************************************************
# pi_add()
#**********************************************************
sub pi_add {
  my $self = shift;
  my ($attr) = @_;
  
  defaults();  
  %DATA = $self->get_data($attr, { default => $self }); 
  
  if($DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }
    
  $self->query($db,  "INSERT INTO users_pi (uid, fio, phone, address_street, address_build, address_flat, 
          email, contract_id, comments)
           VALUES ('$DATA{UID}', '$DATA{FIO}', '$DATA{PHONE}', \"$DATA{ADDRESS_STREET}\", 
            \"$DATA{ADDRESS_BUILD}\", \"$DATA{ADDRESS_FLAT}\",
            '$DATA{EMAIL}', '$DATA{CONTRACT_ID}',
            '$self->{COMMENTS}' );", 'do');
  
  return $self if ($self->{errno});
  
  $admin->action_add($uid, "ADD");
  return $self;
}



#**********************************************************
# Personal inforamtion
# personal_info()
#**********************************************************
sub pi {
	my $self = shift;

  $self->query($db, "SELECT pi.fio, 
  pi.phone, 
  pi.address_street, 
  pi.address_build,
  pi.address_flat,
  pi.email,  
  pi.contract_id,
  pi.comments
    FROM users_pi pi
    WHERE pi.uid='$self->{UID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{FIO}, 
   $self->{PHONE}, 
   $self->{ADDRESS_STREET}, 
   $self->{ADDRESS_BUILD}, 
   $self->{ADDRESS_FLAT}, 
   $self->{EMAIL}, 
   $self->{CONTRACT_ID},
   $self->{COMMENTS}
  )= @$ar;
	
	
	return $self;
}

#**********************************************************
# Personal Info change
#
#**********************************************************
sub pi_change {
	my $self   = shift;
  my ($attr) = @_;


my %FIELDS = (EMAIL => 'email',
              FIO => 'fio',
              PHONE => 'phone',
              ADDRESS_BUILD  => 'address_build',
              ADDRESS_STREET => 'address_street',
              ADDRESS_FLAT   => 'address_flat',
              COMMENTS       => 'comments',
              UID            => 'uid',
              CONTRACT_ID    => 'contract_id'
             );

	$self->changes($admin, { CHANGE_PARAM => 'UID',
		                TABLE        => 'users_pi',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->pi($attr->{UID}),
		                DATA         => $attr
		              } );

	
	return $self;
}


#**********************************************************
# defauls user settings
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = ( LOGIN => '', 
   ACTIVATE => '0000-00-00', 
   EXPIRE => '0000-00-00', 
   CREDIT => 0, 
   REDUCTION => '0.00', 
   TARIF_PLAN => 0, 
   SIMULTANEONSLY => 0, 
   DISABLE => 0, 
   COMPANY_ID => 0,
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
 

 my %FIELDS = (GID => 'gid',
               G_NAME => 'name',
               G_DESCRIBE => 'descr');

 $self->changes($admin, { CHANGE_PARAM => 'GID',
		               TABLE        => 'groups',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->group_info($attr->{GID}),
		               DATA         => $attr
		              } );


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

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 my $search_fields = '';

 
 if ($attr->{USERS_WARNINGS}) {
   $self->query($db, " SELECT u.id, pi.email, dv.tp_id, u.credit, b.deposit, tp.name, tp.uplimit
         FROM users u, dv_main dv, bills b
         LEFT JOIN tarif_plans tp ON dv.tp_id = tp.id
         LEFT JOIN users_pi pi ON u.uid = dv.id
         WHERE u.bill_id=b.id
           and b.deposit<tp.uplimit AND tp.uplimit > 0 AND b.deposit+u.credit>0
         ORDER BY u.id;");

   my $list = $self->{list};
   return $list;
  }
 elsif($attr->{CLOSED}) {
   $self->query($db, "SELECT u.id, pi.fio, if(company.id IS NULL, b.deposit, b.deposit), 
      u.credit, tp.name, u.disable, 
      u.uid, u.company_id, u.email, u.tp_id, if(l.start is NULL, '-', l.start)
     FROM users u, bills b
     LEFT JOIN users_pi pi ON u.uid = dv.id
     LEFT JOIN tarif_plans tp ON  (tp.id=u.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN log l ON  (l.uid=u.uid) 
     WHERE  
        u.bill_id=b.id
        and (b.deposit+u.credit-tp.credit_tresshold<=0
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
 if ($attr->{COMPANY_ID}) {
    $WHERE .= ($WHERE ne '') ?  " and u.company_id='$attr->{COMPANY_ID}' " : "WHERE u.company_id='$attr->{COMPANY_ID}' ";
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
 
 
 $self->query($db, "SELECT u.id, 
      pi.fio, if(company.id IS NULL, b.deposit, b.deposit), u.credit, tp.name, u.disable, 
      u.uid, u.company_id, pi.email, dv.tp_id, u.activate, u.expire
     FROM users u
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN dv_main dv ON  (u.uid = dv.uid)
     LEFT JOIN bills b ON u.bill_id = b.id
     LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});



 my $list = $self->{list};

 if ($self->{TOTAL} >= $attr->{PAGE_ROWS}) {
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
  
  defaults();  
  %DATA = $self->get_data($attr, { default => $self }); 
  

  if ($DATA{LOGIN} eq '') {
     $self->{errno} = 8;
     $self->{errstr} = 'ERROR_ENTER_NAME';
     return $self;
   }
  elsif (length($DATA{LOGIN}) > $CONF->{max_username_length}) {
     $self->{errno} = 9;
     $self->{errstr} = 'ERROR_SHORT_PASSWORD';
     return $self;
   }
  elsif($DATA{LOGIN} !~ /$usernameregexp/) {
     $self->{errno} = 10;
     $self->{errstr} = 'ERROR_WRONG_NAME';
     return $self; 	
   }
  elsif($DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }
    
  $self->query($db,  "INSERT INTO users (id, activate, expire, credit, reduction, 
           registration, disable, company_id, gid)
           VALUES ('$DATA{LOGIN}', '$DATA{ACTIVATE}', '$DATA{EXPIRE}', '$DATA{CREDIT}', '$DATA{REDUCTION}', 
           now(),  '$DATA{DISABLE}', 
           '$DATA{COMPANY_ID}', '$DATA{GID}');", 'do');
  
  return $self if ($self->{errno});
  
  $self->{UID} = $self->{INSERT_ID};
  $self->{LOGIN} = $DATA{LOGIN};

  $admin->action_add($self->{UID}, "ADD $DATA{LOGIN}");

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

  my %FIELDS = (UID         => 'uid',
              LOGIN       => 'id',
              ACTIVATE    => 'activate',
              EXPIRE      => 'expire',
              CREDIT      => 'credit',
              REDUCTION   => 'reduction',
              SIMULTANEONSLY => 'logins',
              COMMENTS    => 'comments',
              COMPANY_ID  => 'company_id',
              DISABLE     => 'disable',
              GID         => 'gid',
              PASSWORD    => 'password',
              BILL_ID     => 'bill_id'
             );
 
  if($attr->{create}) {
  	 use Bills;
  	 my $Bill = Bills->new($db, $admin);
  	 $Bill->create({ UID => $self->{UID} });
     if($Bill->{errno}) {
       $self->{errno}  = $Bill->{errno};
       $self->{errstr} =  $Bill->{errstr};
       return $self;
      }
     #$DATA{BILL_ID}=$Bill->{BILL_ID};
     $attr->{BILL_ID}=$Bill->{BILL_ID};
   }
   
	$self->changes($admin, { CHANGE_PARAM => 'UID',
		                TABLE        => 'users',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->info($attr->{UID}),
		                DATA         => $attr
		              } );


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
                  'log',
                  'users',
                  'users_pi');

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