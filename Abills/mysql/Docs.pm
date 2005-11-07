package Docs;
# Users manage functions
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
#  $self->{debug}=1;
  return $self;
}








#**********************************************************
# Bill
#**********************************************************
sub create {
	my $self = shift;
	my ($attr) = @_;
  my %DATA = $self->get_data($attr); 

  $self->query($db, "INSERT INTO bills (deposit, uid, company_id, registration) 
    VALUES ('$DATA{DEPOSIT}', '$DATA{UID}', '$DATA{COMPANY_ID}', now());", 'do');	

  return $self if ($self->{errno});

#  $admin->action_add($uid, "ADD BILL [$self->{INSERT_ID}]");
  
  
  $self->{BILL_ID} = $self->{INSERT_ID};
	
	return $self;
}

#**********************************************************
# Bill add sum to bill
# Type:
#  add
#  take
#**********************************************************
sub action {
	my $self = shift;
	my ($type, $BILL_ID, $SUM, $attr) = @_;
  my $value = '';
  
  if ($type eq 'take') {
  	 $value = "-$SUM";
   }
  elsif($type eq 'add') {
     $value = "+$SUM";
   }

  $self->query($db, "UPDATE bills SET deposit=deposit$value WHERE id='$BILL_ID';", 'do');	
  return $self if($db->err > 0);
#  $admin->action_add($uid, "ADD BILL [$self->{INSERT_ID}]");
	
	return $self;
}


#**********************************************************
# Bill
#**********************************************************
sub change {
	my $self = shift;
	my ($attr) = @_;

	my %FIELDS = (BILL_ID    => 'id',
	              UID        => 'uid', 
	              COMPANY_ID => 'company_id',
	              SUM        => 'sum'); 

 	$self->changes($admin, { CHANGE_PARAM => 'BILL_ID',
		                TABLE        => 'bills',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->bill_info($attr->{BILL_ID}),
		                DATA         => $attr
		              } );


	
	return $self;
}


#**********************************************************
# Bill
#**********************************************************
sub accounts_list {
  my $self = shift;
  my ($attr) = @_;
	

 @WHERE_RULES = ("d.id=o.aid");
 
 #DIsable
 if ($attr->{UID}) {
   push @WHERE_RULES, "d.uid='$attr->{UID}'"; 
 }
 

 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


$self->{debug}=1;

  $self->query($db,   "SELECT d.aid, d.date, d.customer,  sum(o.price * o.counts), u.id, d.maked, d.time, d.uid
    FROM docs_acct d, acct_orders o
    LEFT JOIN users u ON (d.uid=u.uid)
    $WHERE
    GROUP BY d.id 
    ORDER BY $SORT $DESC;");



 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};


 $self->query($db, "SELECT count(*)
    FROM docs_acct d,acct_orders o    
    LEFT JOIN users u ON (d.uid=u.uid)
    $WHERE
    GROUP BY d.id");

 my $a_ref = $self->{list}->[0];

 ($self->{TOTAL}, 
  $self->{SUM}) = @$a_ref;


 #LIMIT $PG, $PAGE_ROWS
	 
	return $list;
}


#**********************************************************
# Bill
#**********************************************************
sub account_del {
	my $self = shift;
	my ($id, $attr) = @_;

   $self->query($db, "DELETE FROM acct_orders WHERE aid='$id'", 'do');
   $self->query($db, "DELETE FROM docs_acct WHERE id='$id'", 'do');

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub info {
	my $self = shift;
	my ($attr) = @_;

  $self->query($db, "SELECT b.id, b.deposit, u.id, b.uid, b.company_id
    FROM bills b
    LEFT JOIN users u ON (u.uid = b.uid)
    WHERE b.id='$attr->{BILL_ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{BILL_ID}, 
   $self->{DEPOSIT}, 
   $self->{LOGIN}, 
   $self->{UID}, 
   $self->{COMPANY_ID}, 
  )= @$ar;
	

	return $self;
}


##**********************************************************
## get_bill_id($self, $ussr, $attr);
##**********************************************************
#sub get_bill_id {
#  my $self = shift;
#	my ($attr) = @_;
#
#  if ($user->{COMPANY_ID} > 0) {
#  	$sql = "SELECT bill_id FROM companies WHERE id='$user->{COMPANY_ID}';";
#   }
#  else {
#    $sql = "SELECT bill_id FROM users WHERE uid='$user->{UID}';";
#   }
#  $self->query($db, "$sql");
#
#  return $id;
#}









1