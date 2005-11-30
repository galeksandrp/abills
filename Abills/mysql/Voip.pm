
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




#**********************************************************
# route_add
#**********************************************************
sub route_add {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO voip_routes (id, prefix, name, disable, date) 
        VALUES ('$DATA{ROUTE_ID}', '$DATA{ROUTE_PREFIX}', '$DATA{ROUTE_NAME}', '$DATA{DISABLE}', now());", 'do');
  return $self if ($self->{errno});

#  $admin->action_add($DATA{UID}, "ADDED", { MODULE => 'voip'});
 
  return $self;
}


#**********************************************************
# Route information
# route_info()
#**********************************************************
sub route_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query($db, "SELECT 
   id,
   prefix,
   name,
   date,
   disable
     FROM voip_routes
   WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{ROUTE_ID},
   $self->{ROUTE_PREFIX}, 
   $self->{ROUTE_NAME}, 
   $self->{DATE},
   $self->{DISABLE}
  )= @$ar;
  
  
  return $self;
}

#**********************************************************
# route_del
#**********************************************************
sub route_del {
  my $self = shift;
  my ($id) = @_;
  
  $self->query($db,  "DELETE FROM voip_routes WHERE id='$id';", 'do');
  return $self if ($self->{errno});

#  $admin->action_add($DATA{UID}, "ADDED", { MODULE => 'voip'});
 
  return $self;
}

#**********************************************************
# route_change()
#**********************************************************
sub route_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ROUTE_ID       => 'id',
                DISABLE        => 'disable',
                ROUTE_PREFIX   => 'prefix',
                ROUTE_NAME     => 'name'
             );


  $self->changes($admin,  { CHANGE_PARAM => 'ROUTE_ID',
                   TABLE        => 'voip_routes',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->route_info($attr->{ROUTE_ID}),
                   DATA         => $attr
                  } );

  return $self->{result};
}








#**********************************************************
# route_list()
#**********************************************************
sub routes_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 
 my $search_fields = '';
 undef @WHERE_RULES;


 if ($attr->{ROUTE_PREFIX}) {
   $attr->{ROUTE_PREFIX} =~ s/\*/\%/ig;
   push @WHERE_RULES, "r.prefix LIKE '$attr->{ROUTE_PREFIX}'";
  }

 if ($attr->{ROUTE_NAME}) {
   $attr->{ROUTE_PREFIX} =~ s/\*/\%/ig;
   push @WHERE_RULES, "r.name LIKE '$attr->{ROUTE_name}'";
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT r.id, r.prefix, r.name, r.disable, r.date
     FROM voip_routes r
     $WHERE 
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(r.id) FROM voip_routes r $WHERE");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

  return $list;
}




#**********************************************************
# list
#**********************************************************
sub tp_list() {
  my $self = shift;
  my ($attr) = @_;


 my $WHERE = '';
 $self->query($db, "SELECT tp.id, tp.name, if(sum(i.tarif) is NULL or sum(i.tarif)=0, 0, 1), 
    tp.payment_type,
    tp.day_fee, tp.month_fee, 
    tp.logins, 
    tp.age,
    tp.rad_pairs
    FROM tarif_plans tp
    LEFT JOIN intervals i ON (i.tp_id=tp.id)
    LEFT JOIN trafic_tarifs tt ON (tt.interval_id=i.id)
    $WHERE
    GROUP BY tp.id
    ORDER BY $SORT $DESC;");

 return $self->{list};
}








#**********************************************************
# Default values
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = ( TP_ID => 0, 
            NAME => '',  
            TIME_TARIF => '0.00000',
            DAY_FEE => '0,00',
            MONTH_FEE => '0.00',
            SIMULTANEOUSLY => 0,
            AGE => 0,
            DAY_TIME_LIMIT => 0,
            WEEK_TIME_LIMIT => 0,
            MONTH_TIME_LIMIT => 0,
            DAY_TRAF_LIMIT => 0, 
            WEEK_TRAF_LIMIT => 0, 
            MONTH_TRAF_LIMIT => 0,
            ACTIV_PRICE => '0.00',
            CHANGE_PRICE => '0.00',
            CREDIT_TRESSHOLD => '0.00',
            ALERT => 0,
            OCTETS_DIRECTION => 0,
            MAX_SESSION_DURATION => 0,
            FILTER_ID            => '',
            PAYMENT_TYPE         => 0,
            MIN_SESSION_COST     => '0.00000',
            RAD_PAIRS            => ''

         );   
 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# Add
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA }); 

  $self->query($db, "INSERT INTO tarif_plans (id, hourp, uplimit, name, month_fee, day_fee, logins, 
     day_time_limit, week_time_limit,  month_time_limit, 
     day_traf_limit, week_traf_limit,  month_traf_limit,
     activate_price, change_price, credit_tresshold, age, octets_direction,
     max_session_duration, filter_id, payment_type, min_session_cost, rad_pairs)
    values ('$DATA{TP_ID}', '$DATA{TIME_TARIF}', '$DATA{ALERT}', \"$DATA{NAME}\", 
     '$DATA{MONTH_FEE}', '$DATA{DAY_FEE}', '$DATA{SIMULTANEONSLY}', 
     '$DATA{DAY_TIME_LIMIT}', '$DATA{WEEK_TIME_LIMIT}',  '$DATA{MONTH_TIME_LIMIT}', 
     '$DATA{DAY_TRAF_LIMIT}', '$DATA{WEEK_TRAF_LIMIT}',  '$DATA{MONTH_TRAF_LIMIT}',
     '$DATA{ACTIV_PRICE}', '$DATA{CHANGE_PRICE}', '$DATA{CREDIT_TRESSHOLD}', '$DATA{AGE}', '$DATA{OCTETS_DIRECTION}',
     '$DATA{MAX_SESSION_DURATION}', '$DATA{FILTER_ID}',
     '$DATA{payment_type}', '$DATA{min_session_cost}', '$DATA{RAD_PAIRS}');", 'do' );

  return $self;
}



#**********************************************************
# change
#**********************************************************
sub change {
  my $self = shift;
  my ($tp_id, $attr) = @_;
	$self->changes(0, { CHANGE_PARAM => 'TP_ID',
		                TABLE        => 'tarif_plans',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->info($tp_id),
		                DATA         => $attr
		              } );

  
  $self->info($tp_id);
	
	return $self;
}

#**********************************************************
# del
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;
  	
  $self->query($db, "DELETE FROM tarif_plans WHERE id='$id';", 'do');

 return $self;
}

#**********************************************************
# Info
#**********************************************************
sub info {
  my $self = shift;
  my ($id) = @_;

  $self->query($db, "SELECT id, name, hourp, day_fee, month_fee, logins, age,
      day_time_limit, week_time_limit,  month_time_limit, 
      day_traf_limit, week_traf_limit,  month_traf_limit,
      activate_price, change_price, credit_tresshold, uplimit, octets_direction, 
      max_session_duration,
      filter_id,
      payment_type,
      min_session_cost,
      rad_pairs
    FROM tarif_plans
    WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];
  
  ($self->{TP_ID}, 
   $self->{NAME}, 
   $self->{TIME_TARIF}, 
   $self->{DAY_FEE}, 
   $self->{MONTH_FEE}, 
   $self->{SIMULTANEOUSLY}, 
   $self->{AGE},
   $self->{DAY_TIME_LIMIT}, 
   $self->{WEEK_TIME_LIMIT}, 
   $self->{MONTH_TIME_LIMIT}, 
   $self->{DAY_TRAF_LIMIT}, 
   $self->{WEEK_TRAF_LIMIT}, 
   $self->{MONTH_TRAF_LIMIT}, 
   $self->{ACTIV_PRICE},    
   $self->{CHANGE_PRICE}, 
   $self->{CREDIT_TRESSHOLD},
   $self->{ALERT},
   $self->{OCTETS_DIRECTION},
   $self->{MAX_SESSION_DURATION},
   $self->{FILTER_ID},
   $self->{PAYMENT_TYPE},
   $self->{MIN_SESSION_COST},
   $self->{RAD_PAIRS}
  ) = @$ar;


  return $self;
}





1