package Docs;

# Documents functions functions
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
my $MODULE = 'Docs';

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;
  my $self = {};
  bless($self, $class);
  $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} = 30 if (!$CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD});
  return $self;
}

#**********************************************************
# Default values
#**********************************************************
sub invoice_defaults {
  my $self = shift;

  %DATA = (
    SUM             => '0.00',
    COUNTS          => 1,
    UNIT            => 1,
    PAYMENT_ID      => 0,
    PHONE           => '',
    VAT             => '',
    DEPOSIT         => 0,
    DELIVERY_STATUS => 0,
    EXCHANGE_RATE   => 0,
    DOCS_CURRENCY   => 0,
    CUSTOMER        => '',
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# invoices_list
#**********************************************************
sub docs_receipt_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ("d.id=o.receipt_id");

  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }
  elsif ($attr->{CUSTOMER}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{CUSTOMER}, 'STR', 'd.customer') };
  }

  if ($attr->{AID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{AID}, 'STR', 'a.id') };
  }

  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

  if ($attr->{DOC_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DOC_ID}, 'INT', 'd.receipt_num') };
  }

  if ($attr->{SUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'o.price * o.counts') };
  }

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if (defined($attr->{PAYMENT_METHOD}) && $attr->{PAYMENT_METHOD} ne '') {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PAYMENT_METHOD}, 'INT', 'p.method') };
  }

  if (defined($attr->{PAYMENT_ID})) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PAYMENT_ID}, 'INT', 'd.payment_id') };
  }

  #DIsable
  if ($attr->{UID}) {
    push @WHERE_RULES, "d.uid='$attr->{UID}'";
  }

  if ($attr->{FULL_INFO}) {
    $self->{EXT_FIELDS} = ",
 	 pi.address_street,
   pi.address_build,
   pi.address_flat,
   if (d.phone<>0, d.phone, pi.phone),
   pi.contract_id,
   pi.contract_date,
   u.id,
   u.company_id";
  }

  $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  if ($attr->{ORDERS_LIST}) {
    $self->query(
      $db, "SELECT  o.receipt_id,  o.orders,  o.unit,  o.counts,  o.price,  o.fees_id
      FROM  (docs_receipts d, docs_receipt_orders o) 
     $WHERE;"
    );

    return $self->{list} if ($self->{TOTAL} < 1);
    my $list = $self->{list};
    return $list;
  }

  $self->query(
    $db, "SELECT d.receipt_num, d.date, if(d.customer='-' or d.customer='', pi.fio, d.customer), sum(o.price * o.counts), u.id, a.name, d.created, p.method, d.uid, d.id, p.id $self->{EXT_FIELDS}
    FROM (docs_receipts d, docs_receipt_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN payments p ON (d.payment_id=p.id)
    $WHERE
    GROUP BY d.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;"
  );

  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  $self->query(
    $db, "SELECT count(DISTINCT d.receipt_num)
    FROM (docs_receipts d, docs_receipt_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN payments p ON (d.payment_id=p.id)
    $WHERE"
  );

  ($self->{TOTAL}) = @{ $self->{list}->[0] };

  return $list;
}

#**********************************************************
# docs_receipt_new
#**********************************************************
sub docs_receipt_new {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  undef @WHERE_RULES;

  if ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'f.uid') };
  }
  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }

  if ($attr->{BILL_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{BILL_ID}, 'INT', 'f.bill_id') };
  }
  elsif ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'u.company_id') };
  }

  if ($attr->{AID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{AID}, 'INT', 'f.aid') };
  }

  if ($attr->{ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{ID}, 'INT', 'f.id') };
  }

  if ($attr->{A_LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{A_LOGIN}, 'STR', 'a.id') };
  }

  if ($attr->{DOMAIN_ID}) {
    push @WHERE_RULES, "u.domain_id='$attr->{DOMAIN_ID}' ";
  }

  # Show debeters
  if ($attr->{DESCRIBE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DESCRIBE}, 'STR', 'f.dsc') };
  }

  if ($attr->{INNER_DESCRIBE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{INNER_DESCRIBE}, 'STR', 'f.inner_describe') };
  }

  if (defined($attr->{METHOD}) && $attr->{METHOD} >= 0) {
    push @WHERE_RULES, "f.method IN ($attr->{METHOD}) ";
  }

  if ($attr->{SUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'f.sum') };
  }

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  # Date
  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, @{ $self->search_expr(">=$attr->{FROM_DATE}", 'DATE', 'date_format(f.date, \'%Y-%m-%d\')') }, @{ $self->search_expr("<=$attr->{TO_DATE}", 'DATE', 'date_format(f.date, \'%Y-%m-%d\')') };
  }
  elsif ($attr->{DATE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DATE}, 'DATE', 'date_format(f.date, \'%Y-%m-%d\')') };
  }

  # Month
  elsif ($attr->{MONTH}) {
    push @WHERE_RULES, "date_format(f.date, '%Y-%m')='$attr->{MONTH}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  $self->query(
    $db, "SELECT f.id, u.id, f.date, f.dsc, f.sum, io.fees_id,
f.last_deposit, 
f.method, f.bill_id, if(a.name is NULL, 'Unknown', a.name), 
INET_NTOA(f.ip), f.uid, f.inner_describe 
FROM fees f 
LEFT JOIN users u ON (u.uid=f.uid) 
LEFT JOIN admins a ON (a.aid=f.aid) 
LEFT JOIN docs_receipt_orders io ON (io.fees_id=f.id) 
$WHERE
GROUP BY f.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;"
  );

  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  return $list;
}

#**********************************************************
# Bill
#**********************************************************
sub docs_receipt_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';

  $self->query(
    $db, "SELECT 
   d.receipt_num,
   d.date,
   d.customer,
   sum(o.price * o.counts), 
   d.phone,
   if(d.vat>0, FORMAT(sum(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)),
   a.name,
   u.id,
   d.created,
   d.by_proxy_seria,
   d.by_proxy_person,
   d.by_proxy_date,
   d.id,
   d.uid,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day,
   d.payment_id,
   d.deposit,
   d.delivery_status,
   d.exchange_rate,
   d.currency

    FROM (docs_receipts d)
    LEFT JOIN  docs_receipt_orders o ON (d.id=o.receipt_id)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    WHERE d.id='$id' $WHERE
    GROUP BY d.id;"
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  (
    $self->{RECEIPT_NUM},     $self->{DATE},          $self->{CUSTOMER}, $self->{TOTAL_SUM}, $self->{PHONE},       $self->{VAT},        $self->{ADMIN},   $self->{LOGIN},           $self->{CREATED},       $self->{BY_PROXY_SERIA},
    $self->{BY_PROXY_PERSON}, $self->{BY_PROXY_DATE}, $self->{DOC_ID},   $self->{UID},       $self->{EXPIRE_DATE}, $self->{PAYMENT_ID}, $self->{DEPOSIT}, $self->{DELIVERY_STATUS}, $self->{EXCHANGE_RATE}, $self->{CURRENCY}
  ) = @{ $self->{list}->[0] };

  $self->{AMOUNT_FOR_PAY} = ($self->{DEPOSIT} < 0) ? abs($self->{DEPOSIT}) : 0 - $self->{DEPOSIT};

  if ($self->{TOTAL} > 0) {
    $self->{NUMBER} = $self->{RECEIPT_NUM};
    $self->query(
      $db, "SELECT receipt_id, orders, unit, counts, price, fees_id, '$self->{LOGIN}'
      FROM docs_receipt_orders WHERE receipt_id='$id'"
    );
    $self->{ORDERS} = $self->{list};
  }

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub docs_receipt_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });

  if ($attr->{ORDER}) {
    push @{ $attr->{ORDERS} }, "$attr->{ORDER}|0|1|$attr->{SUM}";
  }

  if (!$attr->{ORDERS} && !$attr->{IDS}) {
    $self->{errno}  = 1;
    $self->{errstr} = "No orders";
    return $self;
  }

  $DATA{DATE} = ($attr->{DATE}) ? "'$attr->{DATE}'" : 'now()';
  $DATA{RECEIPT_NUM} = ($attr->{RECEIPT_NUM}) ? $attr->{RECEIPT_NUM} : $self->docs_nextid({ TYPE => 'RECEIPT' });

  $self->query(
    $db, "insert into docs_receipts (receipt_num, date, created, customer, phone, aid, uid,
    by_proxy_seria,
    by_proxy_person,
    by_proxy_date,
    payment_id,
    deposit,
    delivery_status,
    exchange_rate, currency)
      values ('$DATA{RECEIPT_NUM}', $DATA{DATE}, now(), '$DATA{CUSTOMER}', '$DATA{PHONE}', 
      '$admin->{AID}', '$DATA{UID}',
      '$DATA{BY_PROXY_SERIA}',
      '$DATA{BY_PROXY_PERSON}',
      '$DATA{BY_PROXY_DATE}',
      '$DATA{PAYMENT_ID}',
      '$DATA{DEPOSIT}',
      '$DATA{DELIVERY_STATUS}',
      '$DATA{EXCHANGE_RATE}', '$DATA{DOCS_CURRENCY}'
      );", 'do'
  );

  return $self if ($self->{errno});
  $self->{DOC_ID} = $self->{INSERT_ID};

  if ($attr->{ORDERS}) {
    foreach my $line (@{ $attr->{ORDERS} }) {
      my ($order, $unit, $count, $sum, $fees_id) = split(/\|/, $line, 4);

      $self->query(
        $db, "INSERT INTO docs_receipt_orders (receipt_id, orders, counts, unit, price, fees_id)
        values ('$self->{DOC_ID}', '$order', '$count', '$unit', '$sum', '$fees_id')", 'do'
      );
    }
  }
  else {
    my @ids = split(/, /, $attr->{IDS});
    foreach my $id (@ids) {
      my $sql = "INSERT INTO docs_receipt_orders (receipt_id, orders, counts, unit, price, fees_id)
        values ($self->{DOC_ID}, '" . $DATA{ 'ORDER_' . $id } . "', '" . ((!$DATA{ 'COUNT_' . $id }) ? 1 : $DATA{ 'COUNT_' . $id }) . "', '" . $DATA{ 'UNIT_' . $id } . "', '" . $DATA{ 'SUM_' . $id } . "', '" . $DATA{ 'FEES_ID_' . $id } . "')";
      $self->query($db, "$sql");
    }
  }

  return $self if ($self->{errno});
  $self->docs_receipt_info($self->{DOC_ID});
  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub docs_receipt_del {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {

    #$self->query($db, "DELETE FROM docs_receipt_orders WHERE receipt_id='$id'", 'do');
    #$self->query($db, "DELETE FROM docs_receipts WHERE uid='$id'", 'do');
  }
  else {
    $self->query($db, "DELETE FROM docs_receipt_orders WHERE receipt_id='$id'", 'do');
    $self->query($db, "DELETE FROM docs_receipts WHERE id='$id'", 'do');
  }

  return $self;
}

#**********************************************************
# invoices_list
#**********************************************************
sub invoices_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  @WHERE_RULES = ("d.id=o.invoice_id");

  if ($SORT == 1) {
    $SORT = "2 DESC, 1";
    $DESC = "DESC";
  }

  if ($attr->{CUSTOMER}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{CUSTOMER}, 'STR', 'd.customer') };
  }
  elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }

  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

  if (defined($attr->{PAYMENT_ID})) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PAYMENT_ID}, 'INT', 'd.payment_id') };
  }

  if (defined($attr->{PAYMENT_METHOD}) && $attr->{PAYMENT_METHOD} ne '') {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PAYMENT_METHOD}, 'INT', 'p.method') };
  }

  if (defined($attr->{COMPANY_ID}) && $attr->{COMPANY_ID} ne '') {
    push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'u.company_id') };
  }

  if ($attr->{DOC_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DOC_ID}, 'INT', 'd.invoice_num') };
  }

  if ($attr->{BILL_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{BIL_ID}, 'INT', 'p.bill_id', { EXT_FIELDS => 1 }) };
  }

  if ($attr->{SUM}) {
    my $value = $self->search_expr($attr->{SUM}, 'INT');
    push @WHERE_RULES, "o.price * o.counts$value";
  }

  if ($attr->{AID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{AID}, 'STR', 'a.id') };
  }

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if ($attr->{PAID_STATUS}) {
    push @WHERE_RULES, "d.payment_id" . (($attr->{PAID_STATUS} == 1) ? '>\'0' : '=\'0') . "'";
  }

  #DIsable
  if ($attr->{UID}) {
    push @WHERE_RULES, "d.uid='$attr->{UID}'";
  }

  $self->{EXT_FIELDS} = '';
  if ($attr->{FULL_INFO}) {
    $self->{EXT_FIELDS} = ",
 	 pi.address_street,
   pi.address_build,
   pi.address_flat,
   if (d.phone<>0, d.phone, pi.phone),
   pi.contract_id,
   pi.contract_date,
   if(u.company_id > 0, c.bill_id, u.bill_id),
   u.company_id";
  }

  if ($attr->{CONTRACT_ID}) {
    push @WHERE_RULES, '(' . join('', @{ $self->search_expr($attr->{CONTRACT_ID}, 'STR', 'concat(pi.contract_sufix,pi.contract_id)') }) . ' OR ' . join('', @{ $self->search_expr($attr->{CONTRACT_ID}, 'STR', 'concat(c.contract_sufix,c.contract_id)') }) . ')';
  }

  $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';
  $self->query(
    $db, "SELECT d.invoice_num, d.date, if(d.customer='-' or d.customer='', pi.fio, d.customer),sum(o.price * o.counts), 
     d.payment_id, u.id, a.name, d.created, p.method, p.ext_id, g.name, 
     if (d.exchange_rate>0, sum(o.price * o.counts) * d.exchange_rate, 0.00),
     d.uid, d.id, u.company_id, c.name, if(u.company_id=0, concat(pi.contract_sufix,pi.contract_id), concat(c.contract_sufix,c.contract_id)), d.currency
     $self->{SEARCH_FIELDS}
     $self->{EXT_FIELDS}
    FROM (docs_invoices d, docs_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN groups g ON (g.gid=u.gid)
    LEFT JOIN companies c ON (u.company_id=c.id)
    LEFT JOIN payments p ON (d.payment_id=p.id)
    $WHERE
    GROUP BY d.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;"
  );

  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  $self->query(
    $db, "SELECT count(*)
    FROM (docs_invoices d, docs_invoice_orders o)    
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN payments p ON (d.payment_id=p.id)
    $WHERE"
  );

  ($self->{TOTAL}) = @{ $self->{list}->[0] };

  if ($attr->{ORDERS_LIST}) {
    $self->query(
      $db, "SELECT  o.invoice_id,  o.orders,  o.unit,  o.counts,  o.price,  o.fees_id
      FROM  (docs_invoices d, docs_invoice_orders o) 
     $WHERE;"
    );

    return $self->{list} if ($self->{TOTAL} < 1);
    my $list = $self->{list};
    return $list;
  }

  return $list;
}

#**********************************************************
# invoices_list
#**********************************************************
sub docs_nextid {
  my $self = shift;
  my ($attr) = @_;

  my $sql = '';

  if ($attr->{TYPE} eq 'INVOICE') {
    $sql = "SELECT max(d.invoice_num), count(*) FROM docs_invoices d
     WHERE YEAR(date)=YEAR(curdate());";
  }
  elsif ($attr->{TYPE} eq 'RECEIPT') {
    $sql = "SELECT max(d.receipt_num), count(*) FROM docs_receipts d
     WHERE YEAR(date)=YEAR(curdate());";
  }
  elsif ($attr->{TYPE} eq 'TAX_INVOICE') {
    $sql = "SELECT max(d.tax_receipt_id), count(*) FROM docs_tax_receipts d
     WHERE YEAR(date)=YEAR(curdate());";
  }
  elsif ($attr->{TYPE} eq 'ACT') {
    $sql = "SELECT max(d.act_id), count(*) FROM docs_acts d
     WHERE YEAR(date)=YEAR(curdate());";
  }

  $self->query($db, "$sql");

  ($self->{NEXT_ID}, $self->{TOTAL}) = @{ $self->{list}->[0] };

  $self->{NEXT_ID}++;
  return $self->{NEXT_ID};
}

#**********************************************************
# docs_invoice_new
#**********************************************************
sub invoice_new {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  undef @WHERE_RULES;

  if ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'f.uid') };
  }
  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }

  if ($attr->{BILL_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{BILL_ID}, 'INT', 'f.bill_id') };
  }
  elsif ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'u.company_id') };
  }

  if ($attr->{AID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{AID}, 'INT', 'f.aid') };
  }

  if ($attr->{ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{ID}, 'INT', 'f.id') };
  }

  if ($attr->{A_LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{A_LOGIN}, 'STR', 'a.id') };
  }

  if ($attr->{DOMAIN_ID}) {
    push @WHERE_RULES, "u.domain_id='$attr->{DOMAIN_ID}' ";
  }

  # Show debeters
  if ($attr->{DESCRIBE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DESCRIBE}, 'STR', 'f.dsc') };
  }

  if ($attr->{INNER_DESCRIBE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{INNER_DESCRIBE}, 'STR', 'f.inner_describe') };
  }

  if (defined($attr->{METHOD}) && $attr->{METHOD} >= 0) {
    push @WHERE_RULES, "f.method IN ($attr->{METHOD}) ";
  }

  if ($attr->{SUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'f.sum') };
  }

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  # Date
  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, @{ $self->search_expr(">=$attr->{FROM_DATE}", 'DATE', 'date_format(f.date, \'%Y-%m-%d\')') }, @{ $self->search_expr("<=$attr->{TO_DATE}", 'DATE', 'date_format(f.date, \'%Y-%m-%d\')') };
  }
  elsif ($attr->{DATE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DATE}, 'DATE', 'date_format(f.date, \'%Y-%m-%d\')') };
  }

  # Month
  elsif ($attr->{MONTH}) {
    push @WHERE_RULES, "date_format(f.date, '%Y-%m')='$attr->{MONTH}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  $self->query(
    $db, "SELECT f.id, u.id, f.date, f.dsc, f.sum, ao.fees_id,
f.last_deposit, 
f.method, f.bill_id, if(a.name is NULL, 'Unknown', a.name), 
INET_NTOA(f.ip), f.uid, f.inner_describe 
FROM fees f 
LEFT JOIN users u ON (u.uid=f.uid) 
LEFT JOIN admins a ON (a.aid=f.aid) 
LEFT JOIN docs_invoice_orders ao ON (ao.fees_id=f.id) 
$WHERE
GROUP BY f.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;"
  );

  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  return $list;
}

#**********************************************************
# Bill
#**********************************************************
sub invoice_add {
  my $self = shift;
  my ($attr) = @_;

  invoice_defaults();

  %DATA = $self->get_data($attr, { default => \%DATA });
  $DATA{DATE} = ($attr->{DATE}) ? "'$attr->{DATE}'" : 'now()';
  $DATA{CUSTOMER}   = '' if (!$DATA{CUSTOMER});
  $DATA{PHONE}      = '' if (!$DATA{PHONE});
  $DATA{VAT}        = '' if (!$DATA{VAT});
  $DATA{PAYMENT_ID} = 0  if (!$DATA{PAYMENT_ID});

  $DATA{INVOICE_NUM} = ($attr->{INVOICE_NUM}) ? $attr->{INVOICE_NUM} : $self->docs_nextid({ TYPE => 'INVOICE' });
  return $self if ($self->{errno});

  $self->query(
    $db, "insert into docs_invoices (invoice_num, date, created, customer, phone, aid, uid, payment_id, vat, deposit, 
    delivery_status, exchange_rate, currency)
      values ('$DATA{INVOICE_NUM}', $DATA{DATE}, now(), \"$DATA{CUSTOMER}\", \"$DATA{PHONE}\", 
      '$admin->{AID}', '$DATA{UID}', '$DATA{PAYMENT_ID}', '$DATA{VAT}', '$DATA{DEPOSIT}', 
      '$DATA{DELIVERY_STATUS}', '$DATA{EXCHANGE_RATE}', '$DATA{DOCS_CURRENCY}');", 'do'
  );

  return $self if ($self->{errno});
  $self->{DOC_ID}      = $self->{INSERT_ID};
  $self->{INVOICE_NUM} = $DATA{INVOICE_NUM};

  if ($attr->{IDS}) {
    my @ids_arr = split(/, /, $attr->{IDS});

    foreach my $id (@ids_arr) {
      $DATA{ 'COUNTS_' . $id } = 1 if (!$DATA{ 'COUNTS_' . $id });

      #next if (! $DATA{'SUM_'.$id} || $DATA{'SUM_'.$id} <= 0);
      $DATA{ 'SUM_' . $id } =~ s/\,/\./g;
      if ($DATA{ER} && $DATA{ER} != 1) {
        $DATA{ 'SUM_' . $id } = $DATA{ 'SUM_' . $id } / $DATA{ER};
      }

      $self->query(
        $db, "INSERT INTO docs_invoice_orders (invoice_id, orders, counts, unit, price, fees_id)
         values (" . $self->{'DOC_ID'} . ", \"" . $DATA{ 'ORDER_' . $id } . "\", '" . $DATA{ 'COUNTS_' . $id } . "', '" . ($DATA{ 'UNIT_' . $id } || 0) . "',
       '" . $DATA{ 'SUM_' . $id } . "','" . ($DATA{ 'FEES_ID_' . $id } || 0) . "')", 'do'
      );
    }
  }
  else {
    $DATA{COUNTS} = 1 if (!$DATA{COUNTS});
    $DATA{UNIT}   = 0 if (!$DATA{UNIT});

    if ($DATA{ER} && $DATA{ER} != 1) {
      $DATA{'SUM'} = $DATA{'SUM'} / $DATA{ER};
    }

    $self->query(
      $db, "INSERT INTO docs_invoice_orders (invoice_id, orders, counts, unit, price)
       values ($self->{DOC_ID}, \"$DATA{ORDER}\", '$DATA{COUNTS}', '$DATA{UNIT}',
    '$DATA{SUM}')", 'do'
    );
  }

  return $self if ($self->{errno});

  $self->invoice_info($self->{DOC_ID});

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub invoice_del {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {
  }
  else {
    $self->query($db, "DELETE FROM docs_invoice_orders WHERE invoice_id='$id'", 'do');
    $self->query($db, "DELETE FROM docs_invoices WHERE id='$id'", 'do');
  }

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub invoice_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';
  $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} = 30 if (!$CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD});
  $self->query(
    $db, "SELECT d.invoice_num, 
   d.date, 
   d.customer,  
   sum(o.price * o.counts), 
   if(d.vat>0, FORMAT(sum(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)),
   u.id, 
   a.name, 
   d.created, 
   d.uid, 
   d.id,
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   if (d.phone<>0, d.phone, pi.phone),
   pi.contract_id,
   pi.contract_date,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day,
   u.company_id,
   c.name,
   d.payment_id,
   p.method,
   p.ext_id,
   d.deposit,
   d.delivery_status,
   d.exchange_rate,
   d.currency
    FROM (docs_invoices d, docs_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN companies c ON (u.company_id=c.id)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN payments p ON (d.payment_id=p.id)
    WHERE d.id=o.invoice_id and d.id='$id' $WHERE
    GROUP BY d.id;"
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }
  (
    $self->{INVOICE_NUM},
    $self->{DATE},
    $self->{CUSTOMER},
    $self->{TOTAL_SUM},
    $self->{VAT},
    $self->{LOGIN},
    $self->{ADMIN},
    $self->{CREATED},
    $self->{UID},
    $self->{DOC_ID},
    $self->{FIO},

    $self->{ADDRESS_STREET},
    $self->{ADDRESS_BUILD},
    $self->{ADDRESS_FLAT},
    $self->{PHONE},
    $self->{CONTRACT_ID},
    $self->{CONTRACT_DATE},
    $self->{EXPIRE_DATE},
    $self->{COMPANY_ID},
    $self->{COMPANY_NAME},
    $self->{PAYMENT_ID},
    $self->{PAYMENT_METHOD_ID},
    $self->{EXT_ID},
    $self->{DEPOSIT},
    $self->{DELIVERY_STATUS},
    $self->{EXCHANGE_RATE},
    $self->{CURRENCY}
  ) = @{ $self->{list}->[0] };

  $self->{AMOUNT_FOR_PAY} = ($self->{DEPOSIT} > 0) ? $self->{TOTAL_SUM} - $self->{DEPOSIT} : $self->{TOTAL_SUM} + $self->{DEPOSIT};

  if ($self->{TOTAL} > 0) {
    $self->{NUMBER} = $self->{INVOICE_ID};

    $self->query(
      $db, "SELECT invoice_id, orders, counts, unit, price, fees_id, '$self->{LOGIN}'
     FROM docs_invoice_orders WHERE invoice_id='$id'"
    );

    $self->{ORDERS} = $self->{list};
  }

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub invoice_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    INVOICE_NUM     => 'invoice_num',
    DATE            => 'date',
    CUSTOMER        => 'customer',
    SUM             => 'sum',
    ID              => 'id',
    UID             => 'uid',
    PAYMENT_ID      => 'payment_id',
    DELIVERY_STATUS => 'delivery_status'
  );

  my $old_info = $self->invoice_info($attr->{ID});

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'docs_invoices',
      FIELDS          => \%FIELDS,
      OLD_INFO        => $old_info,
      DATA            => $attr,
      EXT_CHANGE_INFO => 'ACCT'
    }
  );

  return $self;
}

#**********************************************************
# Del documents
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "DELETE FROM docs_invoice_orders WHERE invoice_id IN (SELECT id FROM docs_invoices WHERE uid='$attr->{UID}')", 'do');
  $self->query($db, "DELETE FROM docs_invoices WHERE uid='$attr->{UID}'",                                                          'do');
  $self->query($db, "DELETE FROM docs_receipt_orders WHERE receipt_id IN (SELECT id FROM docs_receipts WHERE uid='$attr->{UID}')", 'do');
  $self->query($db, "DELETE FROM docs_receipts WHERE uid='$attr->{UID}'",                                                          'do');

  return $self;
}

#**********************************************************
# invoices_list
#**********************************************************
sub tax_invoice_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ();

  if ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'd.uid') };
  }

  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

  if ($attr->{DOC_ID}) {
    push @WHERE_RULES, $self->search_expr($attr->{DOC_ID}, 'INT', 'd.tax_invoice_id');
  }

  if ($attr->{SUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'o.price * o.counts') };
  }

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'd.company_id') };
  }
  if ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'd.uid') };
  }

  my $EXT_TABLES = '';
  if ($attr->{FULL_INFO}) {
    $EXT_TABLES = "LEFT JOIN users u ON (d.uid=u.uid)
      LEFT JOIN users_pi pi ON (pi.uid=u.uid)";

    $self->{EXT_FIELDS} = ",
   if(d.vat>0, FORMAT(sum(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)),
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   pi.phone,
   c.contract_id,
   c.contract_date,
   d.company_id,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day";
  }

  $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  $self->query(
    $db, "SELECT d.tax_invoice_id, d.date, c.name, sum(o.price * o.counts), a.name, d.created, d.uid, d.company_id, d.id $self->{EXT_FIELDS}
    FROM (docs_tax_invoices d)
    LEFT JOIN docs_tax_invoice_orders o ON (d.id=o.tax_invoice_id)
    LEFT JOIN companies c ON (d.company_id=c.id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    $EXT_TABLES
    $WHERE
    GROUP BY d.tax_invoice_id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;"
  );

  $self->{SUM} = 0.00;
  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  $self->query(
    $db, "SELECT count(DISTINCT d.tax_invoice_id), sum(o.price*o.counts)
    FROM (docs_tax_invoices d)
    LEFT JOIN docs_tax_invoice_orders o ON (d.id=o.tax_invoice_id)
    LEFT JOIN companies c ON (d.company_id=c.id)
    $WHERE"
  );

  ($self->{TOTAL}, $self->{SUM}) = @{ $self->{list}->[0] };

  return $list;
}

#**********************************************************
# tax_invoice_reports
#**********************************************************
sub tax_invoice_reports {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();

  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }
  elsif ($attr->{MONTH}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m')='$attr->{MONTH}')";
  }

  if ($attr->{DOC_ID}) {
    push @WHERE_RULES, $self->search_expr($attr->{DOC_ID}, 'INT', 'd.tax_receipt_id');
  }

  if ($attr->{SUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'o.price * o.counts') };
  }

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'd.company_id') };
  }
  if ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'd.uid') };
  }

  $WHERE = ($#WHERE_RULES > -1) ? 'AND ' . join(' and ', @WHERE_RULES) : '';

  $self->query(
    $db, "SELECT 0, DATE_FORMAT(d.date, '%d%m%Y'), d.receipt_num, pi.fio,
    pi._inn, 
    ROUND(sum(inv_orders.price*counts), 2), 
    ROUND(sum(inv_orders.price*counts) - sum(inv_orders.price*counts) /6, 2),  
    ROUND(sum(inv_orders.price*counts) / 6, 2), 
    '-',  'X', '-', 'X', '-', 'X'

FROM (users u, docs_receipts d)
LEFT JOIN users_pi pi ON (d.uid=pi.uid)
LEFT JOIN docs_receipt_orders inv_orders ON (inv_orders.receipt_id=d.id)
WHERE u.uid=d.uid $WHERE
GROUP BY d.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;"
  );

  $self->{SUM} = 0.00;
  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  #
  # $self->query($db, "SELECT count(DISTINCT d.tax_invoice_id), sum(o.price*o.counts)
  #    FROM (docs_tax_invoices d)
  #    LEFT JOIN docs_tax_invoice_orders o ON (d.id=o.tax_invoice_id)
  #    LEFT JOIN companies c ON (d.company_id=c.id)
  #    $WHERE");
  #
  # ($self->{TOTAL}, $self->{SUM}) = @{ $self->{list}->[0] };

  return $list;
}

#**********************************************************
# Bill
#**********************************************************
sub tax_invoice_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });
  $DATA{DATE} = ($attr->{DATE}) ? "'$attr->{DATE}'" : 'now()';
  $DATA{DOC_ID} = ($attr->{DOC_ID}) ? $attr->{DOC_ID} : $self->docs_nextid({ TYPE => 'TAX_INVOICE' });

  return $self if ($self->{errno});

  $self->query(
    $db, "insert into docs_tax_invoices (tax_invoice_id, date, created, aid, uid, company_id)
      values ('$DATA{DOC_ID}', $DATA{DATE}, now(), \"$admin->{AID}\", \"$DATA{UID}\", '$DATA{COMPANY_ID}');", 'do'
  );

  return $self if ($self->{errno});
  $self->{DOC_ID} = $self->{INSERT_ID};

  if (!$attr->{IDS}) {

  }

  if ($attr->{IDS}) {
    my @ids_arr = split(/, /, $attr->{IDS});

    foreach my $id (@ids_arr) {
      $DATA{ 'COUNTS_' . $id } = 1 if (!$DATA{ 'COUNTS_' . $id });
      $self->query(
        $db, "INSERT INTO docs_tax_invoice_orders (tax_invoice_id, orders, counts, unit, price)
         values (" . $self->{'DOC_ID'} . ", \"" . $DATA{ 'ORDER_' . $id } . "\", '" . $DATA{ 'COUNTS_' . $id } . "', '" . $DATA{ 'UNIT_' . $id } . "',
       '" . $DATA{ 'SUM_' . $id } . "')", 'do'
      );
    }
  }

  return $self if ($self->{errno});

  $self->tax_invoice_info($self->{DOC_ID});

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub tax_invoice_del {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {
  }
  else {
    $self->query($db, "DELETE FROM docs_tax_invoice_orders WHERE tax_invoice_id='$id'", 'do');
    $self->query($db, "DELETE FROM docs_tax_invoices WHERE id='$id'", 'do');
  }

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub tax_invoice_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';

  $self->query(
    $db, "SELECT d.tax_invoice_id, 
   d.date, 
   sum(o.price * o.counts), 
   if(d.vat>0, FORMAT(sum(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)),
   u.id, 
   c.name, 
   d.created, 
   d.uid, 
   d.id,
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   pi.phone,
   c.contract_id,
   c.contract_date,
   d.company_id,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day
   
    FROM (docs_tax_invoices d, docs_tax_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN companies c ON (c.id=d.company_id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    WHERE d.id=o.tax_invoice_id and d.id='$id' $WHERE
    GROUP BY d.id;"
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  (
    $self->{TAX_INVOICE_ID},
    $self->{DATE},
    $self->{TOTAL_SUM},
    $self->{VAT},
    $self->{LOGIN},
    $self->{ADMIN},
    $self->{CREATED},
    $self->{UID},
    $self->{DOC_ID},
    $self->{FIO},

    $self->{ADDRESS_STREET},
    $self->{ADDRESS_BUILD},
    $self->{ADDRESS_FLAT},
    $self->{PHONE},
    $self->{CONTRACT_ID},
    $self->{CONTRACT_DATE},
    $self->{COMPANY_NAMA},
    $self->{EXPIRE_DATE}
  ) = @{ $self->{list}->[0] };

  if ($self->{TOTAL} > 0) {
    $self->{NUMBER} = $self->{INVOICE_NUM};

    $self->query(
      $db, "SELECT tax_invoice_id, orders, counts, unit, price
     FROM docs_tax_invoice_orders WHERE tax_invoice_id='$id'"
    );

    $self->{ORDERS} = $self->{list};
  }

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub tax_invoice_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    DOC_ID     => 'doc_id',
    COMPANY_ID => 'company_id',
    DATE       => 'date',
    SUM        => 'sum',
    ID         => 'id',
    UID        => 'uid'
  );

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'docs_tax_invoices',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->tax_invoice_info($attr->{DOC_ID}),
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# acts_list
#**********************************************************
sub acts_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ();

  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

  if ($attr->{DOC_ID}) {
    push @WHERE_RULES, $self->search_expr($attr->{DOC_ID}, 'INT', 'd.act_id');
  }

  if ($attr->{SUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'd.sum') };
  }

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'd.company_id') };
  }
  if ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'd.uid') };
  }

  $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  $self->query(
    $db, "SELECT d.act_id, d.date, c.name, d.sum, a.name, d.created, d.uid, d.company_id, d.id
    FROM (docs_acts d)
    LEFT JOIN companies c ON (d.company_id=c.id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    $WHERE
    GROUP BY d.act_id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;"
  );

  $self->{SUM} = 0.00;
  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  $self->query(
    $db, "SELECT count(DISTINCT d.act_id), sum(d.sum)
    FROM (docs_acts d)
    LEFT JOIN companies c ON (d.company_id=c.id)
    $WHERE"
  );

  ($self->{TOTAL}, $self->{SUM}) = @{ $self->{list}->[0] };

  return $list;
}

#**********************************************************
# Bill
#**********************************************************
sub act_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });
  $DATA{DATE} = ($attr->{DATE}) ? "'$attr->{DATE}'" : 'now()';
  $DATA{DOC_ID} = ($attr->{DOC_ID}) ? $attr->{DOC_ID} : $self->docs_nextid({ TYPE => 'ACT' });

  $self->query(
    $db, "insert into docs_acts (act_id, date, created, aid, uid, company_id, sum)
      values ('$DATA{DOC_ID}', $DATA{DATE}, now(), \"$admin->{AID}\", \"$DATA{UID}\", '$DATA{COMPANY_ID}', '$DATA{SUM}');", 'do'
  );

  return $self if ($self->{errno});
  $self->{DOC_ID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub act_del {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {
  }
  else {
    $self->query($db, "DELETE FROM docs_acts WHERE id='$id'", 'do');
  }

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub act_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';

  $self->query(
    $db, "SELECT d.act_id, 
   d.date, 
   date_format(d.date, '%Y-%m'),
   d.sum, 
   if(d.vat>0, FORMAT(d.sum / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)),
   u.id, 
   a.name, 
   d.created, 
   d.uid, 
   d.id,
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   pi.phone,
   c.contract_id,
   c.contract_date,
   d.company_id,
   c.name,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day
   
   
    FROM (docs_acts d)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN companies c ON (c.id=d.company_id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    WHERE d.id='$id' $WHERE
    GROUP BY d.id;"
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  (
    $self->{ACT_ID},
    $self->{DATE},
    $self->{MONTH},
    $self->{TOTAL_SUM},
    $self->{VAT},
    $self->{LOGIN},
    $self->{ADMIN},
    $self->{CREATED},
    $self->{UID},
    $self->{DOC_ID},
    $self->{FIO},

    $self->{ADDRESS_STREET},
    $self->{ADDRESS_BUILD},
    $self->{ADDRESS_FLAT},
    $self->{PHONE},
    $self->{CONTRACT_ID},
    $self->{CONTRACT_DATE},
    $self->{COMPANY_ID},
    $self->{COMPANY_NAME},
    $self->{EXPIRE_DATE}

  ) = @{ $self->{list}->[0] };

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub act_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    DOC_ID     => 'doc_id',
    COMPANY_ID => 'company_id',
    DATE       => 'date',
    SUM        => 'sum',
    ID         => 'id',
    UID        => 'uid',
  );

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'docs_acts',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->act_info($attr->{DOC_ID}),
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# User information
# info()
#**********************************************************
sub user_info {
  my $self = shift;
  my ($uid, $attr) = @_;

  $WHERE = "WHERE service.uid='$uid'";

  $self->query(
    $db, "SELECT service.uid, 
   service.send_docs, 
   service.periodic_create_docs, 
   service.email, 
   service.comments,
   service.personal_delivery,
   service.invoicing_period,
   service.invoice_date,
   (service.invoice_date + INTERVAL service.invoicing_period MONTH) - INTERVAL 10 day AS PRE_INVOICE_DATE

     FROM docs_main service
   $WHERE;"
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  ($self->{UID}, $self->{SEND_DOCS}, $self->{PERIODIC_CREATE_DOCS}, $self->{EMAIL}, $self->{COMMENTS}, $self->{PERSONAL_DELIVERY}, $self->{INVOICE_PERIOD}, $self->{INVOICE_DATE}, $self->{NEXT_INVOICE_DATE}) = @{ $self->{list}->[0] };

  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
    SEND_DOCS            => 0,
    PERIODIC_CREATE_DOCS => 0,
    EMAIL                => '',
    COMMENTS             => '',
    INVOICE_DATE         => '0000-00-00'
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => defaults() });

  $self->query(
    $db, "INSERT INTO docs_main (uid, 
     send_docs, 
     periodic_create_docs, 
     email, 
     comments,
     personal_delivery,
     invoicing_period,
     invoice_date
     )
        VALUES ('$DATA{UID}',
        '$DATA{SEND_DOCS}', 
        '$DATA{PERIODIC_CREATE_DOCS}',
        '$DATA{EMAIL}',
        '$DATA{COMMENTS}',
        '$DATA{PERSONAL_DELIVERY}',
        '$DATA{INVOICE_PERIOD}',
        '$DATA{INVOICE_DATE}'
         );", 'do'
  );

  return $self if ($self->{errno});
  $admin->action_add("$DATA{UID}", "", { TYPE => 1 });
  return $self;
}

#**********************************************************
# user_change()
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    SEND_DOCS            => 'send_docs',
    PERIODIC_CREATE_DOCS => 'periodic_create_docs',
    EMAIL                => 'email',
    COMMENTS             => 'comments',
    UID                  => 'uid',
    PERSONAL_DELIVERY    => 'personal_delivery',
    INVOICE_PERIOD       => 'invoicing_period',
    INVOICE_DATE         => 'invoice_date'
  );

  if (!$attr->{CHANGE_DATE}) {
    $attr->{SEND_DOCS}            = (!defined($attr->{SEND_DOCS}))            ? 0 : 1;
    $attr->{PERIODIC_CREATE_DOCS} = (!defined($attr->{PERIODIC_CREATE_DOCS})) ? 0 : 1;
    $attr->{PERSONAL_DELIVERY}    = (!defined($attr->{PERSONAL_DELIVERY}))    ? 0 : 1;
  }

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'docs_main',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->user_info($attr->{UID}),
      DATA         => $attr
    }
  );

  $self->user_info($attr->{UID});
  return $self;
}

#**********************************************************
# Delete user info from all tables
#
# user_del(attr);
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "DELETE from iptv_main WHERE uid='$self->{UID}';", 'do');

  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub user_list {
  my $self   = shift;
  my ($attr) = @_;
  my @list   = ();

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  undef @WHERE_RULES;
  push @WHERE_RULES, "u.uid = service.uid";

  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }

  if ($attr->{DEPOSIT}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DEPOSIT}, 'INT', 'u.deposit') };
  }

  if ($attr->{DISCOUNT}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DISCOUNT}, 'INT', 'u.reduction', { EXT_FIELD => 1 }) };
  }

  if ($attr->{FIO}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{FIO}, 'STR', 'pi.fiio') };
  }

  if ($attr->{COMMENTS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{COMMENTS}, 'INT', 'service.comments', { EXT_FIELD => 1 }) };
  }

  # Show debeters
  if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "u.company_id='$attr->{COMPANY_ID}'";
  }

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  #Activate
  if ($attr->{ACTIVATE}) {
    my $value = $self->search_expr("$attr->{ACTIVATE}", 'INT');
    push @WHERE_RULES, "(u.activate='0000-00-00' or u.activate$attr->{ACTIVATE})";
  }

  #Expire
  if ($attr->{EXPIRE}) {
    my $value = $self->search_expr("$attr->{EXPIRE}", 'INT');
    push @WHERE_RULES, "(u.expire='0000-00-00' or u.expire$attr->{EXPIRE})";
  }

  if ($attr->{INVOICE_DATE}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{INVOICE_DATE}", 'DATE', 'service.invoice_date') };
  }

  if ($attr->{PRE_INVOICE_DATE}) {
  	if ($attr->{PRE_INVOICE_DATE} =~ /(\d{4}-\d{2}-\d{2})\/(\d{4}-\d{2}-\d{2})/) {
      my $from_date = $1;
      my $to_date   = $2;

      push @WHERE_RULES, "(u.activate='0000-00-00' 
      AND (( service.invoice_date + INTERVAL service.invoicing_period MONTH - INTERVAL 10 day>='$from_date'
           AND service.invoice_date + INTERVAL service.invoicing_period MONTH - INTERVAL 10 day<='$to_date'  )
      OR   (service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period-1 DAY - INTERVAL 10 day>='$from_date' 
           AND service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period-1 DAY - INTERVAL 10 day<='$to_date' )))";  		
  	}
    else {
      push @WHERE_RULES, "(u.activate='0000-00-00' AND service.invoice_date + INTERVAL service.invoicing_period MONTH - INTERVAL 10 day='$attr->{PRE_INVOICE_DATE}') 
      OR (u.activate<>'0000-00-00' AND service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period-1 DAY   - INTERVAL 10 day='$attr->{PRE_INVOICE_DATE}')";
    }
  }

  if ($attr->{PERIODIC_CREATE_DOCS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{PERIODIC_CREATE_DOCS}", 'INT', 'd.periodic_create_docs') };
  }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';

  my $list;

  $self->query(
    $db, "select u.id, pi.fio, 
     if(company.id IS NULL, b.deposit, cb.deposit), 
     if(u.company_id=0, u.credit, 
          if (u.credit=0, company.credit, u.credit)), u.disable, 
     service.invoice_date, 
     (service.invoice_date + INTERVAL service.invoicing_period MONTH) AS NEXT_INVOICE_DATE,
     service.invoicing_period,    
     service.email, 
     service.send_docs,
     service.uid,
     u.activate,
     $self->{SEARCH_FIELDS}
     if(u.activate='0000-00-00', 
     service.invoice_date + INTERVAL service.invoicing_period MONTH,  
     service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period-1 DAY)   - INTERVAL 10 day AS PRE_INVOICE_DATE 
   FROM (users u, docs_main service)
   
   LEFT JOIN users_pi pi ON (u.uid = pi.uid)
   LEFT JOIN bills b ON (u.bill_id = b.id)
   LEFT JOIN companies company ON  (u.company_id=company.id) 
   LEFT JOIN bills cb ON  (company.bill_id=cb.id)
  
   WHERE u.uid=service.uid AND

   $WHERE 
   ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;"
  );

  return $self if ($self->{errno});

  $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query(
      $db, "SELECT count(u.id)  FROM users u, docs_main service
   WHERE u.uid=service.uid AND $WHERE"
    );
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }

  return $list;
}

1
