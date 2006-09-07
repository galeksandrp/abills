package Companies;
# Companies
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


#**********************************************************
# Init 
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
# Add
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;


  my $name = (defined($attr->{COMPANY_NAME})) ? $attr->{COMPANY_NAME} : '';
  
  if ($name eq '') {
    $self->{errno} = 8;
    $self->{errstr} = 'ERROR_ENTER_NAME';
    return $self;
   }

  my %DATA = $self->get_data($attr); 
  $self->query($db, "INSERT INTO companies (name, tax_number, bank_account, bank_name, cor_bank_account, 
     bank_bic, disable, credit, address, phone) 
     VALUES ('$DATA{COMPANY_NAME}', '$DATA{TAX_NUMBER}', '$DATA{BANK_ACCOUNT}', '$DATA{BANK_NAME}', '$DATA{COR_BANK_ACCOUNT}', 
      '$DATA{BANK_BIC}', '$DATA{DISABLE}', '$DATA{CREDIT}',
      '$DATA{ADDRESS}', '$DATA{PHONE}'
      );", 'do');

  return $self;
}


#**********************************************************
# Change
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;


  if($attr->{create}) {
  	 use Bills;
  	 my $Bill = Bills->new($db, $admin);
  	 $Bill->create({ COMPANY_ID => $attr->{COMPANY_ID} });
     if($Bill->{errno}) {
       $self->{errno}  = $Bill->{errno};
       $self->{errstr} =  $Bill->{errstr};
       return $self;
      }
     $attr->{BILL_ID}=$Bill->{BILL_ID};
   }


 
 my %FIELDS = (
   COMPANY_NAME   => 'name', 
   TAX_NUMBER     => 'tax_number', 
   BANK_ACCOUNT   => 'bank_account', 
   BANK_NAME      => 'bank_name', 
   COR_BANK_ACCOUNT => 'cor_bank_account', 
   BANK_BIC       => 'bank_bic',
   DISABLE        => 'disable',
   CREDIT         => 'credit',
   BILL_ID        => 'bill_id',
   COMPANY_ID     => 'id',
   ADDRESS        => 'address',
   PHONE          => 'phone'
   );

	$self->changes($admin, { CHANGE_PARAM => 'COMPANY_ID',
		               TABLE        => 'companies',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->info($attr->{COMPANY_ID}),
		               DATA         => $attr
		              } );


  $self->info($attr->{COMPANY_ID});

  return $self;
}


#**********************************************************
# Del
#**********************************************************
sub del {
  my $self = shift;
  my ($company_id) = @_;
  $self->query($db, "DELETE FROM companies WHERE id='$company_id';", 'do');
  return $self;
}


#**********************************************************
# Info
#**********************************************************
sub info {
  my $self = shift;
  my ($company_id) = @_;

  $self->query($db, "SELECT c.id, c.name, c.credit, c.tax_number, c.bank_account, c.bank_name, 
  c.cor_bank_account, c.bank_bic, c.disable, c.bill_Id, b.deposit,
  c.address, c.phone
    FROM companies c
    LEFT JOIN bills b ON (c.bill_id=b.id)
    WHERE c.id='$company_id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $a_ref = $self->{list}->[0];

  ($self->{COMPANY_ID}, 
   $self->{COMPANY_NAME}, 
   $self->{CREDIT}, 
   $self->{TAX_NUMBER}, 
   $self->{BANK_ACCOUNT}, 
   $self->{BANK_NAME}, 
   $self->{COR_BANK_ACCOUNT}, 
   $self->{BANK_BIC},
   $self->{DISABLE},
   $self->{BILL_ID},
   $self->{DEPOSIT},
   $self->{ADDRESS},
   $self->{PHONE}
   ) = @$a_ref;
    
  return $self;
}



#**********************************************************
# List
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;
 my $WHERE = '';
 
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 if ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    $WHERE .= ($WHERE ne '') ?  " and c.name LIKE '$attr->{LOGIN_EXPR}' " : "WHERE c.name LIKE '$attr->{LOGIN_EXPR}' ";
  }

 $self->query($db, "SELECT c.name, b.deposit, c.registration, count(u.uid), c.disable, c.id, c.disable, c.bill_id
    FROM companies  c
    LEFT JOIN users u ON (u.company_id=c.id)
    LEFT JOIN bills b ON (b.id=c.bill_id)
    $WHERE
    GROUP BY c.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");
 my $list = $self->{list};

    $self->query($db, "SELECT count(c.id) FROM companies c $WHERE;");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;

#  $self->{list}=$list;

return $list;
}





1