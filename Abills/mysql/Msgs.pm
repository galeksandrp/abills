package Msgs;
# Message system
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

use main;
@ISA  = ("main");


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  #$self->{debug}=1;
  return $self;
}


#**********************************************************
# messages_list
#**********************************************************
sub messages_list {
  my $self = shift;
  my ($attr) = @_;

 
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = (defined($attr->{DESC})) ? $attr->{DESC} : 'DESC';


 @WHERE_RULES = ();
 
 if($attr->{LOGIN_EXPR}) {
	 push @WHERE_RULES, "u.id='$attr->{LOGIN_EXPR}'"; 
  }
 
 if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(m.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(m.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if ($attr->{MSG_ID}) {
 	  my $value = $self->search_expr($attr->{MSG_ID}, 'INT');
    push @WHERE_RULES, "m.id$value";
  }


 if (defined($attr->{REPLY})) {
 	  my $value = $self->search_expr($attr->{REPLY}, '');
    push @WHERE_RULES, "m.reply$value";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }
 
 
 
 #DIsable
 if ($attr->{UID}) {
   push @WHERE_RULES, "m.uid='$attr->{UID}'"; 
 }

 #DIsable
 if ($attr->{STATE}) {
   my $value = $self->search_expr($attr->{STATE}, 'INT');
   push @WHERE_RULES, "m.state$value"; 
  }
 

 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db,   "SELECT m.id, 
    if(m.uid>0, u.id, g.name),
    m.subject, mc.name, m.date,  
    if(m.reply IS NULL, '', m.reply), 
    inet_ntoa(m.ip), 
    a.id,
    m.priority,
    m.uid, 
    a.aid, m.state, m.gid

    FROM (msgs_messages m)
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    LEFT JOIN users u ON (m.uid=u.uid)
    LEFT JOIN admins a ON (m.aid=a.aid)
    LEFT JOIN groups g ON (m.gid=g.gid)
    $WHERE
    GROUP BY m.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 my $list = $self->{list};

 if ($self->{TOTAL} > 0  || $PG > 0) {
   $self->query($db, "SELECT count(*)
    FROM msgs_messages m
    LEFT JOIN users u ON (m.uid=u.uid)
    $WHERE");

   ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }
 


 $WHERE = '';
 @WHERE_RULES=();
  
 return $list;
}


#**********************************************************
# Message
#**********************************************************
sub message_add {
	my $self = shift;
	my ($attr) = @_;
  
 
  %DATA = $self->get_data($attr, { default => \%DATA }); 

  $self->query($db, "insert into msgs_messages (uid, subject, chapter, message, ip, date, reply, aid, state, gid,
   priority, lock_msg)
    values ('$DATA{UID}', '$DATA{SUBJECT}', '$DATA{CHAPTER}', '$DATA{MESSAGE}', INET_ATON('$DATA{IP}'), now(), 
        '$DATA{REPLY}',
        '$admin->{AID}',
        '$DATA{STATE}', 
        '$DATA{GID}',
        '$DATA{PRIORITY}',
        '$DATA{LOCK}');", 'do');

	return $self;
}





#**********************************************************
# Bill
#**********************************************************
sub message_del {
	my $self = shift;
	my ($attr) = @_;

  @WHERE_RULES=();

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

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES)  : '';
  $self->query($db, "DELETE FROM msgs_messages WHERE $WHERE", 'do');

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub message_info {
	my $self = shift;
	my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and m.uid='$attr->{UID}'" : '';

  $self->query($db, "SELECT m.id,
  m.subject,
  m.par,
  m.uid,
  m.chapter,
  m.message,
  m.reply,
  INET_NTOA(m.ip),
  m.date,
  m.state,
  m.aid,
  u.id,
  a.id,
  mc.name,
  m.gid,
  g.name,
  m.priority,
  m.lock_msg
    FROM (msgs_messages m)
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    LEFT JOIN users u ON (m.uid=u.uid)
    LEFT JOIN admins a ON (m.aid=a.aid)
    LEFT JOIN groups g ON (m.gid=g.gid)
  WHERE m.id='$id' $WHERE
  GROUP BY m.id;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID}, 
   $self->{SUBJECT},
   $self->{PARENT_ID},
   $self->{UID},
   $self->{CHAPTER},
   $self->{MESSAGE},
   $self->{REPLY},
   $self->{IP},
   $self->{DATE}, 
   $self->{STATE}, 
   $self->{AID},
   $self->{LOGIN},
   $self->{A_NAME},
   $self->{CHAPTER_NAME},
   $self->{GID},
   $self->{G_NAME},
   $self->{PRIORITY},
   $self->{LOCK}
  )= @{ $self->{list}->[0] };
	
	return $self;
}


#**********************************************************
# change()
#**********************************************************
sub message_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ID          => 'id',
                PARENT_ID   => 'par',
                UID			    => 'uid',
                CHAPTER     => 'chapter',
                MESSAGE     => 'message',
                REPLY       => 'reply',
                IP					=> 'ip',
                DATE        => 'date',
                STATE			  => 'state',
                AID         => 'aid',
                GID         => 'gid',
                PRIORITY    => 'priority',
                LOCK        => 'lock_msg'
             );


  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'msgs_messages',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->message_info($attr->{ID}),
                   DATA         => $attr
                  } );

  return $self->{result};
}





#**********************************************************
# accounts_list
#**********************************************************
sub chapters_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ();
 
 if($attr->{NAME}) {
	 push @WHERE_RULES, "mc.name='$attr->{NAME}'"; 
  }
 
 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db,   "SELECT mc.id, mc.name, count(*)
    FROM msgs_chapters mc
    LEFT JOIN msgs_messages m ON (mc.id=m.chapter)
    $WHERE
    GROUP BY mc.id 
    ORDER BY $SORT $DESC;");

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
   $self->query($db, "SELECT count(*)
     FROM msgs_chapters mc
     $WHERE");

   ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }
 
 
	return $list;
}


#**********************************************************
# chapter_add
#**********************************************************
sub chapter_add {
	my $self = shift;
	my ($attr) = @_;
  
 
  %DATA = $self->get_data($attr, { default => \%DATA }); 
 

  $self->query($db, "insert into msgs_chapters (name)
    values ('$DATA{NAME}');", 'do');

	return $self;
}




#**********************************************************
# chapter_del
#**********************************************************
sub chapter_del {
	my $self = shift;
	my ($attr) = @_;

  @WHERE_RULES=();

  if ($attr->{ID}) {
  	 push @WHERE_RULES, "id='$attr->{ID}'";
   }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES)  : '';
  $self->query($db, "DELETE FROM msgs_chapters WHERE $WHERE", 'do');

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub chapter_info {
	my $self = shift;
	my ($id, $attr) = @_;


  $self->query($db, "SELECT id,  name
    FROM msgs_chapters 
  WHERE id='$id'");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID}, 
   $self->{NAME}
  )= @{ $self->{list}->[0] };

	return $self;
}


#**********************************************************
# change()
#**********************************************************
sub chapter_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ID          => 'id',
                NAME        => 'name'
             );


  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'msgs_chapters',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->chapter_info($attr->{ID}),
                   DATA         => $attr
                  } );

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

  @WHERE_RULES = ();
 
 if($attr->{AID}) {
	 push @WHERE_RULES, "a.aid='$attr->{AID}'"; 
  }
 
 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db, "SELECT a.id, mc.name, ma.priority, 0, a.aid, ma.chapter_id
    FROM admins a 
    LEFT join msgs_admins ma ON (a.aid=ma.aid)
    LEFT join msgs_chapters mc ON (ma.chapter_id=mc.id)
    $WHERE
    ORDER BY $SORT $DESC;");

 my $list = $self->{list};

# if ($self->{TOTAL} > 0) {
#   $self->query($db, "SELECT count(*)
#     FROM msgs_chapters mc
#     $WHERE");

#   ($self->{TOTAL}) = @{ $self->{list}->[0] };
#  }
 
 
	return $list;
}


#**********************************************************
# chapter_add
#**********************************************************
sub admin_change {
	my $self = shift;
	my ($attr) = @_;
  
  my %DATA = $self->get_data($attr, { default => \%DATA }); 

  $self->admin_del({ AID => $attr->{AID}});
  
  my @chapters = split(/, /, $attr->{IDS});
  foreach my $id (@chapters) {
    $self->query($db, "insert into msgs_admins (aid, chapter_id, priority)
      values ('$DATA{AID}', '$id','". $DATA{'PRIORITY_'. $id}."');", 'do');
   }

	return $self;
}




#**********************************************************
# chapter_del
#**********************************************************
sub admin_del {
	my $self = shift;
	my ($attr) = @_;

  $self->query($db, "DELETE FROM msgs_admins WHERE aid='$attr->{AID}'", 'do');

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub admin_info {
	my $self = shift;
	my ($id, $attr) = @_;


  $self->query($db, "SELECT id,  name
    FROM msgs_chapters 
  WHERE id='$id'");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID}, 
   $self->{NAME}
  )= @{ $self->{list}->[0] };

	return $self;
}




#**********************************************************
# messages_list
#**********************************************************
sub messages_reply_list {
  my $self = shift;
  my ($attr) = @_;


 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = (defined($attr->{DESC})) ? $attr->{DESC} : 'DESC';


 @WHERE_RULES = ();
 
 if($attr->{LOGIN_EXPR}) {
	 push @WHERE_RULES, "u.id='$attr->{LOGIN_EXPR}'"; 
  }
 
 if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(m.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(m.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if ($attr->{MSG_ID}) {
 	  my $value = $self->search_expr($attr->{MSG_ID}, 'INT');
    push @WHERE_RULES, "m.id$value";
  }


 if (defined($attr->{REPLY})) {
 	  my $value = $self->search_expr($attr->{REPLY}, '');
    push @WHERE_RULES, "m.reply$value";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }
 
 
 
 #DIsable
 if ($attr->{UID}) {
   push @WHERE_RULES, "m.uid='$attr->{UID}'"; 
 }

 #DIsable
 if ($attr->{STATE}) {
   my $value = $self->search_expr($attr->{STATE}, 'INT');
   push @WHERE_RULES, "m.state$value"; 
  }
 

 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db,   "SELECT mr.id,
    mr.datetime,
    mr.text,
    a.id,
    mr.status,
    mr.caption,
    INET_NTOA(mr.ip)

    FROM (msgs_reply mr)
    LEFT JOIN users u ON (mr.uid=u.uid)
    LEFT JOIN admins a ON (mr.aid=a.aid)
    WHERE main_msg='$attr->{MSG_ID}'
    GROUP BY mr.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");

 
 return $self->{list};
}


#**********************************************************
# Reply ADD
#**********************************************************
sub message_reply_add {
	my $self = shift;
	my ($attr) = @_;
  
  %DATA = $self->get_data($attr, { default => \%DATA }); 

  $self->{debug}=1;

  $self->query($db, "insert into msgs_reply (main_msg,
   caption,
   text,
   datetime,
   ip,
   aid,
   status
   )
    values ('$DATA{ID}', '$DATA{SUBJECT}', '$DATA{REPLY}',  now(),
        INET_ATON('$DATA{IP}'), 
        '$admin->{AID}',
        '$DATA{STATE}'
    );", 'do');


  return $self;	
}



1
