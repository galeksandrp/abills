package Abon;
# Periodic payments  managment functions
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

my $MODULE='Abon';

@ISA  = ("main");
my $uid;


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  
  $admin->{MODULE}=$MODULE;
  my $self = { };
  bless($self, $class);
  return $self;
}




#**********************************************************
# User information
# info()
#**********************************************************
sub tariff_info {
  my $self = shift;
  my ($id) = @_;

  my @WHERE_RULES  = ("id='$id'");
  my $WHERE = '';

 
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
  
  $self->query($db, "SELECT 
   name,
   period,
   price,
   id
     FROM abon_tariffs
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{NAME},
   $self->{PERIOD},
   $self->{SUM}, 
   $self->{ID}
  )= @$ar;
  

  
  return $self;
}



#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
   ID => 0, 
   PERIOD => 0, 
   SUM => '0.00'
  );

 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub tariff_add {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO abon_tariffs (id, name, period, price)
        VALUES ('$DATA{ID}', '$DATA{NAME}', '$DATA{PERIOD}', '$DATA{SUM}');", 'do');

  return $self if ($self->{errno});
#  $admin->action_add($DATA{UID}, "ADDED");
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub tariff_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ID        => 'id',
              NAME				=> 'name',
              PERIOD      => 'period',
              SUM         => 'price'
             );

  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'abon_tariffs',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->tariff_info($attr->{ID}),
                   DATA         => $attr
                  } );


  #$admin->action_add($DATA{UID}, "$self->{result}");

  return $self->{result};
}



#**********************************************************
# Delete user info from all tables
# del(attr);
#**********************************************************
sub tariff_del {
  my $self = shift;
  my ($id) = @_;

  $self->query($db, "DELETE from abon_tariffs WHERE uid='$id';", 'do');
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub tariff_list {
 my $self = shift;
 my ($attr) = @_;

# undef @WHERE_RULES;
# push @WHERE_RULES, "u.uid = service.uid";
# $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT name, price, period, id
     FROM abon_tariffs
     ORDER BY $SORT $DESC;");

  return $self->{list};
}



#**********************************************************
# user_tariffs()
#**********************************************************
sub user_tariff_list {
 my $self = shift;
 my ($uid, $attr) = @_;

# undef @WHERE_RULES;
# push @WHERE_RULES, "u.uid = service.uid";
# $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT id, name, price, period, ul.date, count(ul.uid)
     FROM abon_tariffs
     LEFT JOIN abon_user_list ul ON (abon_tariffs.id=ul.tp_id)
     GROUP BY id
     ORDER BY $SORT $DESC;");

 my $list = $self->{list};

 return $list;
}

#**********************************************************
# user_tariffs()
#**********************************************************
sub user_tariff_change {
 my $self = shift;
 my ($attr) = @_;


 $self->query($db, "DELETE from abon_user_list WHERE uid='$attr->{UID}';", 'do');

 
 my @tp_array = split(/, /, $attr->{IDS});
 my $abon_log = "";
 
 foreach my $tp_id (@tp_array) {
   $self->query($db, "INSERT INTO abon_user_list (uid, tp_id) VALUES ('$attr->{UID}', '$tp_id');", 'do');
   $abon_log.="$tp_id, ";
  }


 $admin->action_add($attr->{UID}, "$abon_log");
 return $self;
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