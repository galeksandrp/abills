#!/usr/bin/perl


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

my $html = Abills::HTML->new( { IMG_PATH => 'img/' } );
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};

require "../language/$html->{language}.pl";
my $sid = $FORM{sid} || 0; # Session ID
if ((length($COOKIES{sid})>1) && (! $FORM{passwd})) {
 $sid = $COOKIES{sid};
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

print $html->header();
my $sessions='sessions.db';
my $uid = 0;
my $page_qs;


print << "[END]";
<table width=100% border=1>
<tr bgcolor=$_COLORS[0]><td align=right>
<h3>ABillS</h3>
</td>
</tr>
</table>
<center>
<table width=90%>
<tr><td align=center>
[END]

my $login = $FORM{user};
my $passwd = $FORM{passwd} || '';


my $user=Users->new($db, undef, \%conf); 
($uid, $sid, $login) = auth("$login", "$passwd", "$sid");

if ($uid > 0) {
  mk_navigator();
  $pages_qs="&UID=$user->{UID}&sid=$sid";
  if ($index != 0 && defined($functions{$index})) {
#    my $m;
#    while(my($k, $v) = each %$sub_menus ) {
#  	  $m .= "<a  href='$SELF_URL?index=$k'>$v</a> :: ";
#     }
#    if ($m ne '') {
#      print "<Table width=100% border=0><tr><td align=right>$m</td></tr></table>\n";
#     }
    $functions{$index}->();
   }
  else {
    $functions{22}->();
   }
}
else {
  form_login();
}

print "</td></tr></table><hr>\n";


#DEBUG#####################################
print "<table border=1>
<tr><td>index</td><td>$index</td></td></tr>
<tr bgcolor=$_COLORS[2]><td>OP</td><td>$OP</td></tr>\n";	

  while(my($k, $v)=each %FORM) {
    print "<tr><td>$k</td><td>$v</td></tr>\n";	
   }
print "</table>\n";


print "<br><table border=1>
<tr><td>index</td><td>$index</td></td></tr>
<tr bgcolor=$_COLORS[2]><td>OP</td><td>$OP</td></tr>\n";	

  while(my($k, $v)=each %COOKIES) {
    print "<tr><td>$k</td><td>$v</td></tr>\n";	
   }
print "</table>\n";

#DEBUG#####################################






#==========================================================

#**********************************************************
# form_stats
#**********************************************************
sub form_stats {
 Abills::HTML->tpl_show(templates('client_info'), $user);



	#my $user = $attr->{USER};

	$UID = $user->{UID};
	$LIST_PARAMS{UID} = $user->{UID};
	if (! defined($FORM{sort})) {
	  $LIST_PARAMS{SORT}=2;
	  $LIST_PARAMS{DESC}=DESC;
   }


 
use Sessions;
my $sessions = Sessions->new($db);

if ($FORM{del} && $FORM{is_js_confirmed}) {
	if(! defined($permissions{3}{1})) {
     message('err', $_ERROR, 'ACCESS DENY');
     return 0;
	 } 

	my ($UID, $session_id, $nas_id, $session_start_date, $session_start_time, $sum, $login)=split(/ /, $FORM{del}, 7);
	$sessions->del($UID, $session_id, $nas_id, "$session_start_date $session_start_time");
  if (! $sessions->{errno})	 {
  	message('info', $_DELETED, "$_LOGIN: $login<br> SESSION_ID: $session_id<br> NAS_ID: $nas_id<br> SESSION_START: $session_start_date $session_start_time<br> $_SUM: $sum");
    form_back_money('log', $sum, { UID => $UID }); #
    return 0;
   }
}

if ($sessions->{errno})	 {
	message('err', $_ERROR, "[$account->{errno}] $err_strs{$account->{errno}}");
 }


if ($FORM{rows}) {
  $LIST_PARAMS{PAGE_ROWS}=$FORM{rows};
  $conf{list_max_recs}=$FORM{rows};
  $pages_qs .= "&rows=$conf{list_max_recs}";
 }


#PEriods totals
my $list = $sessions->periods_totals({ %LIST_PARAMS });
my $table = Abills::HTML->table( { width => '100%',
                                   title_plain => ["$_PERIOD", "$_DURATION", "$_SEND", "$_RECV", "$_SUM"],
                                   cols_align => ['left', 'right', 'right', 'right', 'right'],
                                   rowcolor => $_COLORS[1]
                                  } );
for(my $i = 0; $i < 5; $i++) {
	  $table->addrow("<a href='$SELF_URL?index=$index&period=$i$pages_qs'>$PERIODS[$i]</a>", "$sessions->{'duration_'. $i}",
	  int2byte($sessions->{'sent_'. $i}), int2byte($sessions->{'recv_'. $i}), int2byte($sessions->{'sum_'. $i}));
 }
print $table->show();


print "<form action=$SELF_URL>
<input type=hidden name=sid value='$sid'>
<input type=hidden name=index value='$index'>
<input type=hidden name=UID value='$UID'>\n";

my $table = Abills::HTML->table( { width => '640',
	                                 rowcolor => $_COLORS[0],
                                   title_plain => [ "$_FROM: ", Abills::HTML->date_fld('from', { MONTHES => \@MONTHES} ),
                                   "$_TO: ", Abills::HTML->date_fld('to', { MONTHES => \@MONTHES } ),
                                   "$_ROWS: ",  "<input type=text name=rows value='$conf{list_max_recs}' size=4>",
                                   "<input type=submit name=show value=$_SHOW>"
                                    ],                                   
                                  } );
print $table->show();
print "</form>\n";

stats_calculation($sessions);

if (defined($FORM{show})) {
  $pages_qs .= "&show=y&fromd=$FORM{fromd}&fromm=$FORM{fromm}&fromy=$FORM{fromy}&tod=$FORM{tod}&tom=$FORM{tom}&toy=$FORM{toy}";
  $FORM{fromm}++;
  $FORM{tom}++;
  $FORM{fromm} = sprintf("%.2d", $FORM{fromm}++);
  $FORM{tom} = sprintf("%.2d", $FORM{tom}++);
  $LIST_PARAMS{INTERVAL} = "$FORM{fromy}-$FORM{fromm}-$FORM{fromd}/$FORM{toy}-$FORM{tom}-$FORM{tod}";
 }
elsif ($FORM{period}) {
	$LIST_PARAMS{PERIOD} = $FORM{period}; 
	$pages_qs .= "&period=$FORM{period}";
}

if (! defined($FORM{sort})) {
  $LIST_PARAMS{SORT}=2;
  $LIST_PARAMS{DESC}=DESC;
 }

#Session List
my $list = $sessions->list({ %LIST_PARAMS });	

$table = Abills::HTML->table( { width => '640',
	                              rowcolor => $_COLORS[1],
                                title_plain => ["$_SESSIONS", "$_DURATION", "$_TRAFFIC", "$_SUM"],
                                cols_align => ['right', 'right', 'right', 'right'],
                                rows => [ [ $sessions->{TOTAL}, $sessions->{DURATION}, int2byte($sessions->{TRAFFIC}), $sessions->{SUM} ] ],
                               } );
print "<p>" . $table->show() . "</p>\n";	

show_sessions($list, $sessions);


}




#**********************************************************
# Whow sessions from log
# show_sessions()
#**********************************************************
sub show_sessions {
  my ($list, $sessions) = @_;
#Session List

if (! $list) {
  if (! defined($FORM{sort})) {
	  $LIST_PARAMS{SORT} = 2;
	  $LIST_PARAMS{DESC} = 'DESC';
  }
  use Sessions;
  $sessions = Sessions->new($db);
  $list = $sessions->list({ %LIST_PARAMS });	
}


return 0 if ($sessions->{TOTAL} < 1);



my $table = Abills::HTML->table( { width => '100%',
                                border => 1,
                                title => ["$_USER", "$_START", "$_DURATION", "$_TARIF_PLAN", "$_SENT", "$_RECV", 
                                "CID", "NAS", "IP", "$_SUM", "-", "-"],
                                cols_align => ['left', 'right', 'right', 'left', 'right', 'right', 'right', 'right', 'right', 'right', 'center'],
                                qs => $pages_qs,
                                pages => $sessions->{TOTAL},
                                recs_on_page => $LIST_PARAMS{PAGE_ROWS}
                               } );
my $delete = '';
foreach my $line (@$list) {
  if ($permissions{3}{1}) {
    $delete = $html->button($_DEL, "index=22$pages_qs&del=$line->[12]+$line->[11]+$line->[7]+$line->[1]+$line->[9]+$line->[0]", "$_DEL Session SESSION_ID $line->[11]?");
   }

  $table->addrow($line->[0], 
     $line->[1], $line->[2],  $line->[3],  int2byte($line->[4]), int2byte($line->[5]), $line->[6],
     $line->[7], $line->[10], $line->[9], 
     "(<a href='$SELF_URL?index=23&UID=$user->{UID}&detail=$line->[11]' title='Session Detail'>D</a>)", $delete);
}

print $table->show();
}



#*******************************************************************
# WHERE period
# base_state($where, $period);
#*******************************************************************
sub stats_calculation  {
 my ($sessions) = @_;

$sessions->calculation({ %LIST_PARAMS }); 
my $table = Abills::HTML->table( { width => '640',
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
# mk_navigator()
#**********************************************************
sub mk_navigator {
 my $menu_navigator = "";

# ID:PARENT:NAME:FUNCTION:SHOW SUBMENU:OP:
my @m = ( 
 "16:11:$_TARIF_PLAN:form_chg_tp:0::",
 "17:11:$_PASSWD:form_passwd:0:password:",
 "20:11:$_SEVICES:user_services:0::",
 "22:11:$_STATS:form_stats:1::"
 );

foreach my $line (@m) {
	my ($ID, $PARENT, $NAME, $FUNTION_NAME, $SHOW_SUBMENU, $OP)=split(/:/, $line);
  $menu_items{$ID}{$PARENT}=$NAME;
  $menu_names{$ID}=$NAME;
  $functions{$ID}=\&$FUNTION_NAME if ($FUNTION_NAME  ne '');
  $show_submenu{$ID}='y' if ($SHOW_SUBMENU == 1);
  $op_names{$ID}=$OP if ($OP ne '');
}

}



#**********************************************************
# form_login
#**********************************************************
sub form_login {

print "<form action=$SELF_URL METHOD=post>
<TABLE width=400 cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0><TR><TD bgcolor=$_BG1>
<TABLE width=100% cellspacing=0 cellpadding=0 border=0>
<tr><td>$_LOGIN:</td><td><input type=text name=user></td></tr>
<tr><td>$_PASSWD:</td><td><input type=password name=passwd></td></tr>
<tr><td>$_LANGUAGE:</td><td><select name=ln>\n";

while(my($k, $v) = each %LANG) {
  print "<option value='$k'";
  print ' selected' if ($k eq $language);
  print ">$v\n";	
}

print "</seelct></td></tr>
<tr><th colspan=2><input type=submit name=logined value=$_ENTER></th></tr>
</table>

</td></tr></table>
</td></tr></table>
</form>\n";

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
    
    if ($cur_time - $time > $session_timeout) {
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
    message('err', "$_ERROR", $_NOT_LOGINED);	
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



