package Voip_Sessions;

# Stats functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw(
);

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

my $admin;
my $CONF;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  my $self = {};
  bless($self, $class);

  $self->{db}=$db;

  if ($CONF->{DELETE_USER}) {
    $self->del($CONF->{DELETE_USER}, '', '', '', { DELETE_USER => $CONF->{DELETE_USER} });
  }

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub del {
  my $self = shift;
  my ($uid, $session_id, $nas_id, $session_start, $attr) = @_;

  if ($attr->{DELETE_USER}) {
    $self->query2("DELETE FROM voip_log WHERE uid='$attr->{DELETE_USER}';", 'do');
  }
  else {
    $self->query2("DELETE FROM voip_log 
      WHERE uid='$uid' and start='$session_start' and nas_id='$nas_id' and acct_session_id='$session_id';", 'do'
    );
  }

  return $self;
}

#**********************************************************
# online()
#**********************************************************
sub online {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $WHERE;

  if (defined($attr->{ZAPED})) {
    $WHERE = "c.status=2";
  }
  else {
    $WHERE = "c.status=1 or c.status>=3";
  }

  $self->query2("SELECT c.user_name, 
                          pi.fio, 
                          calling_station_id,
                          called_station_id,
                          SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started)),
                          c.call_origin,
                          INET_NTOA(c.client_ip_address),
                          c.status,
                          c.nas_id,
                          c.uid,
  c.acct_session_id, 
  pi.phone, 
  service.tp_id, 
  0, 
  u.credit, 
  if(date_format(c.started, '%Y-%m-%d')=curdate(), date_format(c.started, '%H:%i:%s'), c.started)

 FROM voip_calls c
 LEFT JOIN users u     ON u.uid=c.uid
 LEFT JOIN voip_main service  ON (service.uid=u.uid)
 LEFT JOIN users_pi pi ON (pi.uid=u.uid)
 WHERE $WHERE
 ORDER BY $SORT $DESC;",
 undef,
 $attr
  );

  if ($self->{TOTAL} < 1) {
    return $self;
  }

  my $list       = $self->{list};
  my %dub_logins = ();
  my %nas_sorted = ();

  foreach my $line (@$list) {
    $dub_logins{ $line->[0] }++;
    push(
      @{ $nas_sorted{"$line->[8]"} },
      [
        $line->[0], $line->[1], $line->[2], $line->[3], $line->[4], $line->[5], $line->[6], $line->[7], $line->[8],

        $line->[9], $line->[10], $line->[11],
        $line->[13], $line->[14], $line->[15], $line->[16], $line->[17], $line->[18], $line->[19], $line->[20], $line->[21], $line->[22]
      ]
    );
  }

  $self->{dub_logins} = \%dub_logins;
  $self->{nas_sorted} = \%nas_sorted;

  return $self->{list};
}

#**********************************************************
# online_del()
#**********************************************************
sub online_del {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{SESSIONS_LIST}) {
    my $session_list = join("', '", @{ $attr->{SESSIONS_LIST} });
    $WHERE = "acct_session_id in ( '$session_list' )";
  }
  else {
    my $NAS_ID          = (defined($attr->{NAS_ID}))          ? $attr->{NAS_ID}          : '';
    my $ACCT_SESSION_ID = (defined($attr->{ACCT_SESSION_ID})) ? $attr->{ACCT_SESSION_ID} : '';
    $WHERE = "nas_id='$NAS_ID'
            and acct_session_id='$ACCT_SESSION_ID'";
  }

  $self->query2("DELETE FROM voip_calls WHERE $WHERE;", 'do');

  return $self;
}

#**********************************************************
# Add online session to log
# online2log()
#**********************************************************
sub online_info {
  my $self = shift;
  my ($attr) = @_;

  my $NAS_ID = (defined($attr->{NAS_ID})) ? $attr->{NAS_ID} : '';

  #  my $NAS_PORT        = (defined($attr->{NAS_PORT})) ? $attr->{NAS_PORT} : '';
  my $ACCT_SESSION_ID = (defined($attr->{ACCT_SESSION_ID})) ? $attr->{ACCT_SESSION_ID} : '';

  $self->query2("SELECT user_name, 
    UNIX_TIMESTAMP(started) AS session_start, 
    UNIX_TIMESTAMP() - UNIX_TIMESTAMP(started) AS acct_session_time, 
    INET_NTOA(client_ip_address) AS client_ip_address,
    lupdated AS last_update,
    nas_id,
    calling_station_id,
    called_station_id,
    acct_session_id,
    conf_id AS h323_conf_id,
    call_origin AS h323_call_origin
    FROM voip_calls 
    WHERE nas_id='$NAS_ID'
     and acct_session_id='$ACCT_SESSION_ID'",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# Session zap
#**********************************************************
sub zap {
  my $self = shift;
  my ($nas_id, $acct_session_id, $nas_port_id) = @_;

  my $WHERE = ($nas_id && $acct_session_id) ? "WHERE nas_id=INET_ATON('$nas_id') and acct_session_id='$acct_session_id'" : '';
  $self->query2("UPDATE voip_calls SET status=2 $WHERE;", 'do');

  return $self;
}

#**********************************************************
# Session detail
#**********************************************************
sub session_detail {
  my $self = shift;
  my ($attr) = @_;

  $WHERE = " and l.uid='$attr->{UID}'" if ($attr->{UID});

  $self->query2("SELECT 
  l.start,
  l.start + INTERVAL l.duration SECOND AS stop,
  l.duration,
  l.tp_id,
  tp.name AS tp_name,
  INET_NTOA(client_ip_address) AS ip,
  l.calling_station_id,
  l.called_station_id,
  l.nas_id,
  n.name,
  n.ip AS nas_ip,
  l.bill_id,
  u.id AS login,
  l.uid,
  l.acct_session_id,
  l.route_id,
  l.terminate_cause,
  l.sum
 FROM (voip_log l, users u)
 LEFT JOIN tarif_plans tp ON (l.tp_id=tp.tp_id) 
 LEFT JOIN nas n ON (l.nas_id=n.id) 
 WHERE l.uid=u.uid 
 $WHERE
 and acct_session_id='$attr->{SESSION_ID}';",
 undef,
 { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# Periods totals
# periods_totals($self, $attr);
#**********************************************************
sub periods_totals {
  my $self   = shift;
  my ($attr) = @_;
  my $WHERE  = '';

  if ($attr->{UID}) {
    $WHERE .= ($WHERE ne '') ? " and uid='$attr->{UID}' " : "WHERE uid='$attr->{UID}' ";
  }

  $self->query2("SELECT  
   SEC_TO_TIME(sum(if(date_format(start, '%Y-%m-%d')=curdate(), duration, 0))) AS duration_0, 
   sum(if(date_format(start, '%Y-%m-%d')=curdate(), sum, 0)) AS sum_0, 
   
   SEC_TO_TIME(sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, duration, 0))) AS duration_1,
   sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, sum, 0)) AS sum_1,
   
   SEC_TO_TIME(sum(if((YEAR(curdate())=YEAR(start)) and WEEK(curdate()) = WEEK(start), duration, 0))) AS duration_2,
   sum(if((YEAR(curdate())=YEAR(start)) and WEEK(curdate()) = WEEK(start), sum, 0)) AS sum_2,
   
   SEC_TO_TIME(sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), duration, 0))) AS duration_3,
   sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), sum, 0)) AS sum_3,
   
   SEC_TO_TIME(sum(duration)) AS duration_4,
   sum(sum) AS sum_4
   
   FROM voip_log $WHERE;"
  );

  ($self->{duration_0}, $self->{sum_0}, $self->{duration_1}, $self->{sum_1}, $self->{duration_2}, $self->{sum_2}, $self->{duration_3}, $self->{sum_3}, $self->{duration_4}, $self->{sum_4}) = @{ $self->{list}->[0] };

  return $self;
}

#**********************************************************
# List
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  @WHERE_RULES = ("u.uid=l.uid");

  #Interval from date to date
  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }

  #Period
  elsif (defined($attr->{PERIOD})) {
    my $period = $attr->{PERIOD};
    if ($period == 4) { $WHERE .= ''; }
    else {
      $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
      if    ($period == 0) { push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()"; }
      elsif ($period == 1) { push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(l.start) = 1 "; }
      elsif ($period == 2) { push @WHERE_RULES, "YEAR(curdate()) = YEAR(l.start) and (WEEK(curdate()) = WEEK(start)) "; }
      elsif ($period == 3) { push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
      elsif ($period == 5) { push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}' "; }
      else                 { $WHERE .= "date_format(start, '%Y-%m-%d')=curdate() "; }
    }
  }

  my $WHERE = $self->search_former($attr, [
      [ 'LOGIN',           'STR', 'u.id AS login',                1],
      [ 'DATE',            'DATE','l.start',                      1],
      [ 'DURATION',        'DATE','SEC_TO_TIME(l.duration) AS duration',   1 ],
      [ 'IP',              'IP',  'l.ip',   'INET_NTOA(l.client_ip_address) AS ip'],
      [ 'CALLING_STATION_ID','STR', 'l.calling_station_id',         1],
      [ 'CALLED_STATION_ID','STR',  'l.called_station_id',         1],
      [ 'TP_ID',           'INT', 'l.tp_id',                      1],
      [ 'SUM',             'INT', 'l.sum',                        1],
      [ 'NAS_ID',          'INT', 'l.nas_id',                     1],
      [ 'NAS_PORT',        'INT', 'l.port_id',                    1],
      [ 'ACCT_SESSION_ID', 'STR', 'l.acct_session_id',            ],
      [ 'TERMINATE_CAUSE', 'INT', 'l.terminate_cause',            1],
      [ 'BILL_ID',         'STR', 'l.bill_id',                    1],
      [ 'DURATION_SEC',    'INT', 'l.duration AS duration_sec',   1],
      #[ 'DATE',            'DATE', "date_format(start, '%Y-%m-%d')" ], 
      [ 'START_UNIXTIME',  'INT', 'UNIX_TIMESTAMP(l.start) AS asstart_unixtime', 1],
      [ 'FROM_DATE|TO_DATE','DATE',"date_format(l.start, '%Y-%m-%d')"],
      [ 'MONTH',           'DATE',"date_format(l.start, '%Y-%m')"    ],
    ], 
    { WHERE       => 1,
    	WHERE_RULES => \@WHERE_RULES,
    	USERS_FIELDS=> 1
    }    
    );

  my $EXT_TABLES = '';
  $EXT_TABLES  = $self->{EXT_TABLES} if($self->{EXT_TABLES});

  if ($WHERE =~ /pi\./ || $self->{SEARCH_FIELDS} =~ /pi\./) {
    $EXT_TABLES  .= 'LEFT JOIN users_pi pi ON (u.uid=pi.uid)';
  }

  $self->query2("SELECT $self->{SEARCH_FIELDS} l.acct_session_id, l.uid
  FROM (voip_log l, users u)
  $EXT_TABLES
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total, SEC_TO_TIME(sum(l.duration)) AS duration, sum(sum) AS sum  
      FROM (voip_log l, users u)
     $WHERE;",
     undef,
     { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# session calculation
# min max average
#**********************************************************
sub calculation {
  my ($self) = shift;
  my ($attr) = @_;

  my $WHERE;

  #Login
  if ($attr->{UID}) {
    $WHERE .= ($WHERE ne '') ? " and l.uid='$attr->{UID}' " : "WHERE l.uid='$attr->{UID}' ";
  }

  $self->query2("SELECT SEC_TO_TIME(min(l.duration)) AS min_dur, 
     SEC_TO_TIME(max(l.duration)) AS max_dur, 
     SEC_TO_TIME(avg(l.duration)) AS avg_dur,
     min(l.sum) AS min_sum, 
     max(l.sum) AS max_sum, 
     avg(l.sum) AS avg_sum
  FROM voip_log l $WHERE",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# Use
#**********************************************************
sub reports {
  my ($self) = shift;
  my ($attr) = @_;

  undef @WHERE_RULES;
  my $date = '';
  my $EXT_TABLES = '';

  if ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "date_format(l.start, '%Y-%m-%d')>='$from' and date_format(l.start, '%Y-%m-%d')<='$to'";
    $attr->{TYPE} = '-' if (!$attr->{TYPE});
    if ($attr->{TYPE} eq 'HOURS') {
      $date = "date_format(l.start, '\%H')";
    }
    elsif ($attr->{TYPE} eq 'DAYS') {
      $date = "date_format(l.start, '%Y-%m-%d')";
    }
    elsif ($attr->{TYPE} eq 'TP') {
      $date = "l.tp_id";
    }
    elsif ($attr->{TYPE} eq 'TERMINATE_CAUSE') {
      $date = "l.terminate_cause";
    }
    elsif ($attr->{TYPE} eq 'GID') {
      $date = "u.gid";
    }
    elsif ($attr->{TYPE} eq 'COMPANIES') {
      $date       = "c.name";
      $EXT_TABLES = "INNER JOIN companies c ON (c.id=u.company_id)";
    }
    else {
      $date = "u.id";
    }
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES, "date_format(l.start, '%Y-%m')='$attr->{MONTH}'";
    $date = "date_format(l.start, '%Y-%m-%d')";
  }
  else {
    $date = "date_format(l.start, '%Y-%m')";
  }


  if ($attr->{TYPE}) {
    if ($attr->{TYPE} eq 'TYPE'){
      $date = "u.id AS login";
    }
  }

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if ($attr->{DATE}) {
    push @WHERE_RULES, "date_format(l.start, '%Y-%m-%d')='$attr->{DATE}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  if ($attr->{DATE}) {
    $self->query2("select $date, if(u.id is NULL, CONCAT('> ', l.uid, ' <'), u.id), count(l.uid), 
     sec_to_time(sum(l.duration)) AS duration_time, 
     sum(l.sum), 
     l.uid,
     sum(l.duration) AS duration
      FROM voip_log l
      LEFT JOIN users u ON (u.uid=l.uid)
      $WHERE 
      GROUP BY l.uid 
      ORDER BY $SORT $DESC",
      undef,
      $attr
    );
  }
  else {
    $self->query2("select $date, count(DISTINCT l.uid), 
      count(l.uid),
      sec_to_time(sum(l.duration)) AS duration_time, 
      sum(l.sum) AS sum,
      u.uid,
      sum(l.duration) AS duration 
       FROM voip_log l
       LEFT JOIN users u ON (u.uid=l.uid)
       $WHERE    
       GROUP BY 1 
       ORDER BY $SORT $DESC;",
      undef,
      $attr
    );
  }

  my $list = $self->{list};

  $self->{USERS}    = 0;
  $self->{SESSIONS} = 0;
  $self->{DURATION} = 0;
  $self->{SUM}      = 0;

  return $list if ($self->{TOTAL} < 1);

  $self->query2("select count(DISTINCT l.uid), 
      count(l.uid),
      sec_to_time(sum(l.duration)), 
      sum(l.sum)
       FROM voip_log l
       LEFT JOIN users u ON (u.uid=l.uid)
       $WHERE;"
  );

  my $a_ref = $self->{list}->[0];

  ($self->{USERS}, $self->{SESSIONS}, $self->{DURATION}, $self->{SUM}) = @$a_ref;

  return $list;
}

1
