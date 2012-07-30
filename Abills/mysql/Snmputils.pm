package Snmputils;

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

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = {};
  bless($self, $class);

  #$self->{debug}=1;

  if ($CONF->{DELETE_USER}) {
    $self->{UID} = $CONF->{DELETE_USER};
    $self->snmp_binding_del({ UID => $CONF->{DELETE_USER} });
  }

  return $self;
}

#**********************************************************
# accounts_list
#**********************************************************
sub snmputils_nas_ipmac {
  my $self = shift;
  my ($attr) = @_;

  $PAGE_ROWS = ($attr->{PAGE_ROWS})     ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})          ? $attr->{SORT}      : 1;
  $DESC      = (defined($attr->{DESC})) ? $attr->{DESC}      : 'DESC';

  @WHERE_RULES = ();
  if (defined($attr->{DISABLE})) {
    push @WHERE_RULES, "u.disable='$attr->{DISABLE}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? 'AND ' . join(' AND ', @WHERE_RULES) : '';

  $self->query(
    $db, "SELECT un.nas_id, 
     u.uid, 
     INET_NTOA(d.ip) AS ip, 
     d.mac,
     if(u.company_id > 0, cb.deposit+u.credit, ub.deposit+u.credit) AS deposit, 
     d.comments,
     d.vid,
     d.ports,
     d.nas,
     u.id AS login,
     d.network,
     if(u.disable=1, 1, if((u.expire='0000-00-00' or u.expire > CURDATE())
        AND (u.activate='0000-00-00' or u.activate <= CURDATE()), 0, 1)
       ) AS status
   FROM (users u, dhcphosts_hosts d)
     LEFT JOIN bills ub ON (u.bill_id = ub.id)
     LEFT JOIN companies company ON  (u.company_id=company.id)
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     LEFT JOIN users_nas un ON (u.uid=un.uid)
            WHERE u.uid=d.uid
               and (d.nas='$attr->{NAS_ID}' or un.nas_id='$attr->{NAS_ID}')
               $WHERE
            ORDER BY $SORT $DESC
            LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};
  return $list;
}

#**********************************************************
# Bill
#**********************************************************
sub snmp_binding_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });

  $self->query(
    $db, "insert into snmputils_binding (uid, binding, comments, params)
    values ('$DATA{UID}', '$DATA{BINDING}', '$DATA{COMMENTS}', '$DATA{PARAMS}');", 'do'
  );

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub snmp_binding_del {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{UID}) {
    $WHERE = "uid='$attr->{UID}'";
  }
  else {
    $WHERE = "binding='$attr->{ID}'";
  }

  $self->query($db, "DELETE FROM snmputils_binding WHERE $WHERE", 'do');
  return $self;
}

#**********************************************************
# group_info()
#**********************************************************
sub snmp_binding_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    UID      => 'uid',
    BINDING  => 'binding',
    COMMENTS => 'comments',
    PARAMS   => 'params',
    ID       => 'id'
  );

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'snmputils_binding',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->snmp_binding_info($attr->{ID}),
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub snmp_binding_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query(
    $db, "SELECT  uid,
    binding,
    comments,
    params
    FROM snmputils_binding
   WHERE id='$id';"
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  ($self->{UID}, $self->{BINDING}, $self->{COMMENTS}, $self->{PARAMS}) = @{ $self->{list}->[0] };

  return $self;
}

#**********************************************************
# accounts_list
#**********************************************************
sub snmputils_binding_list {
  my $self = shift;
  my ($attr) = @_;

  $PAGE_ROWS = ($attr->{PAGE_ROWS})     ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})          ? $attr->{SORT}      : 1;
  $DESC      = (defined($attr->{DESC})) ? $attr->{DESC}      : 'DESC';

  @WHERE_RULES = ();

  if ($attr->{BINDING}) {
    $attr->{BINDING} =~ s/\*/\%/ig;
    push @WHERE_RULES, "b.binding LIKE '$attr->{BINDING}'";
  }
  elsif ($attr->{IDS}) {

    #push @WHERE_RULES, "b.binding IN ($attr->{IDS})";

    $self->query(
      $db, "SELECT u.id, b.binding,  b.params, b.comments, b.id, 
            b.uid,
            if(u.company_id > 0, cb.deposit+u.credit, ub.deposit+u.credit),
            u.disable
            from (snmputils_binding b)
            INNER JOIN users u ON (b.uid = u.uid)
            LEFT JOIN bills ub ON (u.bill_id = ub.id)
            LEFT JOIN companies company ON  (u.company_id=company.id)
            LEFT JOIN bills cb ON  (company.bill_id=cb.id)
            WHERE b.binding IN ($attr->{IDS})
            ORDER BY $SORT $DESC
            LIMIT $PG, $PAGE_ROWS;"
    );

    my $list = $self->{list};
    return $list;
  }

  if ($attr->{PARAMS}) {
    $attr->{PARAMS} =~ s/\*/\%/ig;
    push @WHERE_RULES, "b.params LIKE '$attr->{PARAMS}'";
  }

  if ($attr->{UID}) {
    push @WHERE_RULES, "u.uid = '$attr->{UID}'";
  }

  if ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  $self->query(
    $db, "SELECT u.id, b.binding,  b.params, b.comments, b.id, b.uid 
            from (snmputils_binding b)
            LEFT JOIN users u ON (u.uid = b.uid)
            $WHERE
            ORDER BY $SORT $DESC
            LIMIT $PG, $PAGE_ROWS;"
  );

  my $list = $self->{list};

  return $list;
}

1
