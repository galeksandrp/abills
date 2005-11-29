
package Voip;
# Voip  managment functions
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

my $uid;


my %SEARCH_PARAMS = (TARIF_PLAN => 0, 
   SIMULTANEONSLY => 0, 
   DISABLE => 0, 
   IP => '0.0.0.0', 
   NETMASK => '255.255.255.255', 
   SPEED => 0, 
   FILTER_ID => '', 
   CID => '', 
   REGISTRATION => ''
);

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
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

    $uid             = $users->{UID};
    $self->{DEPOSIT} = $users->{DEPOSIT}; 
    $WHERE =  "WHERE voip.uid='$uid'";
   }
  
  #else {
    $WHERE =  "WHERE voip.uid='$uid'";
  # }
  #my $PASSWORD = '0'; 
  
  $self->query($db, "SELECT 
   voip.uid, 
   voip.tp_id, 
   tp.name, 
   voip.disable
     FROM dv_main dv
     LEFT JOIN voip_tps tp ON (voip.tp_id=tp.id)
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{UID},
   $self->{TP_ID}, 
   $self->{TP_NAME}, 
   $self->{DISABLE},
   $self->{REGISTRATION}
  )= @$ar;
  
  
  return $self;
}



#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
   TARIF_PLAN => 0, 
   SIMULTANEONSLY => 0, 
   DISABLE => 0, 
   IP => '0.0.0.0', 
   NETMASK => '255.255.255.255', 
   SPEED => 0, 
   FILTER_ID => '', 
   CID => '',
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
  
  %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO dv_main (uid, registration, tp_id, 
             logins, disable, ip, netmask, speed, filter_id, cid)
        VALUES ('$DATA{UID}', now(),
        '$DATA{TARIF_PLAN}', '$DATA{SIMULTANEONSLY}', '$DATA{DISABLE}', INET_ATON('$DATA{IP}'), 
        INET_ATON('$DATA{NETMASK}'), '$DATA{SPEED}', '$DATA{FILTER_ID}', LOWER('$DATA{CID}'));", 'do');
  
  return $self if ($self->{errno});
  
 
  $admin->action_add($DATA{UID}, "ADDED");
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
              TARIF_PLAN       => 'tp_id',
              SPEED            => 'speed',
              CID              => 'cid',
              UID              => 'uid',
              FILTER_ID        => 'filter_id'
             );


  $self->changes($admin,  { CHANGE_PARAM => 'UID',
                   TABLE        => 'dv_main',
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

 
 my $search_fields = '';
 undef @WHERE_RULES;
 push @WHERE_RULES, "u.uid = dv.uid";
 
 if ($attr->{USERS_WARNINGS}) {
   $self->query($db, " SELECT u.id, pi.email, dv.tp_id, u.credit, b.deposit, tp.name, tp.uplimit
         FROM users u, voip_main dv, bills b
         LEFT JOIN tarif_plans tp ON dv.tp_id = tp.id
         LEFT JOIN users_pi pi ON u.uid = dv.uid
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
     LEFT JOIN users_pi pi ON u.uid = dv.uid
     LEFT JOIN tarif_plans tp ON  (tp.id=u.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN voip_log l ON  (l.uid=u.uid) 
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
      push @WHERE_RULES, "(u.ip>=INET_ATON('$first_ip') and u.ip<=INET_ATON('$last_ip'))";
     }
    else {
      my $value = $self->search_expr($attr->{IP}, 'IP');
      push @WHERE_RULES, "u.ip$value";
    }
  }

 if ($attr->{PHONE}) {
    my $value = $self->search_expr($attr->{PHONE}, 'INT');
    push @WHERE_RULES, "u.phone$value";
  }


 if ($attr->{DEPOSIT}) {
    my $value = $self->search_expr($attr->{DEPOSIT}, 'INT');
    push @WHERE_RULES, "u.deposit$value";
  }


 if ($attr->{CID}) {
    $attr->{CID} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.cid LIKE '$attr->{CID}'";
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
 if ($attr->{TP_ID}) {
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
 if ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

#Activate
 if ($attr->{ACTIVATE}) {
   my $value = $self->search_expr("'$attr->{ACTIVATE}'", 'INT');
   push @WHERE_RULES, "(u.activate='0000-00-00' or u.activate$value)"; 
 }

#Expire
 if ($attr->{EXPIRE}) {
   my $value = $self->search_expr("'$attr->{EXPIRE}'", 'INT');
   push @WHERE_RULES, "(u.expire='0000-00-00' or u.expire$value)"; 
 }

#DIsable
 if ($attr->{DISABLE}) {
   push @WHERE_RULES, "u.disable='$attr->{DISABLE}'"; 
 }
 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 
 $self->query($db, "SELECT u.id, 
      pi.fio, if(company.id IS NULL, b.deposit, b.deposit), u.credit, tp.name, u.disable, 
      u.uid, u.company_id, pi.email, dv.tp_id, u.activate, u.expire, u.bill_id
     FROM users u, voip_main dv
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON u.bill_id = b.id
     LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     $WHERE 
     GROUP BY u.uid
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});



 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(u.id) FROM users u, dv_main dv $WHERE");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
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