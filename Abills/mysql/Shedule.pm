package Shedule;



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


my $db;
my $uid;
my $admin;
my $CONF;
my %DATA = ();


sub new {
  my $class = shift;
  ($db, $admin) = @_;
  my $self = { };
  bless($self, $class);
  return $self;
}



#**********************************************************
# list()
#**********************************************************
sub info {
 my $self = shift;
 my ($attr) = @_;
 
 @WHERE_RULES =();
 
 if ($attr->{UID}) {
    push @WHERE_RULES, "s.uid='$attr->{UID}'";
  }
 
 if ($attr->{TYPE}) {
    push @WHERE_RULES, "s.type='$attr->{TYPE}'";
  }

 if ($attr->{MODULE}) {
    push @WHERE_RULES, "s.module='$attr->{MODULE}'";
  }
 


 $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if($#WHERE_RULES > -1);

 

 
 $self->query($db, "SELECT s.h, s.d, s.m, s.y, s.counts, s.action, s.date, s.uid, s.id, a.id 
    FROM shedule s
    LEFT JOIN admins a ON (a.aid=s.aid) 
    $WHERE;");

 if ($self->{TOTAL} < 1) {
   $self->{errno} = 2;
   $self->{errstr} = 'ERROR_NOT_EXIST';
   return $self;
  }

 my $ar = $self->{list}->[0];

  ($self->{H}, 
   $self->{D}, 
   $self->{M}, 
   $self->{Y}, 
   $self->{COUNTS},
   $self->{ACTION},
   $self->{DATE}, 
   $self->{UID}, 
   $self->{SHEDULE_ID},
   $self->{ADMIN_NAME}
  )= @$ar;


 return $self;
}



#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 @WHERE_RULES =();
 
 if ($attr->{UID}) {
    push @WHERE_RULES, "s.uid='$attr->{UID}'";
  }
 
 if ($attr->{AID}) {
    push @WHERE_RULES, "s.aid='$attr->{AID}'";
  }

 if ($attr->{TYPE}) {
    push @WHERE_RULES, "s.type='$attr->{TYPE}'";
  }

 if ($attr->{Y}) {
    push @WHERE_RULES, "s.y='$attr->{Y}'";
  }

 if ($attr->{M}) {
    push @WHERE_RULES, "s.m='$attr->{M}'";
  }

 if ($attr->{D}) {
    push @WHERE_RULES, "s.d='$attr->{D}'";
  }


 if ($attr->{MODULE}) {
    push @WHERE_RULES, "s.module='$attr->{MODULE}'";
  }
 


 $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if($#WHERE_RULES > -1);
  
 $self->query($db, "SELECT s.h, s.d, s.m, s.y, s.counts, u.id, s.type, s.action, s.module, a.id, s.date, a.aid, s.uid, s.id  
    FROM shedule s
    LEFT JOIN users u ON (u.uid=s.uid)
    LEFT JOIN admins a ON (a.aid=s.aid) 
   $WHERE");

  return $self->{list};
}





#**********************************************************
# Add new shedule
# add($self)
#**********************************************************
sub add {
 my $self = shift;
 my ($attr) = @_;

 my $DESCRIBE=(defined($attr->{DESCRIBE})) ? $attr->{DESCRIBE} : '';
 my $H=(defined($attr->{H})) ? $attr->{H} : '*';
 my $D=(defined($attr->{D})) ? $attr->{D} : '*';
 my $M=(defined($attr->{M})) ? $attr->{M} : '*';
 my $Y=(defined($attr->{Y})) ? $attr->{Y} : '*';
 my $COUNT=(defined($attr->{COUNT})) ? int($attr->{COUNT}): 0;
 my $UID=(defined($attr->{UID})) ? int($attr->{UID}) : 0;
 my $TYPE=(defined($attr->{TYPE})) ? $attr->{TYPE} : '';
 my $ACTION=(defined($attr->{ACTION})) ? $attr->{ACTION} : '';
 my $MODULE=(defined($attr->{MODULE})) ? $attr->{MODULE} : '';
 
 $self->query($db, "INSERT INTO shedule (h, d, m, y, uid, type, action, aid, date, module) 
        VALUES ('$H', '$D', '$M', '$Y', '$UID', '$TYPE', '$ACTION', '$admin->{AID}', now(), '$MODULE');", 'do');

 if ($self->{errno}) {
     $self->{errno} = 7;
     $self->{errstr} = 'ERROR_DUBLICATE';
     return $self;
   }

 return $self;	
}





#**********************************************************
# Add new shedule
# add($self)
#**********************************************************
sub del {
 my $self = shift;
 my ($attr) = @_;

 $self->query($db, "DELETE FROM shedule WHERE id='$attr->{ID}';", 'do');
 
 # $admin->action_add($user->{UID}, "DELETE SHEDULE $id");
 return $self;	
}


1