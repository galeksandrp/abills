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
 
 my $WHERE;
 
 $self->query($db, "SELECT s.h, s.d, s.m, s.y, s.counts, s.action, s.date, s.uid, s.id  
    FROM shedule s
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
   $self->{SHEDULE_ID}
  )= @$ar;


 return $self;
}



#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 my $WHERE  = '';

 if ($attr->{UID}) {
    $WHERE .= ($WHERE ne '') ?  " and s.uid='$attr->{UID}' " : "WHERE s.uid='$attr->{UID}' ";
  }
 
 if ($attr->{AID}) {
    $WHERE .= ($WHERE ne '') ?  " and s.aid='$attr->{AID}' " : "WHERE s.aid='$attr->{AID}' ";
  }

 if ($attr->{TYPE}) {
    $WHERE .= ($WHERE ne '') ?  " and s.type='$attr->{TYPE}' " : "WHERE s.type='$attr->{TYPE}' ";
  }

 if ($attr->{Y}) {
    $WHERE .= ($WHERE ne '') ?  " and s.y='$attr->{Y}' " : "WHERE s.y='$attr->{Y}' ";
  }

 if ($attr->{M}) {
    $WHERE .= ($WHERE ne '') ?  " and s.m='$attr->{M}' " : "WHERE s.m='$attr->{M}' ";
  }

 if ($attr->{D}) {
    $WHERE .= ($WHERE ne '') ?  " and s.d='$attr->{D}' " : "WHERE s.d='$attr->{D}' ";
  }


 $self->query($db, "SELECT s.h, s.d, s.m, s.y, s.counts, u.id, s.type, s.action, a.id, s.date, a.aid, s.uid, s.id  
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
  
 my $sql = "INSERT INTO shedule (h, d, m, y, uid, type, action, aid, date) 
        VALUES ('$H', '$D', '$M', '$Y', '$UID', '$TYPE', '$ACTION', '$admin->{AID}', now());";
#print $sql;
 my $q = $db->do($sql);

 if ($db->err == 1062) {
     $self->{errno} = 7;
     $self->{errstr} = 'ERROR_DUBLICATE';
     return $self;
   }
 elsif($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
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
 my ($id) = @_;

 $self->query($db, "DELETE FROM shedule WHERE id='$id';", 'do');
 
 # $admin->action_add($user->{UID}, "DELETE SHEDULE $id");
 return $self;	
}


1