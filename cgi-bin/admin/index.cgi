#!/usr/bin/perl
# 701082
# http://www.maani.us/charts/index.php
#use vars qw($begin_time);
BEGIN {
 my $libpath = '../../';
 
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

#
#==== End config


















#use FindBin '$Bin2';
use Abills::SQL;
use Abills::HTML;
use Nas;
use Admins;

$html = Abills::HTML->new();
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});

$db = $sql->{db};
my $admin = Admins->new($db, \%conf);
require "../../language/$html->{language}.pl";
%permissions = ();


#**********************************************************
#IF Mod rewrite enabled
#
#    <IfModule mod_rewrite.c>
#        RewriteEngine on
#        RewriteCond %{HTTP:Authorization} ^(.*)
#        RewriteRule ^(.*) - [E=HTTP_CGI_AUTHORIZATION:%1]
#        Options Indexes ExecCGI SymLinksIfOwnerMatch
#    </IfModule>
#    Options Indexes ExecCGI FollowSymLinks
#
#**********************************************************
#print "Content-type: text/html\n\n";
if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
  use Abills::Base;
  $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
  my ($REMOTE_USER,$REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));  

  if (check_permissions("$REMOTE_USER", "$REMOTE_PASSWD") == 1) {
    print "WWW-Authenticate: Basic realm=\"Billing system\"\n";
    print "Status: 401 Unauthorized\n";
   }
}
else {
  check_permissions('$REMOTE_USER');
}

if ($admin->{errno}) {
  print "Content-type: text/html\n\n";
  my $message = 'Access Deny';
  if (! defined($REMOTE_USER)) {
    $message = "'mod_rewrite' not install";
   }
  else {
    $message = $err_strs{$admin->{errno}};
   }

  message('err', $_ERROR, "$message");
  exit;
}

#Cookie section ============================================
if (defined($FORM{colors})) {
  my $cook_colors = (defined($FORM{default})) ?  '' : $FORM{colors};
  $html->setCookie('colors', "$cook_colors", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
 }

#Operation system ID
$html->setCookie('OP_SID', "$FORM{OP_SID}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
$html->setCookie('language', "$FORM{language}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure) if (defined($FORM{language}));
$html->setCookie('qm', "$FORM{qm_item}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure) if (defined($FORM{quick_set}));
#===========================================================


print $html->header({ 
	 PATH    => '../',
	 CHARSET => $CHARSET });

my @actions = ([$_SA_ONLY, $_ADD, $_LIST, $_PASSWD, $_CHANGE, $_DEL, $_ALL],  # Users
               [$_LIST, $_ADD, $_DEL, $_ALL],                                 # Payments
               [$_LIST, $_ADD, $_DEL, $_ALL],                                 # Fees
               [$_LIST, $_DEL],                                               # reports view
               [$_LIST, $_ADD, $_CHANGE, $_DEL],                              # system magment
               [$_ALL],                                                       # Modules managments
               [$_SEARCH],                                                    # Search
               [$_MONITORING],
               [$_PROFILE],
               );

@action = ('add', $_ADD);
@bool_vals = ($_NO, $_YES);

my @PAYMENT_METHODS = ('Cashe', 'Bank', 'Credit Card', 'Internet Card');
my %menu_items = ();
my %menu_names = ();
my $root_index = 0;
my $maxnumber = 0;
my %uf_menus = (); #User form menu list

my %SEARCH_TYPES = (11 => $_USERS,
                    2 =>  $_PAYMENTS,
                    3 =>  $_FEES,
                    13 => $_COMPANY
);

if($FORM{index} != 7 && ! defined($FORM{type})) {
	$FORM{type}=$FORM{index};
 }
elsif (! defined $FORM{type}) {
	$FORM{type}=11;
}

my $SEL_TYPE = "<select name=type>\n";
while(my($k, $v)=each %SEARCH_TYPES) {
	$SEL_TYPE .= "<option value=$k";
	$SEL_TYPE .= ' selected' if ($FORM{type} eq $k);
	$SEL_TYPE .= ">$v\n";
}
$SEL_TYPE .= "</select>\n";


fl();
#Add modules
foreach my $m (@MODULES) {
	require "Abills/modules/$m/config";
  my %module_fl=();

  my @sordet_module_menu = sort keys %FUNCTIONS_LIST;
  foreach $line (@sordet_module_menu) {
   
    $maxnumber++;
    my($ID, $SUB, $NAME, $FUNTION_NAME, $ARGS)=split(/:/, $line, 5);
    $ID = int($ID);
    my $v = $FUNCTIONS_LIST{$line};

    $module_fl{"$ID"}=$maxnumber;
    $menu_args{$maxnumber}=$ARGS if ($ARGS ne '');
    #print "$line -- $ID, $SUB, $NAME, $FUNTION_NAME  // $module_fl{$SUB}<br>";
    
    if($SUB > 0) {
      $menu_items{$maxnumber}{$module_fl{$SUB}}=$NAME;
     } 
    else {
      $menu_items{$maxnumber}{$v}=$NAME;
      if ($SUB == -1) {
        $uf_menus{$maxnumber}=$NAME;
      }
    }
    $menu_names{$maxnumber}=$NAME;
    $functions{$maxnumber}=\&$FUNTION_NAME if ($FUNTION_NAME  ne '');
    $module{$maxnumber}=$m;
  }
}


my ($menu_text, $navigat_menu) = mk_navigator();
my ($online_users, $online_count) = $admin->online();


print "<table width=100%>
<tr bgcolor=$_COLORS[3]><td colspan=2>
<table width=100% border=0>
<form action=$SELF_URL>
  <tr><th align=left>$_DATE: $DATE $TIME Admin: <a href='$SELF_URL?index=53'>$admin->{A_LOGIN}</a> / Online: <abbr title=\"$online_users\"><a href='$SELF_URL?index=50' title='$online_users'>Online: $online_count</a></abbr></th>
  <th align=right><input type=hidden name=index value=7><input type=hidden name=search value=y>
  Search: $SEL_TYPE <input type=text name=LOGIN_EXPR value='$FORM{LOGIN_EXPR}'> (<b><a href='#' onclick=\"window.open('help.cgi?index=$index','help',
'height=550,width=450,resizable=0,scrollbars=yes,menubar=no, status=yes');\">?</a></b>)</th></tr>
</form>
</table>
</td></tr>\n";


use Users;
my $users = Users->new($db, $admin, \%conf); 


if(defined($conf{tech_works})) {
  print "<tr><th bgcolor=red colspan=2>$conf{tech_works}</th></tr>";
}

if (defined($COOKIES{qm}) && $COOKIES{qm} ne '') {
  print "<tr><td colspan=2><table width=100% border=0>";
	my @a = split(/, /, $COOKIES{qm});
  my $i = 0;
	foreach my $line (@a) {
    if (  $i % 6 == 0) {
      print "<tr>\n";
     }
    my $color=($line eq $index) ? $_COLORS[0] : $_COLORS[2];
    print "<th bgcolor=$color><a href='$SELF_URL?index=$line'>$menu_names{$line}</a></th>\n";
	  $i++;
	 }
  
  print "</table></td></tr>\n";
}

print "<tr><td valign=top width=18% bgcolor=$_COLORS[2] rowspan=2>
<p>$menu_text</p>
</td><td bgcolor=$_COLORS[0] height=50>$navigat_menu</td></tr>
<tr><td valign=top align=center>";


if ($functions{$index}) {
  if(defined($module{$index})) {
 	 	require "Abills/modules/$module{$index}/webinterface";
   }
  
  if(defined($FORM{UID}) && $FORM{UID} > 0) {
  	my $ui = user_info($FORM{UID});
  	if($ui->{errno}==2) {
  		message('err', $_ERROR, "[$FORM{UID}] $_USER_NOT_EXIST")
  	 }
  	else {
  	  $functions{$index}->({ USER => $ui });
  	  $LIST_PARAMS{LOGIN} = '11111';
  	}
   }
  else {
     $functions{$index}->();
   }
}
else {
  message('err', $_ERROR,  "Function not exist ($index / $root_index / $functions{$index})");	
}


print "</td></tr></table>\n";
if ($begin_time > 0) {
  my $end_time = gettimeofday;
  my $gen_time = $end_time - $begin_time;
  $conf{version} .= " (Generation time: $gen_time)";
}
print '<hr>'. $conf{version};


$html->test();






























#**********************************************************
#
# check_permissions()
#**********************************************************
sub check_permissions {
  my ($login, $password, $attr)=@_;

  my %PARAMS = ( LOGIN => "$login", 
                 PASSWORD => "$password",
                 SECRETKEY => $conf{secretkey},
                 IP => $SESSION_IP);

  $admin->info(0, {%PARAMS } );

  if ($admin->{errno}) {
    return 1;
   }

  my $p_ref = $admin->get_permissions();
  %permissions = %$p_ref;
  
  return 0;
}



#**********************************************************
# form_customers
#**********************************************************
sub form_companies {
  use Customers;	
  my $customer = Customers->new($db);
  my $company = $customer->company();

if ($FORM{add}) {
  $company->add({ %FORM });
 
  if (! $company->{errno}) {
    message('info', $_ADDED, "$_ADDED");
   }
 }
elsif($FORM{change}) {

  $company->change({ %FORM });

  if (! $company->{errno}) {
    message('info', $_INFO, $_CHANGED. " # $company->{ACCOUNT_NAME}");
    goto INFO;  	 
   }

 }
elsif($FORM{COMPANY_ID}) {
  

  
  INFO:

  $company->info($FORM{COMPANY_ID});
  $LIST_PARAMS{COMPANY_ID}=$FORM{COMPANY_ID};
  $pages_qs .= "&COMPANY_ID=$FORM{COMPANY_ID}";

  func_menu({ 
  	         'ID' => $company->{COMPANY_ID}, 
  	         $_NAME =>$company->{COMPANY_NAME}
  	       }, 
  	{ 
  	 $_INFO     => ":COMPANY_ID=$company->{COMPANY_ID}",
     $_USERS    => "11:COMPANY_ID=$company->{COMPANY_ID}",
     $_PAYMENTS => "2:COMPANY_ID=$company->{COMPANY_ID}",
     $_FEES     => "3:COMPANY_ID=$company->{COMPANY_ID}",
     $_ADD_USER => "12:COMPANY_ID=$FORM{COMPANY_ID}",
     $_BILL     => "19:COMPANY_ID=$FORM{COMPANY_ID}"
  	 });
 

  #Sub functions
  if (! $FORM{subf}) {
    $company->{ACTION}='change';
    $company->{LNG_ACTION}=$_CHANGE;
    $company->{DISABLE} = ($company->{DISABLE} > 0) ? 'checked' : '';
    Abills::HTML->tpl_show(templates('form_company'), $company);
  }

 }
elsif($FORM{del}) {
   $company->del( $FORM{del} );
   message('info', $_INFO, "$_DELETED # $FORM{del}");
 }
else {
  my $list = $company->list( { %LIST_PARAMS } );
  my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_NAME, $_DEPOSIT, $_REGISTRATION, $_USERS, $_STATUS, '-', '-'],
                                   cols_align => ['left', 'right', 'right', 'right', 'center', 'center'],
                                   pages => $company->{TOTAL},
                                   qs => $pages_qs
                                  } );

  foreach my $line (@$list) {
    $table->addrow($line->[0],  $line->[1], $line->[2], "<a href='$SELF_URL?index=$index&COMPANY_ID=$line->[5]'>$line->[3]</a>", "$status[$line->[4]]",
      "<a href='$SELF_URL?index=$index&COMPANY_ID=$line->[5]'>$_INFO</a>", $html->button($_DEL, "index=$index&del=$line->[5]", "$_DEL ?"));
   }
  print $table->show();

  $table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$company->{TOTAL}</b>" ] ]
                               } );
  print $table->show();
}

  if ($company->{errno}) {
    message('info', $_ERROR, "[$company->{errno}] $err_strs{$company->{errno}}");
   }

}


#**********************************************************
# Functions menu
#**********************************************************
sub func_menu {
  my ($header, $items, $f_args)=@_; 
 
print "<Table width=100% bgcolor=$_COLORS[2]>\n";

while(my($k, $v)=each %$header) {
  print "<tr><td>$k: <b>$v</b></td></tr>\n";
}
print "<tr bgcolor=$_COLORS[3]><td>\n";

my $menu;
while(my($name, $v)=each %$items) {
  my ($subf, $ext_url)=split(/:/, $v, 2);
  $menu .= (defined($FORM{subf})  && $FORM{subf} eq $subf) ? ":: <a href='$SELF_URL?index=$index&$ext_url&subf=$subf'><b>$name</b></a>": ":: <a href='$SELF_URL?index=$index&$ext_url&subf=$subf'>$name</a>\n";
}
print "$menu</td></tr>
</table>\n";


if ($FORM{subf}) {
  if ($functions{$FORM{subf}}) {
 	  if(defined($module{$index})) {
  	 	require "Abills/modules/$module{$index}/webinterface";
     }
    $functions{$FORM{subf}}->($f_args->{f_args});
   }
  else {
  	message('err', $_ERROR, "Function not Defined");
   }
 } 


 
}

#**********************************************************
# add_company()
#**********************************************************
sub add_company {
  my $company;
  $company->{ACTION}='add';
  $company->{LNG_ACTION}=$_ADD;
  Abills::HTML->tpl_show(templates('form_company'), $company);
}



#**********************************************************
# user_form()
#**********************************************************
sub user_form {
 my ($type, $user_info, $attr) = @_;

 
 
 if (! defined($user_info->{UID})) {
   my $user = Users->new($db, $admin); 
   $user_info = $user->defaults();

   if ($FORM{COMPANY_ID}) {
     use Customers;	
     my $customers = Customers->new($db);
     my $company = $customers->company->info($FORM{COMPANY_ID});
 	   $user_info->{COMPANY_ID}=$FORM{COMPANY_ID};
     $user_info->{EXDATA} =  "<tr><td>$_COMPANY:</td><td><a href='$SELF_URL?index=13&COMPANY_ID=$company->{COMPANY_ID}'>$company->{COMPANY_NAME}</a></td></tr>\n";
    }

   $user_info->{EXDATA} .= "
   <tr><td>$_USER:*</td><td><input type=text name=LOGIN value=''></td></tr>
   <tr><td>$_BILL:</td><td><input type=checkbox name=CREATE_BILL value='1'> $_CREATE</td></tr>
   \n";

   $user_info->{ACTION}='add';
   $user_info->{LNG_ACTION}=$_ADD;
  }
 else {
   $user_info->{EXDATA} = "
            <input type=hidden name=UID value=\"$FORM{UID}\"> 
            <tr><td>$_DEPOSIT:</td><td>$user_info->{DEPOSIT}</td></tr>
            <tr><td>$_COMPANY:</td><td><a href='$SELF_URL?index=13&COMPANY_ID=$user_info->{COMPANY_ID}'>$user_info->{COMPANY_NAME}</a></td></tr>
            <tr><td>BILL_ID:<td>%BILL_ID%</td></tr>\n";

   $user_info->{DISABLE} = ($user_info->{DISABLE} > 0) ? 'checked' : '';
   $user_info->{ACTION}='change';
   $user_info->{LNG_ACTION}=$_CHANGE;
  } 

Abills::HTML->tpl_show(templates('form_user'), $user_info);

}


#**********************************************************
# form_groups()
#**********************************************************
sub form_groups {

if ($FORM{add}) {
  $users->group_add( { %FORM });
  if (! $users->{errno}) {
    message('info', $_ADDED, "$_ADDED $users->{GID}");
   }
}
elsif($FORM{change}){
  $users->group_change($FORM{chg}, { %FORM });
  if (! $users->{errno}) {
    message('info', $_CHANGED, "$_CHANGED $users->{GID}");
   }
}
elsif($FORM{GID}){
  $users->group_info( $FORM{GID} );

  $LIST_PARAMS{GID}=$users->{GID};
  $pages_qs="&GID=$users->{GID}&subf=$FORM{subf}";

  func_menu({ 
  	         'ID' => $users->{GID}, 
  	         $_NAME =>$users->{G_NAME}
  	       }, 
  	{ 
     $_CHANGE     => ":GID=$users->{GID}",
     $_USERS    => "11:GID=$users->{GID}",
     $_PAYMENTS => "2:GID=$users->{GID}",
     $_FEES     => "3:GID=$users->{GID}",
  	 });
 

  #Sub functions
  if (! $FORM{subf}) {
#    if (! $users->{errno}) {
#      message('info', $_CHANGED, "$_CHANGING $users->{GID}");
#     }
    $users->{ACTION}='change';
    $users->{LNG_ACTION}=$_CHANGE;
    Abills::HTML->tpl_show(templates('form_groups'), $users);
  }
 
  return 0;
}
elsif($FORM{del} && $FORM{is_js_confirmed}){
  $users->group_del( $FORM{del} );
  if (! $users->{errno}) {
    message('info', $_DELETED, "$_DELETED $users->{GID}");
   }
}


if ($users->{errno}) {
   message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
  }

my $list = $users->groups_list({ %LIST_PARAMS });
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_ID, $_NAME, $_DESCRIBE, $_USERS, '-', '-'],
                                   cols_align => ['right', 'left', 'left', 'right', 'center', 'center'],
                                   qs => $pages_qs,
                                   pages => $users->{TOTAL}
                                  } );

foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=27$pages_qs&del=$line->[0]", "$_DEL ?"); 
  $table->addrow("<b>$line->[0]</b>", "$line->[1]", "$line->[2]", 
   "<a href='$SELF_URL?index=27&GID=$line->[0]&subf=11'>$line->[3]</a>", 
   "<a href='$SELF_URL?index=27&GID=$line->[0]'>$_INFO</a>",
   $delete);
}
print $table->show();




$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$users->{TOTAL}</b>" ] ]
                               } );
print $table->show();
}



#**********************************************************
# form_users()
#**********************************************************
sub add_groups {
  my $users;
  $users->{ACTION}='add';
  $users->{LNG_ACTION}=$_ADD;
  Abills::HTML->tpl_show(templates('form_groups'), $users); 
}

#**********************************************************
# user_info
#**********************************************************
sub user_info {
  my ($UID)=@_;
	my $user_info = $users->info( $UID );
  
  print  "<table width=100% bgcolor=$_COLORS[2]><tr><td>$_USER:</td>
   <td><a href='$SELF_URL?index=11&UID=$user_info->{UID}'><b>$user_info->{LOGIN}</b></td></tr></table>\n";
  
  $LIST_PARAMS{UID}=$user_info->{UID};
  $pages_qs =  "&UID=$user_info->{UID}";
  $pages_qs .= "&subf=$FORM{subf}" if (defined($FORM{subf}));

  
  return 	$user_info;
}


#**********************************************************
#
#**********************************************************
sub user_pi {
  my ($attr) = @_;

  my $user = $attr->{USER};

 if($FORM{add}) {
 	 my $user_pi = $user->pi_add({ %FORM });
   if (! $user_pi->{errno}) {
    message('info', $_ADDED, "$_ADDED");	
   }
  }
 elsif($FORM{change}) {
 	 my $user_pi = $user->pi_change({ %FORM });
   if (! $user_pi->{errno}) {
    message('info', $_CHAGED, "$_CHANGED");	
   }
 }

  if ($user_pi->{errno}) {
    message('err', $_ERROR, "[$user_pi->{errno}] $err_strs{$user_pi->{errno}}");	
   }


  my $user_pi = $user->pi();
  if($user_pi->{TOTAL} < 1) {
  	$user_pi->{ACTION}='add';
   	$user_pi->{LNG_ACTION}=$_ADD;
    }
  else {
 	  $user_pi->{ACTION}='change';
	  $user_pi->{LNG_ACTION}=$_CHANGE;
   }
   
  Abills::HTML->tpl_show(templates('form_pi'), $user_pi);      
	
}

#**********************************************************
# form_users()
#**********************************************************
sub form_users {
  my ($attr)=@_;

if(defined($attr->{USER})) {

  my $user_info = $attr->{USER};
  if ($users->{errno}) {
    message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
    return 0;
   }

  print "<table width=100% border=0 cellspacing=1 cellpadding=2><tr><td valign=top align=center>\n";
  
  
  form_passwd({ USER => $user_info}) if (defined($FORM{newpassword}));

  if ($FORM{change}) {
    $user_info->change($user_info->{UID}, { %FORM } );
    if ($user_info->{errno}) {
      message('err', $_ERROR, "[$user_info->{errno}] $err_strs{$user_info->{errno}}");	
      user_form();    
      print "</td></table>\n";
      return 0;	
     }
    else {
      message('info', $_CHANGED, "$_CHANGED $users->{info}");
     }
   }
  elsif ($FORM{del_user} && $FORM{is_js_confirmed} && $index == 11) {
    $user_info->del();
    if ($users->{errno}) {
      message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
     }
    else {
      message('info', $_DELETE, "$_DELETED <br>from tables<br>$users->{info}");
     }
    print "</td></tr></table>\n";
    return 0;
   }
  else {
    @action = ('change', $_CHANGE);
    user_form('test', $user_info);
    
    user_pi({ USER => $user_info });

   }


print "
</td><td bgcolor=$_COLORS[3] valign=top width=180>
<table width=100% border=0><tr><td>
      <li><a href='$SELF_URL?UID=$user_info->{UID}&index=2'>$_PAYMENTS</a>
      <li><a href='$SELF_URL?UID=$user_info->{UID}&index=3'>$_FEES</a>
      <li><a href='$SELF_URL?UID=$user_info->{UID}&index='>$_SEND_MAIL</a>
</td></tr>
<tr><td> 
  <br>\n";

my %userform_menus = (
             15 =>  $_LOG,
             17 =>  $_PASSWD,
             21 =>  $_COMPANY,
             24 =>  $_GROUP,
             18 =>  $_NAS,
             20 =>  $_SERVICES,
             19	=>  $_BILL
 );

while(my($k, $v)=each %uf_menus) {
	$userform_menus{$k}=$v;
}

 

while(my($k, $v)=each (%userform_menus) ) {
  print "<li><a href='$SELF_URL?index=$k&UID=$user_info->{UID}'>";
  my $a = (defined($FORM{$k})) ? "<b>$v</b>" : $v;
  print "$a </a>\n";
}

print "<li><a href='$SELF?index=$index&del_user=y&UID=$user_info->{UID}' onclick=\"return confirmLink(this, '$_USER: $user_info->{LOGIN} / $user_info->{UID} ')\">$_DEL</a>
</td></tr>
</table>
</td></tr></table>\n";
  return 0;
}
elsif ($FORM{add}) {
  my $user_info = $users->add({ %FORM });  

  if ($users->{errno}) {
    message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
    user_form();    
    return 0;	
   }
  else {
    message('info', $_ADDED, "$_ADDED '$user_info->{LOGIN}' / [$user_info->{UID}]");
    $user_info = $users->info( $user_info->{UID} );
    Abills::HTML->tpl_show(templates('user_info'), $user_info);

    $LIST_PARAMS{UID}=$user_info->{UID};
    $index=2;
    form_payments({ USER => $user_info });
    return 0;
   }
}


if ($FORM{COMPANY_ID}) {
  print "<p><b>$_COMPANY:</b> $FORM{COMPANY_ID}</p>\n";
  $pages_qs .= "&COMPANY_ID=$FORM{COMPANY_ID}";
  $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID};
 }  

if ($FORM{debs}) {
  print "<p>$_DEBETERS</p>\n";
  $pages_qs .= "&debs=$FORM{debs}";
  $LIST_PARAMS{DEBETERS} = 'y';
 }  

#if ($FORM{TP_ID}) {
#  print "<p>$_VARIANT: $FORM{TP_ID}</p>\n"; 
#  $pages_qs .= "&TP_ID=$FORM{TP_ID}";
#  $LIST_PARAMS{TP} = $FORM{TP_ID};
# }

my $letters = "<a href='$SELF?index=$index'>All</a> ::";
for (my $i=97; $i<123; $i++) {
  my $l = chr($i);
  if ($FORM{letter} eq $l) {
     $letters .= "<b>$l </b>";
    }
  else {
     #$pages_qs = '';
     $letters .= "<a href='$SELF?index=$index&letter=$l$pages_qs'>$l</a> ";
   }
 }

 if ($FORM{letter}) {
   $LIST_PARAMS{FIRST_LETTER} = $FORM{letter};
   $pages_qs .= "&letter=$FORM{letter}";
  } 


my $list = $users->list( { %LIST_PARAMS } );

if ($users->{errno}) {
  message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
  return 0;
 }
elsif ($users->{TOTAL} == 1) {
	form_users({  USER => user_info($list->[0]->[5]) });
	return 0;
}

print $letters;


my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_LOGIN, $_FIO, $_DEPOSIT, $_CREDIT, $_STATUS, '-', '-'],
                                   cols_align => ['left', 'left', 'right', 'right', 'center', 'center', 'center', 'center'],
                                   qs => $pages_qs,
                                   pages => $users->{TOTAL}
                                  } );

foreach my $line (@$list) {
  my $payments = ($permissions{1}) ? "<a href='$SELF_URL?index=2&UID=$line->[5]'>$_PAYMENTS</a>" : ''; 
  my $fees     = ($permissions{2}) ? "<a href='$SELF_URL?index=3&UID=$line->[5]'>$_FEES</a>" : '';

  $table->addrow("<a href='$SELF_URL?index=11&UID=$line->[5]'>$line->[0]</a>", "$line->[1]",
   "$line->[2]", "$line->[3]", "$status[$line->[4]]", $payments, $fees);
}
print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$users->{TOTAL}</b>" ] ]
                               } );
print $table->show();
}

#**********************************************************
# user_group
#**********************************************************
sub user_group {
  my ($attr) = @_;
  my $user = $attr->{USER};

  $user->{SEL_GROUPS} = "<select name=GID>\n";
  $user->{SEL_GROUPS} .= "<option value='0'>-N/S-\n";
  my $groups = $user->groups_list();
  foreach my $line (@$groups) {
    $user->{SEL_GROUPS} .= "<option value='$line->[0]'>$line->[0]:$line->[1]\n";
   }
  $user->{SEL_GROUPS} .= "</select>\n";

  Abills::HTML->tpl_show(templates('chg_group'), $user);
}

#**********************************************************
# user_company
#**********************************************************
sub user_company {
 my ($attr) = @_;

 my $user_info = $attr->{USER};

 use Customers;
 my $customer = Customers->new($db);

$user_info->{SEL_COMPANIES} = "<select name=COMPANY_ID>\n";
$user_info->{SEL_COMPANIES} .= "<option value='0'>-N/S-\n";
my $list = $customer->company->list();
foreach my $line (@$list) {
   $user_info->{SEL_COMPANIES} .= "<option value='$line->[5]'>$line->[0]\n";
 }

$user_info->{SEL_COMPANIES} .= "</select>\n";

Abills::HTML->tpl_show(templates('chg_company'), $user_info);
}

#**********************************************************
# user_services
#**********************************************************
sub user_services {
  my ($attr) = @_;
  
  my $user = $attr->{USER};
if ($FORM{add}) {
	
}


 use Tariffs;
 my $tariffs = Tariffs->new($db, \%conf);
 my $variant_out = '';
 
 my $tariffs_list = $tariffs->list();
 $variant_out = "<select name=servise>";

 foreach my $line (@$tariffs_list) {
     $variant_out .= "<option value=$line->[0]";
#     $variant_out .= ' selected' if ($line->[0] == $user_info->{TARIF_PLAN});
     $variant_out .=  ">$line->[0]:$line->[1]\n";
    }
  $variant_out .= "</select>";



print << "[END]";
<FORM action=$SELF_URL>
<input type=hidden name=UID value=$user->{UID}>
<input type=hidden name=op value=users>
<input type=hidden name=services value=y>
<table>
<tr><td>$_SERVICES:</td><td>$variant_out</td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=S_DESCRIBE value="%S_DESCRIBE%"></td></tr>
</table>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</form>
[END]


my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_SERVISE, $_DATE, $_DESCRIBE, '-', '-'],
                                   cols_align => ['left', 'right', 'left', 'center', 'center'],
                                   qs => $pages_qs,
                                   pages => $users->{TOTAL}
                                  } );

print $table->show();

}


#*******************************************************************
# Users and Variant NAS Servers
# form_nas_allow()
#*******************************************************************
sub form_nas_allow {
 my ($attr) = @_;
 my @allow = split(/, /, $FORM{ids});
 my %allow_nas = (); 
 my $op = '';

if ($attr->{USER}) {
  my $user = $attr->{USER};
  if ($FORM{change}) {
    $user->nas_add(\@allow);
    if (! $user->{errno}) {
      message('info', $_INFO, "$_ALLOW $_NAS: $FORM{ids}");
     }
   }
  elsif($FORM{default}) {
    $user->nas_del();
    if (! $user->{errno}) {
      message('info', $_NAS, "$_CHANGED");
     }
   }

  if ($user->{errno}) {
    message('err', $_ERROR, "[$user->{errno}] $err_strs{$user->{errno}}");	
   }

  my ($nas_servers, $total) = $user->nas_list();
  foreach my $nas_id (@$nas_servers) {
     $allow_nas{$nas_id}='test';
   }
  $op = "<input type=hidden name=UID  value='$user->{UID}'>\n";
 }
elsif($attr->{TP}) {
  my $tarif_plan = $attr->{TP};

  if ($FORM{change}){
    $tarif_plan->nas_add(\@allow);
    if ($tarif_plan->{errno}) {
      message('err', $_ERROR, "[$tarif_plan->{errno}] $err_strs{$tarif_plan->{errno}}");	
     }
    else {
      message('info', $_INFO, "$_ALLOW $_NAS: $FORM{ids}");
     }
   }
  
  my $list = $tarif_plan->nas_list();
  foreach my $nas_id (@$list) {
     $allow_nas{$nas_id->[0]}='y';
   }

  $op = "<input type=hidden name=TP_ID  value='$tarif_plan->{TP_ID}'>\n";
}
elsif (defined($FORM{TP_ID})) {
  $FORM{chg}=$FORM{TP_ID};
  $FORM{subf}=$index;
  dv_tp();
  return 0;
 }

my $nas = Nas->new($db, \%conf);
my $out = "<form action='$SELF_URL'>
  <input type=hidden name=index  value='$FORM{index}'>
  <input type=hidden name=subf  value='$FORM{subf}'>
$op";

my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ["$_ALLOW", "ID", "$_NAME", "IP", "$_TYPE", "$_AUTH"],
                                   cols_align => ['center', 'left', 'left', 'right', 'left', 'left'],
                                   qs => $pages_qs,
                                  } );

my $list = $nas->list();

foreach my $line (@$list) {
  my $checked = (defined($allow_nas{$line->[0]}) || $allow_nas{all}) ? ' checked ' :  '';    
  $table->addrow("<input type=checkbox name=ids value=$line->[0] $checked>", $line->[2], $line->[1], 
    $line->[4], $line->[5], $auth_types[$line->[6]]);
}

$out .= $table->show();
$out .= "<p><input type=submit name=change value=$_CHANGE> <input type=submit name=default value='$_DEFAULT'>
</form>\n";

print $out;
}




#**********************************************************
# form_bills();
#**********************************************************
sub form_bills {
  my ($attr) = @_;
  my $user = $attr->{USER};


  if($FORM{UID} && $FORM{change}) {
  	form_users({ USER => $user } ); 
  	return 0;
  }
  
  use Bills;
  my  $bills = Bills->new($db);

  $user->{SEL_BILLS} =  "<select name=BILL_ID>\n";
  $user->{SEL_BILLS} .= "<option value='0'>-N/S-\n";
  my $list = $bills->list({  COMPANY_ONLY => 'y',
  	                         UID   => $user->{UID} });
  foreach my $line (@$list) {
    if($line->[3] ne '') {
      $user->{SEL_BILLS} .= "<option value='$line->[0]'>$line->[0] : <font color='EE44EE'>$line->[3]</font> :$line->[1]\n";
     }
    elsif($line->[2] ne '') {
    	$user->{SEL_BILLS} .= "<option value='$line->[0]'> >> $line->[0] : Personal :$line->[1]\n";
     }
   }

  $user->{SEL_BILLS} .= "</select>\n";
  Abills::HTML->tpl_show(templates('chg_bill'), $user);
}


#**********************************************************
# form_changes();
#**********************************************************
sub form_changes {
 my ($attr) = @_; 
 
if ($FORM{del} && $FORM{is_js_confirmed}) {
	$admin->action_del( $FORM{del} );
  if ($admins->{errno}) {
    message('err', $_ERROR, "[$admins->{errno}] $err_strs{$admins->{errno}}");	
   }
  else {
    message('info', $_DELETED, "$_DELETED [$FORM{del}]");
   }
 }
elsif($FORM{AID} && ! defined($LIST_PARAMS{AID})) {
	$FORM{subf}=$index;
	form_admins();
	return 0;
 }


#u.id, aa.datetime, aa.actions, a.name, INET_NTOA(aa.ip),  aa.UID, aa.aid, aa.id

if (! defined($FORM{sort})) {
  $LIST_PARAMS{SORT}=1;
  $LIST_PARAMS{DESC}=DESC;
 }

my $list = $admin->action_list( { %LIST_PARAMS } );
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['#', 'UID',  $_DATE,  $_CHANGE,  $_ADMIN,   'IP', '-'],
                                   cols_align => ['right', 'left', 'right', 'left', 'left', 'right', 'center'],
                                   qs => $pages_qs,
                                   pages => $admin->{TOTAL}
                                   
                                  } );
foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=$index$pages_qs&del=$line->[0]", "$_DEL ?"); 
  $table->addrow("<b>$line->[0]</b>", "<a href='$SELF_URL?index=11&UID=$line->[6]'>$line->[1]</a>", $line->[2], $line->[3], 
   $line->[4], $line->[5], $delete);
}

print $table->show();
$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$admin->{TOTAL}</b>" ] ]
                               } );
print $table->show();
}



#**********************************************************
# Time intervals
# form_intervals()
#**********************************************************
sub form_intervals {
  my ($attr) = @_;

  @DAY_NAMES = ("$_ALL", 'Sun', 'Mon', 'Tue', 'Wen', 'The', 'Fri', 'Sat', "$_HOLIDAYS");

  my %visual_view = ();
  my $tarif_plan;
  

if(defined($attr->{TP})) {
  $tarif_plan = $attr->{TP};
 	$tarif_plan->{ACTION}='add';
 	$tarif_plan->{LNG_ACTION}=$_ADD;


  if(defined($FORM{tt})) {
    dv_traf_tarifs({ TP => $tarif_plan });
   }
  elsif ($FORM{add}) {
    $tarif_plan->ti_add( { %FORM });
    if (! $tarif_plan->{errno}) {
      message('info', $_INFO, "$_INTERVALS $_ADDED");
     }
   }
  elsif($FORM{change}) {
    $tarif_plan->ti_change( $FORM{TI_ID}, { %FORM } );

    if (! $tarif_plan->{errno}) {
      message('info', $_INFO, "$_INTERVALS $_CHANGED [$tarif_plan->{TI_ID}]");
     }
   }
  elsif(defined($FORM{chg})) {
  	$tarif_plan->ti_info( $FORM{chg} );
    if (! $tarif_plan->{errno}) {
      message('info', $_INFO, "$_INTERVALS $_CHANGE [$FORM{chg}]");
     }

 	 	$tarif_plan->{ACTION}='change';
 	 	$tarif_plan->{LNG_ACTION}=$_CHANGE;
   }
  elsif($FORM{del} && $FORM{is_js_confirmed}) {
    $tarif_plan->ti_del($FORM{del});
    if (! $tarif_plan->{errno}) {
      message('info', $_DELETED, "$_DELETED $FORM{del}");
     }
   }
  else {
 	 	$tarif_plan->ti_defaults();
   }

  my $list = $tarif_plan->ti_list({ %LIST_PARAMS });
  my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['#', $_DAYS, $_BEGIN, $_END, $_HOUR_TARIF, $_TRAFFIC, '-', '-',  '-'],
                                   cols_align => ['left', 'left', 'right', 'right', 'right', 'right', 'center', 'center', 'center', 'center'],
                                   qs => $pages_qs,
                                   caption => $_INTERVALS
                                  } );

  my $color="AAA000";
  foreach my $line (@$list) {

    my $delete = $html->button($_DEL, "index=$index$pages_qs&del=$line->[0]", "$_DEL [$line->[0]] ?"); 
    $color = sprintf("%06x", hex('0x'. $color) + 7000);
     
    #day, $hour|$end = color
    my ($h_b, $m_b, $s_b)=split(/:/, $line->[2], 3);
    my ($h_e, $m_e, $s_e)=split(/:/, $line->[3], 3);

     push ( @{$visual_view{$line->[1]}}, "$h_b|$h_e|$color|$line->[0]")  ;

    if (($FORM{tt} eq $line->[0]) || ($FORM{chg} eq $line->[0])) {
       $table->{rowcolor}=$_COLORS[0];      
     }
    else {
    	 undef($table->{rowcolor});
     }
    
    $table->addtd(
                  $table->td($line->[0], { rowspan => ($line->[5] > 0) ? 2 : 1 } ), 
                  $table->td("<b>$DAY_NAMES[$line->[1]]</b>"), 
                  $table->td($line->[2]), 
                  $table->td($line->[3]), 
                  $table->td($line->[4]), 
                  $table->td("<a href='$SELF_URL?index=$index$pages_qs&tt=$line->[0]'>$_TRAFFIC</a>"),
                  $table->td("<a href='$SELF_URL?index=$index$pages_qs&chg=$line->[0]'>$_CHANGE</a>"),
                  $table->td($delete),
                  $table->td("&nbsp;", { bgcolor => $color, rowspan => ($line->[5] > 0) ? 2 : 1 })
      );

     if($line->[5] > 0) {
     	 my $TI_ID = $line->[0];
     	 #Traffic tariff IN (1 Mb) Traffic tariff OUT (1 Mb) Prepaid (Mb) Speed (Kbits) Describe NETS 

       my $table2 = Abills::HTML->table( { width => '100%',
                                   title_plain => ["#", "$_TRAFFIC_TARIFF In ", "$_TRAFFIC_TARIFF Out ", "$_PREPAID", "$_SPEED IN",  "$_SPEED OUT", "DESCRIBE", "NETS", "-", "-"],
                                   cols_align => ['center', 'right', 'right', 'right', 'right', 'right', 'right', 'center', 'center', 'center', 'center'],
                                   caption => "$_BYTE_TARIF"
                                  } );

       my $list_tt = $tarif_plan->tt_list({ TI_ID => $line->[0] });
       foreach my $line (@$list_tt) {
          $table2->addrow($line->[0], 
           $line->[1], 
           $line->[2], 
           $line->[3], 
           $line->[4], 
           $line->[5], 
           $line->[6], 
           convert($line->[7], { text2html => yes  }),
           "<a href=$SELF_URL?index=$index$pages_qs&tt=$TI_ID&chg=$line->[0]>$_CHANGE</a>",
           $html->button($_DEL, "index=$index$pages_qs&tt=$TI_ID&del=$line->[0]", "$_DEL ?"));
        }

       my $table_traf = $table2->show();
  
       $table->addtd($table->td("$table_traf", { color => 'red', colspan => 7}));
     }
     
   };
  print $table->show();
  
 }
elsif (defined($FORM{TP_ID})) {
  $FORM{subf}=$index;
  dv_tp();
  return 0;
 }

if ($tarif_plan->{errno}) {
   message('err', $_ERROR, "[$tarif_plan->{errno}] $err_strs{$tarif_plan->{errno}} $tarif_plan->{errstr}");	
 }


#visualization
#                               title_plain => ["#", "$_TRAFFIC_TARIFF In ", "$_TRAFFIC_TARIFF Out ", "$_PREPAID", "$_SPEED", "DESCRIBE", "NETS"],
#                               cols_align => ['center', 'right', 'right', 'right', 'right', 'right', 'right', 'center', 'center'],


$table = Abills::HTML->table( { width => '100%',
	                              title_plain => [$_DAYS, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,14,15,16,17,18, 19, 20, 21, 22, 23],
                                caption => "$_INTERVALS",
                                rowcolor => $_COLORS[1]
                               } );



for(my $i=0; $i<9; $i++) {
  my @hours = ();

  my ($h_b, $h_e, $color, $p);

#  if(defined($visual_view{$i})) {
#     ($h_b, $h_e, $color, $p)=split(/\|/, $visual_view{$i}, 4);
#     
#    # print "$i ()() $h_b, $h_e, $color-  $visual_view{$i} --<br>\n";
#   }

  my $link = "&nbsp;";
  for(my $h=0; $h<24; $h++) {

  	 if(defined($visual_view{$i})) {
  	   $day_periods = $visual_view{$i};
       #print "<br>";
       foreach my $line (@$day_periods) {
     	   #print "$i -- $line    <br>\n";
     	   ($h_b, $h_e, $color, $p)=split(/\|/, $line, 4);
     	   if (($h >= $h_b) && ($h < $h_e)) {
#     	   	 print "$i // $h => $h_b && $h <= $h_e // $color <br> \n";
  	   	   $tdcolor = $color;
  	 	     $link = "<a href='$SELF_URL?index=$index&TP_ID=$FORM{TP_ID}&subf=$FORM{subf}&chg=$p'>#</a>";
  	 	     last;
  	 	    }
  	     else {
  	 	     $link = "&nbsp;";
  	 	     $tdcolor = $_COLORS[1];
  	      }
       }
     }
  	 else {
  	 	 $link = "&nbsp;";
  	 	 $tdcolor = $_COLORS[1];
  	  }
     
     
  	 push(@hours, $table->td("$link", { align=>'center', bgcolor => $tdcolor }) );
    }
  
  
  $table->addtd("<td>$DAY_NAMES[$i]</td>", @hours);
}


print $table->show();




if (defined($FORM{tt})) {

  $tarif_plan->{SEL_TT_ID} = "<select name=TT_ID>";
  for(my $i=0; $i<3; $i++) {
    $tarif_plan->{SEL_TT_ID} .= "<option value=$i";
    $tarif_plan->{SEL_TT_ID} .= " selected" if ($i eq $tarif_plan->{TT_ID});
    $tarif_plan->{SEL_TT_ID} .= ">$i\n";
   }
  $tarif_plan->{SEL_TT_ID} .=  '</select>';

  Abills::HTML->tpl_show(_include('dv_tt', 'Dv'), $tarif_plan);
}
else {
  my $i=0;
  foreach $line (@DAY_NAMES) {
    $tarif_plan->{SEL_DAYS} .= "<option value=$i";
    $tarif_plan->{SEL_DAYS} .= " selected" if ($FORM{day} == $i || $tarif_plan->{TI_DAY} == $i);
    $tarif_plan->{SEL_DAYS} .= ">$line\n";
    $i++;
  }
  
  Abills::HTML->tpl_show(templates('ti'), $tarif_plan);
}

}



#**********************************************************
# form_hollidays
#**********************************************************
sub form_holidays {
	my $holidays = Tariffs->new($db, \%conf);
	
  my %holiday = ();

if ($FORM{add}) {
  my($add_month, $add_day)=split(/-/, $FORM{add});
  $add_month++;

  $holidays->holidays_add({MONTH => $add_month, 
  	              DAY => $add_day
  	             });
  if (! $holidays->{errno}) {
    message('info', $_INFO, "$_ADDED");	
  }
}
elsif($FORM{del}){
  $holidays->holidays_del($FORM{del});

  if (! $holidays->{errno}) {
    message('info', $_INFO, "$_DELETED");	
  }
}

if ($holidays->{errno}) {
    message('err', $_ERROR, "[$holidays->{errno}] $err_strs{$holidays->{errno}}");	
 }


my $list = $holidays->holidays_list( { %LIST_PARAMS });
my $table = Abills::HTML->table( { width => '640',
                                   title => [$_DAY,  $_DESCRIBE, '-'],
                                   cols_align => ['left', 'left', 'center'],
                                  } );
my ($delete); 
foreach my $line (@$list) {
	my ($m, $d)=split(/-/, $line->[0]);
	$m--;
  $delete = $html->button($_DEL, "index=75&del=$line->[0]", "$_DEL ?"); 
  $table->addrow("$d $MONTHES[$m]", $line->[1], $delete);
  $hollidays{$m}{$d}='y';
}

print $table->show();

$table = Abills::HTML->table( { width => '640',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$holidays->{TOTAL}</b>" ] ]
                               } );
print $table->show();

my $year = $FORM{year} || strftime("%Y", localtime(time));
my $month = $FORM{month} || 0;

if ($month + 1 > 11) {
  $n_month = 0;
  $n_year = $FORM{year}+1;
}
else {
 $n_month = $month + 1;
 $n_year = $year;
}

if ($month - 1 < 0) {
  $p_month = 11;
  $p_year = $year-1;
 }
else {
  $p_month = $month - 1;
  $p_year = $year;
}

my $tyear = $year - 1900;
my $curtime = POSIX::mktime(0, 1, 1, 1, $month, $tyear);
my ($sec,$min,$hour,$mday,$mon, $gyear,$gwday,$yday,$isdst) = gmtime($curtime);
#print  "($sec,$min,$hour,$mday,$mon,$gyear,$gwday,$yday,$isdst)<br>";

print "<p><TABLE width=400 cellspacing=0 cellpadding=0 border=0>
<tr><TD bgcolor=$_COLORS[4]>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_COLORS[0]><th><a href='$SELF_URL?index=75&month=$p_month&year=$p_year'> << </a></th><th colspan=5>$MONTHES[$month] $year</th><th><a href='$SELF_URL?index=75&month=$n_month&year=$n_year'> >> </a></th></tr>
<tr bgcolor=$_COLORS[0]><th>$WEEKDAYS[1]</th><th>$WEEKDAYS[2]</th><th>$WEEKDAYS[3]</th>
<th>$WEEKDAYS[4]</th><th>$WEEKDAYS[5]</th>
<th><font color=red>$WEEKDAYS[6]</font></th><th><font color=red>$WEEKDAYS[7]</font></th></tr>\n";



my $day = 1;
my $month_days = 31;
while($day < $month_days) {
  print "<tr bgcolor=$_COLORS[1]>";
  for($wday=0; $wday < 7 and $day < $month_days; $wday++) {
     if ($day == 1 && $gwday != $wday) { 
       print "<td>&nbsp</td>";
       if ($wday == 7) {
       	 print "$day == 1 && $gwday != $wday";
       	 return 0;
       	}
      }
     else {
       my $bg = '';
       if ($wday > 4) {
       	  $bg = "bgcolor=$_COLORS[2]";
       	}

       if (defined($holiday{$month}{$day})) {
         print "<th bgcolor=$_COLORS[0]>$day</th>";
        }
       else {
         print "<td align=right $bg><a href='$SELF_URL?index=75&add=$month-$day'>$day</a></td>";
        }
       $day++;
      }
    }
  print "</tr>\n";
}


print "</table>\n</td></tr></table>\n";

}

#**********************************************************
# form_admins()
#**********************************************************
sub form_admins {

my $admin_form = Admins->new($db, \%conf);
$admin_form->{ACTION}='add';
$admin_form->{LNG_ACTION}=$_ADD;

if ($FORM{AID}) {
  $admin_form->info($FORM{AID});
  $LIST_PARAMS{AID}=$admin_form->{AID};  	
  $pages_qs = "&AID=$admin_form->{AID}&subf=$FORM{subf}";

  func_menu({ 
  	         'ID'   => $admin_form->{AID}, 
  	         $_NAME => $admin_form->{A_LOGIN}
  	       }, 
  	{ 
  	 $_CHANGE         => ":AID=$admin_form->{AID}",
     $_LOG            => "51:AID=$admin_form->{AID}",
     $_FEES           => "3:AID=$admin_form->{AID}",
     $_PAYMENTS       => "2:AID=$admin_form->{AID}",
     $_PERMISSION     => "52:AID=$admin_form->{AID}",
     $_PASSWD         => "54:AID=$admin_form->{AID}",
  	 },
  	{
  		f_args => { ADMIN => $admin_form }
  	 });

#  if ($FORM{newpassword}) {
#    my $password = form_passwd( { ADMIN => $admin_form  });
#    if ($password ne '0') {
#      $admin_form->password($password, { secretkey => $conf{secretkey} } ); 
#      if (! $admin_form->{errno}) {
#        message('info', $_INFO, "$_ADMINS: $admin_form->{NAME}<br>$_PASSWD $_CHANGED");
#      }
#     }
#    return 0;
#   }
  form_passwd({ ADMIN => $admin_form}) if (defined($FORM{newpassword}));

  if ($FORM{subf}) {
   	return 0;
   }
  elsif($FORM{change}) {
    $admin_form->change({	%FORM  });
    if (! $admin_form->{errno}) {
      message('info', $_CHANGED, "$_CHANGED ");	
     }
   }
  $admin_form->{ACTION}='change';
  $admin_form->{LNG_ACTION}=$_CHANGE;
 }
elsif ($FORM{add}) {
  $admin_form->add( {
    A_LOGIN => $FORM{A_LOGIN},
    A_FIO   => $FORM{A_FIO},
    DISABLE => $FORM{DISABLE},
    A_PHONE => $FORM{A_PHONE}	
    } 
  );

  if (! $admin_form->{errno}) {
     message('info', $_INFO, "$_ADDED");	
   }

}
elsif($FORM{del}) {
  $admin_form->del($FORM{del});
  if (! $admin_form->{errno}) {
     message('info', $_DELETE, "$_DELETED");	
   }
}


if ($admin_form->{errno}) {
     message('err', $_ERROR, $err_strs{$admin_form->{errno}});	
 }


$admin_form->{DISABLE} = ($admin_form->{DISABLE} > 0) ? 'checked' : '';
Abills::HTML->tpl_show(templates('form_admin'), $admin_form);

my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['ID', $_NAME, $_FIO, $_CREATE, $_GROUPS, '-', '-', '-', '-', '-', '-'],
                                   cols_align => ['right', 'left', 'left', 'right', 'left', 'center', 'center', 'center', 'center', 'center', 'center'],
                                  } );

my $list = $admin_form->list();
foreach my $line (@$list) {
  $table->addrow(@$line, "<a href='$SELF_URL?index=$index&subf=52&AID=$line->[0]'>$_PERMISSION</a>", 
   "<a href='$SELF_URL?index=$index&subf=51&AID=$line->[0]'>$_LOG</a>",
   "<a href='$SELF_URL?index=$index&subf=54&AID=$line->[0]'>$_PASSWD</a>",
   "<a href='$SELF_URL?index=$index&AID=$line->[0]'>$_INFO</a>", $html->button($_DEL, "index=$index&del=$line->[0]", "$_DEL ?"));
}
print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$admin_form->{TOTAL}</b>" ] ]
                               } );
print $table->show();


}







#**********************************************************
# permissions();
#**********************************************************
sub admin_permissions {
 my ($attr) = @_;
 my %permits = ();

 if(! defined($attr->{ADMIN})) {
    $FORM{subf}=52;
    form_admins();
    return 0;	
  }

 my $admin = $attr->{ADMIN};

 if (defined($FORM{set})) {
   while(my($k, $v)=each(%FORM)) {
     if ($v eq 'yes') {
       my($section_index, $action_index)=split(/_/, $k);
       $permits{$section_index}{$action_index}='y';
      }
    }
   $admin->set_permissions(\%permits);

   if ($admin->{errno}) {
     message('err', $_ERROR, "$err_strs{$admin->{errno}}");
    }
   else {
     message('info', $_INFO, "$_CHANGED");
    }
  }

 my $p = $admin->get_permissions();
 if ($admin->{errno}) {
    message('err', $_ERROR, "$err_strs{$admin->{errno}}");
    return 0;
  }
 my %permits = %$p;
 
print "<form action=$SELF_URL METHOD=POST>
 <input type=hidden name=index value=50>
 <input type=hidden name=AID value='$FORM{AID}'>
 <input type=hidden name=subf value=$FORM{subf}>
 <table width=640>\n";

while(my($k, $v) = each %menu_items ) {
  if (defined($menu_items{$k}{0})) {
    print "<tr bgcolor=$_COLORS[0]><td colspan=3>$k: <b>$menu_items{$k}{0}</b></td></tr>\n";
    $k--;
    my $actions_list = $actions[$k];
    my $action_index = 0;
    foreach my $action (@$actions_list) {
      my $checked = (defined($permits{$k}{$action_index})) ? 'checked' : '';
      print "<tr><td align=right>$action_index</td><td>$action</td><td><input type=checkbox name='$k". "_$action_index' value='yes' $checked></td></tr>\n";
      $action_index++;
     }
   }
 }
  
print "</table>
 <input type=submit name='set' value=\"$_SET\">
</form>\n";
}




#*******************************************************************
# 
# profile()
#*******************************************************************
sub admin_profile {
 my ($admin) = @_;

 my @colors_descr = ('# 0 TH', 
                     '# 1 TD.1',
                     '# 2 TD.2',
                     '# 3 TH.sum, TD.sum',
                     '# 4 border',
                     '# 5',
                     '# 6',
                     '# 7 vlink',
                     '# 8 link',
                     '# 9 Text',
                     '#10 background'
                    );
print "$FORM{colors}";


my $REFRESH=$COOKIES{REFRESH} || 60;
my $ROWS=$COOKIES{PAGE_ROWS} || $PAGE_ROWS;


print "
<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
<tr><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_BG1><td colspan=2>$_LANGUAGE:</td>
<td><select name=language>\n";
while(my($k, $v) = each %LANG) {
  print "<option value='$k'";
  print ' selected' if ($k eq $language);
  print ">$v\n";	
}
print "</select></td></tr>
<tr bgcolor=$_BG1><th colspan=3>&nbsp;</th></tr>
<tr bgcolor=$_BG0><th colspan=2>$_PARAMS</th><th>$_VALUE</th></tr>\n";

 for($i=0; $i<=10; $i++) {
   print "<tr bgcolor=FFFFFF><td width=30% bgcolor=$_COLORS[$i]>$i</td><td>$colors_descr[$i]</td><td><input type=text name=colors value='$_COLORS[$i]'></td></tr>\n";
  } 
 
print "
</table>
<table width=100%>
<tr><td colspan=2>&nbsp;</td></tr>
<tr><td>$_REFRESH (sec.):</td><td><input type=input name=REFRESH value='$REFRESH'></td></tr>
<tr><td>$_ROWS:</td><td><input type=input name=PAGE_ROWS value='$PAGE_ROWS'></td></tr>
</table>
</td></tr></table>
<p><input type=submit name=set value='$_SET'> 
<input type=submit name=default value='$_DEFAULT'>
</form>\n";
   
my %profiles = ();
$profiles{'Black'} = "#333333, #000000, #444444, #555555, #777777, #FFFFFF, #FFFFFF, #BBBBBB, #FFFFFF, #EEEEEE, #000000";
$profiles{'Green'} = "#33AA44, #FFFFFF, #eeeeee, #dddddd, #E1E1E1, #FFFFFF, #FFFFFF, #000088, #0000A0, #000000, #FFFFFF";
$profiles{'Ligth Green'} = "4BD10C, #FFFFFF, #eeeeee, #dddddd, #E1E1E1, #FFFFFF, #FFFFFF, #000088, #0000A0, #000000, #FFFFFF";
$profiles{'мс'} = "#FCBB43, #FFFFFF, #eeeeee, #dddddd, #E1E1E1, #FFFFFF, #FFFFFF, #000088, #0000A0, #000000, #FFFFFF";
$profiles{'Cisco'} = "#99CCCC, #FFFFFF, #FFFFFF, #669999, #669999, #FFFFFF, #FFFFFF, #003399, #003399, #000000, #FFFFFF";

while(my($thema, $colors)=each %profiles ) {
  print "<a href='$SELF?index=53&set=set";
  my @c = split(/, /, $colors);
  foreach my $line (@c) {
      $line =~ s/#/%23/ig;
      print "&colors=$line";
    }
  print "'>$thema</a> ::";
}



 return 0;
}


#**********************************************************
# form_nas
#**********************************************************
sub form_nas {
  my $nas = Nas->new($db, \%conf);	
  $nas->{ACTION}='add';
  $nas->{LNG_ACTION}=$_ADD;


if($FORM{nid}) {
  $nas->info( { 
  	NID => $FORM{nid},
  	SECRETKEY => $conf{secretkey} 
  	} );

print "<Table width=100% bgcolor=$_COLORS[2]>
<tr><td>$_NAME: <b>$nas->{NAS_NAME}</b></td></tr>
<tr><td>ID: $nas->{NID}</td></tr>
<tr bgcolor=$_COLORS[3]><td>
:: <a href='$SELF_URL?index=61&nid=$nas->{NID}'>IP POOLs</a> 
:: <a href='$SELF_URL?index=60&nid=$nas->{NID}'>$_CHANGE</a>
</td></tr>
</table>\n";

  if ($index == 61) {
     form_ip_pools({ NAS => $nas });
     return 0;  	
   }
  elsif ($FORM{change}) {
  	$FORM{SECRETKEY}=$conf{secretkey};
  	$nas->change({ %FORM });
    if (! $nas->{errno}) {
      message('info', $_INFO, "$_CHANGED '$nas->{NAS_NAME}' [$nas->{NID}]");
     }
   }

  $nas->{ACTION}='change';
  $nas->{LNG_ACTION}=$_CHANGE;
 }
elsif ($FORM{add}) {
  $FORM{SECRETKEY}=$conf{secretkey};
  $nas->add({	%FORM	});

  if (! $nas->{errno}) {
    message('info', $_INFO, "$_ADDED '$FORM{NAS_IP}'");
   }
 }
elsif ($FORM{del} && $FORM{is_js_confirmed}) {
  $nas->del($FORM{del});
  if (! $nas->{errno}) {
    message('info', $_INFO, "$_DELETED [$FORM{del}]");
   }

}

if ($nas->{errno}) {
  message('err', $_ERROR, "$err_strs{$nas->{errno}}");
 }

 my @nas_types = ('other', 'usr', 'pm25', 'ppp', 'exppp', 'radpppd', 'expppd', 'pppd', 'dslmax', 'mpd', 'gnugk');
 my %nas_descr = (
  'usr'      => "USR Netserver 8/16",
  'pm25'      => 'LIVINGSTON portmaster 25',
  'ppp'       => 'FreeBSD ppp demon',
  'exppp'     => 'FreeBSD ppp demon with extended futures',
  'dslmax'    => 'ASCEND DSLMax',
  'expppd'    => 'pppd deamon with extended futures',
  'radpppd'   => 'pppd version 2.3 patch level 5.radius.cbcp',
  'mpd'       => 'MPD',
  'ipcad'     => 'IP accounting daemon with Cisco-like ip accounting export',
  'pppd'      => 'pppd + RADIUS plugin (Linux)',
  'gnugk'     => 'GNU GateKeeper',
  'other'     => 'Other nas server');

  foreach my $nt (@nas_types) {
     $nas->{SEL_TYPE} .= "<option value=$nt";
     $nas->{SEL_TYPE} .= ' selected' if ($nas->{NAS_TYPE} eq $nt);
     $nas->{SEL_TYPE} .= ">$nt ($nas_descr{$nt})\n";
   }

  my $i = 0;
  foreach my $at (@auth_types) {
     $nas->{SEL_AUTH_TYPE} .= "<option value=$i";
     $nas->{SEL_AUTH_TYPE} .= ' selected' if ($nas->{NAS_AUTH_TYPE} eq $i);
     $nas->{SEL_AUTH_TYPE} .= ">$at\n";
     $i++;
   }

$nas->{NAS_DISABLE} = ($nas->{NAS_DISABLE} > 0) ? ' checked' : '';

Abills::HTML->tpl_show(templates('form_nas'), $nas);

    
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ["ID", "$_NAME", "NAS-Identifier", "IP", "$_TYPE", "$_AUTH", '-', '-', '-', '-'],
                                   cols_align => ['center', 'left', 'left', 'right', 'left', 'left', 'center', 'center', 'center', 'center'],
                                  } );

my $list = $nas->list({ %LIST_PARAMS });

foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=60&del=$line->[0]", "$_DEL NAS $line->[2]?"); 
  $table->addrow($line->[0], $line->[1], $line->[2], 
    $line->[4], $line->[5], $auth_types[$line->[6]], 
    $status[$line->[7]],
    "<a href='$SELF_URL?index=61&nid=$line->[0]'>IP POOLs</a>",
    "<a href='$SELF_URL?index=60&nid=$line->[0]'>$_CHANGE</a>",
    $delete);
}
print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$nas->{TOTAL}</b>" ] ]
                               } );
print $table->show();
}

#**********************************************************
# form_ip_pools()
#**********************************************************
sub form_ip_pools {
	my ($attr) = @_;
	my $nas;
  my ($pages_qs);
  
if ($attr->{NAS}) {
	$nas = $attr->{NAS};
  if ($FORM{add}) {
    $nas->ip_pools_add( {
       NAS_IP_SIP => $FORM{NAS_IP_SIP},
       NAS_IP_COUNT => $FORM{NAS_IP_COUNT}
     });

    if (! $nas->{errno}) {
       message('info', $_INFO, "$_ADDED");
     }
   }
  elsif($FORM{del}) {
    $nas->ip_pools_del( $FORM{del} );

    if (! $nas->{errno}) {
       message('info', $_INFO, "$_DELETED");
     }
   }
  $pages_qs = "&nid=$nas->{NID}";

  Abills::HTML->tpl_show(templates('form_ip_pools'), $nas);
 }
elsif($FORM{nid}) {
  form_nas();
  return 0;
}
else {
  $nas = Nas->new($db, \%conf);	
}

if ($nas->{errno}) {
  message('err', $_ERROR, "$err_strs{$nas->{errno}}");
 }



    
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ["NAS", "$_BEGIN", "$_END", "$_COUNT", '-'],
                                   cols_align => ['left', 'right', 'right', 'right', 'center'],
                                   qs => $pages_qs              
                                  } );

my $list = $nas->ip_pools_list({ %LIST_PARAMS });	

foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=61$pages_qs&del=$line->[6]", "$_DEL NAS $line->[4]?"); 
  $table->addrow("<a href='$SELF_URL?index=60&nid=$line->[7]'>$line->[0]</a>", $line->[4], $line->[5], 
    $line->[3],  $delete);
}
print $table->show();
}

#**********************************************************
# form_nas_stats()
#**********************************************************
sub form_nas_stats {
my $nas = Nas->new($db, \%conf);	

my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ["NAS", "NAS_PORT", "$_SESSIONS", "$_LAST_LOGIN", "$_AVG", "$_MIN", "$_MAX"],
                                   cols_align => ['left', 'right', 'right', 'right', 'right', 'right', 'right'],
                                  } );
my $list = $nas->stats({ %LIST_PARAMS });	

foreach my $line (@$list) {
  $table->addrow("<a href='$SELF_URL?index=60&nid=$line->[7]'>$line->[0]</a>", 
     $line->[1], $line->[2],  $line->[3],  $line->[4], $line->[5], $line->[6] );
}

print $table->show();
}





#**********************************************************
# form_back_money()
#**********************************************************
sub form_back_money {
  my ($type, $sum, $attr)	= @_;
  my $UID;

if ($type eq 'log') {
	if(defined($attr->{LOGIN})) {
     my $list = $users->list( { LOGIN => $attr->{LOGIN} } );

     if($users->{TOTAL} < 1) {
     	 message('err', $_USER, "[$users->{errno}] $err_strs{$users->{errno}}");
     	 return 0;
      }
	   $UID = $list->[0]->[6];
	 }
  else {
	  $UID = $attr->{UID};
   }

}


my $OP_SID = mk_unique_value(16);

print << "[END]";
<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=subf value=$index>
<input type=hidden name=sum value='$sum'>
<input type=hidden name=OP_SID value='$OP_SID'>
<input type=hidden name=UID value='$UID'>


<input type=submit name=bm value='$_BACK_MONEY ?'>
</form>
[END]

}
















#**********************************************************
# form_passwd($attr)
#**********************************************************
sub form_passwd {
 my ($attr)=@_;
 my $hidden_inputs;
 
 if (defined($FORM{AID})) {
 	 $hidden_inputs = "<input type=hidden name=AID value='$FORM{AID}'>";
 	 $index=50;
 	}
 elsif (defined($attr->{USER})) {
	 $hidden_inputs = "<input type=hidden name=UID value='$attr->{USER}->{UID}'>";
	 $index=11;
 }


if ($FORM{newpassword} eq '') {

}
elsif (length($FORM{newpassword}) < $conf{passwd_length}) {
  message('err', $_ERROR, $err_strs{6});
}
elsif ($FORM{newpassword} eq $FORM{confirm}) {
  $FORM{PASSWORD} = $FORM{newpassword};
}
elsif($FORM{newpassword} ne $FORM{confirm}) {
  message('err', $_ERROR, $err_strs{5});
}

use Abills::Base;
my $gen_password=mk_unique_value(8);



print << "[END]";
<h3>$_CHANGE_PASSWD</h3>
<form action=$SELF_URL  METHOD=POST>
<input type=hidden name=index value=$index>
$hidden_inputs
<table>
<tr><td>$_GENERED_PARRWORD:</td><td>$gen_password</td></tr>
<tr><td>$_PASSWD:</td><td><input type=password name=newpassword value='$gen_password'></td></tr>
<tr><td>$_CONFIRM_PASSWD:</td><td><input type=password name=confirm value='$gen_password'></td></tr>
</table>
<input type=submit name=change value="$_CHANGE">
</form>
[END]

 return 0;
}


#**********************************************************
#
#**********************************************************
sub fl {
	# ID:PARENT:NAME:FUNCTION:SHOW SUBMENU:module:
my @m = (
 "0:0::null:::",
 "1:0:$_CUSTOMERS:null:::",
 "11:1:$_USERS:form_users:::",
 "12:11:$_ADD:user_form:::",
 "13:1:$_COMPANY:form_companies:::",
 "14:13:$_ADD:add_company:::",
 "22:13:$_LIST:form_companies:::",
 "15:11:$_LOG:form_changes:UID::",
 "17:11:$_PASSWD:form_passwd:UID::",
 "18:11:$_NAS:form_nas_allow:UID::",
 "19:11:$_BILL:form_bills:UID::",
 "20:11:$_SERVICES:null:UID::",
 "21:11:$_COMPANY:user_company:UID::",
 "101:11:$_PAYMENTS:form_payments:UID::",
 "102:11:$_FEES:form_fees:UID::",

 "25:22:$_STATS:form_back_money:UID::",
 "23:22:_DETAIL:session_detail:UID::",
 "24:11:$_GROUP:user_group:UID::",
 "27:1:$_GROUPS:form_groups:::",
 "28:27:$_ADD:add_groups:::",
 "29:27:$_LIST:form_groups:::",
 "30:11:$_USER_INFO:user_pi:UID::",

 "2:0:$_PAYMENTS:form_payments:::",
 "3:0:$_FEES:form_fees:::",
 "4:0:$_REPORTS:null:::",

 "5:0:$_SYSTEM:null:::",
 "50:5:$_ADMINS:form_admins:::",
 "51:50:$_LOG:form_changes:AID::",
 "52:50:$_PERMISSION:admin_permissions:AID::",
 "54:50:$_PASSWD:form_passwd:AID::",
 "55:50:$_FEES:form_fees:AID::",
 "56:50:$_PAYMENTS:form_payments:AID::",
 "57:50:$_CHANGE:form_admins:AID::",
 
 "59:5:$_LOG:form_changes:::",
  
 "60:5:$_NAS:form_nas:::",
 "61:60:IP POOLs:form_ip_pools:::",
 "62:60:$_NAS_STATISTIC:form_nas_stats:NID::",

 "65:5:$_EXCHANGE_RATE:form_exchange_rate:::",
 "75:5:$_HOLIDAYS:form_holidays:::",

 
 "85:5:$_SHEDULE:form_shedule:::",
 "90:5:$_TEMPLATES:form_templates:::",
 
 "6:0:$_OTHER:null:::",
 "1000:6:$_DOCS::::",
  
 "7:0:$_SEARCH:form_search:::",
 
 "8:0:$_MONITORING:null:::",
 "9:0:$_PROFILE:admin_profile:::",
 "53:9:$_PROFILE:admin_profile:::",
 "99:9:$_FUNCTIONS_LIST:flist:::",
 );



foreach my $line (@m) {
	my ($ID, $PARENT, $NAME, $FUNTION_NAME, $ARGS, $OP)=split(/:/, $line);
  $menu_items{$ID}{$PARENT}=$NAME;
  $menu_names{$ID}=$NAME;
  $functions{$ID}=\&$FUNTION_NAME if ($FUNTION_NAME  ne '');
  $menu_args{$ID}=$ARGS if ($ARGS ne '');
  $maxnumber=$ID if ($maxnumber < $ID);
}

	
}


#**********************************************************
# mk_navigator()
#**********************************************************
sub mk_navigator {

 my $menu_navigator = "";
 my %tree = ();

 # make navigate line 
 if ($index > 0) {
  $root_index = $index;	
  my $h = $menu_items{$root_index};

  while(my ($par_key, $name) = each ( %$h )) {
    $menu_navigator =  " <a href='$SELF_URL?index=$root_index'>$name</a> /" . $menu_navigator;
    $tree{$root_index}='y';
    if ($par_key > 0) {
      $root_index = $par_key;
      $h = $menu_items{$par_key};
     }
   }
}

$FORM{root_index} = $root_index;
if ($root_index > 0) {
  my $ri = $root_index-1;
  if (! defined($permissions{$ri})) {
	  message('err', $_ERROR, "Access deny");
#	  exit 0;
   }
}


#my %menu = ();
#my @sorted_menu_items = sort {
#   $ages{$b} <=> $ages{$a}
#     ||
#   length($a) <=> length($b)
#     ||
#   $a cmp $b
#} keys %menu_items;


#@persons = sort keys %ages;

foreach my $ID (sort keys %menu_items) {
 	my $VALUE_HASH = $menu_items{$ID};
 	foreach my $parent (sort keys %$VALUE_HASH) {
    push( @{$menu{$parent}},  "$ID:$VALUE_HASH->{$parent}" );
   }
}




 my @sorted_menu = sort {
   $ages{$b} <=> $ages{$a}
     ||
   length($a) <=> length($b)
     ||
   $a cmp $b
 } keys %menu;
 
 my @last_array = ();

 my $menu_text = "<table border=0 width=100%>\n";
 
 foreach my $parent (@sorted_menu) {

    
    next if ($parent > 0);
 	  my $level  = 0;
 	  my $prefix = '';

 	  label:
 	  $sub_menu_array =  \@{$menu{$parent}};
 	  while( $sm_item = pop @$sub_menu_array) {
 	     my($ID, $name)=split(/:/, $sm_item, 2);

 	     next if((! $permissions{$ID-1}) && $parent == 0);
	      	      	     
 	     $name = (defined($tree{$ID})) ? "> <b>$name</b>": "$name";
 	     #print "$prefix$level / $parent /$ID ";


        if(! defined($menu_args{$ID}) || (defined($menu_args{$ID}) && defined($FORM{$menu_args{$ID}})) ) {
       	   my $ext_args = '';
       	   if (defined($menu_args{$ID})) {
       	       $ext_args = "&$menu_args{$ID}=$FORM{$menu_args{$ID}}";
       	       $name = "<b>$name</b>";
       	     }

       	   $link = "<a href='$SELF_URL?index=$ID$ext_args'>$name</a>";   

    	     if($parent == 0) {
 	        	 $menu_text .= "<tr><td bgcolor=$_COLORS[3] align=left>$prefix$link</td></tr>\n";
 	          }
 	         elsif(defined($tree{$ID})) {
 	           $menu_text .= "<tr><td bgcolor=$_COLORS[2] align=left>$prefix>$link</td></tr>\n";
 	          }
 	         else {
 	           $menu_text  .= "<tr><td bgcolor=$_COLORS[1]>$prefix$link</td></tr>\n";
 	          }
         }
        else {
          #next;
          #$link = "<a href='$SELF_URL?index=$ID&$menu_args{$ID}'>$name</a>";	
         }

 	      	     

 	     if(defined($tree{$ID})) {
 	     	 $level++;
 	     	 $prefix .= "&nbsp;&nbsp;&nbsp;";
         push @last_array, $parent;
         $parent = $ID;
 	     	 $sub_menu_array = \@{$menu{$parent}};
 	      }
 	   }
 	  
    if ($#last_array > -1) {
      $parent = pop @last_array;	
      #print "POP/$#last_array/$parent/<br>\n";
      $level--;
      $prefix = substr($prefix, 0, $level * 6 * 3);
      goto label;
     }
 	  
  }
 
 
 $menu_text .= "</table>\n";

return  $menu_text, "/".$menu_navigator;
}







#**********************************************************
# Functions list
#**********************************************************
sub flist {

my  %new_hash = ();
while((my($findex, $hash)=each(%menu_items))) {
  while(my($k, $val)=each %$hash) {
    $new_hash{$k}{$findex}=$val;
   }
}

my $h = $new_hash{0};
my @last_array = ();

my @menu_sorted = sort {
   $h->{$b} <=> $h->{$a}
     ||
   length($a) <=> length($b)
     ||
   $a cmp $b
} keys %$h;

my %qm = ();
if (defined($COOKIES{qm})) {
	my @a = split(/, /, $COOKIES{qm});
	foreach $line (@a) {
     $qm{$line} = 1;
	 }
}

my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left', 'left', 'center']
                                  } );


foreach my $parent (@menu_sorted) { 
  my $val = $h->{$parent};
  my $level = 0;
  my $prefix = '';
  $table->addrow("$level:", ">> <a href='$SELF_URL?index=$parent'>$val</a> <<");

  if (defined($new_hash{$parent})) {
    $level++;
    $prefix .= "&nbsp;&nbsp;&nbsp;";
    label:
      my $mi = $new_hash{$parent};

      while(my($k, $val)=each %$mi) {
       
        my $checked = '';
        if (defined($qm{$k})) { 
        	$checked = " checked";  
        	$val = "<b>$val</b>";
         }

        
        $table->addrow("$k <input type=checkbox name=qm_item value=$k $checked>", "$prefix <a href='$SELF_URL?index=$k'>$val</a>");

        if (defined($new_hash{$k})) {
      	   $mi = $new_hash{$k};
      	   $level++;
           $prefix .= "&nbsp;&nbsp;&nbsp;";
           push @last_array, $parent;
           $parent = $k;
         }
        delete($new_hash{$parent}{$k});
      }
    
    if ($#last_array > -1) {
      $parent = pop @last_array;	
#      print "POP/$#last_array/$parent/<br>\n";
      $level--;
      
      $prefix = substr($prefix, 0, $level * 6 * 3);
      goto label;
    }
    delete($new_hash{0}{$parent});
   }
}
print "
<form action=$SELF_URL >
<input type=hidden name=index value=$index>\n";


print $table->show();


print "<input type=submit name=quick_set value='Quick Menu'>
</form>\n";
}





#**********************************************************
# check_access
#**********************************************************
sub check_access {
	#! defined($permissions{1})
	return 0;
}

#**********************************************************
# form_payments
#**********************************************************
sub form_payments () {
 my ($attr) = @_; 
 use Finance;
 my $payments = Finance->payments($db, $admin, \%conf);

 return 0 if (! defined ($permissions{1}));


if (defined($attr->{USER})) { 
  my $user = $attr->{USER};
  $payments->{UID} = $user->{UID};

  if($user->{BILL_ID} < 1) {
    form_bills({ USER => $user });
    return 0;
  }

  if (defined($FORM{OP_SID}) and $FORM{OP_SID} eq $COOKIES{OP_SID}) {
 	  message('err', $_ERROR, "$_EXIST");
   }
  elsif ($FORM{add} && $FORM{SUM})	{
    my $er = $payments->exchange_info($FORM{ER});
    $FORM{ER} = $er->{EX_RATE};
    $payments->add($user, { %FORM } );  

    if ($payments->{errno}) {
      message('err', $_ERROR, "[$payments->{errno}] $err_strs{$payments->{errno}}");	
     }
    else {
      message('info', $_PAYMENTS, "$_ADDED");
     }
   }
  elsif($FORM{del} && $FORM{is_js_confirmed}) {
  	if (! defined($permissions{1}{2})) {
      message('err', $_ERROR, "[13] $err_strs{13}");
      return 0;		
	   }

	  $payments->del($user, $FORM{del});
    if ($payments->{errno}) {
      message('err', $_ERROR, "[$payments->{errno}] $err_strs{$payments->{errno}}");	
     }
    else {
      message('info', $_PAYMENTS, "$_DELETED");
     }
   }

#exchange rate sel
my ($er, $total) = $payments->exchange_list();
$payments->{SEL_ER} = "<select name=ER>\n";
  $payments->{SEL_ER} .= "<option value=''>\n";
foreach my $line (@$er) {
  $payments->{SEL_ER} .= "<option value=$line->[4]";
  $payments->{SEL_ER} .= ">$line->[1] : $line->[2]\n";
}
$payments->{SEL_ER} .= "</select>\n";


my $i=0;

$payments->{SEL_METHOD} = "<select name=METHOD>\n";
foreach my $line (@PAYMENT_METHODS) {
  $payments->{SEL_METHOD} .= "<option value=$i";
  $payments->{SEL_METHOD} .= ">$line\n";
  $i++;
}
$payments->{SEL_METHOD} .= "</select>\n";

if (defined ($permissions{1}{1})) {
   $payments->{OP_SID} = mk_unique_value(16);
   Abills::HTML->tpl_show(templates('form_payments'), $payments);
 }
}
elsif($FORM{AID} && ! defined($LIST_PARAMS{AID})) {
	#$FORM{subf}=$index;
	form_admins();
	return 0;
 }
elsif($FORM{UID}) {
	form_users();
	return 0;
}	
elsif($index != 7) {
	form_search();
}


if (! defined($FORM{sort})) {
  $LIST_PARAMS{SORT}=1;
  $LIST_PARAMS{DESC}=DESC;
 }


my $list = $payments->list( { %LIST_PARAMS } );
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['ID', $_LOGIN, $_DATE, $_SUM, $_DESCRIBE, $_ADMINS, 'IP',  $_DEPOSIT, $_PAYMENT_METHOD, 'ID', '-'],
                                   cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left', 'left', 'center'],
                                   qs => $pages_qs,
                                   pages => $payments->{TOTAL}
                                  } );

$pages_qs .= "&subf=2" if (! $FORM{subf});

foreach my $line (@$list) {
  my $delete = ($permissions{1}{2}) ?  $html->button($_DEL, "index=$index&del=$line->[0]&UID=$line->[10]$pages_qs", "$_DEL ?") : ''; 
  $table->addrow("<b>$line->[0]</b>", "<a href='$SELF_URL?index=11&UID=$line->[10]'>$line->[1]</a>", $line->[2], 
   $line->[3], $line->[4],  "$line->[5]", "$line->[6]", "$line->[7]", $PAYMENT_METHODS[$line->[8]], "$line->[9]", $delete);
}

print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right', 'right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$payments->{TOTAL}</b>", "$_SUM", "<b>$payments->{SUM}</b>" ] ],
                                rowcolor => $_COLORS[2]
                               } );
print $table->show();
}

#*******************************************************************
# form_exchange_rate
#*******************************************************************
sub form_exchange_rate {
 my @action = ('add', "$_ADD");
 my $short_name = $FORM{short_name} || '-';
 my $money = $FORM{money} || '-';
 my $rate  = $FORM{rate} || '0.0000';
 
 
 use Finance;
 my $finance = Finance->new($db, $admin);


if ($FORM{add}) {
	$finance->exchange_add($money, $short_name, $rate);
  if ($finance->{errno}) {
    message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    message('info', $_EXCHANGE_RATE, "$_ADDED");
   }
}
elsif($FORM{change}) {
	$finance->exchange_change("$FORM{chg}", $money, $short_name, $rate);
  if ($finance->{errno}) {
    message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    message('info', $_EXCHANGE_RATE, "$_CHANGED");
   }
}
elsif($FORM{chg}) {
	$finance->exchange_info("$FORM{chg}");
  if ($finance->{errno}) {
    message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
  	@action = ('change', $_CHANGE);
    message('info', $_EXCHANGE_RATE, "$_CHANGING");
   }
}
elsif($FORM{del}) {
	$finance->exchange_del("$FORM{del}");
  if ($finance->{errno}) {
    message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    message('info', $_EXCHANGE_RATE, "$_DELETED");
   }

}
	
print << "[END]";
<form action=$SELF_URL>
<input type=hidden name=index   value=$index>
<input type=hidden name=op   value=er>
<input type=hidden name=chg   value="$FORM{chg}"> 
<table>
<tr><td>$_MONEY:</td><td><input type=text name=money value='$finance->{MU_NAME}'></td></tr>
<tr><td>$_SHORT_NAME:</td><td><input type=text name=short_name value='$finance->{MU_SHORT_NAME}'></td></tr>
<tr><td>$_EXCHANGE_RATE:</td><td><input type=text name=rate value='$finance->{EX_RATE}'></td></tr>
</table>
<input type=submit name=$action[0] value='$action[1]'>
</form>
[END]

my $table = Abills::HTML->table( { width => '640',
                                   title => ["$_MONEY", "$_SHORT_NAME", "$_EXCHANGE_RATE (1 unit =)", "$_CHANGED", '-', '-'],
                                   cols_align => ['left', 'left', 'right', 'center', 'center'],
                                  } );

my ($list, $total) = $finance->exchange_list( {%LIST_PARAMS} );
foreach my $line (@$list) {
  $table->addrow($line->[0], $line->[1], $line->[2], $line->[3], "<a href='$SELF_URL?index=65&chg=$line->[4]'>$_CHANGE</a>", 
     $html->button($_DEL, "index=65&del=$line->[4]", "$_DEL ?"));
}
print $table->show();
}



#*******************************************************************
# form_fees
#*******************************************************************
sub form_fees  {
 my ($attr) = @_;
 my $period = $FORM{period} || 0;
 
 return 0 if (! defined ($permissions{2}));
 
 use Finance;
 my $fees = Finance->fees($db, $admin);

if (defined($attr->{USER})) {
  my $user = $attr->{USER};

  if($user->{BILL_ID} < 1) {
    form_bills({ USER => $user });
    return 0;
  }

  $fees->{UID} = $user->{UID};
  if ($FORM{take} && $FORM{SUM}) {
    # add to shedule
    if ($period == 1) {
      use Shedule;
      $FORM{date_m}++;
      my $shedule = Shedule->new($db, $admin); 
      $shedule->add( { DESCRIBE => $FORM{DESCR}, 
      	               D => $FORM{date_d},
      	               M => $FORM{date_m},
      	               Y => $FORM{date_y},
                       UID => $user->{UID},
                       TYPE => 'fees',
                       ACTION => "$FORM{SUM}:$FORM{DESCR}"
                      } );
     }
    #Add now
    else {
      $fees->take($user, $FORM{SUM}, { DESCRIBE => $FORM{DESCR} } );  
      if ($fees->{errno}) {
        message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");	
       }
      else {
        message('info', $_PAYMENTS, "$_ADDED");
       }
    }
   }
  elsif ($FORM{del} && $FORM{is_js_confirmed}) {
  	if (! defined($permissions{2}{2})) {
      message('err', $_ERROR, "[13] $err_strs{13}");
      return 0;		
	   }

	  $fees->del($user,  $FORM{del});
    if ($fees->{errno}) {
      message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");
     }
    else {
      message('info', $_DELETED, "$_DELETED [$FORM{del}]");
    }
   }


  $fees->{PERIOD_FORM}=form_period($period);

if (defined ($permissions{2}{1})) {
  Abills::HTML->tpl_show(templates('form_fees'), $fees);
 }	
}
elsif($FORM{AID} && ! defined($LIST_PARAMS{AID})) {
	$FORM{subf}=$index;
	form_admins();
	return 0;
 }
elsif($FORM{UID}) {
	form_users();
	return 0;
}
elsif($index != 7) {
	form_search();
}


if (! defined($FORM{sort})) {
  $LIST_PARAMS{SORT}=1;
  $LIST_PARAMS{DESC}=DESC;
 }

my $list = $fees->list( { %LIST_PARAMS } );
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['ID', $_LOGIN, $_DATE, $_SUM, $_DESCRIBE, $_ADMINS, 'IP',  $_DEPOSIT, '-'],
                                   cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'center'],
                                   qs => $pages_qs,
                                   pages => $fees->{TOTAL}
                                  } );


$pages_qs .= "&subf=2" if (! $FORM{subf});
foreach my $line (@$list) {
  my $delete = ($permissions{2}{2}) ?  $html->button($_DEL, "index=$index&del=$line->[0]&UID=$line->[8]$pages_qs", "$_DEL ?") : ''; 

  $table->addrow("<b>$line->[0]</b>", "<a href='$SELF_URL?index=11&UID=$line->[8]'>$line->[1]</a>", $line->[2], 
   $line->[3], $line->[4],  "$line->[5]", "$line->[6]", "$line->[7]", $delete);
}

print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right', 'right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$fees->{TOTAL}</b>", "$_SUM:", "<b>$fees->{SUM}</b>" ] ],
                                rowcolor => $_COLORS[2]
                                  } );
print $table->show();


}




#*******************************************************************
# Search form
#*******************************************************************
sub form_search {
  my ($attr) = @_;

my %SEARCH_DATA = $admin->get_data(\%FORM);  

if (defined($attr->{HIDDEN_FIELDS})) {
	my $SEARCH_FIELDS = $attr->{HIDDEN_FIELDS};
	while(my($k, $v)=each( %$SEARCH_FIELDS )) {
	  $SEARCH_DATA{HIDDEN_FIELDS}.="<input type=hidden name=\"$k\" value=\"$v\">\n";
	 }
}


if (defined($attr->{SIMPLE})) {

	my $SEARCH_FIELDS = $attr->{SIMPLE};
	while(my($k, $v)=each( %$SEARCH_FIELDS )) {
	  $SEARCH_DATA{SEARCH_FORM}.="<tr><td>$k:</td><td><input type=text name=\"$v\" value=\"%". $v ."%\"></td></tr>\n";
	 }
  Abills::HTML->tpl_show(templates('form_search_simple'), \%SEARCH_DATA);
}
else {

my $i=0;
my $SEL_METHOD = "<select name=METHOD>\n";
   $SEL_METHOD .= "<option value=''>$_ALL\n";
foreach my $line (@PAYMENT_METHODS) {
  $SEL_METHOD .= "<option value=$i";
	$SEL_METHOD .= ' selected' if ($FORM{METHOD} eq $i);
  $SEL_METHOD .= ">$line\n";
  $i++;
}
$SEL_METHOD .= "</select>\n";




my %search_form = ( 
2 => "
<!-- PAYMENTS -->
<tr><td colspan=2><hr></td></tr>
<tr><td>$_OPERATOR:</td><td><input type=text name=A_LOGIN value='%A_LOGIN%'></td></tr>
<tr><td>$_DESCRIBE (*):</td><td><input type=text name=DESCRIBE value='%DESCRIBE%'></td></tr>
<tr><td>$_SUM (<,>):</td><td><input type=text name=SUM value='%SUM%'></td></tr>
<tr><td>$_PAYMENT_METHOD:</td><td>$SEL_METHOD</td></tr>\n",

3 => "
<!-- FEES -->
<tr><td colspan=2><hr></td></tr>
<tr><td>$_OPERATOR (*):</td><td><input type=text name=A_LOGIN value='%A_LOGIN%'></td></tr>
<tr><td>$_DESCRIBE (*):</td><td><input type=text name=DESCRIBE value='%DESCRIBE%'></td></tr>
<tr><td>$_SUM (<,>):</td><td><input type=text name=SUM value='%SUM%'></td></tr>\n",

11 => "
<!-- USERS -->
<tr><td colspan=2><hr></td></tr>
<tr><td>IP (>, <, *):</td><td><input type=text name=IP value='%IP%' title='Examples:\n 192.168.101.1\n >192.168.0\n 192.168.*.*'></td></tr>
<tr><td>$_SPEED (>, <):</td><td><input type=text name=SPEED value='%SPEED%'></td></tr>
<tr><td>CID</td><td><input type=text name=CID value='%CID%'></td></tr>
<tr><td>$_FIO (*):</td><td><input type=text name=FIO value='%FIO%'></td></tr>
<tr><td>$_PHONE (>, <, *):</td><td><input type=text name=PHONE value='%PHONE%'></td></tr>
<tr><td>$_COMMENTS (*):</td><td><input type=text name=COMMENTS value='%COMMENTS%'></td></tr>\n",

);


$SEARCH_DATA{SEARCH_FORM}=(defined($attr->{SEARCH_FORM})) ? $attr->{SEARCH_FORM} : $search_form{$FORM{type}};
$SEARCH_DATA{FROM_DATE} = Abills::HTML->date_fld('FROM_', { MONTHES => \@MONTHES });
$SEARCH_DATA{TO_DATE} = Abills::HTML->date_fld('TO_', { MONTHES => \@MONTHES} );
$SEARCH_DATA{SEL_TYPE}="<tr><td>WHERE:</td><td>$SEL_TYPE</td></tr>\n" if ($index == 7);

Abills::HTML->tpl_show(templates('form_search'), \%SEARCH_DATA);

}

if ($FORM{search}) {

	$LIST_PARAMS{LOGIN_EXPR}=$FORM{LOGIN_EXPR};
  $pages_qs = "&search=y&type=$FORM{type}";

	if(defined($FORM{FROM_D}) && defined($FORM{TO_D})) {
	  $FORM{FROM_DATE}="$FORM{FROM_Y}-". ($FORM{FROM_M}+1). "-$FORM{FROM_D}";
	  $FORM{TO_DATE}="$FORM{TO_Y}-". ($FORM{TO_M}+1) ."-$FORM{TO_D}";
   }	 
	
	while(my($k, $v)=each %FORM) {
		if ($k =~ /([A-Z0-9]+)/ && $v ne '') {
		  print "$k, $v<br>";
		  $LIST_PARAMS{$k}=$v;
	    $pages_qs .= "&$k=$v";
		 }
	 }



  if ($FORM{type} ne $index) {
  	#$index = $FORM{type};
    $functions{$FORM{type}}->();
   }
}





}







#*******************************************************************
# form_shedule()
#*******************************************************************
sub form_shedule {

use Shedule;
my $shedule = Shedule->new($db, $admin);

if ($FORM{del} && $FORM{is_js_confirmed}) {
  $shedule->del($FORM{del});
  if ($admins->{errno}) {
    message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");
   }
  else {
    message('info', $_DELETED, "$_DELETED [$FORM{del}]");
   }
}


my $list = $shedule->list( { %LIST_PARAMS } );
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ["$_HOURS", "$_DAY", "$_MONTH", "$_YEAR", "$_COUNT", "$_USER", "$_TYPE", "$_VALUE", "$_MODULES", "$_ADMINS", "$_CREATED", "-"],
                                   cols_align => ['right', 'right', 'right', 'right', 'right', 'left', 'right', 'right', 'right', 'left', 'right', 'center'],
                                   qs => $pages_qs,
                                   pages => $shedule->{TOTAL}
                                  } );

foreach my $line (@$list) {
  my $delete = ($permissions{4}{3}) ?  $html->button($_DEL, "index=$index&del=$line->[13]", "$_DEL ?") : '-'; 
  $table->addrow("<b>$line->[0]</b>", $line->[1], $line->[2], 
    $line->[3],  $line->[4],  "<a href='$SELF_URL?index=11&UID=$line->[11]'>$line->[5]</a>", 
    "$line->[6]", "$line->[7]", "$line->[8]", "$line->[9]", "$line->[10]", $delete);
}

print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right', 'right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$shedule->{TOTAL}</b>" ] ]
                               } );
print $table->show();





}




#**********************************************************
# Create templates
# form_templates()
#**********************************************************
sub form_templates {
  my %templates = ('user_warning' => USER_WARNING,
                   'invoce'       => INVOCE,
                   'admin_report' => ADMIN_REPORT,
                   'account'      => ACCOUNT,
                   'user_info'    => USER_INFO);





if ($FORM{change}) {
  my $FORM2  = ();
  my @pairs = split(/&/, $FORM{__BUFFER});

foreach my $pair (@pairs) {
   my ($side, $value) = split(/=/, $pair);
   $value =~ tr/+/ /;
   $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

   if (defined($FORM2{$side})) {
     $FORM2{$side} .= ", $value";
    }
   else {
     $FORM2{$side} = $value;
    }
 }


  $template = $FORM2{template};
  


  
	open(FILE, ">$conf{TPL_DIR}/$FORM{tpl_name}") || message('err', $_ERROR, "Can't open file '$conf{TPL_DIR}/$FORM{tpl_name}' $!\n");
	  print FILE "$template";
	close(FILE);

	message('info', $_INFO, "$_ADDED");
}
elsif($FORM{tpl_name}) {
  if (-f  "$conf{TPL_DIR}/$FORM{tpl_name}" ) {
	  open(FILE, "$conf{TPL_DIR}/$FORM{tpl_name}") || message('err', $_ERROR, "Can't open file '$conf{TPL_DIR}/$FORM{tpl_name}' $!\n");;
  	  while(<FILE>) {
	    	 $template .= $_;
	    }	 
	  close(FILE);
   }
	  message('info', $_CHAMGE, "$_CHANGE: $templates{$FORM{tpl_name}}");
}



print << "[END]";
<form action=$SELF_URL METHOD=POST>
<input type=hidden name=index value='$index'>
<input type=hidden name=tpl_name value='$FORM{tpl_name}'>
<table>
<tr bgcolor=$_COLORS[0]><th>$_TEMPLATES</th></tr>
<tr><td>
<textarea cols=100 rows=30 name=template>$template</textarea>
</td></tr>
</table>
<input type=submit name=change value='$_CHANGE'>
</form>
[END]

my $table = Abills::HTML->table( { width => '600',
                                   title_plain => ["FILE", "$_NAME", "-"],
                                   cols_align => ['left', 'left', 'center']
                                  } );

while(my($k, $v) = each %templates) {
  $table->addrow("<b>$k</b>", "$v", "<a href='$SELF_URL?index=$index&tpl_name=$k'>$_CHANGE</a>");
}

print $table->show();





}

























#**********************************************************
# sql()
#**********************************************************
sub sql {
print << "[END]";
<a href='$SELF_URL?index=81'>SQL Commander</a> :: 
<a href='$SELF_URL?index=82'>SQL Backup</a>
[END]


}


#**********************************************************
# sql_cmd()
#**********************************************************
sub sql_cmd {
print << "[END]";

[END]
}


#**********************************************************
# sql_backup()
#**********************************************************
sub sql_backup {

print << "[END]";

[END]
}








#*******************************************************************
# form_period
#*******************************************************************
sub form_period  {
 my ($period) = @_;


 my @periods = ("$_NOW", "$_DATE");
 my $date_fld = $html->date_fld('date_', { MONTHES => \@MONTHES });
 my $form_period='';


 $form_period .= "<tr><td>$_DATE:</td><td>";

 my $i=0;
 foreach my $t (@periods) {
   $form_period .= "<br><br><input type=radio name=period value=$i";
   $form_period .= " checked" if ($i eq $period);
   $form_period .= "> $t\n";	
   $i++;
 }
 $form_period .= "$date_fld</td></tr>\n";


 return $form_period;	
}


#*******************************************************************
# sel_groups();
#*******************************************************************
sub sel_groups {
	
my $list = $users->groups_list({ %LIST_PARAMS });

my $GROUPS_SEL = "<select name=GID>\n";
foreach my $line (@$list) {
 $GROUPS_SEL .= "<option value=$line->[0]";
 $GROUPS_SEL .= ' selected' if ($line->[0] eq $FORM{GID});
 $GROUPS_SEL .= ">$line->[1]\n";
}
$GROUPS_SEL .= "</select>\n";

 return $GROUPS_SEL;	
}

#*******************************************************************
#
#*******************************************************************
sub weblog {
	my ($action, $value) = @_;

  open(FILE, ">>$conf{WEB_LOGFILE}") || die "Can't open file '$conf{WEB_LOGFILE}' $!\n";
    print FILE "$DATE $TIME $admin->{A_LOGIN} $admin->{SESSION_IP} $action:$value\n";
  close(FILE);
	
}




