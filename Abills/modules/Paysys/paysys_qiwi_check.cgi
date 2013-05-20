#!/usr/bin/perl -w
# PaySys Console
# Console interface for payments and fees import

use vars qw($begin_time %FORM %LANG
$DATE $TIME
$CHARSET
@MODULES);

BEGIN {
  my $libpath = '../../../';
  $sql_type = 'mysql';
  unshift(@INC, './');
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, "/usr/abills/Abills/$sql_type/");
  unshift(@INC, "/usr/abills/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'libexec/');

  eval { require Time::HiRes; };
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
  }
  else {
    $begin_time = 0;
  }
}

use FindBin '$Bin';

require $Bin . '/../../../libexec/config.pl';

use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Users;
use Paysys;
use Finance;
use Admins;

my $html = Abills::HTML->new();
my $sql  = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
 { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $db   = $sql->{db};
require "Abills/Misc.pm";
#Operation status

my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $payments  = Finance->payments($db, $admin, \%conf);
my $fees      = Finance->fees($db, $admin, \%conf);
my $Paysys    = Paysys->new($db, $admin, \%conf);
my $Users     = Users->new($db, $admin, \%conf);
my $debug     = 0;
my $error_str = '';
%PAYSYS_PAYMENTS_METHODS = %{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };

#Arguments
my $ARGV = parse_arguments(\@ARGV);

if (defined($ARGV->{help})) {
  help();
  exit;
}

if ($ARGV->{DEBUG}) {
  $debug = $ARGV->{DEBUG};
  print "DEBUG: $debug\n";
}

$DATE = $ARGV->{DATE} if ($ARGV->{DATE});

qiwi_check();

#**********************************************************
#
#**********************************************************
sub qiwi_check {
  my ($attr) = @_;
  require "Abills/modules/Paysys/Qiwi.pm";
  my $payment_system    = 'QIWI';
  my $payment_system_id = 59;

  $Paysys->{debug} = 1 if ($debug > 6);
  my ($Y, $M, $D) = split(/-/, $DATE, 3);

  my $list = $Paysys->list(
    {
      %LIST_PARAMS,
      PAYMENT_SYSTEM => $payment_system_id,
      #INFO           => '-',
      STATUS         => 1,
      PAGE_ROWS      => $ARGV->{ROWS} || 1000,
      MONTH          => "$Y-$M",
      COLS_NAME      => 1
    }
  );

  my %status_hash = (
    10  => 'Не обработана',
    20  => 'Отправлен запрос провайдеру',
    25  => 'Авторизуется',
    30  => 'Авторизована',
    48  => 'Проходит финансовый контроль',
    49  => 'Проходит финансовый контроль',
    50  => 'Проводится',
    51  => 'Проведена (51)',
    58  => 'Перепроводится',
    59  => 'Принята к оплате',
    60  => 'Проведена',
    61  => 'Проведена',
    125 => 'Не смогли отправить провайдеру',
    130 => 'Отказ от провайдера',
    148 => 'Не прошел фин. контроль',
    149 => 'Не прошел фин. контроль',
    150 => 'Ошибка авторизации (неверный логин/пароль)',
    160 => 'Не проведена',
    161 => 'Отменен (Истекло время)'
  );

  my @ids_arr = ();
  
  foreach my $line (@$list) {
    push @ids_arr, $line->{transaction_id};
    if ($debug > 5) {
      print "Unregrequest: $line->{transaction_id}\n";
    }
  }

  my $result = qiwi_status(
    {
      IDS   => \@ids_arr,
      DEBUG => $debug
    }
  );

  if ($result->{'result-code'}->[0]->{fatal} && $result->{'result-code'}->[0]->{fatal} eq 'true') {
    print "Error: " . $result->{'result-code'}->[0]->{content} . ' ' . $status_hash{ $result->{'result-code'}->[0]->{content} } . "\n";
    exit;
  }

  my %res_hash = ();
  foreach my $id (keys %{ $result->{'bills-list'}->[0]->{bill} }) {
    my $status = int($result->{'bills-list'}->[0]->{bill}->{$id}->{status});
    if ($debug > 5) {
      print "$id / " . $status . "\n";
    }
    $res_hash{$id} = $status;
  }

  foreach my $line (@$list) {
    print "$line->{id} LOGIN: $line->{login}:$line->{datetime} SUM: $line->{sum} PAYSYS: $line->{system_id} TRANSACTION_ID: $line->{transaction_id}  $line->{status} STATUS: $res_hash{$line->{transaction_id}}\n" if ($debug > 0);
    if ($res_hash{ $line->{transaction_id} } == 50) {

    }
    elsif ($res_hash{ $line->{transaction_id} } == 60 || $res_hash{ $line->{transaction_id} } == 61 || $res_hash{ $line->{transaction_id} } == 51) {
      my $user = $Users->info($line->{uid});

      if ($Users->{TOTAL} < 1) {
        print "$line->{id} LOGIN: $line->{login} $line->{datetime} $line->{transaction_id} Not exists\n";
        next;
      }
      elsif ($Users->{errno}) {
        print "$line->{id} LOGIN: $line->{login} $line->{datetime} $line->{transaction_id} [$Users->{error}] $Users->{errstr}\n";
        next;
      }

      $payments->add(
        $user,
        {
          SUM          => $line->{sum},
          DESCRIBE     => "$payment_system",
          METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
          EXT_ID       => "$payment_system:$line->{transaction_id}",
          CHECK_EXT_ID => "$payment_system_id:$line->{transaction_id}"
        }
      );

      if ($payments->{error}) {
        print "Payments: $line->{id} LOGIN: $line->{login}:$line->{datetime} $line->{transaction_id} [$payments->{error}] $payments->{errstr}\n";
        next;
      }

      $Paysys->change(
        {
          ID        => $line->{id},
          PAYSYS_IP => $ENV{'REMOTE_ADDR'},
          INFO      => "DATE: $DATE $TIME $res_hash{$line->{transaction_id}} - $status_hash{$res_hash{$line->{transaction_id}}}",
          STATUS    => 2
        }
      );
    }
    elsif (in_array($res_hash{ $line->{transaction_id} }, [ 160, 161 ])) {
      $Paysys->change(
        {
          ID        => $line->{id},
          PAYSYS_IP => $ENV{'REMOTE_ADDR'},
          INFO      => "$_DATE: $DATE $TIME $res_hash{$line->{transaction_id}} - $status_hash{$res_hash{$line->{transaction_id}}}",
          STATUS    => 2
        }
      );
    }
  }

  return 0;
}

#**********************************************************
#
#**********************************************************
sub help {
  print << "[END]";
  QIWI checker:
    DEBUG=... - debug mode
    ROWS=..   - Rows for analise
    help      - this help
[END]

}
1
