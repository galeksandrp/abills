package Netlist;
#Nas Server configuration and managing
 
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);


my $db;
use main;
@ISA  = ("main");
my $CONF;
my $SECRETKEY = '';

sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  #$self->{debug}=1;
  return $self;
}

#**********************************************************
# list
#**********************************************************
sub groups_list() {
  my $self = shift;
  my ($attr) = @_;

 $self->query($db, "SELECT ng.name, ng.comments, count(ni.ip), ng.id
    FROM netlist_groups ng
    LEFT JOIN netlist_ips ni ON (ng.id=ni.gid)
    GROUP BY ng.id
    ORDER BY $SORT $DESC;");

 return $self->{list};
}


#**********************************************************
# Add
#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  
  %DATA = $self->get_data($attr); 

  $self->query($db, "INSERT INTO netlist_groups (name, comments)
    values ('$DATA{NAME}', '$DATA{COMMENTS}');", 'do');

  return $self;
}


#**********************************************************
# change
#**********************************************************
sub group_change {
  my $self = shift;
  my ($attr) = @_;


  my %FIELDS = ( ID       => 'id', 
                 NAME     => 'name',
                 COMMENTS => 'comments'
                );   
 
	$self->changes($admin, { CHANGE_PARAM => 'ID',
		                TABLE        => 'netlist_groups',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->group_info($attr->{ID}, $attr),
		                DATA         => $attr
		              } );
 
	return $self;
}

#**********************************************************
# del
#**********************************************************
sub group_del {
  my $self = shift;
  my ($id) = @_;
  	
  $self->query($db, "DELETE FROM netlist_groups WHERE id='$id';", 'do');
  
 return $self;
}

#**********************************************************
# Info
#**********************************************************
sub group_info {
  my $self = shift;
  my ($id, $attr) = @_;
  
  

  $self->query($db, "SELECT id, 
       name,
       comments
    FROM netlist_groups
    WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];
  
  ($self->{ID}, 
   $self->{NAME}, 
   $self->{COMMENTS}
  ) = @$ar;


  return $self;
}



#**********************************************************
# list
#**********************************************************
sub ip_list() {
  my $self = shift;
  my ($attr) = @_;

 $self->query($db, "SELECT INET_NTOA(ip), INET_NTOA(netmask), hostname, status, ip
    FROM netlist_ips
    GROUP BY ip
    ORDER BY $SORT $DESC;");

 return $self->{list};
}


#**********************************************************
# Add
#**********************************************************
sub ip_add {
  my $self = shift;
  my ($attr) = @_;

 
  %DATA = $self->get_data($attr); 

  $self->query($db, "INSERT INTO netlist_ips (ip, netmask, hostname, 
     gid,
     status,
     comments,
     date,
     aid)
    values (INET_ATON('$DATA{IP}'), INET_ATON('$DATA{NETMASK}'), '$DATA{HOSTNAME}',
      '$DATA{GID}',
      '$DATA{STATUS}',
      '$DATA{COMMENTS}',
      now(),
      '$admin->{AID}'
     );", 'do');

  return $self;
}


#**********************************************************
# change
#**********************************************************
sub ip_change {
  my $self = shift;
  my ($attr) = @_;


  my %FIELDS = ( IP        => 'ip', 
                 NETMASK   => 'netmask',
                 HOSTNAME  => 'hostname',
                 GID       => 'gid',
                 STATUS    => 'status',
                 COMMENTS  => 'comments'
                );   
 
	$self->changes($admin, { CHANGE_PARAM => 'IP',
		                TABLE        => 'netlist_ips',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->group_info($attr->{IP}, $attr),
		                DATA         => $attr
		              } );
 
	return $self;
}

#**********************************************************
# del
#**********************************************************
sub ip_del {
  my $self = shift;
  my ($ip) = @_;
  	
  $self->query($db, "DELETE FROM netlist_ips WHERE ip='$ip';", 'do');
  
 return $self;
}

#**********************************************************
# Info
#**********************************************************
sub ip_info {
  my $self = shift;
  my ($ip, $attr) = @_;
  
  

  $self->query($db, "SELECT INET_NTOA(ip), 
       INET_NTOA(netmask),
       hostname,
       gid,
       status,
       comments
    FROM netlist_ips
    WHERE ip='$ip';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];
  
  ($self->{IP}, 
   $self->{NETMASK}, 
   $self->{HOSTNAME},
   $self->{GID},
   $self->{STATUS},
   $self->{COMMENTS}
  ) = @$ar;


  return $self;
}

1