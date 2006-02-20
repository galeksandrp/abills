#!/usr/bin/perl
# User Web interface
#
#

#use vars qw($begin_time);
BEGIN {
 my $libpath = '../';
 
 $sql_type='mysql';
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');

 eval { require Time::HiRes; };
 if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
   }
 else {
    $begin_time = 0;
  }
}


require "config.pl";
require "Abills/defs.conf";
require "Abills/templates.pl";
use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Users;

my $output = Abills::HTML;

$html = $output->new( { IMG_PATH => 'img/',
	                      NO_PRINT  => 'y' } );
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};

$html->{language}=$FORM{language} if (defined($FORM{language}));

require "../language/$html->{language}.pl";
$sid = $FORM{sid} || ''; # Session ID
if ((length($COOKIES{sid})>1) && (! $FORM{passwd})) {
  $sid = $COOKIES{sid};
}
elsif((length($COOKIES{sid})>1) && (defined($FORM{passwd}))){
	#print "Content-TYpe: text/html\n\n";
	$html->setCookie('sid', "", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
	$COOKIES{sid}=undef;
	#exit;
}

#Cookie section ============================================
if (defined($FORM{colors})) {
  my $cook_colors = (defined($FORM{default})) ?  '' : $FORM{colors};
  $html->setCookie('colors', "$cook_colors", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
 }
#Operation system ID
$html->setCookie('OP_SID', "$FORM{OP_SID}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
$html->setCookie('language', "$FORM{language}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure) if (defined($FORM{language}));

if (defined($FORM{sid})) {
  $html->setCookie('sid', "$FORM{sid}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
}

#$html->setCookie('qm', "$FORM{qm_item}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure) if (defined($FORM{quick_set}));
#===========================================================

print $html->header({ CHARSET => $CHARSET });
my $sessions='admin/sessions.db';
my $maxnumber = 0;
my $uid = 0;
my $page_qs;
my $admin;
my %OUTPUT = ();


#print << "[END]";
#<TABLE width="100%" border="0">
#<TR bgcolor="$_COLORS[0]"><TD align="right"><h3>ABillS</h3></TD></TR>
#</TABLE>
#<TABLE width="100%">
#<TR><TD align="center">
#[END]

my $login = $FORM{user} || '';
my $passwd = $FORM{passwd} || '';

 my @m = ( 
   "10:0:$_LOGOUT:logout:::",
   "30:0:$_USER_INFO:form_info:::"
   );






my $user=Users->new($db, undef, \%conf); 
($uid, $sid, $login) = auth("$login", "$passwd", "$sid");

if ($uid > 0) {

  push @m, "17:0:$_PASSWD:form_passwd:::"   if($conf{user_chg_passwd} eq 'yes');

  foreach my $line (@m) {
	  my ($ID, $PARENT, $NAME, $FUNTION_NAME, $SHOW_SUBMENU, $OP)=split(/:/, $line);
    $menu_items{$ID}{$PARENT}=$NAME;
    $menu_names{$ID}=$NAME;
    $functions{$ID}=\&$FUNTION_NAME if ($FUNTION_NAME  ne '');
    $maxnumber=$ID if ($maxnumber < $ID);
   }

  foreach my $m (@MODULES) {
  	require "Abills/modules/$m/config";
    my %module_fl=();

    #next if (keys %USER_FUNCTION_LIST < 1);
    my @sordet_module_menu = sort keys %USER_FUNCTION_LIST;

    foreach my $line (@sordet_module_menu) {
      $maxnumber++;
      my($ID, $SUB, $NAME, $FUNTION_NAME, $ARGS)=split(/:/, $line, 5);
      $ID = int($ID);
      my $v = $FUNCTIONS_LIST{$line};

      $module_fl{"$ID"}=$maxnumber;
      $menu_args{$maxnumber}=$ARGS if ($ARGS ne '');
      #print "$line -- $ID, $SUB, $NAME, $FUNTION_NAME  // $module_fl{$SUB}<br/>";
     
      if($SUB > 0) {
        $menu_items{$maxnumber}{$module_fl{$SUB}}=$NAME;
       } 
      else {
        $menu_items{$maxnumber}{0}=$NAME;
        if ($SUB == -1) {
          $uf_menus{$maxnumber}=$NAME;
         }
      }
      $menu_names{$maxnumber}=$NAME;
      $functions{$maxnumber}=\&$FUNTION_NAME if ($FUNTION_NAME  ne '');
      $module{$maxnumber}=$m;
    }
  }

  (undef, $OUTPUT{MENU}) = $html->menu(\%menu_items, \%menu_args, undef, 
     { EX_ARGS => "&sid=$sid", ALL_PERMISSIONS => 'y' });
  
  if ($html->{ERROR}) {
  	message('err',  $_ERROR, "$html->{ERROR}");
  	exit;
  }

  $OUTPUT{DATE}=$DATE;
  $OUTPUT{TIME}=$TIME;

  $pages_qs="&UID=$user->{UID}&sid=$sid";
  $LIST_PARAMS{UID}=$user->{UID};
  $LIST_PARAMS{LOGIN}=$user->{LOGIN};

  if(defined($module{$index})) {
 	 	require "Abills/modules/$module{$index}/webinterface";
   }


  if ($index != 0 && defined($functions{$index})) {
    $functions{$index}->();
   }
  else {
    $functions{30}->();
   }

  $OUTPUT{BODY}=$html->{OUTPUT};

  $OUTPUT{BODY}=$html->tpl_show(templates('users_main'), \%OUTPUT);
}
else {
  form_login();
}

print $html->tpl_show(templates('users_start'), \%OUTPUT);


$html->test();


#==========================================================



#**********************************************************
# form_stats
#**********************************************************
sub form_info {
  $user->pi();
  
  use Finance;
  my $payments = Finance->payments($db, $admin);
  $LIST_PARAMS{PAGE_ROWS}=1;
  $LIST_PARAMS{DESC}='desc';
  $LIST_PARAMS{SORT}=1;
  my $list = $payments->list( { %LIST_PARAMS } );
  
  $user->{PAYMENT_DATE}=$list->[0]->[2];
  $user->{PAYMENT_SUM}=$list->[0]->[3];
  $html->tpl_show(templates('client_info'), $user);
}






#*******************************************************************
# WHERE period
# base_state($where, $period);
#*******************************************************************
sub stats_calculation  {
  my ($sessions) = @_;

$sessions->calculation({ %LIST_PARAMS }); 
my $table = $html->table( { width => '640',
	                              rowcolor => $_COLORS[1],
                                title_plain => ["-", "$_MIN", "$_MAX", "$_AVG"],
                                cols_align => ['left', 'right', 'right', 'right'],
                                rows => [ [ $_DURATION,  $sessions->{min_dur}, $sessions->{max_dur}, $sessions->{avg_dur} ],
                                          [ "$_TRAFFIC $_RECV", int2byte($sessions->{min_recv}), int2byte($sessions->{max_recv}), int2byte($sessions->{avg_recv}) ],
                                          [ "$_TRAFFIC $_SENT", int2byte($sessions->{min_sent}), int2byte($sessions->{max_sent}), int2byte($sessions->{avg_sent}) ],
                                          [ "$_TRAFFIC $_SUM",  int2byte($sessions->{min_sum}),  int2byte($sessions->{max_sum}),  int2byte($sessions->{avg_sum}) ]
                                        ]
                               } );
print $table->show();
}


#**********************************************************
# form_login
#**********************************************************
sub form_login {
 my %first_page = ();
 $first_page{SEL_LANGUAGE} = $html->form_select('language', 
                                { EX_PARAMS => 'onChange="selectLanguage()"',
 	                                SELECTED  => $html->{language},
 	                                SEL_HASH  => \%LANG,
 	                                NO_ID     => 'y' });

 $OUTPUT{BODY} = $html->tpl_show(templates('form_user_login'), \%first_page);
}


#*******************************************************************
# FTP authentification
# auth($login, $pass)
#*******************************************************************
sub auth { 
 my ($login, $password, $sid) = @_;
 my $uid = 0;
 my $ret = 0;
 my $REMOTE_ADDR = $ENV{'REMOTE_ADDR'} || '';
 my $HTTP_X_FORWARDED_FOR = $ENV{'HTTP_X_FORWARDED_FOR'} || '';
 my $ip = "$REMOTE_ADDR/$HTTP_X_FORWARDED_FOR";

 use DB_File; 
 tie %h, "DB_File",  "$sessions", O_RDWR|O_CREAT, 0640, $DB_HASH
         or die "Cannot open file '$sessions': $!\n";
 


if ($FORM{op} eq 'logout') {
  delete $h{$sid} ;
  untie %h;
  return 0;
 }
elsif (length($sid) > 1) {
  if (defined($h{$sid})) {
    ($uid, $time, $login, $ip)=split(/:/, $h{$sid});
    my $cur_time = time;
    
    if ($cur_time - $time > $conf{web_session_timeout}) {
      #print "$cur_time - $time > '$conf{web_session_timeout}'";
      #web_session_timeout
      delete $h{$sid};
      message('info', "$_INFO", 'timeout');	
      return 0; 
     }
    elsif($ip ne $REMOTE_ADDR) {
      message('err', "$_ERROR", 'WRONG IP');	
      return 0; 
     }

    $user->info($uid);

    #print "'$uid', $time,  $ip<b>$_WELCOME</b> $uid \n";
    untie %h;
    return ($uid, $sid, $login);
   }
  else { 
    message('err', "$_ERROR", "$_NOT_LOGINED");	
    return 0; 
   }
 }
else {
# print "$sid";
  return 0 if (! $login  || ! $password);
  
  $res = auth_sql("$login", "$password");
  if ($res < 1) {
    
    eval { require Net::FTP; };
    if (! $@) {
      Net::FTP->import();
      my $ftp = Net::FTP->new($ftpserver) || die "could not connect to the server '$ftpserver' $!";
      $res = $ftp->login("$login", "$password");
      $ftp->quit();
     }
    else {
      message('info', $_INFO, "Install 'libnet' module from http://cpan.org");
     }
   }
}
#Get user ip

if ($res > 0) {
  $user->info(0, { LOGIN => "$login" });

  if ($user->{TOTAL} > 0) {
    $ret = $user->{UID};
    $time = time;
    $sid = mk_unique_value(14);
    $h{$sid} = "$ret:$time:$login:$REMOTE_ADDR";
    untie %h;
    $action = 'Access';
   }
  else {
    message('err', "$_ERROR", "$_WRONG_PASSWD");
    $action = 'Error';
   }
 }
#elsif ($res == undef) {
#   return ($pass eq $universal_pass) ? 0 : 1;
#  }
else {
   message('err', "$_ERROR", "$_WRONG_PASSWD");
   $ret = 0;
   $action = 'Error';
 }

 open(FILE, ">>login.log") || die "can't open file 'login.log' $!";
   print FILE "$DATE $TIME $action:$login:$logined:$ip\n";
 close(FILE);

 return ($ret, $sid, $login);
}


#*******************************************************************
# Authentification from SQL DB
# auth_sql($login, $password)
#*******************************************************************
sub auth_sql {
 my ($login, $password) = @_;
 my $ret = 0;

 $user->info(0, {
 	                   LOGIN => "$login", 
 	                   PASSWORD => "$password" }
 	               ); 

if ($user->{TOTAL} < 1) {
  #message('err', $_ERROR, "$_NOT_FOUND");
}
elsif($user->{errno}) {
	message('err', $_ERROR, "$user->{errno} $user->{errstr}");
}
else {
  $ret = $user->{UID};
}

#else {
#  message('err', "$_ERROR", "$_WRONG_PASSWD");
#  $action = 'Error';
#  $ret = -1;
#}

 return $ret;	
}


#**********************************************************
# form_passwd($attr)
#**********************************************************
sub form_passwd {
 my ($attr)=@_;
 my $hidden_inputs;

 
if ($FORM{newpassword} eq '') {

}
elsif (length($FORM{newpassword}) < $conf{passwd_length}) {
  message('err', $_ERROR, $err_strs{6});
}
elsif ($FORM{newpassword} eq $FORM{confirm}) {
  %INFO = ( PASSWORD => $FORM{newpassword},
            UID      => $user->{UID}
            );

  $user->change($user->{UID}, { %INFO });

  if(!$user->{errno}) {
  	 message('info', $_INFO, "$_CHANGED");	
   }
  else {
  	 message('err', $_ERROR, "[$user->{errno}] $err_strs{$user->{errno}}");	
   }
  return 0;
}
elsif($FORM{newpassword} ne $FORM{confirm}) {
  message('err', $_ERROR, $err_strs{5});
}


 $html->tpl_show(templates('form_password'), undef);

 return 0;
}

sub logout {
	$FORM{op}='logout';
	auth('', '', $sid);
	message('info', $_INFO, $_LOGOUT);
	
	
	
	return 0;
}

