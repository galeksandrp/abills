package Dv;
# Dialup & Vpn  managment functions
#



use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");

use Tariffs;
use Users;
use Fees;



my $uid;

my $MODULE='Dv';

my %SEARCH_PARAMS = (TP_ID => 0, 
   SIMULTANEONSLY => 0, 
   DISABLE        => 0, 
   IP             => '0.0.0.0', 
   NETMASK        => '255.255.255.255', 
   SPEED          => 0, 
   FILTER_ID      => '', 
   CID            => '', 
   REGISTRATION   => ''
);

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $admin->{MODULE}=$MODULE;
  my $self = { };
  
  bless($self, $class);
  
  if ($CONF->{DELETE_USER}) {
    $self->{UID}=$CONF->{DELETE_USER};
    $self->del({ UID => $CONF->{DELETE_USER} });
   }
  
  return $self;
}




#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  if(defined($attr->{LOGIN})) {
    use Users;
    my $users = Users->new($db, $admin, $CONF);   
    $users->info(0, {LOGIN => "$attr->{LOGIN}"});
    if ($users->{errno}) {
       $self->{errno} = 2;
       $self->{errstr} = 'ERROR_NOT_EXIST';
       return $self; 
     }

    $uid              = $users->{UID};
    $self->{DEPOSIT}  = $users->{DEPOSIT};
    $self->{ACCOUNT_ACTIVATE} = $users->{ACTIVATE};
    $WHERE =  "WHERE dv.uid='$uid'";
   }
  
  
  $WHERE =  "WHERE dv.uid='$uid'";
  
  if (defined($attr->{IP})) {
  	$WHERE = "WHERE dv.ip=INET_ATON('$attr->{IP}')";
   }
  
  $self->query($db, "SELECT dv.uid, dv.tp_id, 
   tp.name, 
   dv.logins, 
    INET_NTOA(dv.ip), 
   INET_NTOA(dv.netmask), 
   dv.speed, 
   dv.filter_id, 
   dv.cid,
   dv.disable,
   dv.callback,
   dv.port,
   tp.gid
     FROM dv_main dv
     LEFT JOIN tarif_plans tp ON (dv.tp_id=tp.id)
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }


  ($self->{UID},
   $self->{TP_ID}, 
   $self->{TP_NAME}, 
   $self->{SIMULTANEONSLY}, 
   $self->{IP}, 
   $self->{NETMASK}, 
   $self->{SPEED}, 
   $self->{FILTER_ID}, 
   $self->{CID},
   $self->{DISABLE},
   $self->{CALLBACK},
   $self->{PORT},
   $self->{TP_GID}
  )= @{ $self->{list}->[0] };
  
  
  return $self;
}



#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
   TP_ID     => 0, 
   SIMULTANEONSLY => 0, 
   DISABLE        => 0, 
   IP             => '0.0.0.0', 
   NETMASK        => '255.255.255.255', 
   SPEED          => 0, 
   FILTER_ID      => '', 
   CID            => '',
   CALLBACK       => 0,
   PORT           => 0
  );

 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  
  my %DATA = $self->get_data($attr, { default => defaults() }); 


  if ($DATA{TP_ID} > 0) {
     my $tariffs = Tariffs->new($db, $CONF, $admin);
     $tariffs->info($DATA{TP_ID});
     
     if($tariffs->{ACTIV_PRICE} > 0) {
       my $user = Users->new($db, $admin, $CONF);
       $user->info($DATA{UID});
       
       if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE}) {
         
         print "$user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE}";
         
         $self->{errno}=15;
       	 return $self; 
        }
       my $fees = Fees->new($db, $admin, $CONF);
       $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE  => "ACTIV TP" });  
      }
   }



  $self->query($db,  "INSERT INTO dv_main (uid, registration, 
             tp_id, 
             logins, 
             disable, 
             ip, 
             netmask, 
             speed, 
             filter_id, 
             cid,
             callback,
             port)
        VALUES ('$DATA{UID}', now(),
        '$DATA{TP_ID}', '$DATA{SIMULTANEONSLY}', '$DATA{DISABLE}', INET_ATON('$DATA{IP}'), 
        INET_ATON('$DATA{NETMASK}'), '$DATA{SPEED}', '$DATA{FILTER_ID}', LOWER('$DATA{CID}'),
        '$DATA{CALLBACK}',
        '$DATA{PORT}');", 'do');

  return $self if ($self->{errno});
  $admin->action_add("$DATA{UID}", "ACTIVE");
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;
  

  
  my %FIELDS = (SIMULTANEONSLY => 'logins',
              DISABLE          => 'disable',
              IP               => 'ip',
              NETMASK          => 'netmask',
              TP_ID            => 'tp_id',
              SPEED            => 'speed',
              CID              => 'cid',
              UID              => 'uid',
              FILTER_ID        => 'filter_id',
              CALLBACK         => 'callback',
              PORT             => 'port'
             );
  
  if (! $attr->{CALLBACK}) {
  	$attr->{CALLBACK}=0;
   }

  my $old_info = $self->info($attr->{UID});
  if ($old_info->{TP_ID} != $attr->{TP_ID}) {
     my $tariffs = Tariffs->new($db, $CONF, $admin);
     $tariffs->info($attr->{TP_ID});
     
     if($tariffs->{CHANGE_PRICE} > 0) {
       my $user = Users->new($db, $admin, $CONF);
       $user->info($attr->{UID});
       
       if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{CHANGE_PRICE}) {
         $self->{errno}=15;
       	 return $self; 
        }

       my $fees = Fees->new($db, $admin, $CONF);
       $fees->take($user, $tariffs->{CHANGE_PRICE}, { DESCRIBE  => "CHANGE TP" });  
      }

     if ($tariffs->{AGE} > 0) {
       my $user = Users->new($db, $admin, $CONF);

       use POSIX qw(strftime);
       my $EXPITE_DATE = strftime( "%Y-%m-%d", localtime(time + 86400 * $tariffs->{AGE}) );
       #"curdate() + $tariffs->{AGE} days";
       $user->{debug}=1;
       $user->change($attr->{UID}, { EXPIRE => $EXPITE_DATE, UID => $attr->{UID} });
     }
   }

  $admin->{MODULE}=$MODULE;
  $self->changes($admin, { CHANGE_PARAM => 'UID',
                   TABLE        => 'dv_main',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $old_info,
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

  $self->query($db, "DELETE from dv_main WHERE uid='$self->{UID}';", 'do');

  $admin->action_add($uid, "DELETE");
  return $self->{result};
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


 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 undef @WHERE_RULES;
 push @WHERE_RULES, "u.uid = dv.uid";
 
 if ($attr->{USERS_WARNINGS}) {
   $self->query($db, "SELECT u.id, pi.email, dv.tp_id, u.credit, b.deposit, tp.name, tp.uplimit
         FROM (users u,
               dv_main dv,
               bills b,
               tarif_plans tp)
         LEFT JOIN users_pi pi ON u.uid = pi.uid
         WHERE
               u.uid=dv.uid
           and u.bill_id=b.id
           and dv.tp_id = tp.id
           and b.deposit<tp.uplimit AND tp.uplimit > 0 AND b.deposit+u.credit>0
         GROUP BY u.uid
         ORDER BY u.id;");


   return $self if ($self->{errno});
   
   my $list = $self->{list};
   return $list;
  }
 elsif($attr->{CLOSED}) {
   $self->query($db, "SELECT u.id, pi.fio, if(company.id IS NULL, b.deposit, b.deposit), 
      u.credit, tp.name, u.disable, 
      u.uid, u.company_id, u.email, u.tp_id, if(l.start is NULL, '-', l.start)
     FROM ( users u, bills b )
     LEFT JOIN users_pi pi ON u.uid = dv.uid
     LEFT JOIN tarif_plans tp ON  (tp.id=u.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN dv_log l ON  (l.uid=u.uid) 
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
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }
 elsif ($attr->{LOGIN}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
  }
 # Login expresion
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
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
      push @WHERE_RULES, "(dv.ip>=INET_ATON('$first_ip') and dv.ip<=INET_ATON('$last_ip'))";
     }
    else {
      my $value = $self->search_expr($attr->{IP}, 'IP');
      push @WHERE_RULES, "dv.ip$value";
    }

    $self->{SEARCH_FIELDS} = 'INET_NTOA(dv.ip), ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{PHONE}) {
    my $value = $self->search_expr($attr->{PHONE}, 'INT');
    push @WHERE_RULES, "u.phone$value";
  }


 if ($attr->{DEPOSIT}) {
    my $value = $self->search_expr($attr->{DEPOSIT}, 'INT');
    push @WHERE_RULES, "u.deposit$value";
  }

 if ($attr->{SPEED}) {
    my $value = $self->search_expr($attr->{SPEED}, 'INT');
    push @WHERE_RULES, "u.speed$value";

    $self->{SEARCH_FIELDS} .= 'dv.speed, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{PORT}) {
    my $value = $self->search_expr($attr->{PORT}, 'INT');
    push @WHERE_RULES, "dv.port$value";

    $self->{SEARCH_FIELDS} .= 'dv.port, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{CID}) {
    $attr->{CID} =~ s/\*/\%/ig;
    push @WHERE_RULES, "dv.cid LIKE '$attr->{CID}'";
    $self->{SEARCH_FIELDS} .= 'dv.cid, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{COMMENTS}) {
   $attr->{COMMENTS} =~ s/\*/\%/ig;
   push @WHERE_RULES, "u.comments LIKE '$attr->{COMMENTS}'";
  }


 if ($attr->{FIO}) {
    $attr->{FIO} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.fio LIKE '$attr->{FIO}'";
  }

 # Show users for spec tarifplan 
 if (defined($attr->{TP_ID})) {
    push @WHERE_RULES, "dv.tp_id='$attr->{TP_ID}'";
  }

 # Show debeters
 if ($attr->{DEBETERS}) {
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }

 # Show debeters
 if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "u.company_id='$attr->{COMPANY_ID}'";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

#Activate
 if ($attr->{ACTIVATE}) {
   #my $value = $self->search_expr("$attr->{ACTIVATE}", 'INT');
   push @WHERE_RULES, "(u.activate='0000-00-00' or u.activate$attr->{ACTIVATE})"; 
 }

#Expire
 if ($attr->{EXPIRE}) {
   #my $value = $self->search_expr("$attr->{EXPIRE}", 'INT');
   push @WHERE_RULES, "(u.expire='0000-00-00' or u.expire$attr->{EXPIRE})"; 
 }

#DIsable
 if (defined($attr->{DISABLE})) {
   push @WHERE_RULES, "u.disable='$attr->{DISABLE}'"; 
 }
 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT u.id, 
      pi.fio, if(u.company_id > 0, cb.deposit, b.deposit), 
      u.credit, 
      tp.name, 
      u.disable, 
      $self->{SEARCH_FIELDS}
      u.uid, 
      u.company_id, 
      pi.email, 
      dv.tp_id, 
      u.activate, 
      u.expire, 
      if(u.company_id > 0, company.bill_id, u.bill_id),
      u.reduction
     FROM (users u, dv_main dv)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     $WHERE 
     GROUP BY u.uid
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(u.id) FROM (users u, dv_main dv) $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}


#**********************************************************
# Periodic
#**********************************************************
sub periodic {
  my $self = shift;
  my ($period) = @_;
  
  if($period eq 'daily') {
    $self->daily_fees();
  }
  
  return $self;
}




1
