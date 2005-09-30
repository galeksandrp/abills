package Finance;
# Finance module
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw(
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();


use main;
@ISA  = ("main");
use Bills;



#**********************************************************
# Init Finance module
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
# fees
#**********************************************************
sub fees {
  my $class = shift;
  ($db, $admin) = @_;


  use Fees;
  my $fees = Fees->new($db, $admin);
  return $fees;
}


#**********************************************************
# Init 
#**********************************************************
sub payments {
  my $class = shift;
  ($db, $admin) = @_;

  use Payments;
  my $payments = Payments->new($db, $admin);
  return $payments;
}

#**********************************************************
# exchange_list
#**********************************************************
sub exchange_list {
	my $self = shift;
  my ($attr) = @_;
  
 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
# my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
# my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 $self->query($db, "SELECT money, short_name, rate, changed, id 
    FROM exchange_rate
    ORDER BY $SORT $DESC;");

 return $self->{list};
}


#**********************************************************
# exchange_add
#**********************************************************
sub exchange_add {
	my $self = shift;
  my ($money, $short_name, $rate) = @_;
  
  my $self->query($db, "INSERT INTO exchange_rate (money, short_name, rate, changed) 
   values ('$money', '$short_name', '$rate', now());", 'do');

	return $self;
}


#**********************************************************
# exchange_del
#**********************************************************
sub exchange_del {
	my $self = shift;
  my ($id) = @_;
  my $self->query($db, "DELETE FROM exchange_rate WHERE id='$id';", 'do');

	return $self;
}


#**********************************************************
# exchange_change
#**********************************************************
sub exchange_change {
	my $self = shift;
  my ($id, $money, $short_name, $rate) = @_;
 
  $self->query($db, "UPDATE exchange_rate SET
    money='$money', 
    short_name='$short_name', 
    rate='$rate',
    changed=now()
   WHERE id='$id';", 'do');

	return $self;
}


#**********************************************************
# exchange_info
#**********************************************************
sub exchange_info {
	my $self = shift;
  my ($id) = @_;

  $self->query($db, "SELECT money, short_name, rate FROM exchange_rate WHERE id='$id';");
  my $ar = $self->{list}->[0];
  ($self->{MU_NAME}, 
   $self->{MU_SHORT_NAME}, 
   $self->{EX_RATE})=@$ar;

	return $self;
}

1