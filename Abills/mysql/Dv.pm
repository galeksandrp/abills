package Dv;
# Dialup & Vpn  managment functions
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
@ISA  = ("main");

my $uid;


my %SEARCH_PARAMS = (TARIF_PLAN => 0, 
   SIMULTANEONSLY => 0, 
   DISABLE => 0, 
   IP => '0.0.0.0', 
   NETMASK => '255.255.255.255', 
   SPEED => 0, 
   FILTER_ID => '', 
   CID => '', 
   REGISTRATION => ''
);

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  return $self;
}




#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  my $WHERE;
  #my $PASSWORD = '0'; 
  
  $self->query($db, "SELECT dv.uid, dv.tp_id, 
   tp.name, 
   dv.logins, 
    INET_NTOA(dv.ip), 
   INET_NTOA(dv.netmask), 
   dv.speed, 
   dv.filter_id, 
   dv.cid,
   dv.disable
     FROM dv_main dv
     LEFT JOIN tarif_plans tp ON (dv.tp_id=tp.id)
     WHERE dv.uid='$uid';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{UID},
   $self->{TP_ID}, 
   $self->{TP_NAME}, 
   $self->{SIMULTANEONSLY}, 
   $self->{IP}, 
   $self->{NETMASK}, 
   $self->{SPEED}, 
   $self->{FILTER_ID}, 
   $self->{CID},
   $self->{DISABLE},
   $self->{REGISTRATION}
  )= @$ar;
  
  
  return $self;
}



#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
   TARIF_PLAN => 0, 
   SIMULTANEONSLY => 0, 
   DISABLE => 0, 
   IP => '0.0.0.0', 
   NETMASK => '255.255.255.255', 
   SPEED => 0, 
   FILTER_ID => '', 
   CID => '',
  );

 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO dv_main (uid, registration, tp_id, 
             logins, disable, ip, netmask, speed, filter_id, cid)
        VALUES ('$DATA{UID}', now(),
        '$DATA{TARIF_PLAN}', '$DATA{SIMULTANEONSLY}', '$DATA{DISABLE}', INET_ATON('$DATA{IP}'), 
        INET_ATON('$DATA{NETMASK}'), '$DATA{SPEED}', '$DATA{FILTER_ID}', LOWER('$DATA{CID}'));", 'do');
  
  return $self if ($self->{errno});
  
  $admin->action_add($uid, "ADDED");
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (SIMULTANEONSLY => 'logins',
              DISABLE          => 'disable',
              IP               => 'ip',
              NETMASK          => 'netmask',
              TARIF_PLAN       => 'tp_id',
              SPEED            => 'speed',
              CID              => 'cid',
              UID              => 'uid',
              FILTER_ID        => 'filter_id'
             );

print "$attr->{TARIF_PLAN} ---";

	$self->changes($admin,  { CHANGE_PARAM => 'UID',
		               TABLE        => 'dv_main',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->info($attr->{UID}),
		               DATA         => $attr
		              } );

  return $self->{result};
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "DELETE from dv_main WHERE uid='$self->{UID}';", 'do');

  $admin->action_add($uid, "DELETE");
  return $self->{result};
}



1