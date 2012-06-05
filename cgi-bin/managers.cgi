#!/usr/bin/perl
# ABillS User Web interface
#

use vars qw($begin_time %LANG $CHARSET @MODULES $USER_FUNCTION_LIST);

BEGIN {
  my $libpath = '../';

  $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath . "Abills/");
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

require "config.pl";
require "Abills/templates.pl";
use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Portal;

$html = Abills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
  }
);

print "Content-Type: text/html\n\n";

my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

my $db = $sql->{db};

require Admins;
Admins->import();
$admin = Admins->new($db, \%conf);
$admin->info($conf{USERS_WEB_ADMIN_ID} ? $conf{USERS_WEB_ADMIN_ID} : $conf{SYSTEM_ADMIN_ID}, { DOMAIN_ID => $FORM{DOMAIN_ID}, IP => $ENV{REMOTE_ADDR} });
$admin->{SESSION_IP} = $ENV{REMOTE_ADDR};
$conf{WEB_TITLE} = $admin->{DOMAIN_NAME} if ($admin->{DOMAIN_NAME});

use Users;
$users = Users->new($db, $admin, \%conf);
use Dv;
$Dv = Dv->new($db, $admin, \%conf);

require "../language/russian.pl";
$html->{CHARSET} = $CHARSET if ($CHARSET);

%permissions = ();
my $res = check_permissions("abills", "demo");
my $error_msg = 0;
my %OUTPUT;    # Отвечает за генерацию шаблона
my $list          = '';
my $table_content = '';
my $users_total;                 # Всего учетных записей
my $mounth_contracts_added;      # Всего заключено договоров(текущий месяц год)
my $mounth_contracts_deleted;    # Всего разторгнуто договоров(текущий месяц год)
my $mounth_disabled_users;       # Всего временно отключившихся(текущий месяц год)
my $mounth_total_debtors;        # не оплативших текущий месяц
my $total_debtors;               # не оплативших 2 и более месяцев
my @service_status = ("$_ENABLE", "$_DISABLE", "$_NOT_ACTIVE", "$_HOLD_UP", "$_DISABLE: $_NON_PAYMENT", "$ERR_SMALL_DEPOSIT");
my @ref = ();    #ccылка на резултат запроса, для формирования отчета

if ($DATE && $DATE =~ /^(\d{1,4})\-(\d{2})\-(\d{2})$/) {
  $OUTPUT{YEAR}       = $1;
  $OUTPUT{MOUNTH}     = $2;
  $OUTPUT{DAY}        = $3;
  $OUTPUT{MOUNTH_STR} = $MONTHES[ $OUTPUT{MOUNTH} - 1 ];
}

my $content = '';

if ($FORM{SHOW_REPORT}) {
  form_reports()
}
else {
  form_main();
}

print $html->tpl_show(templates('mg_template'), 
    { CONTENT => $content || $html->{OUTPUT}, 
	    FILTER  => $filter,
    	});

#**********************************************************
#
#**********************************************************
sub form_main {

# Всего пользователей
$users_total = $Dv->list(
  {
    COLS_NAME      => 1,
    ADDRESS_STREET => '*',
    ADDRESS_BUILD  => '*',
    ADDRESS_FLAT   => '*',
    CONTRACT_DATE  => '>=0000',
    REGISTRATION   => '>=0000',
  }
);
$OUTPUT{USER_TOTAL} = $Dv->{TOTAL};

$mounth_contracts_added = $Dv->list(
  {
    ADDRESS_STREET => '*',
    ADDRESS_BUILD  => '*',
    ADDRESS_FLAT   => '*',
    CONTRACT_DATE  => '>=0000',
    COLS_NAME      => 1,
    REGISTRATION   => ">=$OUTPUT{YEAR}-$OUTPUT{MOUNTH}-01;<=$OUTPUT{YEAR}-$OUTPUT{MOUNTH}-$OUTPUT{DAY}",
  }
);
if ( !$admin->{permissions}->{0}
  || !$admin->{permissions}->{0}->{8}
  || ($attr->{USER_STATUS} && !$attr->{DELETED})) {
  print 'Main page';
}
elsif (defined($attr->{DELETED})) {
  print "$_DELETED";
}


$OUTPUT{REGISTRATION_MOUNTH_TOTAL} = $Dv->{TOTAL};

# Всего разторгнуто договоров(месяц год) -
$mounth_contracts_deleted = $Dv->list(
  {
    ADDRESS_STREET => '*',
    ADDRESS_BUILD  => '*',
    ADDRESS_FLAT   => '*',
    CONTRACT_DATE  => '>=0000',
    COLS_NAME      => 1,
    ACTION_DATE    => ">=$OUTPUT{YEAR}-$OUTPUT{MOUNTH}-01;<=$OUTPUT{YEAR}-$OUTPUT{MOUNTH}-$OUTPUT{DAY}",
    ACTION_TYPE    => 12,
    DELETED        => 1,
    USER_STATUS    => 1,
  }
);

$OUTPUT{DISCONNECTED} = $Dv->{TOTAL};

$mounth_disabled_users = $Dv->list(
  {
    ADDRESS_STREET => '*',
    ADDRESS_BUILD  => '*',
    ADDRESS_FLAT   => '*',
    CONTRACT_DATE  => '>=0000',
    COLS_NAME      => 1,
    ACTION_DATE    => ">=$OUTPUT{YEAR}-$OUTPUT{MOUNTH}-01;<=$OUTPUT{YEAR}-$OUTPUT{MOUNTH}-$OUTPUT{DAY}",
    ACTION_TYPE    => 9,
    REGISTRATION   => '>=0000',
  }
);

$OUTPUT{TEMPORARILY_DISCONNECTED} = $Dv->{TOTAL};

#Всего должников:
#не оплативших текущий месяц

$mounth_total_debtors = $Dv->report_debetors(
  {
    COLS_NAME      => 1,
    ADDRESS_STREET => '*',
    ADDRESS_BUILD  => '*',
    ADDRESS_FLAT   => '*',
    CONTRACT_ID    => '*',
    CONTRACT_DATE  => '>=0000',
    REGISTRATION   => '>=0000',
  }
);

$OUTPUT{REPORT_DEBETORS} = $Dv->{TOTAL};

#не оплативших 2 и более месяцев -
$total_debtors = $Dv->report_debetors(
  {
    COLS_NAME      => 1,
    ADDRESS_STREET => '*',
    ADDRESS_BUILD  => '*',
    ADDRESS_FLAT   => '*',
    CONTRACT_ID    => '*',
    CONTRACT_DATE  => '>=0000',
    REGISTRATION   => '>=0000',
    PERIOD         => 2
  }
);

$OUTPUT{REPORT_DEBETORS2} = $Dv->{TOTAL};

############## SEARCH
#					LOGIN           => $FORM{QUERY},
#					COLS_NAME       => 1,
#					ADDRESS_STREET  => '*',
#					ADDRESS_BUILD   => '*',
#					ADDRESS_FLAT    => '*',
#					CONTRACT_ID     => '*',

$LIST_PARAMS{LOGIN}          = '*';
$LIST_PARAMS{ADDRESS_STREET} = '*';
$LIST_PARAMS{ADDRESS_BUILD}  = '*';
$LIST_PARAMS{ADDRESS_FLAT}   = '*';
$LIST_PARAMS{CONTRACT_ID}    = '*';
$LIST_PARAMS{PHONE}          = '*';
$LIST_PARAMS{IP}             = '>=0.0.0.0';

#    if ($FORM{letter}) {
#      $LIST_PARAMS{COMPANY_NAME} = "$FORM{letter}*";
#      $pages_qs .= "&letter=$FORM{letter}";
#    }

if ($FORM{SEARCH} and $FORM{QUERY} ne '') {
  if ($FORM{TYPE} eq 'login') {

    $LIST_PARAMS{LOGIN} = "$FORM{QUERY}*";
  }
  elsif ($FORM{TYPE} eq 'address') {

    if ($FORM{QUERY} =~ /^(\w+).?(\d+)?.?(\d+)?$/) {
      $LIST_PARAMS{ADDRESS_STREET} = $1 || '*';
      $LIST_PARAMS{ADDRESS_BUILD}  = $2 || '*';
      $LIST_PARAMS{ADDRESS_FLAT}   = $3 || '*';
    }
    else {

    }

  }
  elsif ($FORM{TYPE} eq 'contract_id') {
    $LIST_PARAMS{CONTRACT_ID} = "$FORM{QUERY}*";
  }
  elsif ($FORM{TYPE} eq 'phone') {
    $LIST_PARAMS{PHONE} = "$FORM{QUERY}*";
  }
  elsif ($FORM{TYPE} eq 'ip') {
    $LIST_PARAMS{IP} = "$FORM{QUERY}";
  }
  else {
    $error_msg = 1;
  }

  #$Dv->{debug}=1;
  $list = $Dv->list({ %LIST_PARAMS, COLS_NAME => 1 });

  if ($Dv->{errno}) {
    $html->message('err', $_ERROR, "[$Dv->{errno}] $err_strs{$Dv->{errno}}");
    return 0;
  }

}
else {
  $Dv->{TOTAL} = 0;
}

my $table = $html->table(
  {
    width      => '100%',
    caption    => "$_SEARCH",
    border     => 1,
    title      => [ '-', $_CONTRACT_ID, $_FIO, $_ADDRESS, $_TARIF_PLAN, $_BALANCE, $_STATUS, '-' ],
    cols_align => [ 'left', 'left', 'right', 'right', 'left', 'center', 'center:noprint', 'center:noprint' ],
    qs         => $pages_qs,
    pages      => $Dv->{TOTAL},
    ID         => '$_SEARCH',
    header     => $status_bar
  }
);

foreach my $line (@$list) {
  my $payments = ($permissions{1}) ? $html->button("$_PAYMENTS", "index=2&UID=" . $line->{uid}, { CLASS => 'payments' }) : '';

  my @fields_array = ();
  for (my $i = 6 ; $i < 6 + $Dv->{SEARCH_FIELDS_COUNT} ; $i++) {
    push @fields_array, $line->{ $Dv->{COL_NAMES_ARR}->[$i] };
  }

  $table->addrow(
    '-',
    $line->{contract_id},
    $line->{fio},
    $line->{address_street} . ' ' . $line->{address_build} . ' ' . $line->{address_flat},
    $line->{tp_name},
    $line->{deposit},
    $service_status[ $line->{dv_status} ],
    $html->button("$_GO", "EDIT_USER=$line->{uid}", { BUTTON => 1 }),

  );
}

$OUTPUT{RESULT_TABLE} = $table->show({ OUTPUT2RETURN => 1 });
$OUTPUT{RESULT_TOTAL} = $Dv->{TOTAL};

  if (defined($FORM{NEW_USER})) {
    $content = $html->tpl_show(templates('mg_new_user'), {%OUTPUT});
  }
  elsif (defined($FORM{EDIT_USER} && $FORM{EDIT_USER} > 0)) {
    $content = $html->tpl_show(templates('mg_edit_user'), {%OUTPUT});
  }
  else {
    $content = $html->tpl_show(templates('mg_main_content'), {%OUTPUT});
  }

}

#**********************************************************
#
#**********************************************************
sub form_reports {
  my $table = $html->table(
    {
      width   => '100%',
      caption => 'Отчет',
      border  => 1,
      title   => [ 'номер договора', 'фио', 'адрес', 'тариф', 'статус учетной записи ', 'дата заключения договора', 'дата фактического подключения', 'дата отключения' ],
      cols_align => [ 'left', 'right', 'right', 'right', 'center', 'center' ],
      pages      => $users->{TOTAL},
      ID         => 'STORAGE_ID',

    }
  );

  # Выбираем тип отчета
  if ($FORM{SHOW_REPORT} eq 'users_total') {
    $ref = \@$users_total;
  }
  elsif ($FORM{SHOW_REPORT} eq 'mounth_contracts_added') {
    $ref = \@$mounth_contracts_added;
  }
  elsif ($FORM{SHOW_REPORT} eq 'mounth_contracts_deleted') {
    $ref = \@$mounth_contracts_deleted;
  }
  elsif ($FORM{SHOW_REPORT} eq 'mounth_disabled_users') {
    $ref = \@$mounth_disabled_users;
  }
  elsif ($FORM{SHOW_REPORT} eq 'mounth_total_debtors') {
    $ref = \@$mounth_total_debtors;
  }
  elsif ($FORM{SHOW_REPORT} eq 'total_debtors') {
    $ref = \@$total_debtors;
  }

  foreach my $u (@$ref) {
    $table->addrow($u->{id}, $u->{fio}, $u->{address_street} . ' ' . $u->{address_build} . ' ' . $u->{address_flat}, $u->{tp_name}, $service_status[ $u->{dv_status} ], $u->{contract_date}, $u->{registration}, '-',);

  }

  $table->show();
  $filter = $html->tpl_show(templates('mg_filter_reports'), { undef, OUTPUT2RETURN => 1 });
}




#**********************************************************
# check_permissions()
#**********************************************************
sub check_permissions {
  my ($login, $password, $attr) = @_;

  if ($conf{ADMINS_ALLOW_IP}) {
    $conf{ADMINS_ALLOW_IP} =~ s/ //g;
    my @allow_ips_arr = split(/,/, $conf{ADMINS_ALLOW_IP});
    my $allow_ips_hash = ();
    foreach my $ip (@allow_ips_arr) {
      $allow_ips_hash{$ip} = 1;
    }
    if (!$allow_ips_hash{ $ENV{REMOTE_ADDR} }) {
      $admin->system_action_add("$login:$password DENY IP: $ENV{REMOTE_ADDR}", { TYPE => 11 });
      $admin->{errno} = 3;
      return 3;
    }
  }

  $login    =~ s/"/\\"/g;
  $login    =~ s/'/\''/g;
  $password =~ s/"/\\"/g;
  $password =~ s/'/\\'/g;

  my %PARAMS = (
    LOGIN     => "$login",
    PASSWORD  => "$password",
    SECRETKEY => $conf{secretkey},
    IP        => $ENV{REMOTE_ADDR} || '0.0.0.0'
  );

  $admin->info(0, {%PARAMS});
  if ($admin->{errno}) {
    if ($admin->{errno} == 4) {
      $admin->system_action_add("$login:$password", { TYPE => 11 });
      $admin->{errno} = 4;
    }
    return 1;
  }
  elsif ($admin->{DISABLE} == 1) {
    $admin->{errno}  = 2;
    $admin->{errstr} = 'DISABLED';
    return 2;
  }

  if ($admin->{WEB_OPTIONS}) {
    my @WO_ARR = split(/;/, $admin->{WEB_OPTIONS});
    foreach my $line (@WO_ARR) {
      my ($k, $v) = split(/=/, $line);
      $admin->{WEB_OPTIONS}{$k} = $v;
    }
  }

  %permissions = %{ $admin->get_permissions() };
  return 0;
}

#**********************************************************
#
#**********************************************************
sub user_ext_menu {
  my ($UID, $LOGIN, $attr) = @_;

  my $payments_menu = (defined($permissions{1})) ? '<li>' . $html->button($_PAYMENTS, "UID=$UID&index=2") . '</li>' : '';
  my $fees_menu     = (defined($permissions{2})) ? '<li>' . $html->button($_FEES,     "UID=$UID&index=3") . '</li>' : '';
  my $sendmail_manu = '<li>' . $html->button($_SEND_MAIL, "UID=$UID&index=31") . '</li>';

  my $second_menu    = '';
  my %userform_menus = (
    22 => $_LOG,
    21 => $_COMPANY,
    12 => $_GROUP,
    18 => $_NAS,
    20 => $_SERVICES,
    19 => $_BILL
  );

  $userform_menus{17} = $_PASSWD if ($permissions{0}{3});

  while (my ($k, $v) = each %uf_menus) {
    $userform_menus{$k} = $v;
  }

  #Make service menu
  my $service_menu       = '';
  my $service_func_index = 0;
  my $service_func_menu  = '';
  foreach my $key (sort keys %menu_items) {
    if (defined($menu_items{$key}{20})) {
      $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
      $service_menu .= '<li>' . $html->button($menu_items{$key}{20}, "UID=$UID&index=$key");
    }

    if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
      $service_func_menu .= $html->button($menu_items{$key}{$service_func_index}, "UID=$UID&index=$key") . ' ';
    }
  }

  foreach my $k (sort { $b <=> $a } keys %userform_menus) {
    my $v   = $userform_menus{$k};
    my $url = "index=$k&UID=$UID";
    my $a   = (defined($FORM{$k})) ? $html->b($v) : $v;
    $second_menu .= "<li>" . $html->button($a, "$url") . '</li>';
  }

  my $ext_menu = qq{
<div id=quick_menu class=noprint>
<ul id=topNav>
  <li><a href="#"><img src='/img/user.png' border=0/></a>
  <ul>
    $payments_menu
    $fees_menu
    $sendmail_manu
    <li><a href='#'>Service >> </a>
      <ul>
       $service_menu
      </ul>
    </li>
    <li><a href='#'>$_OTHER >> </a>
      <ul>
        $second_menu
      </ul>
    </li> 
   </ul>
   </li> 
</ul>
</div>
};

  my $return = $ext_menu;
  if ($attr->{SHOW_UID}) {
    $return .= ' : ' . $html->button($html->b($LOGIN), "index=15&UID=${UID}") . " (UID: $UID) ";
  }
  else {
    $return .= $html->button($LOGIN, "index=15&UID=$UID" . (($attr->{EXT_PARAMS}) ? "&$attr->{EXT_PARAMS}" : ''), { TITLE => $attr->{TITLE} });
  }

  return $return;
}

#**********************************************************
# title_former
#**********************************************************
sub title_former {
  my ($attr) = @_;
  my @title = ();

  my $data = $attr->{INPUT_DATA};

  my %SEARCH_TITLES = (
    'disable'                           => "$_STATUS",
    'deposit'                           => "$_DEPOSIT",
    'credit'                            => "$_CREDIT",
    'id'                                => "$_LOGIN",
    'fio'                               => "$_FIO",
    'ext_deposit'                       => "$_EXTRA $_DEPOSIT",
    'last_payment'                      => "$_PAYMENTS $_DATE",
    'email'                             => 'E-Mail',
    'address_street'                    => $_ADDRESS,
    'pasport_date'                      => "$_PASPORT $_DATE",
    'pasport_num'                       => "$_PASPORT $_NUM",
    'pasport_grant'                     => "$_PASPORT $_GRANT",
    'address_build'                     => "$_ADDRESS_BUILD",
    'address_flat'                      => "$_ADDRESS_FLAT",
    'city'                              => "$_CITY",
    'zip'                               => "$_ZIP",
    'contract_id'                       => "$_CONTRACT_ID",
    'registration'                      => "$_REGISTRATION",
    'phone'                             => "$_PHONE",
    'comments'                          => "$_COMMENTS",
    'company_id'                        => '$_COMPANY_ID',
    'bill_id'                           => '$_BILLS',
    'activate'                          => "$_ACTIVATE",
    'expire'                            => "$_EXPIRE",
    'credit_date'                       => "$_CREDIT $_DATE",
    'reduction'                         => "$_REDUCTION",
    'domain_id'                         => 'DOMAIN ID',
    'build_number'                      => "$_BUILDS",
    'streets_name'                      => "$_STREETS",
    'district_name'                     => "$_DISTRICTS",
    'u.deleted'                         => "$_DELETED",
    'u.gid'                             => "$_GROUP",
    'builds.id'                         => 'Location ID',
    'uid'                               => 'UID',
    'if(company.id IS NULL,b.id,cb.id)' => "_BILL"
  );

  if ($data->{EXTRA_FIELDS}) {
    foreach my $line (@{ $data->{EXTRA_FIELDS} }) {
      if ($line->[0] =~ /ifu(\S+)/) {
        my $field_id = $1;
        my ($position, $type, $name, $user_portal) = split(/:/, $line->[1]);
        if ($type == 2) {
          $SEARCH_TITLES{ $field_id . '_list_name' } = eval "\"$name\"";
        }
        else {
          $SEARCH_TITLES{$field_id} = eval "\"$name\"";
        }
      }
    }
  }

  %SEARCH_TITLES = (%SEARCH_TITLES, %{ $attr->{EXT_TITLES} });

  my $base_fields  = $attr->{BASE_FIELDS};
  my @EX_TITLE_ARR = @{ $data->{COL_NAMES_ARR} };
  my @title        = ();

  for (my $i = 0 ; $i < $base_fields + $data->{SEARCH_FIELDS_COUNT} ; $i++) {
    $title[$i] = $SEARCH_TITLES{ $EX_TITLE_ARR[$i] } || "$_SEARCH";
  }
  foreach my $function_fld_name (split(/,/, $attr->{FUNCTION_FIELDS})) {
    $title[ $#title + 1 ] = '-';
  }
  return \@title;
}

#**********************************************************
# user_info
#**********************************************************
sub user_info {
  my ($UID) = @_;

  my $user_info = $users->info($UID, {%FORM});

  if ($users->{TOTAL} == 0 && !$FORM{UID}) {
    return 0;
  }

  my $deleted = ($user_info->{DELETED}) ? $html->color_mark($html->b($_DELETED), '#FF0000') : '';
  my $ext_menu = user_ext_menu($user_info->{UID}, $user_info->{LOGIN}, { SHOW_UID => 1 });

  $table = $html->table(
    {
      width      => '100%',
      rowcolor   => 'even',
      border     => 0,
      cols_align => ['left:noprint'],
      rows       => [ [ "$ext_menu" . $deleted ] ],
      class      => 'form',
    }
  );

  $user_info->{TABLE_SHOW} = $table->show();
  $LIST_PARAMS{UID}        = $user_info->{UID};
  $pages_qs                = "&UID=$user_info->{UID}";
  $pages_qs .= "&subf=$FORM{subf}" if (defined($FORM{subf}));

  return $user_info;
}

#**********************************************************
# form_users()
#**********************************************************
sub form_users {
  my ($attr) = @_;

  if ($FORM{PRINT_CONTRACT}) {
    load_module('Docs', $html);
    docs_contract();
    return 0;
  }
  elsif ($FORM{SEND_SMS_PASSWORD}) {
    load_module('Sms', $html);
    $users->info($FORM{UID}, { SHOW_PASSWORD => 1 });
    $users->pi({ UID => $FORM{UID} });
    if (
      sms_send(
        {
          NUMBER => $users->{PHONE},
          ,
          MESSAGE => "LOGIN: $users->{LOGIN} PASSWORD: $users->{PASSWORD}",
          UID     => $users->{UID}
        }
      )
    )
    {
      $html->message('info', "$_INFO", "$_PASSWD SMS $_SENDED");
    }
    return 0;
  }

  if ($attr->{USER_INFO}) {
    my $user_info = $attr->{USER_INFO};
    if ($users->{errno}) {
      $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");
      return 0;
    }

    print "<table width=\"100%\" border=\"0\" cellspacing=\"1\" cellpadding=\"2\"><tr><td valign=\"top\" align=\"center\">\n";

    #Make service menu
    my $service_menu       = '';
    my $service_func_index = 0;
    my $service_func_menu  = '';
    foreach my $key (sort keys %menu_items) {
      if (defined($menu_items{$key}{20})) {
        $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
        $service_menu .= '<li class=umenu_item>' . $html->button($menu_items{$key}{20}, "UID=$user_info->{UID}&index=$key");
      }

      if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
        $service_func_menu .= $html->button($menu_items{$key}{$service_func_index}, "UID=$user_info->{UID}&index=$key") . ' ';
      }
    }

    form_passwd({ USER_INFO => $user_info }) if (defined($FORM{newpassword}));

    if ($FORM{change}) {
      if (!$permissions{0}{4}) {
        $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");
        print "</td></table>\n";
        return 0;
      }
      elsif (!$permissions{0}{9} && $user_info->{CREDIT} != $FORM{CREDIT}) {
        $html->message('err', $_ERROR, "$_CHANGE $_CREDIT $ERR_ACCESS_DENY");
        $FORM{CREDIT} = undef;
      }
      elsif (!$permissions{0}{11} && $user_info->{REDUCTION} != $FORM{REDUCTION}) {
        $html->message('err', $_ERROR, "$_REDUCTION $ERR_ACCESS_DENY");
        $FORM{REDUCTION} = undef;
      }

      $user_info->change($user_info->{UID}, {%FORM});
      if ($user_info->{errno}) {
        $html->message('err', $_ERROR, "[$user_info->{errno}] $err_strs{$user_info->{errno}}");
        user_form();
        print "</td></table>\n";
        return 0;
      }
      else {
        $html->message('info', $_CHANGED, "$_CHANGED $users->{info}");
        if (defined($FORM{FIO})) {
          $users->pi_change({%FORM});
        }

        cross_modules_call('_payments_maked', { USER_INFO => $user_info, });

        #External scripts
        if ($conf{external_userchange}) {
          if (!_external($conf{external_userchange}, {%FORM})) {
            return 0;
          }
        }
        if ($attr->{REGISTRATION}) {
          print "</td></tr></table>\n";
          return 0;
        }
      }
    }
    elsif ($FORM{del_user} && $FORM{is_js_confirmed} && $index == 15 && $permissions{0}{5}) {
      user_del({ USER_INFO => $user_info });
      print "</td></tr></table>\n";
      return 0;
    }
    else {
      if (!$permissions{0}{4}) {
        @action = ();
      }
      else {
        @action = ('change', $_CHANGE);
      }

      user_form({ USER_INFO => $user_info });

      if ($conf{USER_ALL_SERVICES}) {

        foreach my $module (@MODULES) {
          $FORM{MODULE} = $module;
          my $service_func_index = 0;
          my $service_func_menu  = '';
          my $service_menu       = '';
          foreach my $key (sort keys %menu_items) {
            if (defined($menu_items{$key}{20})) {
              $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
              $service_menu .= '<li class=umenu_item>' . $html->button($menu_items{$key}{20}, "UID=$user_info->{UID}&index=$key");
            }

            if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
              $service_func_menu .= $html->button($menu_items{$key}{$service_func_index}, "UID=$user_info->{UID}&index=$key") . ' ';
            }
          }
          if ($service_func_index) {
            print "<TABLE width='100%' border=0>
        <TR><TH class=form_title>$module</TH></TR>
        <TR><TH class=odd><div id='rules'><ul><li class='center'>$service_func_menu</li></ul></div></TH></TR></TABLE>\n";

            $index = $service_func_index;
            if (defined($module{$service_func_index})) {
              load_module($module{$service_func_index}, $html);
            }

            $functions{$service_func_index}->({ USER_INFO => $user_info });
          }
        }

      }
      else {

        #===============
        #$service_func_index
        if ($functions{$service_func_index}) {
          $index = $service_func_index;
          if (defined($module{$service_func_index})) {
            load_module($module{$service_func_index}, $html);
          }

          print "<TABLE width='100%' border=0>
      <TR><TH class=form_title>$module{$service_func_index}</TH></TR>
      <TR><TH class=even><div id='rules'><ul><li class='center'>$service_func_menu</li></ul></div></TH></TR>
    </TABLE>\n";

          $functions{$service_func_index}->({ USER_INFO => $user_info });
        }

        #===============
      }
      user_pi({ %$attr, USER_INFO => $user_info });
    }

    my $payments_menu = (defined($permissions{1})) ? '<li class=umenu_item>' . $html->button($_PAYMENTS, "UID=$user_info->{UID}&index=2") . '</li>' : '';
    my $fees_menu     = (defined($permissions{2})) ? '<li class=umenu_item>' . $html->button($_FEES,     "UID=$user_info->{UID}&index=3") . '</li>' : '';
    my $sendmail_manu = '<li class=umenu_item>' . $html->button($_SEND_MAIL, "UID=$user_info->{UID}&index=31") . '</li>';

    my $second_menu    = '';
    my %userform_menus = (
      22 => $_LOG,
      21 => $_COMPANY,
      12 => $_GROUP,
      18 => $_NAS,
      20 => $_SERVICES,
      19 => $_BILL
    );

    $userform_menus{17} = $_PASSWD if ($permissions{0}{3});

    while (my ($k, $v) = each %uf_menus) {
      $userform_menus{$k} = $v;
    }

    foreach my $k (sort { $b <=> $a } keys %userform_menus) {
      my $v   = $userform_menus{$k};
      my $url = "index=$k&UID=$user_info->{UID}";
      my $a   = (defined($FORM{$k})) ? $html->b($v) : $v;
      $second_menu .= "<li class=umenu_item>" . $html->button($a, "$url") . '</li>';
    }

    my $full_delete = '';
    if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8} && ($user_info->{DELETED})) {
      $second_menu .= "<li class=umenu_item>" . $html->button($_UNDELETE, "index=15&del_user=1&UNDELETE=1&UID=$user_info->{UID}&is_js_confirmed=1") . '</li>';
      $full_delete = "&FULL_DELETE=1";
    }

    $second_menu .= "<li class=umenu_item>" . $html->button($_DEL, "index=15&del_user=1&UID=$user_info->{UID}$full_delete", { MESSAGE => "$_USER: $user_info->{LOGIN} / $user_info->{UID}" }) . '</li>' if (defined($permissions{0}{5}));

    print "
</td><td bgcolor='$_COLORS[3]' valign='top' width='180'>
<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td>
<div class=l_user_menu>
<ul class=user_menu>
  $payments_menu
  $fees_menu
  $sendmail_manu
</ul>
</div>
</td></tr>
<tr><td>
  <div class=l_user_menu> 
  <ul class=user_menu>
   $service_menu
  </ul></div>
<div class=l_user_menu>
<ul class=user_menu>
 $second_menu
</ul></div>
</td></tr>
</table>
</td></tr></table>\n";
    return 0;
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");
      return 0;
    }

    if ($FORM{newpassword}) {
      if (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
        $html->message('err', $_ERROR, "$ERR_SHORT_PASSWD $conf{PASSWD_LENGTH}");
      }
      elsif ($FORM{newpassword} eq $FORM{confirm}) {
        $FORM{PASSWORD} = $FORM{newpassword};
      }
      elsif ($FORM{newpassword} ne $FORM{confirm}) {
        $html->message('err', $_ERROR, "$ERR_WRONG_CONFIRM");
      }
      else {
        $FORM{PASSWORD} = $FORM{newpassword};
      }
    }

    $FORM{REDUCTION} = 100 if ($FORM{REDUCTION} && $FORM{REDUCTION} > 100);

    my $user_info = $users->add({%FORM});
    if ($users->{errno}) {
      if ($users->{errno} == 10) {
        $html->message('err', $_ERROR, "'$FORM{LOGIN}' $ERR_WRONG_NAME");
      }
      elsif ($users->{errno} == 7) {
        $html->message('err', $_ERROR, "'$FORM{LOGIN}' $_USER_EXIST");
      }
      else {
        $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");
      }

      delete($FORM{add});

      #user_form();
      return 1;
    }
    else {
      $html->message('info', $_ADDED, "$_ADDED '$user_info->{LOGIN}' / [$user_info->{UID}]");
      if ($conf{external_useradd}) {
        if (!_external($conf{external_useradd}, {%FORM})) {
          return 0;
        }
      }

      $user_info = $users->info($user_info->{UID}, { SHOW_PASSWORD => 1 });
      $html->tpl_show(templates('form_user_info'), $user_info);
      $LIST_PARAMS{UID} = $user_info->{UID};
      $FORM{UID}        = $user_info->{UID};
      user_pi({ %$attr, REGISTRATION => 1 });

      #$index=get_function_index('form_payments');
      #form_payments({ USER => $user_info });
      if ($FORM{COMPANY_ID}) {
        form_companie_admins($attr);
      }
      return 0;
    }
  }

  #Multi user operations
  elsif ($FORM{MULTIUSER}) {
    my @multiuser_arr = split(/, /, $FORM{IDS});
    my $count         = 0;
    my %CHANGE_PARAMS = ();
    while (my ($k, $v) = each %FORM) {
      if ($k =~ /^MU_(\S+)/) {
        my $val = $1;
        $CHANGE_PARAMS{$val} = $FORM{$val};
      }
    }

    if (!defined($FORM{DISABLE})) {
      $CHANGE_PARAMS{UNCHANGE_DISABLE} = 1;
    }
    else {
      $CHANGE_PARAMS{DISABLE} = $FORM{MU_DISABLE} || 0;
    }

    if ($#multiuser_arr < 0) {
      $html->message('err', $_MULTIUSER_OP, "$_SELECT_USER");
    }
    elsif (scalar keys %CHANGE_PARAMS < 1) {

      #$html->message('err', $_MULTIUSER_OP, "$_SELECT_USER");
    }
    else {
      foreach my $uid (@multiuser_arr) {
        if ($FORM{DEL} && $FORM{MU_DEL}) {
          my $user_info = $users->info($uid);
          user_del({ USER_INFO => $user_info });

          if ($users->{errno}) {
            $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");
          }
        }
        else {
          $users->change($uid, { UID => $uid, %CHANGE_PARAMS });
          if ($users->{errno}) {
            $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");
            return 0;
          }
        }
      }
      $html->message('info', $_MULTIUSER_OP, "$_TOTAL: " . $#multiuser_arr + 1 . " IDS: $FORM{IDS}");
    }
  }

  if (!$permissions{0}{2}) {
    return 0;
  }

  if ($FORM{COMPANY_ID} && !$FORM{change}) {
    print $html->br($html->b("$_COMPANY:") . $FORM{COMPANY_ID});
    $pages_qs .= "&COMPANY_ID=$FORM{COMPANY_ID}";
    $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID};
  }

  if ($FORM{letter}) {
    $LIST_PARAMS{LOGIN} = "$FORM{letter}*";
    $pages_qs .= "&letter=$FORM{letter}";
  }

  my @statuses = ($_ALL, $_ACTIV, $_DEBETORS, $_DISABLE, $_EXPIRE, $_CREDIT);
  if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) {
    push @statuses, $_DELETED,;
  }

  my $i            = 0;
  my $users_status = 0;
  foreach my $name (@statuses) {
    if (defined($FORM{USERS_STATUS}) && $FORM{USERS_STATUS} == $i && $FORM{USERS_STATUS} ne '') {
      $LIST_PARAMS{USER_STATUS} = 1;
      if ($i == 1) {
        $LIST_PARAMS{ACTIVE} = 1;
      }
      elsif ($i == 2) {
        $LIST_PARAMS{DEPOSIT} = '<0';
      }
      elsif ($i == 3) {
        $LIST_PARAMS{DISABLE} = 1;
      }
      elsif ($i == 4) {
        $LIST_PARAMS{EXPIRE} = "<$DATE,>0000-00-00";
      }
      elsif ($i == 5) {
        $LIST_PARAMS{CREDIT} = ">0";
      }
      elsif ($i == 6) {
        $LIST_PARAMS{DELETED} = 1;
      }

      $pages_qs   .= "&USERS_STATUS=$i";
      $status_bar .= ' ' . $html->b($name);
      $users_status = $i;
    }
    else {
      my $qs = $pages_qs;
      $qs =~ s/\&USERS_STATUS=\d//;
      $status_bar .= ' ' . $html->button("$name", "index=$index&USERS_STATUS=$i$qs");
    }
    $i++;
  }

  my $list = $users->list(
    {
      %LIST_PARAMS,
      FULL_LIST => 1,
      COLS_NAME => 1,
    }
  );

  if ($users->{errno}) {
    $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");
    return 0;
  }
  elsif ($users->{TOTAL} == 1) {
    $FORM{index} = 15;
    if (!$FORM{UID}) {
      $FORM{UID} = $list->[0]->{uid};
      if ($FORM{LOGIN} =~ /\*/ || $FORM{LOGIN} eq '') {
        delete $FORM{LOGIN};
        $ui = user_info($FORM{UID});
        print $ui->{TABLE_SHOW};
      }
    }

    form_users({ USER_INFO => $ui });
    return 0;
  }
  elsif ($users->{TOTAL} == 0) {
    $html->message('err', $_ERROR, "$_USER $_NOT_EXIST");
    return 0;
  }

  print $html->letters_list({ pages_qs => $pages_qs });

  my $TITLE = title_former(
    {
      INPUT_DATA      => $users,
      BASE_FIELDS     => 5,
      FUNCTION_FIELDS => 'payments, fees',
    }
  );

  #User list
  my $table = $html->table(
    {
      width      => '100%',
      caption    => "$_USERS - " . $statuses[$users_status],
      title      => $TITLE,
      cols_align => [ 'left', 'left', 'right', 'right', 'center', 'right', 'center:noprint', 'center:noprint' ],
      qs         => $pages_qs,
      pages      => $users->{TOTAL},
      ID         => 'USERS_LIST',
      header     => ($permissions{0}{7})
      ? "<script language=\"JavaScript\" type=\"text/javascript\">
<!-- 
function CheckAllINBOX() {
  for (var i = 0; i < document.users_list.elements.length; i++) {
    if(document.users_list.elements[i].type == 'checkbox' && document.users_list.elements[i].name == 'IDS'){
      document.users_list.elements[i].checked =         !(document.users_list.elements[i].checked);
    }
  }
}
//-->
</script>\n
<a href=\"javascript:void(0)\" onClick=\"CheckAllINBOX();\" class=export_button>$_SELECT_ALL</a>\n$status_bar"
      : undef,
      EXPORT => ' XML:&xml=1;',
      MENU   => "$_ADD:index=" . get_function_index('form_wizard') . ':add' . ";$_SEARCH:index=" . get_function_index('form_search') . ":search"
    }
  );
  my $base_fields = 5;
  foreach my $line (@$list) {
    my $uid      = $line->{uid};
    my $payments = ($permissions{1}) ? $html->button($_PAYMENTS, "index=2&UID=$uid", { CLASS => 'payments' }) : '';
    my $fees     = ($permissions{2}) ? $html->button($_FEES, "index=3&UID=$uid", { CLASS => 'fees' }) : '';

    my @fields_array = ();
    for (my $i = $base_fields ; $i < $base_fields + $users->{SEARCH_FIELDS_COUNT} ; $i++) {
      if ($conf{EXT_BILL_ACCOUNT} && $users->{COL_NAMES_ARR}->[$i] eq 'ext_bill_deposit') {
        $line->{ext_bill_deposit} = ($line->{ext_bill_deposit} < 0) ? $html->color_mark($line->{ext_bill_deposit}, $_COLORS[6]) : $line->{ext_bill_deposit};
      }
      elsif ($users->{COL_NAMES_ARR}->[$i] eq 'deleted') {
        $line->{deleted} = $html->color_mark($bool_vals[ $line->{deleted} ], ($line->{deleted} == 1) ? $state_colors[ $line->{deleted} ] : '');
      }
      push @fields_array, $table->td($line->{ $users->{COL_NAMES_ARR}->[$i] });
    }

    my $multiuser = ($permissions{0}{7}) ? $html->form_input('IDS', "$uid", { TYPE => 'checkbox', }) : '';
    $table->addtd(
      $table->td($multiuser . user_ext_menu($uid, $line->{id})),
      $table->td($line->{fio}),
      $table->td(($line->{deposit} + $line->{credit} < 0) ? $html->color_mark($line->{deposit}, $_COLORS[6]) : $line->{deposit}),
      $table->td($line->{credit}),
      $table->td($status[ $line->{disable} ], { bgcolor => $state_colors[ $line->{disable} ], align => 'center' }),
      @fields_array, $table->td($payments), $table->td($fees),
    );
  }

  my @totals_rows =
  ([ $html->button("$_TOTAL:", "index=$index&USERS_STATUS=0"), $html->b($users->{TOTAL}) ], [ $html->button("$_EXPIRE:", "index=$index&USERS_STATUS=2"), $html->b($users->{TOTAL_EXPIRED}) ], [ $html->button("$_DISABLE:", "index=$index&USERS_STATUS=3"), $html->b($users->{TOTAL_DISABLED}) ]);

  if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) {
    $users->{TOTAL} -= $users->{TOTAL_DELETED};
    $totals_rows[0] = [ $html->button("$_TOTAL:", "index=$index&USERS_STATUS=0"), $html->b($users->{TOTAL}) ];
    push @totals_rows, [ $html->button("$_DELETED:", "index=$index&USERS_STATUS=4"), $html->b($users->{TOTAL_DELETED}) ],;
  }

  my $table2 = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right' ],
      rows       => [@totals_rows]
    }
  );

  if ($permissions{0}{7}) {
    my $table3 = $html->table(
      {
        width      => '100%',
        caption    => "$_MULTIUSER_OP",
        cols_align => [ 'left', 'left' ],
        rowcolor   => $_COLORS[1],
        rows       => [
          [ $html->form_input('MU_GID', "1", { TYPE => 'checkbox', }) . $_GROUP, sel_groups() ],
          [ $html->form_input('MU_DISABLE',     "1", { TYPE => 'checkbox', }) . $_DISABLE,         $html->form_input('DISABLE',     "1", { TYPE => 'checkbox', }) . $_CONFIRM ],
          [ $html->form_input('MU_DEL',         "1", { TYPE => 'checkbox', }) . $_DEL,             $html->form_input('DEL',         "1", { TYPE => 'checkbox', }) . $_CONFIRM ],
          [ $html->form_input('MU_ACTIVATE',    "1", { TYPE => 'checkbox', }) . $_ACTIVATE,        $html->form_input('ACTIVATE',    "0000-00-00") ],
          [ $html->form_input('MU_EXPIRE',      "1", { TYPE => 'checkbox', }) . $_EXPIRE,          $html->form_input('EXPIRE',      "0000-00-00") ],
          [ $html->form_input('MU_CREDIT',      "1", { TYPE => 'checkbox', }) . $_CREDIT,          $html->form_input('CREDIT',      "0") ],
          [ $html->form_input('MU_CREDIT_DATE', "1", { TYPE => 'checkbox', }) . "$_CREDIT $_DATE", $html->form_input('CREDIT_DATE', "0000-00-00") ],
          [ '', $html->form_input('MULTIUSER', "$_CHANGE", { TYPE => 'submit' }) ],

        ]
      }
    );

    print $html->form_main(
      {
        CONTENT => $table->show({ OUTPUT2RETURN => 1 }) . ((!$admin->{MAX_ROWS}) ? $table2->show({ OUTPUT2RETURN => 1 }) : '') . $table3->show({ OUTPUT2RETURN => 1 }),
        HIDDEN => {
          index       => 11,
          FULL_DELETE => ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) ? 1 : undef,
        },
        NAME => 'users_list'
      }
    );

  }
  else {
    print $table->show();
    print $table2->show() if (!$admin->{MAX_ROWS});
  }
}

#**********************************************************
# user_form()
#**********************************************************
sub user_form {
  my ($attr) = @_;

  $index = 15 if (!$attr->{ACTION} && !$attr->{REGISTRATION});

  if ($FORM{add} || $FORM{change}) {
    form_users($attr);
  }
  elsif (!$attr->{USER_INFO}) {
    my $user = Users->new($db, $admin, \%conf);
    $user_info = $user->defaults();

    if ($FORM{COMPANY_ID}) {
      use Customers;
      my $customers = Customers->new($db, $admin, \%conf);
      my $company = $customers->company->info($FORM{COMPANY_ID});
      $user_info->{COMPANY_ID} = $FORM{COMPANY_ID};
      $user_info->{EXDATA} = "<tr><td>$_COMPANY:</td><td>" . (($company->{COMPANY_ID} > 0) ? $html->button($company->{COMPANY_NAME}, "index=13&COMPANY_ID=$company->{COMPANY_ID}", { BUTTON => 1 }) : '') . "</td></tr>\n";
    }

    if ($admin->{GIDS}) {
      $user_info->{GID} = sel_groups();
    }
    elsif ($admin->{GID}) {
      $user_info->{GID} .= $html->form_input('GID', "$admin->{GID}", { TYPE => 'hidden' });
    }
    else {
      $FORM{GID} = $attr->{GID};
      delete $attr->{GID};
      $user_info->{GID} = sel_groups();
    }

    $user_info->{EXDATA} .= $html->tpl_show(templates('form_user_exdata_add'), { %$attr, CREATE_BILL => ' checked' }, { OUTPUT2RETURN => 1 });
    $user_info->{EXDATA} .= $html->tpl_show(templates('form_ext_bill_add'), { CREATE_EXT_BILL => ' checked' }, { OUTPUT2RETURN => 1 }) if ($conf{EXT_BILL_ACCOUNT});

    if ($user_info->{DISABLE} > 0) {
      $user_info->{DISABLE} = ' checked';
      $user_info->{DISABLE_MARK} = $html->color_mark($html->b($_DISABLE), $_COLORS[6]);
    }
    else {
      $user_info->{DISABLE} = '';
    }

    my $main_account = $html->tpl_show(templates('form_user'), { %$user_info, %$attr }, { OUTPUT2RETURN => 1 });
    $main_account .= $html->tpl_show(templates('form_password'), { %$user_info, %$attr }, { OUTPUT2RETURN => 1 });

    $main_account =~ s/<FORM.+>//ig;
    $main_account =~ s/<\/FORM>//ig;
    $main_account =~ s/<input.+type=submit.+>//ig;
    $main_account =~ s/<input.+index.+>//ig;
    $main_account =~ s/user_form/users_pi/ig;

    user_pi({ MAIN_USER_TPL => $main_account, %$attr });
  }
  else {
    $user_info = $attr->{USER_INFO};
    $FORM{UID} = $user_info->{UID};
    $user_info->{COMPANY_NAME} = $html->color_mark("$_NOT_EXIST ID: $user_info->{COMPANY_ID}", $_COLORS[6]) if ($user_info->{COMPANY_ID} && !$user_info->{COMPANY_NAME});

    if ($permissions{1}) {
      $user_info->{PAYMENTS_BUTTON} = $html->button($_PAYMENTS, "index=2&UID=$LIST_PARAMS{UID}", { CLASS => 'payments rightAlignText' });
    }

    if ($permissions{2}) {
      $user_info->{FEES_BUTTON} = $html->button($_FEES, "index=3&UID=$LIST_PARAMS{UID}", { CLASS => 'fees rightAlignText' });
    }

    $user_info->{EXDATA} = $html->tpl_show(templates('form_user_exdata'), $user_info, { OUTPUT2RETURN => 1 });
    if ($conf{EXT_BILL_ACCOUNT} && $user_info->{EXT_BILL_ID}) {
      $user_info->{EXDATA} .= $html->tpl_show(templates('form_ext_bill'), $user_info, { OUTPUT2RETURN => 1 });
    }

    if ($user_info->{DISABLE} > 0) {
      $user_info->{DISABLE} = ' checked';
      $user_info->{DISABLE_MARK} = $html->color_mark($html->b($_DISABLE), $_COLORS[6]);

      my $list = $admin->action_list(
        {
          UID       => $user_info->{UID},
          TYPE      => 9,
          PAGE_ROWS => 1,
          SORT      => 1,
          DESC      => 'DESC'
        }
      );
      if ($admin->{TOTAL} > 0) {
        $user_info->{DISABLE_COMMENTS} = $list->[0][3];
      }
    }
    else {
      $user_info->{DISABLE} = '';
    }

    $user_info->{ACTION}     = 'change';
    $user_info->{LNG_ACTION} = $_CHANGE;

    if ($permissions{5}) {
      my $info_field_index = get_function_index('form_info_fields');
      $user_info->{ADD_INFO_FIELD} = $html->button("$_ADD $_INFO_FIELDS", "index=$info_field_index", { CLASS => 'add rightAlignText', ex_params => ' target=_info_fields' });
    }

    if ($permissions{0}{3}) {
      $user_info->{PASSWORD} =
      ($FORM{SHOW_PASSWORD})
      ? "$_PASSWD: '$user_info->{PASSWORD}'"
      : $html->button("$_SHOW $_PASSWD", "index=$index&UID=$LIST_PARAMS{UID}&SHOW_PASSWORD=1", { BUTTON => 1 }) . ' ' . $html->button("$_CHANGE $_PASSWD", "index=" . get_function_index('form_passwd') . "&UID=$LIST_PARAMS{UID}", { BUTTON => 1 });
    }

    if (in_array('Sms', \@MODULES)) {
      $user_info->{PASSWORD} .= ' ' . $html->button("$_SEND $_PASSWD SMS", "index=$index&header=1&UID=$LIST_PARAMS{UID}&SHOW_PASSWORD=1&SEND_SMS_PASSWORD=1", { BUTTON => 1, MESSAGE => "$_SEND $_PASSWD SMS ?" });
    }

    if ($attr->{REGISTRATION}) {
      my $main_account = $html->tpl_show(templates('form_user'), { %$user_info, %$attr }, { OUTPUT2RETURN => 1 });
      $main_account =~ s/<FORM.+>//ig;
      $main_account =~ s/<\/FORM>//ig;
      $main_account =~ s/<input.+type=submit.+>//ig;
      $main_account =~ s/<input.+index.+>//ig;
      $main_account =~ s/user_form/users_pi/ig;
      user_pi({ MAIN_USER_TPL => $main_account, %$attr });
    }
    else {
      $html->tpl_show(templates('form_user'), $user_info);
    }
  }

}

#**********************************************************
# Get function index
#
# get_function_index($function_name, $attr)
#**********************************************************
sub get_function_index {
  my ($function_name, $attr) = @_;
  my $function_index = 0;

  foreach my $k (keys %functions) {
    my $v = $functions{$k};
    if ($v eq "$function_name") {
      $function_index = $k;
      if ($attr->{ARGS} && $attr->{ARGS} ne $menu_args{$k}) {
        next;
      }
      last;
    }
  }

  return $function_index;
}

#**********************************************************
# user_pi()
#**********************************************************
sub user_pi {
  my ($attr) = @_;

  my $user;
  if ($attr->{USER_INFO}) {
    $user = $attr->{USER_INFO};
  }
  else {
    $user = $users->info($FORM{UID});
  }

  if ($FORM{ATTACHMENT}) {
    form_show_attach();
    return 0;
  }
  elsif ($FORM{address}) {
    form_address_sel();
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");
      return 0;
    }

    my $user_pi = $user->pi_add({%FORM});
    if (!$user_pi->{errno}) {
      return 0 if ($attr->{REGISTRATION});
      $html->message('info', $_ADDED, "$_ADDED");
    }
  }
  elsif ($FORM{change}) {
    if (!$permissions{0}{4}) {
      $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");
      return 0;
    }

    my $user_pi = $user->pi_change({%FORM});
    if (!$user_pi->{errno}) {
      $html->message('info', $_CHAGED, "$_CHANGED");
    }
  }

  if ($user_pi->{errno}) {
    $html->message('err', $_ERROR, "[$user_pi->{errno}] $err_strs{$user_pi->{errno}}");
  }

  my $user_pi = $user->pi();

  if ($user_pi->{TOTAL} < 1 && $permissions{0}{1}) {
    if ($attr->{ACTION}) {
      $user_pi->{ACTION}     = $attr->{ACTION};
      $user_pi->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user_pi->{ACTION}     = 'add';
      $user_pi->{LNG_ACTION} = $_ADD;
    }
  }
  elsif ($permissions{0}{4}) {
    if ($attr->{ACTION}) {
      $user_pi->{ACTION}     = $attr->{ACTION};
      $user_pi->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user_pi->{ACTION}     = 'change';
      $user_pi->{LNG_ACTION} = $_CHANGE;
    }
    $user_pi->{ACTION} = 'change';
  }

  #Info fields
  my $i = 0;
  foreach my $field_id (@{ $user_pi->{INFO_FIELDS_ARR} }) {
    my ($position, $type, $name, $user_portal) = split(/:/, $user_pi->{INFO_FIELDS_HASH}->{$field_id});

    my $input = '';
    if ($type == 2) {
      $input = $html->form_select(
        "$field_id",
        {
          SELECTED          => $user_pi->{INFO_FIELDS_VAL}->[$i],
          SEL_MULTI_ARRAY   => $user->info_lists_list({ LIST_TABLE => $field_id . '_list' }),
          MULTI_ARRAY_KEY   => 0,
          MULTI_ARRAY_VALUE => 1,
          SEL_OPTIONS       => { 0 => '-N/S-' },
          NO_ID             => 1
        }
      );

    }
    elsif ($type == 4) {
      $input = $html->form_input(
        $field_id,
        1,
        {
          TYPE  => 'checkbox',
          STATE => ($user_pi->{INFO_FIELDS_VAL}->[$i]) ? 1 : undef
        }
      );
    }

    #'ICQ',
    elsif ($type == 8) {
      $input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { SIZE => 10 });
      if ($user_pi->{INFO_FIELDS_VAL}->[$i] ne '') {

        #
        $input .= " <a href=\"http://www.icq.com/people/about_me.php?uin=$user_pi->{INFO_FIELDS_VAL}->[$i]\"><img  src=\"http://status.icq.com/online.gif?icq=$user_pi->{INFO_FIELDS_VAL}->[$i]&img=21\" border=0></a>";
      }
    }

    #'URL',
    elsif ($type == 9) {
      $input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { SIZE => 35 })
      . $html->button(
        "$_GO", "",
        {
          GLOBAL_URL => "$user_pi->{INFO_FIELDS_VAL}->[$i]",
          ex_params  => ' target=' . $user_pi->{INFO_FIELDS_VAL}->[$i],
          BUTTON     => 1
        }
      );
    }

    #'PHONE',
    #'E-Mail'
    #'SKYPE'
    elsif ($type == 12) {
      $input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { SIZE => 20 });
      if ($user_pi->{INFO_FIELDS_VAL}->[$i] ne '') {
        $input .=
        qq{  <script type="text/javascript" src="http://download.skype.com/share/skypebuttons/js/skypeCheck.js"></script>  <a href="skype:abills.support?call"><img src="http://mystatus.skype.com/smallclassic/$user_pi->{INFO_FIELDS_VAL}->[$i]" style="border: none;" width="114" height="20"/></a>};
      }
    }
    elsif ($type == 3) {
      $input = $html->form_textarea($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]");
    }
    elsif ($type == 13) {
      $input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { TYPE => 'file' });
      if ($user_pi->{INFO_FIELDS_VAL}->[$i]) {
        $user_pi->attachment_info({ ID => $user_pi->{INFO_FIELDS_VAL}->[$i], TABLE => $field_id . '_file' });

        $input .= ' ' . $html->button("$user_pi->{FILENAME}, " . int2byte($user_pi->{FILESIZE}), "qindex=" . get_function_index('user_pi') . "&ATTACHMENT=$field_id:$user_pi->{INFO_FIELDS_VAL}->[$i]", { BUTTON => 1 });
      }
    }
    else {
      $user_pi->{INFO_FIELDS_VAL}->[$i] =~ s/\"/&quot;/g;
      $input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { SIZE => 40 });
    }

    $user_pi->{INFO_FIELDS} .= "<tr><td>" . (eval "\"$name\"") . ":</td><td valign=center>$input</td></tr>\n";
    $i++;
  }

  if (in_array('Docs', \@MODULES)) {
    $user_pi->{PRINT_CONTRACT} = $html->button("$_PRINT", "qindex=15&UID=$user_pi->{UID}&PRINT_CONTRACT=$user_pi->{UID}" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''), { ex_params => ' target=new', CLASS => 'print rightAlignText' });

    if ($conf{DOCS_CONTRACT_TYPES}) {
      $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
      my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});

      my %CONTRACTS_LIST_HASH = ();
      $FORM{CONTRACT_SUFIX} = "|$user_pi->{CONTRACT_SUFIX}";
      foreach my $line (@contract_types_list) {
        my ($prefix, $sufix, $name, $tpl_name) = split(/:/, $line);
        $prefix =~ s/ //g;
        $CONTRACTS_LIST_HASH{"$prefix|$sufix"} = $name;
      }

      $user_pi->{CONTRACT_TYPE} = " $_TYPE: "
      . $html->form_select(
        'CONTRACT_TYPE',
        {
          SELECTED => $FORM{CONTRACT_SUFIX},
          SEL_HASH => { '' => '', %CONTRACTS_LIST_HASH },
          NO_ID    => 1
        }
      );
    }
  }

  if ($conf{ACCEPT_RULES}) {
    $user_pi->{ACCEPT_RULES} = ($user_pi->{ACCEPT_RULES}) ? $_YES : $html->color_mark($html->b($_NO), $_COLORS[6]);
  }

  $index = 30 if (!$attr->{MAIN_USER_TPL});
  $user_pi->{PASPORT_DATE} = $html->date_fld2(
    'PASPORT_DATE',
    {
      FORM_NAME => 'users_pi',
      WEEK_DAYS => \@WEEKDAYS,
      MONTHES   => \@MONTHES,
      DATE      => $user_pi->{PASPORT_DATE}
    }
  );

  $user_pi->{CONTRACT_DATE} = $html->date_fld2(
    'CONTRACT_DATE',
    {
      FORM_NAME => 'users_pi',
      WEEK_DAYS => \@WEEKDAYS,
      MONTHES   => \@MONTHES,
      DATE      => $user_pi->{CONTRACT_DATE}
    }
  );

  if ($conf{ADDRESS_REGISTER}) {
    my $add_address_index = get_function_index('form_districts');
    $user_pi->{ADD_ADDRESS_LINK} = $html->button("$_ADD $_ADDRESS", "index=$add_address_index", { CLASS => 'add rightAlignText' });
    $user_pi->{ADDRESS_TPL} = $html->tpl_show(templates('form_address_sel'), $user_pi, { OUTPUT2RETURN => 1 });
  }
  else {
    my $countries = $html->tpl_show(templates('countries'), undef, { OUTPUT2RETURN => 1 });
    my @countries_arr = split(/\n/, $countries);
    my %countries_hash = ();
    foreach my $c (@countries_arr) {
      my ($id, $name) = split(/:/, $c);
      $countries_hash{ int($id) } = $name;
    }
    $user_pi->{COUNTRY_SEL} = $html->form_select(
      'COUNTRY_ID',
      {
        SELECTED => $user_pi->{COUNTRY_ID},
        SEL_HASH => { '' => '', %countries_hash },
        NO_ID    => 1
      }
    );
    $user_pi->{ADDRESS_TPL} = $html->tpl_show(templates('form_address'), $user_pi, { OUTPUT2RETURN => 1 });
  }

  $html->tpl_show(templates('form_pi'), { %$attr, UID => $LIST_PARAMS{UID}, %$user_pi, });
}

1

