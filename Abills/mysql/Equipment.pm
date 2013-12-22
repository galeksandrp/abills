package Equipment;
#Equipment list


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

my $db;
use main;
use Socket;

@ISA = ("main");
my $CONF;
my $admin;
my $SECRETKEY = '';

sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  my $self = {};
  bless($self, $class);
  
  $self->{db}=$db;
  
  return $self;
}



#**********************************************************
# list
#**********************************************************
sub vendor_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->query2("SELECT id, name, support, site
    FROM equipment_vendors
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
# Add
#**********************************************************
sub vendor_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);
  $self->query_add('equipment_vendors', $attr);

  return $self;
}

#**********************************************************
# change
#**********************************************************
sub vendor_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_vendors',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub vendor_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM equipment_vendors WHERE id='$id';", 'do');

  return $self;
}



#**********************************************************
# Info
#**********************************************************
sub vendor_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT id, 
       name,
       support,
       site       
    FROM equipment_vendors
    WHERE id='$id';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# list
#**********************************************************
sub type_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->query2("SELECT id, name
    FROM equipment_types
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
# Add
#**********************************************************
sub type_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);
  $self->query_add('equipment_types', $attr);

  return $self;
}

#**********************************************************
# change
#**********************************************************
sub type_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_types',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub type_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM equipment_types WHERE id='$id';", 'do');

  return $self;
}



#**********************************************************
# Info
#**********************************************************
sub type_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT id, 
       name
    FROM equipment_types
    WHERE id='$id';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# list
#**********************************************************
sub model_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();

  if ($attr->{GID}) {
    my $value = $self->search_expr($attr->{GID}, 'INT');
    push @WHERE_RULES, "ni.gid$value";
  }

  if ($attr->{IP}) {
    push @WHERE_RULES, "ni.ip=INET_ATON('$attr->{IP}')";
  }

  if ($attr->{STATUS}) {
    push @WHERE_RULES, "ni.status='$attr->{STATUS}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT 
        m.model_name,
        v.name AS vendor_name,
        t.name AS type_name,
        m.ports,
        m.id
    FROM equipment_models m
    LEFT JOIN equipment_types t ON (t.id=m.type_id)
    LEFT JOIN equipment_vendors v ON (v.id=m.vendor_id)
    $WHERE
    GROUP BY m.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total
    FROM equipment_models m
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
# Add
#**********************************************************
sub model_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_models', $attr);

  return $self;
}

#**********************************************************
# change
#**********************************************************
sub model_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_models',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub model_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM equipment_models WHERE id='$id';", 'do');

  return $self;
}



#**********************************************************
# Info
#**********************************************************
sub model_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT id,
    type_id,
    vendor_id,
    model_name,
    site,
    ports,
    comments
    FROM equipment_models
    WHERE id='$id';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# list
#**********************************************************
sub _list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();

  if ($attr->{GID}) {
    my $value = $self->search_expr($attr->{GID}, 'INT');
    push @WHERE_RULES, "ni.gid$value";
  }

  if ($attr->{IP}) {
    push @WHERE_RULES, "ni.ip=INET_ATON('$attr->{IP}')";
  }

  if ($attr->{STATUS}) {
    push @WHERE_RULES, "ni.status='$attr->{STATUS}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT 
        i.nas_id,
        i.system_id,
        i.status,
        m.model_name,
        v.name AS vendor_name,
        t.name AS type_name,
        m.ports,
        m.id
    FROM equipment_infos i
    INNER JOIN equipment_models m ON (m.id=i.model_id)
    INNER JOIN equipment_types t ON (t.id=m.type_id)
    INNER JOIN equipment_vendors v ON (v.id=m.vendor_id)
    $WHERE
    GROUP BY i.nas_id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total
    FROM equipment_infos m
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
# Add
#**********************************************************
sub _add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_infos', $attr);

  return $self;
}

#**********************************************************
# change
#**********************************************************
sub _change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'NAS_ID',
      TABLE        => 'equipment_infos',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub _del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM equipment_infos WHERE nas_id='$id';", 'do');

  return $self;
}



#**********************************************************
# Info
#**********************************************************
sub _info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT  nas_id,
    model_id,
    system_id,
    ports,
    firmware1,
    firmware2,
    status
    FROM equipment_infos
    WHERE nas_id='$id';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

1
