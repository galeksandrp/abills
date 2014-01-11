package Log;

#Make logs

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION

%log_levels
);

@EXPORT_OK = qw(log_add log_print);
@EXPORT    = qw(%log_levels);

my ($CONF, $attr);
use main;
@ISA = ("main");


# Log levels. For details see <syslog.h>
%log_levels = (
  'LOG_EMERG'   => 0,
  'LOG_ALERT'   => 1,
  'LOG_CRIT'    => 2,
  'LOG_ERR'     => 3,
  'LOG_WARNING' => 4,
  'LOG_NOTICE'  => 5,
  'LOG_INFO'    => 6,
  'LOG_DEBUG'   => 7,
  'LOG_SQL'     => 8,
);

#**********************************************************
# Log new
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($CONF, $attr) = @_;

  my $self = {};
  bless($self, $class);
  
  if ($attr->{DEBUG_LEVEL}) {
    my %rev_log_level = reverse %log_levels;
    for(my $i=0; $i<=$attr->{DEBUG_LEVEL}; $i++) {
      $self->{debugmods} .= "$rev_log_level{$i} ";
    }
  }
  
  $self->{db}=$db;

  return $self;
}

#**********************************************************
# Log list
#**********************************************************
sub log_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ($attr->{NAS_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{NAS_ID}, 'INT', 'l.nas_id') };
  }

  my $WHERE =  $self->search_former($attr, [
      ['DATE',              'DATE', "date_format(l.date, '%Y-%m-%d')", 1 ],
      ['LOG_TYPE',          'INT',  'l.log_type',                      1 ],
      ['ACTION',            'INT',  'l.action',                        1 ],
      ['USER',              'STR',  'l.user',                          1 ],
      ['MESSAGE',           'STR',  'l.message',                       1 ],
      ['NAS_ID',            'INT',   'l.nas_id',                       1 ],
      ['FROM_DATE|TO_DATE', 'DATE', "date_format(l.date, '%Y-%m-%d')",   ],
    ],
    { WHERE       => 1,
    }    
    );

  $self->query2("SELECT l.date, l.log_type, l.action, l.user, l.message, l.nas_id
  FROM errors_log l
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  my $list = $self->{list};
  $self->{OUTPUT_ROWS} = $self->{TOTAL};

  $self->query2("SELECT l.log_type, count(*) AS count
  FROM errors_log l
  $WHERE
  GROUP BY 1
  ORDER BY 1;",
  undef,
  $attr
  );

  return $list;
}

#**********************************************************
# Make log records
# log_print($self)
#**********************************************************
sub log_print {
  my $self = shift;
  my ($LOG_TYPE, $USER_NAME, $MESSAGE, $attr) = @_;
  my $Nas = $attr->{NAS} || undef;

  my $action = $attr->{'ACTION'} || $self->{ACTION} || '';
  if ($self->{LOG_FILE}) {
    $attr->{LOG_FILE}=$self->{LOG_FILE};
  }

  if ($self->{debugmods}) {
    $CONF->{debugmods}=$self->{debugmods}; 
  }

  if (!$CONF->{debugmods} || $CONF->{debugmods} =~ /$LOG_TYPE/) {
    if ($CONF->{ERROR2DB} && !$attr->{LOG_FILE}) {
      $self->log_add(
        {
          LOG_TYPE  => $log_levels{$LOG_TYPE},
          ACTION    => $action,
          USER_NAME => $USER_NAME || '-',
          MESSAGE   => "$MESSAGE",
          NAS_ID    => $Nas->{NAS_ID}
        }
      );
    }
    else {
      use POSIX qw(strftime);
      my $DATE = strftime "%Y-%m-%d", localtime(time);
      my $TIME = strftime "%H:%M:%S", localtime(time);
      my $nas = (defined($Nas->{NAS_ID})) ? "NAS: $Nas->{NAS_ID} ($Nas->{NAS_IP}) " : '';
      my $logfile = ($attr->{LOG_FILE}) ? $attr->{LOG_FILE} : $CONF->{LOGFILE};
      if (open(FILE, ">>$logfile")) {
        print FILE "$DATE $TIME $LOG_TYPE: $action [$USER_NAME] $nas$MESSAGE\n";
        close(FILE);
      }
      else {
        print "Can't open file '$logfile' $!\n";
      }
    }

    if ($self->{PRINT} || $attr->{PRINT}) {
      use POSIX qw(strftime);
      my $DATE = strftime "%Y-%m-%d", localtime(time);
      my $TIME = strftime "%H:%M:%S", localtime(time);
      my $nas = (defined($Nas->{NAS_ID})) ? "NAS: $Nas->{NAS_ID} ($Nas->{NAS_IP}) " : '';
      print "$DATE $TIME $LOG_TYPE: $action [$USER_NAME] $nas$MESSAGE\n";
    }
  }
}

#**********************************************************
# Add log records
# log_add($self)
#**********************************************************
sub log_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr);

  # $date, $time, $log_type, $action, $user, $message
  $DATA{MESSAGE} =~ s/'/\\'/g;
  $DATA{NAS_ID} = (!$attr->{NAS_ID}) ? 0 : $attr->{NAS_ID};

  $self->query2("INSERT INTO errors_log (date, log_type, action, user, message, nas_id)
 values (now(), '$DATA{LOG_TYPE}', '$DATA{ACTION}', '$DATA{USER_NAME}', '$DATA{MESSAGE}',  '$DATA{NAS_ID}');", 'do'
  );

  return 0;
}

#**********************************************************
# Del log records
# log_del($self)
#**********************************************************
sub log_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{LOGIN}) {
    $WHERE = "user='$attr->{LOGIN}'";
  }

  $self->query2("DELETE FROM errors_log WHERE $WHERE;", 'do');

  return 0;
}

1

