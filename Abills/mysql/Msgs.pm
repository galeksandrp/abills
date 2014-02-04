package Msgs;
# Message system
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw();

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

my $MODULE = 'Msgs';

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift; 
  ($admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;
  my $self = {};

  bless($self, $class);
  
  $self->{db}=$db;
  
  return $self;
}

#**********************************************************
# messages_new
#**********************************************************
sub messages_new {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $EXT_TABLE   = '';
  my $fields      = '';

  if ($attr->{USER_READ}) {
    push @WHERE_RULES, "m.user_read='$attr->{USER_READ}' AND admin_read>'0000-00-00 00:00:00' AND m.inner_msg='0'";
    $fields = 'count(*), \'\', \'\', max(m.id), m.chapter, m.id, 1';
  }
  elsif ($attr->{ADMIN_READ}) {
    $fields = "sum(if(admin_read='0000-00-00 00:00:00', 1, 0)), 
     sum(if(plan_date=curdate(), 1, 0)),
     sum(if(state = 0, 1, 0)), 
    1, 1,1,1
      ";

    #push @WHERE_RULES, "m.state=0";
  }

  if ($attr->{UID}) {
    push @WHERE_RULES, "m.uid='$attr->{UID}'";
  }

  if ($attr->{CHAPTERS}) {
    push @WHERE_RULES, "c.id IN ($attr->{CHAPTERS})";
  }

  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
    $EXT_TABLE = "LEFT JOIN users u  ON (m.uid = u.uid)";
  }

  $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  if ($attr->{SHOW_CHAPTERS}) {
    $self->query2("SELECT c.id, c.name, sum(if(admin_read='0000-00-00 00:00:00', 1, 0)), 
     sum(if(plan_date=curdate(), 1, 0)),
     sum(if(state = 0, 1, 0)), 
          sum(if(resposible = $admin->{AID}, 1, 0)),1,1,1
    FROM msgs_chapters c
    LEFT JOIN msgs_messages m ON (m.chapter= c.id AND m.state=0)
    $EXT_TABLE
    $WHERE 
    GROUP BY c.id;",
    undef,
    $attr
    );
    return $self->{list};
  }

  if ($attr->{GIDS}) {
    $self->query2("SELECT $fields 
      FROM (msgs_messages m, users u)
      $WHERE and u.uid=m.uid GROUP BY 7Y;"
      );
  }
  else {
    $self->query2("SELECT $fields 
      FROM (msgs_messages m)
      $WHERE GROUP BY 7;"
     );
  }

  if ($self->{TOTAL}) {
    ($self->{UNREAD}, $self->{TODAY}, $self->{OPENED}, $self->{LAST_ID}, $self->{CHAPTER}, $self->{MSG_ID}) = @{ $self->{list}->[0] };
  }

  return $self;
}

#**********************************************************
# messages_list
#**********************************************************
sub messages_list {
  my $self = shift;
  my ($attr) = @_;

  $PAGE_ROWS = ($attr->{PAGE_ROWS})     ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})          ? $attr->{SORT}      : 1;
  $DESC      = (defined($attr->{DESC})) ? $attr->{DESC}      : 'DESC';
  $PG        = (defined($attr->{PG}))   ? $attr->{PG}        : 0;
  
  $self->{COL_NAMES_ARR}=undef;

  #$attr->{SKIP_GID} = 1;
  if ($attr->{PLAN_FROM_DATE}) {
    push @WHERE_RULES, "(date_format(m.plan_date, '%Y-%m-%d')>='$attr->{PLAN_FROM_DATE}' and date_format(m.plan_date, '%Y-%m-%d')<='$attr->{PLAN_TO_DATE}')";
  }
  elsif ($attr->{PLAN_WEEK}) {
    push @WHERE_RULES, "(WEEK(m.plan_date)=WEEK(curdate()) and date_format(m.plan_date, '%Y')=date_format(curdate(), '%Y'))";
  }
  elsif ($attr->{PLAN_MONTH}) {
    push @WHERE_RULES, "date_format(m.plan_date, '%Y-%m')=date_format(curdate(), '%Y-%m')";
  }

  if ($attr->{CHAPTERS_DELIGATION}) {
    my @WHERE_RULES_pre = ();
    while (my ($chapter, $deligation) = each %{ $attr->{CHAPTERS_DELIGATION} }) {
      my $privileges = '';
      if ($attr->{PRIVILEGES}) {
        if ($attr->{PRIVILEGES}->{$chapter} <= 2) {
          $privileges = " AND (m.resposible=0 or m.aid='$admin->{AID}' or m.resposible='$admin->{AID}')";
        }
      }
      push @WHERE_RULES_pre, "(m.chapter='$chapter' AND m.deligation<='$deligation' $privileges)";
    }
    push @WHERE_RULES, "(" . join(" or ", @WHERE_RULES_pre) . ")";
  }
  elsif ($attr->{CHAPTERS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{CHAPTERS}, 'INT', 'm.chapter') };
  }

  if (defined($attr->{STATE})) {
    if ($attr->{STATE} == 4) {
      push @WHERE_RULES, @{ $self->search_expr('0000-00-00 00:00:00', 'INT', 'm.admin_read') };
    }
    elsif ($attr->{STATE} == 7) {
      push @WHERE_RULES, @{ $self->search_expr(">0", 'INT', 'm.deligation') };
    }
    elsif ($attr->{STATE} == 8) {
      push @WHERE_RULES, @{ $self->search_expr("$admin->{AID}", 'INT', 'm.resposible') };
      push @WHERE_RULES, @{ $self->search_expr("0;3;6",         'INT', 'm.state') };
      undef $attr->{DELIGATION};
    }
    else {
      push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'm.state') };
    }
  }

  if ($admin->{GID} || $admin->{GIDS}) {
    if ($admin->{GID}) {
      $admin->{GIDS} .= ", $admin->{GID}";
    }
    $attr->{SKIP_GID}=1;
    push @WHERE_RULES, "(u.gid IN ($admin->{GIDS}) or m.gid IN ($admin->{GIDS}))";
  }
  
  $admin->{permissions}->{0}->{8}=1;
  
  my $WHERE = $self->search_former($attr, [
      ['MSG_ID',       'INT',  'm.id'             ],
      ['DISABLE',      'INT',  'u.disable',     1 ],
      ['INNER_MSG',    'INT',  'm.inner_msg',   1 ], 
      ['SUBJECT',      'STR',  'm.subject'        ],
      ['MESSAGE',      'STR',  'm.message',     1 ],
      ['REPLY',        'STR',  'm.user_read',   1 ],
      ['PHONE',        'STR',  'm.phone',       1 ],
      ['USER_READ',    'INT',  'm.user_read',   1 ],
      ['ADMIN_READ',   'INT',  'm.admin_read',  1 ],
      ['CLOSED_DATE',  'DATE', 'm.closed_date', 1 ],
      ['RUN_TIME',     'DATE', 'SEC_TO_TIME(sum(r.run_time))',  'SEC_TO_TIME(sum(r.run_time)) AS run_time' ],
      ['DONE_DATE',    'DATE', 'm.done_date',   1 ],
      ['CHAPTER',      'INT',  'm.chapter',       ],
      ['UID',          'INT',  'm.uid',           ],
      ['DELIGATION',   'INT',  'm.delegation',  1 ],
      ['RESPOSIBLE',   'INT',  'm.resposible',    ],
      ['PRIORITY',     'INT',  'm.state',         ],
      ['PLAN_DATE',    'INT',  'm.plan_date',   1 ], 
      #['PLAN_DATE',    'INT',  "DATE_FORMAT(plan_date, '%w')", "DATE_FORMAT(plan_date, '%w') AS plan_date", 1 ], 
      ['PLAN_TIME',    'INT',  'm.plan_time',   1 ],
      ['DISPATCH_ID',  'INT',  'm.dispatch_id', 1 ],
      ['IP',           'IP',   'm.ip',  'INET_NTOA(m.ip)', 1 ],
      ['DATE',         'DATE', "date_format(m.date, '%Y-%m-%d')" ],
      ['FROM_DATE|TO_DATE', 'DATE', "date_format(m.date, '%Y-%m-%d')" ],
      ['A_LOGIN',      'INT',  'a.aid',  'a.id AS admin_login',  1 ],
      ['A_NAME',       'INT',  'a.name', 'a.name AS admin_name', 1 ],
      ['REPLIES_COUNTS','',    '',       'if(r.id IS NULL, 0, count(r.id)) AS replies_counts' ],
    ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
      USERS_FIELDS      => 1,
      SKIP_USERS_FIELDS => [ 'GID' ]
    }
    );

  if ($attr->{DEPOSIT}) {
    $self->{EXT_TABLES} .= "LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN companies company ON  (u.company_id=company.id) 
      LEFT JOIN bills cb ON (company.bill_id=cb.id)";
  }

  my $EXT_TABLE = $self->{EXT_TABLES};

  if ($self->{SEARCH_FIELDS} =~ /pi\./) {
    $EXT_TABLE = "LEFT JOIN users_pi pi ON (u.uid = pi.uid) $EXT_TABLE";
  }

  $self->query2("SELECT m.id,
   if(m.uid>0, u.id, g.name) AS client_id,
   m.subject,
   mc.name AS chapter_name,
   m.date,
   m.state,
   m.priority,
   ra.id AS resposible_admin_login,
   CONCAT(m.plan_date, ' ', m.plan_time) AS plan_date_time,
   $self->{SEARCH_FIELDS}
   m.uid,
   a.aid,
   m.chapter AS chapter_id,
   m.deligation,
   m.admin_read,
   m.inner_msg
FROM (msgs_messages m)
LEFT JOIN users u ON (m.uid=u.uid)
$EXT_TABLE
LEFT JOIN admins a ON (m.aid=a.aid)
LEFT JOIN groups g ON (m.gid=g.gid)
LEFT JOIN msgs_reply r ON (m.id=r.main_msg)
LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
LEFT JOIN admins ra ON (m.resposible=ra.aid)
 $WHERE
GROUP BY m.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
 undef,
 $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query2("SELECT count(DISTINCT m.id) AS total, 
      sum(if(m.admin_read = '0000-00-00 00:00:00', 1, 0)) AS in_work,
      sum(if(m.state = 0, 1, 0)) AS open,
      sum(if(m.state = 1, 1, 0)) AS unmaked,
      sum(if(m.state = 2, 1, 0)) AS closed
    FROM msgs_messages m
    LEFT JOIN users u ON (m.uid=u.uid)
    LEFT JOIN msgs_reply r ON (m.id=r.main_msg)
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    $EXT_TABLE
    $WHERE",
    undef,
    { INFO => 1 }
    );
  }

  $WHERE       = '';
  @WHERE_RULES = ();

  return $list;
}

#**********************************************************
# Message
#**********************************************************
sub message_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });
  $self->query_add('msgs_messages', { %DATA,
                                           CLOSED_DATE => ($DATA{STATE} == 1 || $DATA{STATE} == 2) ? 'now()' : "0000-00-00 00:00:00",
                                           AID         => $admin->{AID},
                                           DATE        => 'now()'
                                         });

  $self->{MSG_ID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub message_del {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();

  if ($attr->{ID}) {
    if ($attr->{ID} =~ /,/) {
      push @WHERE_RULES, "id IN ($attr->{ID})";
    }
    else {
      push @WHERE_RULES, "id='$attr->{ID}'";
    }
  }

  if ($attr->{UID}) {
    push @WHERE_RULES, "uid='$attr->{UID}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';
  $self->query2("DELETE FROM msgs_messages WHERE $WHERE", 'do');

  $self->message_reply_del({ MAIN_MSG => $attr->{ID}, UID => $attr->{UID} });
  $self->query2("DELETE FROM msgs_attachments WHERE message_id='$attr->{ID}' and message_type=0", 'do');

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub message_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and m.uid='$attr->{UID}'" : '';

  $self->query2("SELECT m.id,
  m.subject,
  m.par AS parent_id,
  m.uid,
  m.chapter,
  m.message,
  m.reply,
  INET_NTOA(m.ip) AS ip,
  m.date,
  m.state,
  m.aid,
  u.id AS login,
  a.id AS a_name,
  mc.name AS chapter_name,
  m.gid,
  g.name AS fg_name,
  m.state,
  m.priority,
  m.lock_msg,
  m.plan_date,
  m.plan_time,
  m.closed_date,
  m.done_date,
  m.user_read,
  m.admin_read,
  m.resposible,
  m.inner_msg,
  m.phone,
  m.dispatch_id,
  m.deligation,
  m.survey_id
    FROM (msgs_messages m)
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    LEFT JOIN users u ON (m.uid=u.uid)
    LEFT JOIN admins a ON (m.aid=a.aid)
    LEFT JOIN groups g ON (m.gid=g.gid)
  WHERE m.id='$id' $WHERE
  GROUP BY m.id;",
  undef,
  { INFO => 1 }
  );

  $self->attachment_info({ MSG_ID => $self->{ID} });

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub message_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    ID          => 'id',
    PARENT_ID   => 'par',
    UID         => 'uid',
    CHAPTER     => 'chapter',
    MESSAGE     => 'message',
    REPLY       => 'reply',
    IP          => 'ip',
    DATE        => 'date',
    STATE       => 'state',
    AID         => 'aid',
    GID         => 'gid',
    PRIORITY    => 'priority',
    LOCK        => 'lock_msg',
    PLAN_DATE   => 'plan_date',
    PLAN_TIME   => 'plan_time',
    CLOSED_DATE => 'closed_date',
    DONE_DATE   => 'done_date',
    USER_READ   => 'user_read',
    ADMIN_READ  => 'admin_read',
    RESPOSIBLE  => 'resposible',
    INNER_MSG   => 'inner_msg',
    PHONE       => 'phone',
    DISPATCH_ID => 'dispatch_id',
    DELIGATION  => 'deligation'
  );

  $attr->{STATUS} = ($attr->{STATUS}) ? $attr->{STATUS} : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'msgs_messages',
      FIELDS          => \%FIELDS,
      OLD_INFO        => $self->message_info($attr->{ID}),
      DATA            => $attr,
      EXT_CHANGE_INFO => "MSG_ID:$attr->{ID}"
    }
  );

  return $self->{result};
}

#**********************************************************
# chapters_list
#**********************************************************
sub chapters_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $WHERE = $self->search_former($attr, [
      ['INNER_CHAPTER',  'INT',  'mc.inner_chapter' ],
      ['NAME',           'STR',  'mc.name' ],
      ['CHAPTERS',       'STR',  'mc.id' ]
    ],
    { WHERE => 1 });

  $self->query2("SELECT mc.id, mc.name, mc.inner_chapter
    FROM msgs_chapters mc
    $WHERE
    GROUP BY mc.id 
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
# chapter_add
#**********************************************************
sub chapter_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });

  $self->query_add('msgs_chapters', \%DATA);

  $admin->system_action_add("MGSG_CHAPTER:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
# chapter_del
#**********************************************************
sub chapter_del {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();

  if ($attr->{ID}) {
    push @WHERE_RULES, "id='$attr->{ID}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';
  $self->query2("DELETE FROM msgs_chapters WHERE $WHERE", 'do');

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub chapter_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT id,  name, inner_chapter
    FROM msgs_chapters 
  WHERE id='$id'",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub chapter_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;

  my %FIELDS = (
    ID            => 'id',
    NAME          => 'name',
    INNER_CHAPTER => 'inner_chapter'
  );

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_chapters',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->chapter_info($attr->{ID}),
      DATA         => $attr,

    }
  );

  return $self->{result};
}

#**********************************************************
# accounts_list
#**********************************************************
sub admins_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
      ['AID',          'INT',  'ma.aid'             ],
      ['EMAIL_NOTIFY', 'INT',  'ma.email_notify'    ],
      ['EMAIL',        'STR',  'a.email',           ], 
      ['CHAPTER_ID',   'INT',  'ma.chapter_id'      ],
    ],
    { WHERE => 1,
    }
    );

  $self->query2("SELECT a.id AS admin_login, 
     mc.name AS chapter_name, 
     ma.priority, 
     ma.deligation_level, 
     a.aid, 
     if(ma.chapter_id IS NULL, 0, ma.chapter_id) AS chapter_id, 
     ma.email_notify, 
     a.email
    FROM admins a 
    LEFT join msgs_admins ma ON (a.aid=ma.aid)
    LEFT join msgs_chapters mc ON (ma.chapter_id=mc.id)
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
# chapter_add
#**********************************************************
sub admin_change {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => \%DATA });

  $self->admin_del({ AID => $attr->{AID} });

  my @chapters = split(/, /, $attr->{IDS});
  foreach my $id (@chapters) {
    $self->query2("insert into msgs_admins (aid, chapter_id, priority, email_notify, deligation_level)
      values ('$DATA{AID}', '$id','" . $DATA{ 'PRIORITY_' . $id } . "','" . $DATA{ 'EMAIL_NOTIFY_' . $id } . "', '" . $DATA{ 'DELIGATION_LEVEL_' . $id } . "');", 'do'
    );
  }

  return $self;
}

#**********************************************************
# chapter_del
#**********************************************************
sub admin_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("DELETE FROM msgs_admins WHERE aid='$attr->{AID}'", 'do');

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub admin_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT id, name
    FROM msgs_chapters 
  WHERE id='$id'",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# message_reply_del
#**********************************************************
sub message_reply_del {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();

  if ($attr->{MAIN_MSG}) {
    if ($attr->{MAIN_MSG} =~ /,/) {
      push @WHERE_RULES, "main_msg IN ($attr->{MAIN_MSG})";
    }
    else {
      push @WHERE_RULES, "main_msg='$attr->{MAIN_MSG}'";
    }
  }
  elsif ($attr->{ID}) {
    push @WHERE_RULES, "id='$attr->{ID}'";
    $self->query2("DELETE FROM msgs_attachments WHERE message_id='$attr->{ID}' and message_type=1", 'do');
  }
  elsif ($attr->{UID}) {
    push @WHERE_RULES, "id='$attr->{UID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';
  $self->query2("DELETE FROM msgs_reply WHERE $WHERE", 'do');

  return $self;
}

#**********************************************************
# messages_list
#**********************************************************
sub messages_reply_list {
  my $self = shift;
  my ($attr) = @_;

  $PAGE_ROWS = ($attr->{PAGE_ROWS})     ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})          ? $attr->{SORT}      : 1;
  $DESC      = (defined($attr->{DESC})) ? $attr->{DESC}      : 'DESC';

  @WHERE_RULES = ("main_msg='$attr->{MSG_ID}'");

  my $WHERE = $self->search_former($attr, [
      ['LOGIN',        'INT',  'u.id'            ],
      ['UID',          'INT',  'm.uid'           ],
      ['INNER_MSG',    'INT',  'mr.inner_msg'    ],
      ['REPLY',        'STR',  'm.reply',        ], 
      ['STATE',        'INT',  'm.state'         ],
      ['ID',           'INT',  'mr.id',          ], 
      ['FROM_DATE|TO_DATE',   'DATE',  "date_format(m.date, '%Y-%m-%d')"      ],
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
    );  

  $self->query2("SELECT mr.id,
    mr.datetime,
    mr.text,
    if(mr.aid>0, a.id, u.id) AS creator_id,
    mr.status,
    mr.caption,
    INET_NTOA(mr.ip) AS ip,
    ma.filename,
    ma.content_size,
    ma.id AS attachment_id,
    mr.uid,
    SEC_TO_TIME(mr.run_time) AS run_time,
    mr.aid,
    mr.inner_msg,
    mr.survey_id
    FROM (msgs_reply mr)
    LEFT JOIN users u ON (mr.uid=u.uid)
    LEFT JOIN admins a ON (mr.aid=a.aid)
    LEFT JOIN msgs_attachments ma ON (mr.id=ma.message_id and ma.message_type=1 )
    $WHERE
    GROUP BY mr.id 
    ORDER BY datetime ASC;",
  undef,
  $attr
  );

  return $self->{list};
}

#**********************************************************
# Reply ADD
#**********************************************************
sub message_reply_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });
  $self->query2("insert into msgs_reply (main_msg,
   caption,
   text,
   datetime,
   ip,
   aid,
   status,
   uid,
   run_time,
   inner_msg,
   survey_id
   )
    values ('$DATA{ID}', '$DATA{REPLY_SUBJECT}', '$DATA{REPLY_TEXT}',  now(),
        INET_ATON('$DATA{IP}'), 
        '$DATA{AID}',
        '$DATA{STATE}',
        '$DATA{UID}', '$DATA{RUN_TIME}',
        '$DATA{REPLY_INNER_MSG}',
        '$DATA{SURVEY_ID}'
    );", 'do'
  );

  $self->{REPLY_ID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
#
#**********************************************************
sub attachment_add () {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "INSERT INTO msgs_attachments "
    . " (message_id, filename, content_type, content_size, content, "
    . " create_time, create_by, change_time, change_by, message_type) "
    . " VALUES "
    . " ('$attr->{MSG_ID}', '$attr->{FILENAME}', '$attr->{CONTENT_TYPE}', '$attr->{FILESIZE}', ?, "
    . " current_timestamp, '$attr->{UID}', current_timestamp, '0', '$attr->{MESSAGE_TYPE}')",
    'do',
    { Bind => [ $attr->{CONTENT} ] }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub attachment_info () {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{MSG_ID}) {
    $WHERE = "message_id='$attr->{MSG_ID}' and message_type='0'";
  }
  elsif ($attr->{REPLY_ID}) {
    $WHERE = "message_id='$attr->{REPLY_ID}' and message_type='1'";
  }
  elsif ($attr->{ID}) {
    $WHERE = "id='$attr->{ID}'";
  }

  if ($attr->{UID}) {
    $WHERE .= " and (create_by='$attr->{UID}' or create_by='0')";
  }

  $self->query2("SELECT id AS attachment_id, filename, 
    content_type, 
    content_size,
    content
   FROM  msgs_attachments 
   WHERE $WHERE",
   undef,
   { INFO => 1 }
  );

  if ($self->{errno} && $self->{errno} == 2) {
    $self->{errno} = undef;
  }

  return $self;
}

#**********************************************************
# fees
#**********************************************************
sub messages_reports {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  undef @WHERE_RULES;

  # Start letter
  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }

  if ($attr->{STATUS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'm.status') };
  }

  if ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'm.uid') };
  }

  my $date      = 'date_format(m.date, \'%Y-%m-%d\')';
  my $EXT_TABLE = '';
  if ($attr->{TYPE}) {
    if ($attr->{TYPE} eq 'ADMINS') {
      $date = 'a.id';
      $EXT_TABLE     = 'LEFT JOIN  admins a ON (m.resposible=a.aid)';
    }
    elsif ($attr->{TYPE} eq 'USER') {
      $date = 'u.id';
    }
    elsif ($attr->{TYPE} eq 'RESPOSIBLE') {
      $date          = "a.id";
      $EXT_TABLE     = 'LEFT JOIN  admins a ON (m.resposible=a.aid)';
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
    push @WHERE_RULES, "date_format(m.date, '%Y-%m-%d')='$attr->{DATE}'";
    $date = "date_format(m.date, '%Y-%m-%d')";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "date_format(m.date, '%Y-%m-%d')>='$from' and date_format(m.date, '%Y-%m-%d')<='$to'";
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES, "date_format(m.date, '%Y-%m')='$attr->{MONTH}'";
    $date = "date_format(m.date, '%Y-%m-%d')";
  }
  else {
    $date = "date_format(m.date, '%Y-%m')";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT $date, 
   sum(if (m.state=0, 1, 0)) AS open,
   sum(if (m.state=1, 1, 0)) AS unmaked,
   sum(if (m.state=2, 1, 0)) AS maked,
   count(DISTINCT m.id),
   SEC_TO_TIME(sum(mr.run_time)),
   m.uid
   FROM msgs_messages m
  LEFT JOIN  users u ON (m.uid=u.uid)
  LEFT JOIN  msgs_reply mr ON (m.id=mr.main_msg)
  $EXT_TABLE
  $WHERE
  GROUP BY 1
  ORDER BY $SORT $DESC ; ",
  undef,
  $attr
  );

  #  LIMIT $PG, $PAGE_ROWS;");
  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query2("SELECT count(DISTINCT m.id) AS total,
      sum(if (m.state=0, 1, 0)) AS open,
      sum(if (m.state=1, 1, 0)) AS unmaked,
      sum(if (m.state=2, 1, 0)) AS maked,
      SEC_TO_TIME(sum(mr.run_time)) AS run_time,
      sum(if(m.admin_read = '0000-00-00 00:00:00', 1, 0)) AS in_work
     FROM msgs_messages m
     LEFT JOIN  msgs_reply mr ON (m.id=mr.main_msg)
     $EXT_TABLE
    $WHERE;",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# accounts_list
#**********************************************************
sub dispatch_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ();

  if (defined($attr->{STATE}) && $attr->{STATE} ne '') {
    if ($attr->{STATE} == 4) {
      push @WHERE_RULES, @{ $self->search_expr('0000-00-00 00:00:00', 'INT', 'd.admin_read') };
    }
    else {
      push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'd.state') };
    }
  }

  my $WHERE = $self->search_former($attr, [
      ['NAME',         'STR',  'd.name'          ],
      ['CHAPTERS',     'INT',  'd.id'           ],
    ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES      
    }
  );

  $self->query2("SELECT d.id, d.comments, d.plan_date, created, count(m.id) AS message_count
    FROM msgs_dispatch d
    LEFT JOIN msgs_messages m ON (d.id=m.dispatch_id)
    $WHERE
    GROUP BY d.id 
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
# chapter_add
#**********************************************************
sub dispatch_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });

  $self->query_add('msgs_dispatch', { %DATA,
                                      CREATED => 'now()' 
                                     }); 

  $self->{DISPATCH_ID} = $self->{INSERT_ID};

  $admin->system_action_add("MGSG_DISPATCH:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
# chapter_del
#**********************************************************
sub dispatch_del {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();

  if ($attr->{ID}) {
    push @WHERE_RULES, "id='$attr->{ID}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';
  $self->query2("DELETE FROM msgs_dispatch WHERE $WHERE", 'do');

  $admin->system_action_add("MGSG_DISPATCH:$attr->{ID}", { TYPE => 10 });

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub dispatch_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT md.id, md.comments, md.created, md.plan_date, 
  md.state,
  md.closed_date,
  a.aid,
  ra.aid AS resposible_id,
  a.name AS admin_fio,
  ra.name AS resposible_fio
    FROM msgs_dispatch md
    LEFT JOIN admins a ON (a.aid=md.aid)
    LEFT JOIN admins ra ON (ra.aid=md.resposible)
  WHERE md.id='$id'",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# dispatch_change()
#**********************************************************
sub dispatch_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_dispatch',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
# dispatch_admins_change
#**********************************************************
sub dispatch_admins_change {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => \%DATA });

  $self->query2("DELETE FROM msgs_dispatch_admins WHERE dispatch_id='$attr->{DISPATCH_ID}';", 'do');

  my @admins = split(/, /, $attr->{AIDS});
  foreach my $aid (@admins) {
    $self->query2("INSERT INTO msgs_dispatch_admins (dispatch_id, aid)
      VALUES ('$DATA{DISPATCH_ID}', '$aid');", 'do'
    );
  }

  return $self;
}

#**********************************************************
# chapter_add
#**********************************************************
sub dispatch_admins_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT dispatch_id, aid FROM msgs_dispatch_admins WHERE dispatch_id='$attr->{DISPATCH_ID}';",
    undef, $attr);

  return $self->{list};
}

#**********************************************************
# messages_list
#**********************************************************
sub unreg_requests_list {
  my $self = shift;
  my ($attr) = @_;

  $PAGE_ROWS = ($attr->{PAGE_ROWS})     ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})          ? $attr->{SORT}      : 1;
  $DESC      = (defined($attr->{DESC})) ? $attr->{DESC}      : 'DESC';

  @WHERE_RULES = ();
  $self->{COL_NAMES_ARR}=undef;

  if (defined($attr->{STATE})) {
    if ($attr->{STATE} == 4) {
      push @WHERE_RULES, @{ $self->search_expr('0000-00-00 00:00:00', 'INT', 'm.admin_read') };
    }
    if ($attr->{STATE} == 7) {

    }
    else {
      push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'm.state') };
    }
  }

  my $EXT_JOIN = '';

  my $WHERE = $self->search_former($attr, [
      ['MSG_ID',       'INT',  'm.id'             ],
      ['DATETIME',     'DATE', 'm.datetime',    1 ],
      ['SUBJECT',      'STR',  'm.subject',     1 ],
      ['FIO',          'STR',  'm.fio',         1 ],
      ['PHONE',        'STR',  'm.phone',       1 ],
      ['STATUS',       'INT',  'm.state',       1 ],
      ['CHAPTER',      'INT',  'm.chapter', 'mc.name AS chapter_name'],
      ['CLOSED_DATE',  'DATE', 'm.closed_date', 1 ],
      ['ADMIN_LOGIN',  'INT',  'a.id',  'a.id AS admin_login' ],
      ['INNER_MSG',    'INT',  'm.inner_msg',   1 ], 
      ['MESSAGE',      'STR',  'm.message',     1 ],
      ['ADMIN_READ',   'INT',  'm.admin_read',  1 ],
      ['RUN_TIME',     'DATE', 'SEC_TO_TIME(sum(r.run_time))',  'SEC_TO_TIME(sum(r.run_time)) AS run_time' ],
      ['DONE_DATE',    'DATE', 'm.done_date',   1 ],
      ['UID',          'INT',  'm.uid',           ],
      ['DELIGATION',   'INT',  'm.delegation',  1 ],
      ['RESPOSIBLE',   'INT',  'm.resposible',    ],
      ['PRIORITY',     'INT',  'm.state',         ],
      ['PLAN_DATE',    'INT',  'm.plan_date',   1 ], 
      ['PLAN_TIME',    'INT',  'm.plan_time',   1 ],
      ['DISPATCH_ID',  'INT',  'm.dispatch_id', 1 ],
      ['IP',           'IP',   'm.ip',  'INET_NTOA(m.ip) AS ip' ],
      ['DATE',         'DATE',  "date_format(m.datetime, '%Y-%m-%d')" ],
      ['FROM_DATE|TO_DATE', 'DATE', "date_format(m.datetime, '%Y-%m-%d')" ],
      ['SHOW_TEXT',    '',    '',       'm.message' ],
    ],
    { WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    }
    );

  $self->query2("SELECT  m.id,
  $self->{SEARCH_FIELDS}
  m.responsible_admin
FROM (msgs_unreg_requests m)
LEFT JOIN admins a ON (m.received_admin=a.aid)
LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
 $WHERE
GROUP BY m.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query2("SELECT count(*) AS total
    FROM (msgs_unreg_requests m)
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    $WHERE",
    undef, { INFO => 1 }
    );
  }

  $WHERE       = '';
  @WHERE_RULES = ();

  return $list;
}

#**********************************************************
# Message
#**********************************************************
sub unreg_requests_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });

  $self->query2("INSERT INTO msgs_unreg_requests (datetime, received_admin, ip, subject, comments, chapter, request, state,
   priority,
   fio,
   phone,
   email,
   address_street,
   address_build,
   address_flat,
   country_id,
   company,
   CONNECTION_TIME,
   location_id )
    values (now(), '$admin->{AID}', INET_ATON('$admin->{SESSION_IP}'),  '$DATA{SUBJECT}', '$DATA{COMMENTS}', '$DATA{CHAPTER}', '$DATA{REQUEST}',  '$DATA{STATE}',
        '$DATA{PRIORITY}',
        '$DATA{FIO}',
        '$DATA{PHONE}', 
        '$DATA{EMAIL}',
        '$DATA{ADDRESS_STREET}',
        '$DATA{ADDRESS_BUILD}',
        '$DATA{ADDRESS_FLAT}',
        '$DATA{COUNTRY}',
        '$DATA{COMPANY_NAME}',
        '$DATA{CONNECTION_TIME}',
        '$DATA{LOCATION_ID}'        
        );", 'do'
  );

  $self->{MSG_ID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
# unreg_requests_del
#**********************************************************
sub unreg_requests_del {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();

  if ($attr->{ID}) {
    if ($attr->{ID} =~ /,/) {
      push @WHERE_RULES, "id IN ($attr->{ID})";
    }
    else {
      push @WHERE_RULES, "id='$attr->{ID}'";
    }
  }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';
  $self->query2("DELETE FROM msgs_unreg_requests WHERE $WHERE", 'do');

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub unreg_requests_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and m.uid='$attr->{UID}'" : '';

  $self->query2("SELECT 
    m.id,
    m.datetime,
    ra.id AS received_admin,
    m.state,
    m.priority,
    m.subject,
    mc.name AS chapter,
    m.request,
    m.comments,
    m.responsible_admin,
    m.fio,
    m.phone,
    m.email,
    m.address_street,
    m.address_build,
    m.address_flat,
    m.ip,
    m.closed_date,
    m.uid,
    m.company as company_name,
    m.country_id as country,
    m.connection_time,
    m.location_id
    FROM (msgs_unreg_requests m)
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    LEFT JOIN admins ra ON (m.received_admin=ra.aid)
  WHERE m.id='$id' $WHERE
  GROUP BY m.id;",
  undef,
  { INFO => 1 }
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  if ($self->{LOCATION_ID} > 0) {
    $self->query2("select d.id AS district_id, 
      d.city, 
      d.name AS address_district, 
      s.name AS address_street, 
      b.number AS address_build  
     FROM builds b
     LEFT JOIN streets s  ON (s.id=b.street_id)
     LEFT JOIN districts d  ON (d.id=s.district_id)
     WHERE b.id='$self->{LOCATION_ID}'",
     undef,
     { INFO => 1 }
    );
  }

  return $self;
}

#**********************************************************
# unreg_requests_change()
#**********************************************************
sub unreg_requests_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    ID                => 'id',
    DATETIME          => 'datetime',
    RECIEVED_ADMIN    => 'received_admin',
    STATE             => 'state',
    PRIORITY          => 'priority',
    SUBJECT           => 'subject',
    CHAPTER           => 'chapter',
    REQUEST           => 'request',
    COMMENTS          => 'comments',
    RESPONSIBLE_ADMIN => 'responsible_admin',
    FIO               => 'fio',
    PHONE             => 'phone',
    EMAIL             => 'email',
    ADDRESS_STREET    => 'address_street',
    ADDRESS_BUILD     => 'address_build',
    ADDRESS_FLAT      => 'address_flat',
    IP                => 'ip',
    CLOSED_DATE       => 'closed_date',
    UID               => 'uid',
    COMPANY           => 'company',
    COUNTRY           => 'country_id',
    CONNECTION_TIME   => 'connection_time',
    LOCATION_ID       => 'location_id'
  );
  $attr->{STATUS} = ($attr->{STATUS}) ? $attr->{STATUS} : 0;

  $admin->{MODULE} = $MODULE;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'msgs_unreg_requests',
      FIELDS          => \%FIELDS,
      OLD_INFO        => $self->unreg_requests_info($attr->{ID}),
      DATA            => $attr,
      EXT_CHANGE_INFO => "MSG_ID:$attr->{ID}"
    }
  );

  return $self->{result};
}

#**********************************************************
# survey_subjects_list
#**********************************************************
sub survey_subjects_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
      ['NAME',         'STR',  'mc.name'          ],
      ['CHAPTERS',     'INT',  'mc.id',           ],
      ['INNER_CHAPTER','INT',  'mc.inner_chapter' ], 
    ],
    { WHERE => 1,
    }
    );

  $self->query2("SELECT  ms.id, ms.name, ms.comments, ms.aid, ms.created
    FROM msgs_survey_subjects ms
    $WHERE
    GROUP BY ms.id 
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total
     FROM msgs_survey_subjects ms
     $WHERE",
     undef,
     { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# survey_subjects_add
#**********************************************************
sub survey_subject_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });

  $self->query_add('msgs_survey_subjects',  { %DATA,
                                              CREATED => 'now()'
                                            });

  return $self;
}

#**********************************************************
# chapter_survey_subjects
#**********************************************************
sub survey_subject_del {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();

  if ($attr->{ID}) {
    push @WHERE_RULES, "id='$attr->{ID}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';
  $self->query2("DELETE FROM msgs_survey_subjects WHERE $WHERE", 'do');

  return $self;
}

#**********************************************************
# survey_subjects_info
#**********************************************************
sub survey_subject_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT id AS survey_id, name, comments, aid, created
    FROM msgs_survey_subjects 
  WHERE id='$id'",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# survey_subjects_change()
#**********************************************************
sub survey_subject_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;

  my %FIELDS = (
    SURVEY_ID => 'id',
    NAME      => 'name',
    COMMENTS  => 'comments',
  );

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'SURVEY_ID',
      TABLE        => 'msgs_survey_subjects',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->survey_subject_info($attr->{SURVEY_ID}),
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
# survey_subjects_list
#**********************************************************
sub survey_questions_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
      ['SURVEY',         'STR',  'mq.survey_id'     ],
    ],
    { WHERE => 1,
    }
    );

  $self->query2("SELECT  mq.num, mq.question, mq.comments, mq.params, mq.user_comments, mq.fill_default, mq.id
    FROM msgs_survey_questions mq
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total
     FROM msgs_survey_questions mq
     $WHERE",
     undef,
     { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# survey_questions_add
#**********************************************************
sub survey_question_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });

  $self->query2("insert into msgs_survey_questions (num, question, comments, params, user_comments, survey_id, fill_default)
    values ('$DATA{NUM}', '$DATA{QUESTION}', '$DATA{COMMENTS}', '$DATA{PARAMS}', '$DATA{USER_COMMENTS}', '$DATA{SURVEY}', '$DATA{FILL_DEFAULT}');", 'do'
  );

  return $self;
}

#**********************************************************
# urvey_questions_del
#**********************************************************
sub survey_question_del {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();

  if ($attr->{ID}) {
    push @WHERE_RULES, "id='$attr->{ID}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';
  $self->query2("DELETE FROM msgs_survey_questions WHERE $WHERE", 'do');

  return $self;
}

#**********************************************************
# survey_questions_info
#**********************************************************
sub survey_question_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT id, 
      num, 
      question, 
      comments, 
      params, 
      user_comments, 
      survey_id AS survey, 
      fill_default
    FROM msgs_survey_questions 
  WHERE id='$id'",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# survey_questions_change()
#**********************************************************
sub survey_question_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;
  $attr->{USER_COMMENTS} = ($attr->{USER_COMMENTS}) ? 1 : 0;
  $attr->{FILL_DEFAULT}  = ($attr->{FILL_DEFAULT})  ? 1 : 0;

  my %FIELDS = (
    ID            => 'id',
    NUM           => 'num',
    QUESTION      => 'question',
    COMMENTS      => 'comments',
    PARAMS        => 'params',
    USER_COMMENTS => 'user_comments',
    SURVEY        => 'survey_id',
    FILL_DEFAULT  => 'fill_default'
  );

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'msgs_survey_questions',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->survey_question_info($attr->{ID}),
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
#
#**********************************************************
sub survey_answer_show {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = ($attr->{REPLY_ID}) ? "AND reply_id='$attr->{REPLY_ID}'" : "AND msg_id='$attr->{MSG_ID}' AND reply_id='0' ";

  $self->query2("SELECT question_id,
  uid,
  answer,
  comments,
  date_time,
  survey_id 
  FROM msgs_survey_answers 
  WHERE survey_id='$attr->{SURVEY_ID}' 
  AND uid='$attr->{UID}' $WHERE;",
  undef,
  $attr
  );

  return $self->{list};
}

#**********************************************************
#
#**********************************************************
sub survey_answer_add {
  my $self = shift;
  my ($attr) = @_;

  my @ids = split(/, /, $attr->{IDS});

  my @fill_default      = ();
  my %fill_default_hash = ();
  if ($attr->{FILL_DEFAULT}) {
    @fill_default = split(/, /, $attr->{FILL_DEFAULT});
    foreach my $id (@fill_default) {
      $fill_default_hash{$id} = 1;
    }
  }

  foreach my $id (@ids) {
    if ($attr->{FILL_DEFAULT} && !$fill_default_hash{$id}) {
      next;
    }

    my $sql = "INSERT INTO msgs_survey_answers (question_id,
  uid,
  answer,
  comments,
  date_time,
  survey_id,
  msg_id,
  reply_id)
  values ('$id', 
  '$attr->{UID}', 
  '" . $attr->{ 'PARAMS_' . $id } . "', 
  '" . $attr->{ 'USER_COMMENTS_' . $id } . "', 
  now(), 
  '$attr->{SURVEY_ID}',
  '$attr->{MSG_ID}',
  '$attr->{REPLY_ID}'
  );";

    $self->query2($sql, 'do');
  }

  return $self;
}

#**********************************************************
#
#**********************************************************
sub survey_answer_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = ($attr->{REPLY_ID}) ? "AND reply_id='$attr->{REPLY_ID}'" : "'$attr->{MSG_ID}'";

  $self->query2("DELETE FROM msgs_survey_answers WHERE survey_id='$attr->{SURVEY_ID}' AND uid='$attr->{UID}' $WHERE;", 'do');
  return $self;
}

1

