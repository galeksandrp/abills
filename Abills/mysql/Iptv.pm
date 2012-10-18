package Iptv;

# Iptv  managment functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw();

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

use Tariffs;
use Users;
use Fees;

my $uid;
my $MODULE = 'Iptv';

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;
  my $self = {};

  bless($self, $class);

  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub user_info {
  my $self = shift;
  my ($uid, $attr) = @_;

  if (defined($attr->{LOGIN})) {
    use Users;
    my $users = Users->new($db, $admin, $CONF);
    $users->info(0, { LOGIN => "$attr->{LOGIN}" });
    if ($users->{errno}) {
      $self->{errno}  = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
      return $self;
    }

    $uid                      = $users->{UID};
    $self->{DEPOSIT}          = $users->{DEPOSIT};
    $self->{ACCOUNT_ACTIVATE} = $users->{ACTIVATE};
    $WHERE                    = "WHERE service.uid='$uid'";
  }

  $WHERE = "WHERE service.uid='$uid'";

  $self->query(
    $db, "SELECT service.uid, 
   tp.name AS tp_name, 
   tp.tp_id, 
   service.filter_id, 
   service.cid,
   service.disable,
   service.pin,
   service.vod,
   tp.gid AS tp_gid,
   tp.month_fee,
   tp.day_fee,
   tp.postpaid_monthly_fee,
   tp.payment_type,
   tp.period_alignment,
   tp.id AS tp_num,
   service.dvcrypt_id
     FROM iptv_main service
     LEFT JOIN tarif_plans tp ON (service.tp_id=tp.tp_id)
   $WHERE;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
    TP_ID          => 0,
    SIMULTANEONSLY => 0,
    STATUS         => 0,
    IP             => '0.0.0.0',
    NETMASK        => '255.255.255.255',
    SPEED          => 0,
    FILTER_ID      => '',
    CID            => '',
    CALLBACK       => 0,
    PORT           => 0,
    PIN            => '',
    DVCRYPT_ID     => '',
    
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => defaults() });

  if ($DATA{TP_ID} > 0 && !$DATA{STATUS}) {
    my $tariffs = Tariffs->new($db, $CONF, $admin);
    $self->{TP_INFO} = $tariffs->info($DATA{TP_ID});

    #Take activation price
    if ($tariffs->{ACTIV_PRICE} > 0) {
      my $user = Users->new($db, $admin, $CONF);
      $user->info($DATA{UID});

      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE} && $tariffs->{PAYMENT_TYPE} == 0) {
        $self->{errno} = 15;
        return $self;
      }

      my $fees = Fees->new($db, $admin, $CONF);
      $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE => "ACTIV TP" });
      $tariffs->{ACTIV_PRICE} = 0;
    }
  }

  $self->query(
    $db, "INSERT INTO iptv_main (uid, registration, 
             tp_id, 
             disable, 
             filter_id,
             pin,
             vod,
             dvcrypt_id,
             cid
             )
        VALUES ('$DATA{UID}', now(),
        '$DATA{TP_ID}', '$DATA{STATUS}',
        '$DATA{FILTER_ID}',
        '$DATA{PIN}',
        '$DATA{VOD}',
        '$DATA{DVCRYPT_ID}',
        '$DATA{CID}'
         );", 'do'
  );

  return $self if ($self->{errno});
  $admin->action_add("$DATA{UID}", "", { TYPE => 1 });
  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    SIMULTANEONSLY => 'logins',
    STATUS         => 'disable',
    IP             => 'ip',
    NETMASK        => 'netmask',
    TP_ID          => 'tp_id',
    UID            => 'uid',
    FILTER_ID      => 'filter_id',
    PIN            => 'pin',
    VOD            => 'vod',
    DVCRYPT_ID     => 'dvcrypt_id',
    CID            => 'cid'
  );

  $attr->{VOD} = (!defined($attr->{VOD})) ? 0 : 1;
  my $old_info = $self->user_info($attr->{UID});

  if ($attr->{TP_ID} && $old_info->{TP_ID} != $attr->{TP_ID}) {
    my $tariffs = Tariffs->new($db, $CONF, $admin);
    $self->{TP_INFO} = $tariffs->info($attr->{TP_ID});
    my $user = Users->new($db, $admin, $CONF);

    $user->info($attr->{UID});
    if ($old_info->{STATUS} == 2 && (defined($attr->{STATUS}) && $attr->{STATUS} == 0) && $tariffs->{ACTIV_PRICE} > 0) {
      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE} && $tariffs->{PAYMENT_TYPE} == 0 && $tariffs->{POSTPAID_FEE} == 0) {
        $self->{errno} = 15;
        return $self;
      }

      my $fees = Fees->new($db, $admin, $CONF);
      $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE => "ACTIV TP" });

      $tariffs->{ACTIV_PRICE} = 0;
    }
    elsif ($tariffs->{CHANGE_PRICE} > 0) {

      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{CHANGE_PRICE}) {
        $self->{errno} = 15;
        return $self;
      }

      my $fees = Fees->new($db, $admin, $CONF);
      $fees->take($user, $tariffs->{CHANGE_PRICE}, { DESCRIBE => "CHANGE TP" });
    }

    if ($tariffs->{AGE} > 0) {
      my $user = Users->new($db, $admin, $CONF);
      use POSIX qw(strftime);
      my $EXPITE_DATE = strftime("%Y-%m-%d", localtime(time + 86400 * $tariffs->{AGE}));

      #"curdate() + $tariffs->{AGE} days";
      $user->change($attr->{UID}, { EXPIRE => $EXPITE_DATE, UID => $attr->{UID} });
    }
  }
  elsif ($old_info->{STATUS} == 2 && $attr->{STATUS} == 0) {
    my $tariffs = Tariffs->new($db, $CONF, $admin);
    $self->{TP_INFO} = $tariffs->info($old_info->{TP_ID});
  }

  $attr->{JOIN_SERVICE} = ($attr->{JOIN_SERVICE}) ? $attr->{JOIN_SERVICE} : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'iptv_main',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $old_info,
      DATA         => $attr
    }
  );

  $self->user_info($attr->{UID});
  return $self;
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "DELETE from iptv_main WHERE uid='$self->{UID}';", 'do');

  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub user_list {
  my $self   = shift;
  my ($attr) = @_;
  my @list   = ();

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = @{ $self->search_expr_users({ %$attr, 
  	                         EXT_FIELDS => [
  	                                        'PHONE',
  	                                        'EMAIL',
  	                                        'ADDRESS_FLAT',
  	                                        'PASPORT_DATE',
                                            'PASPORT_NUM', 
                                            'PASPORT_GRANT',
                                            'CITY', 
                                            'ZIP',
                                            'GID',
                                            'CONTRACT_ID',
                                            'CONTRACT_SUFIX',
                                            'CONTRACT_DATE',
                                            'EXPIRE',

                                            'CREDIT',
                                            'CREDIT_DATE', 
                                            'REDUCTION',
                                            'REGISTRATION',
                                            'REDUCTION_DATE',
                                            'COMMENTS:skip',
                                            'BILL_ID',
                                            
                                            'ACTIVATE',
                                            'EXPIRE',

  	                                         ] }) };


  push @WHERE_RULES, "u.uid = service.uid";

  if ($attr->{FILTER_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{FILTER_ID}, 'STR', 'service.filter_id', { EXT_FIELD => 1 }) };
  }

  if ($attr->{DVCRYPT_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DVCRYPT_ID}, 'INT', 'service.dvcrypt_id', { EXT_FIELD => 1 }) };
  }

  if ($attr->{COMMENTS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{COMMENTS}, 'STR', 'service.comments', { EXT_FIELD => 1 }) };
  }

  # Show users for spec tarifplan
  if (defined($attr->{TP_ID})) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{TP_ID}, 'INT', 'service.tp_id', { EXT_FIELD => 1 }) };
  }

  # Show debeters
  if ($attr->{DEBETERS}) {
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }

  #DIsable
  if (defined($attr->{STATUS})) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{STATUS}", 'INT', 'service.disable') };
  }

  if ($attr->{MONTH_PRICE}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{MONTH_PRICE}", 'INT', 'ti_c.month_price') };
  }
  
  my $EXT_TABLE = $self->{EXT_TABLES};
  if ($attr->{SHOW_CONNECTIONS}) {
    $EXT_TABLE = "LEFT JOIN dhcphosts_hosts dhcp ON (dhcp.uid=u.uid)
 	               LEFT JOIN nas  ON (nas.id=dhcp.nas)";

    $self->{SEARCH_FIELDS} = "nas.ip AS nas_ip, dhcp.ports, nas.nas_type, nas.mng_user, DECODE(nas.mng_password, '$CONF->{secretkey}') AS mng_password,";
    $self->{SEARCH_FIELDS_COUNT} += 5;
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $list;
  if ($attr->{SHOW_CHANNELS}) {
    $self->query(
      $db, "SELECT  u.id, 
        if(u.company_id > 0, cb.deposit, b.deposit) AS deposit, 
        u.credit, 
        tp.name AS tp_name, 
        $self->{SEARCH_FIELDS}
        u.uid, 
        u.company_id, 
        service.tp_id, 
        u.activate, 
        u.expire, 
        if(u.company_id > 0, company.bill_id, u.bill_id) as bill_id,
        u.reduction,
        if(u.company_id > 0, company.ext_bill_id, u.ext_bill_id) AS ext_bill_id,
        ti_c.channel_id, 
        c.num AS channel_num,
        c.name AS channel_name,
        ti_c.month_price,
        u.disable AS login_status, 
        service.disable AS iptv_status
   from intervals i

     INNER JOIN iptv_ti_channels ti_c ON (i.id=ti_c.interval_id)
     INNER JOIN iptv_users_channels uc ON (ti_c.channel_id=uc.channel_id)
     INNER JOIN iptv_channels c ON (uc.channel_id=c.id)

     INNER JOIN users u ON (u.uid=uc.uid)
     INNER JOIN iptv_main service ON (u.uid = service.uid )

     INNER JOIN tarif_plans tp ON (tp.tp_id=i.tp_id)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id)
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)

     $EXT_TABLE
  $WHERE 
GROUP BY uc.uid, channel_id
ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
    );

    $list = $self->{list};
  }
  else {
    $self->query(
      $db, "SELECT u.id, 
      pi.fio, if(u.company_id > 0, cb.deposit, b.deposit) AS deposit, 
      u.credit, 
      tp.name AS tp_name, 
      service.disable AS iptv_status, 
      $self->{SEARCH_FIELDS}
      u.uid, 
      u.company_id, 
      pi.email, 
      service.tp_id, 
      u.activate, 
      u.expire, 
      if(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,
      u.reduction,
      if(u.company_id > 0, company.ext_bill_id, u.ext_bill_id) as ext_bill_id
     FROM (users u, iptv_main service)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN tarif_plans tp ON (tp.id=service.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     $EXT_TABLE
     $WHERE 
     GROUP BY u.uid
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
    );

    return $self if ($self->{errno});

    $list = $self->{list};

    if ($self->{TOTAL} >= 0) {
      $self->query($db, "SELECT count(u.id) FROM (users u, iptv_main service) $WHERE");
      ($self->{TOTAL}) = @{ $self->{list}->[0] };
    }
  }
  return $list;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub user_tp_channels_list {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();

  #DIsable
  if (defined($attr->{STATUS})) {
    push @WHERE_RULES, "service.disable='$attr->{STATUS}'";
  }

  if (defined($attr->{LOGIN_STATUS})) {
    push @WHERE_RULES, "u.disable='$attr->{LOGIN_STATUS}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $list = $self->{list};
  return $self if ($self->{errno});

  if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(u.id) FROM (users u, iptv_main service) $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }

  return $self->{list};
}

#**********************************************************
# User information
# info()
#**********************************************************
sub channel_info {
  my $self = shift;
  my ($attr) = @_;

  $WHERE = "WHERE id='$attr->{ID}'";

  $self->query(
    $db, "SELECT id,
   name,
   num,
   port,
   comments,
   disable
     FROM iptv_channels
   $WHERE;"
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  ($self->{ID}, $self->{NAME}, $self->{NUMBER}, $self->{PORT}, $self->{DESCRIBE}, $self->{DISABLE}) = @{ $self->{list}->[0] };

  return $self;
}

#**********************************************************
#
#**********************************************************
sub channel_defaults {
  my $self = shift;

  my %DATA = (
    ID       => 0,
    NAME     => '',
    NUMBER   => 0,
    PORT     => 0,
    DESCRIBE => '',
    DISABLE  => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub channel_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => channel_defaults() });

  $self->query(
    $db, "INSERT INTO iptv_channels (name,
   num,
   port,
   comments,
   disable
             )
        VALUES (
   '$DATA{NAME}', 
   '$DATA{NUMBER}', 
   '$DATA{PORT}', 
   '$DATA{DESCRIBE}',
   '$DATA{DISABLE}'
         );", 'do'
  );

  return $self if ($self->{errno});

  #$admin->action_add("$DATA{UID}", "ACTIVE");
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub channel_add_stalker {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => channel_defaults() });

  $self->query(
    $db, "INSERT INTO $CONF->{IPTV_STALKET_DB}.itv (name,
   num,
   port,
   comments,
   disable
             )
        VALUES (
   '$DATA{NAME}', 
   '$DATA{NUMBER}', 
   '$DATA{PORT}', 
   '$DATA{DESCRIBE}',
   '$DATA{DISABLE}'
         );", 'do'
  );

  return $self if ($self->{errno});

  #$admin->action_add("$DATA{UID}", "ACTIVE");
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub channel_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    ID       => 'id',
    NAME     => 'name',
    NUMBER   => 'num',
    PORT     => 'port',
    DESCRIBE => 'comments',
    DISABLE  => 'disable'

  );

  my $old_info = $self->channel_info({ ID => $attr->{ID} });

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'iptv_channels',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $old_info,
      DATA         => $attr
    }
  );

  return $self if ($self->{errno});

  $self->channel_info({ ID => $attr->{ID} });

  return $self;
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub channel_del {
  my $self = shift;
  my ($id) = @_;

  $self->query($db, "DELETE from iptv_channels WHERE id='$id';", 'do');

  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub channel_list {
  my $self   = shift;
  my ($attr) = @_;
  my @list   = ();

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  undef @WHERE_RULES;

  # Start letter
  if ($attr->{NAME}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "name='$attr->{NAME}'";
  }

  if ($attr->{DESCRIBE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DESCRIBE}, 'STR', 'comments') };
  }

  if ($attr->{NUMBER}) {
    my $value = $self->search_expr($attr->{NUMBER}, 'INT');
    push @WHERE_RULES, "number$value";
  }

  if ($attr->{PORT}) {
    my $value = $self->search_expr($attr->{PORT}, 'INT');
    push @WHERE_RULES, "port$value";
  }

  #DIsable
  if (defined($attr->{DISABLE})) {
    push @WHERE_RULES, "disable='$attr->{DISABLE}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    $db, "SELECT num, name,   comments, port,
   disable, id
     FROM iptv_channels
     $WHERE 
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(*) AS total FROM iptv_channels $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
#
#**********************************************************
sub tp_defaults {
  my $self = shift;

  my %DATA = (
    ID       => 0,
    NAME     => '',
    NUMBER   => 0,
    PORT     => 0,
    DESCRIBE => '',
    DISABLE  => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub user_channels {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr);

  $self->query($db, "DELETE FROM iptv_users_channels WHERE uid='$DATA{UID}'", 'do'),

  my @ids = split(/, /, $attr->{IDS});

  foreach my $id (@ids) {
    $self->query(
      $db, "INSERT INTO iptv_users_channels 
     ( uid, tp_id, channel_id, changed)
        VALUES ( '$DATA{UID}',  '$DATA{TP_ID}', '$id', now());", 'do'
    );
  }

  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub user_channels_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    $db, "SELECT uid, tp_id, channel_id, changed FROM iptv_users_channels 
     WHERE tp_id='$attr->{TP_ID}' and uid='$attr->{UID}';"
  );

  $self->{USER_CHANNELS} = $self->{TOTAL};
  return $self->{list};
}

#**********************************************************
# add()
#**********************************************************
sub channel_ti_change {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr);

  $self->query($db, "DELETE FROM iptv_ti_channels WHERE interval_id='$attr->{INTERVAL_ID}'", 'do'),

  my @ids = split(/, /, $attr->{IDS});

  foreach my $id (@ids) {
    $self->query(
      $db, "INSERT INTO iptv_ti_channels 
     ( interval_id, channel_id, month_price, day_price, mandatory)
        VALUES ( '$DATA{INTERVAL_ID}',  '$id', '" . $DATA{ 'MONTH_PRICE_' . $id } . "', 
        '" . $DATA{ 'DAY_PRICE_' . $id } . "', '" . $DATA{ 'MANDATORY_' . $id } . "');", 'do'
    );
  }

  return $self if ($self->{errno});

  #$admin->action_add("$DATA{UID}", "ACTIVE");
  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub channel_ti_list {
  my $self   = shift;
  my ($attr) = @_;
  my @list   = ();

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  undef @WHERE_RULES;

  # Start letter
  if ($attr->{NAME}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{NAME}, 'STR', 'name') };
  }

  if ($attr->{DESCRIBE}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{DESCRIBE}, 'STR', 'comments') };
  }

  if ($attr->{NUMBER}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{NUMBER}, 'INT', 'number') };
  }

  if ($attr->{PORT}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PORT}, 'INT', 'port') };
  }

  if ($attr->{IDS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{IDS}, 'INT', 'c.id') };
  }

  if ($attr->{INTERVAL_ID}) {
    $attr->{TI} = $attr->{INTERVAL_ID};
    push @WHERE_RULES, @{ $self->search_expr($attr->{TI}, 'INT', 'ic.interval_id') };
  }

  if ($attr->{MANDATORY}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{MANDATORY}, 'INT', 'ic.mandatory') };
  }

  #DIsable
  if (defined($attr->{DISABLE})) {
    push @WHERE_RULES, "disable='$attr->{DISABLE}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    $db, "SELECT if (ic.channel_id IS NULL, 0, 1) AS interval_channel_id,
   c.num AS channel_num, c.name,  c.comments, ic.month_price, ic.day_price, ic.mandatory, c.port,
   c.disable, c.id AS channel_id
     FROM iptv_channels c
     LEFT JOIN iptv_ti_channels ic ON (id=ic.channel_id and ic.interval_id='$attr->{TI}')
     $WHERE
     ORDER BY $SORT $DESC ;",
    undef,
    $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query(
      $db, "SELECT count(*) AS total, sum(if (ic.channel_id IS NULL, 0, 1)) AS active 
     FROM iptv_channels c
     LEFT JOIN iptv_ti_channels ic ON (c.id=ic.channel_id and ic.interval_id='$attr->{TI}')
     $WHERE
    ",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
#
#**********************************************************
sub reports_channels_use {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $sql = "SELECT c.num,  c.name, count(uc.uid), sum(if(if(company.id IS NULL, b.deposit, cb.deposit)>0, 0, 1))
FROM iptv_channels c
LEFT JOIN iptv_users_channels uc ON (c.id=uc.channel_id)
LEFT JOIN users u ON (uc.uid=u.uid)
LEFT JOIN bills b ON (u.bill_id = b.id)
LEFT JOIN companies company ON  (u.company_id=company.id) 
LEFT JOIN bills cb ON  (company.bill_id=cb.id)
GROUP BY c.id
ORDER BY $SORT $DESC ";

  #	$sql = "select c.num, c.name, count(*), c.id
  #FROM iptv_channels c
  #LEFT JOIN iptv_ti_channels ic  ON (c.id=ic.channel_id)
  #LEFT JOIN intervals i ON (ic.interval_id=i.id)
  #LEFT JOIN tarif_plans tp ON (tp.tp_id=i.tp_id)
  #LEFT JOIN iptv_main u ON (tp.tp_id=u.tp_id)
  #group BY c.id
  #     ORDER BY $SORT $DESC ;";

  $self->query($db, $sql);

  return $self if ($self->{errno});

  my $list = $self->{list};

  # if ($self->{TOTAL} >= 0) {
  #    $self->query($db, "SELECT count(*), sum(if (ic.channel_id IS NULL, 0, 1))
  #     FROM iptv_channels c
  #     LEFT JOIN iptv_ti_channels ic ON (c.id=ic.channel_id and ic.interval_id='$attr->{TI}')
  #     $WHERE
  #    ");
  #
  #    ($self->{TOTAL}, $self->{ACTIVE}) = @{ $self->{list}->[0] };
  #   }

  return $list;
}

#**********************************************************
# Add channel to stalker middleware
#**********************************************************
sub stalker_channel_add {
	my $self = shift;
	my ($attr) = @_;
	
	%DATA = $self->get_data($attr);

	for (keys %DATA){
    if ($DATA{$_} eq 'on'){
      $DATA{$_} = 1; 
    }
  }
    
    if($DATA{STATUS} == 1) {
    	$DATA{STATUS} = 0;	
    }
    else {
    	$DATA{STATUS} = 1;	
    }

$self->query($db, "INSERT INTO $CONF->{IPTV_STALKET_DB}.itv(
  name,
  number,
  use_http_tmp_link,
  wowza_tmp_link,
  wowza_dvr,
  censored,
  base_ch,
  bonus_ch,
  hd,
  cost,
  cmd, 
  mc_cmd,
  enable_wowza_load_balancing,
  enable_tv_archive,
  enable_monitoring,
  monitoring_url,
  descr,
  tv_genre_id, 
  status,
  xmltv_id,
  service_id,
  volume_correction,
  correct_time
)	  
VALUES 
(
  '$DATA{NAME}', 
  '$DATA{NUMBER}', 
  '$DATA{USE_HTTP_TMP_LINK}', 
  '$DATA{WOWZA_TMP_LINK}',
  '$DATA{WOWZA_DVR}', 
  '$DATA{CENSORED}', 
  '$DATA{BASE_CH}', 
  '$DATA{BONUS_CH}', 
  '$DATA{HD}',
  '$DATA{COST}', 
  '$DATA{CMD}', 
  '$DATA{MC_CMD}', 
  '$DATA{ENABLE_WOWZA_LOAD_BALANCING}', 
  '$DATA{ENABLE_TV_ARCHIVE}',
  '$DATA{ENABLE_MONITORING}', 
  '$DATA{MONITORING_URL}', 
  '$DATA{DESCR}', 
  '$DATA{TV_GENRE_ID}', 
  '$DATA{STATUS}',
  '$DATA{XMLTV_ID}', 
  '$DATA{SERVICE_ID}', 
  '$DATA{VOLUME_CORRECTION}',
  '$DATA{CORRECT_TIME}' 
);", 'do' 																											
);
	return 0;	
}

#**********************************************************
# Delete channel from stalker DB
#**********************************************************
sub stalker_channel_del {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr);

  $self->query($db, "DELETE from $CONF->{IPTV_STALKET_DB}.itv WHERE name LIKE '$DATA{STALKER_NAME}';", 'do');
  $self->query($db, "DELETE from iptv_channels WHERE id='$DATA{ABILLS_ID}';", 'do');
  return $self->{result};	

}

#**********************************************************
# Stalker channel list
#**********************************************************
sub stalker_channel_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	if(defined($attr->{ID})) {
  		push @WHERE_RULES, "id='$attr->{ID}'";
	}
	if(defined($attr->{NAME})) {
  		push @WHERE_RULES, "name LIKE '$attr->{NAME}'";
	}	  
	if(defined($attr->{NUMBER})) {
  		push @WHERE_RULES, "number LIKE '$attr->{NUMBER}'";
	}	
 
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, 
    "SELECT
      name,
      number,
      use_http_tmp_link,
      wowza_tmp_link,
      wowza_dvr,
      censored,
      base_ch,
      bonus_ch,
      hd,
      cost,
      cmd, 
      mc_cmd,
      enable_wowza_load_balancing,
      enable_tv_archive,
      enable_monitoring,
      monitoring_url,
      descr,
      tv_genre_id, 
      status,
      xmltv_id,
      service_id,
      volume_correction,
      correct_time
    FROM $CONF->{IPTV_STALKET_DB}.itv
    $WHERE
    ORDER BY $SORT $DESC;");
  return $self->{list};
}

#**********************************************************
# Stalker channel info
#**********************************************************
sub stalker_channel_info {
	my $self = shift;
	my ($attr) = @_;
 
 	%DATA = $self->get_data($attr); 

	$self->query($db,
    "SELECT
      name,
      number,
      use_http_tmp_link,
      wowza_tmp_link,
      wowza_dvr,
      censored,
      base_ch,
      bonus_ch,
      hd,
      cost,
      cmd, 
      mc_cmd,
      enable_wowza_load_balancing,
      enable_tv_archive,
      enable_monitoring,
      monitoring_url,
      descr,
      tv_genre_id, 
      status,
      xmltv_id,
      service_id,
      volume_correction,
      correct_time,
      name,
      number
    FROM $CONF->{IPTV_STALKET_DB}.itv
    WHERE name LIKE '$attr->{NAME}';");

  ( $self->{NAME},
    $self->{NUMBER},
    $self->{USE_HTTP_TMP_LINK},
    $self->{WOWZA_TMP_LINK},
    $self->{WOWZA_DVR},
    $self->{CENSORED},
    $self->{BASE_CH},
    $self->{BONUS_CH},
    $self->{HD},
    $self->{COST},
    $self->{CMD},
    $self->{MC_CMD},
    $self->{ENABLE_WOWZA_LOAD_BALANCING},
    $self->{ENABLE_TV_ARCHIVE},
    $self->{ENABLE_MONITORING},
    $self->{MONITORING_URL},
    $self->{DESCR},
    $self->{TV_GENRE_ID_SELECT},
    $self->{STATUS},
    $self->{XMLTV_ID},
    $self->{SERVICE_ID},
    $self->{VOLUME_CORRECTION},
    $self->{CORRECT_TIME},
    $self->{CHANGE_PARAM},
    $self->{OLD_NUMBER}    
  )= @{ $self->{list}->[0] };

	return $self;	
}


#**********************************************************
# Stalker change channels
#**********************************************************
sub stalker_change_channels {
	my $self = shift;
	my ($attr) = @_; 

  %DATA = $self->get_data($attr);

  for (keys %DATA){
    if ($DATA{$_} eq 'on'){
      $DATA{$_} = 1; 
    }
  }

  if($DATA{STATUS} == 1) {
    $DATA{STATUS} = 0;	
  }
  else {
    $DATA{STATUS} = 1;	
  }

$self->query($db, 
  "UPDATE $CONF->{IPTV_STALKET_DB}.itv SET
    name                        = '$DATA{NAME}',
    number                      = '$DATA{NUMBER}',
    use_http_tmp_link           = '$DATA{USE_HTTP_TMP_LINK}',
    wowza_tmp_link              = '$DATA{WOWZA_TMP_LINK}',
    wowza_dvr                   = '$DATA{WOWZA_DVR}',
    censored                    = '$DATA{CENSORED}',
    base_ch                     = '$DATA{BASE_CH}',
    bonus_ch                    = '$DATA{BONUS_CH}',
    hd                          = '$DATA{HD}',
    cost                        = '$DATA{COST}',
    cmd                         = '$DATA{CMD}', 
    mc_cmd                      = '$DATA{MC_CMD}',
    enable_wowza_load_balancing = '$DATA{ENABLE_WOWZA_LOAD_BALANCING}',
    enable_tv_archive           = '$DATA{ENABLE_TV_ARCHIVE}',
    enable_monitoring           = '$DATA{ENABLE_MONITORING}',
    monitoring_url              = '$DATA{MONITORING_URL}',
    descr                       = '$DATA{DESCR}',
    tv_genre_id                 = '$DATA{TV_GENRE_ID}', 
    status                      = '$DATA{STATUS}',
    xmltv_id                    = '$DATA{XMLTV_ID}',
    service_id                  = '$DATA{SERVICE_ID}',
    volume_correction           = '$DATA{VOLUME_CORRECTION}',
    correct_time                = '$DATA{CORRECT_TIME}'
  WHERE name LIKE '$DATA{CHANGE_PARAM}';", 'do' 																											
);
  return $self;
}


##**********************************************************
## stalker_channel_export
##**********************************************************
#sub stalker_channel_export {
#  my $self = shift;
#  my ($attr) = @_;
#  
#  $self->query(
#    $db, "REPLACE INTO $CONF->{dbname}.iptv_channels (name,
#	   num,
#	   port,
#	   comments,
#	   disable) SELECT name, 
#	   number, 
#	   id, 
#	   descr, 
#	   if(status=1, 0, 1) 
#   FROM $CONF->{IPTV_STALKET_DB}.itv", 'do');
#  return 0;
#}





1
