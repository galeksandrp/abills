#!/usr/bin/perl
# 
# http://www.maani.us/charts/index.php
#use vars qw($begin_time);
BEGIN {
 my $libpath = '../../';
 
 $sql_type='mysql';
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');
 unshift(@INC, $libpath . 'Abills/');

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


my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef  });

$db = $sql->{db};
$admin = Admins->new($db, \%conf);
use Abills::Base;

@state_colors = ("#00FF00", "#FF0000", "#AAAAFF");

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

#print "Content-Type: texthtml\n\n";    
#while(my($k, $v)=each %ENV) {
#	print "$k, $v\n";
#}
#exit;
%permissions = ();
if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
  $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
  my ($REMOTE_USER,$REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));  

  my $res =  check_permissions("$REMOTE_USER", "$REMOTE_PASSWD");
  if ($res == 1) {
    print "WWW-Authenticate: Basic realm=\"Billing system\"\n";
    print "Status: 401 Unauthorized\n";
   }
  elsif ($res == 2) {
    print "WWW-Authenticate: Basic realm=\"Billing system / '$REMOTE_USER' Account Disabled\"\n";
    print "Status: 401 Unauthorized\n";
   }

}
else {
  check_permissions('$REMOTE_USER');
}

$html = Abills::HTML->new({ CONF => \%conf, NO_PRINT => 0, %{ $admin->{WEB_OPTIONS} } });
require "../../language/$html->{language}.pl";

if ($admin->{errno}) {
  print "Content-type: text/html\n\n";
  my $message = 'Access Deny';

  if ($admin->{errno} == 2) {
  	$message = "Account Disabled or $admin->{errstr}";
   }
  elsif (! defined($REMOTE_USER)) {
    $message = "Wrong password";
   }
  elsif (! defined($REMOTE_PASSWD)) {
  	$message = "'mod_rewrite' not install";
   }
  else {
    $message = $err_strs{$admin->{errno}};
   }

  $html->message('err', $_ERROR, "$message");
  exit;
}


#Operation system ID
$html->setCookie('OP_SID', "$FORM{OP_SID}", "Fri, 1-Jan-2038 00:00:01", '', $domain, $secure);

#Admin Web_options
if ($FORM{AWEB_OPTIONS}) {
  my %WEB_OPTIONS = ( language  => 1,
                      REFRESH   => 1,
                      colors    => 1,
                      PAGE_ROWS => 1
                    );

	my $web_options = '';
	
	if (! $FORM{default}) {
	  while(my($k, $v)=each %WEB_OPTIONS){
		  if ($FORM{$k}) {
  			$web_options .= "$k=$FORM{$k};";
	  	 }
      else {
    	  $web_options .= "$k=$admin->{WEB_OPTIONS}{$k};" if ($admin->{WEB_OPTIONS}{$k});
       } 
	   }
   }

  if (defined($FORM{quick_set})) {
    my(@qm_arr) = split(/, /, $FORM{qm_item});
    $web_options.="qm=";
    foreach my $line (@qm_arr) {
      $web_options .= (defined($FORM{'qm_name_'.$line})) ? "$line:".$FORM{'qm_name_'.$line}."," : "$line:,";
     }
    chop($web_options);
   }
  else {
    $web_options.="qm=$admin->{WEB_OPTIONS}{qm};";
   }
  
  $admin->change({ AID => $admin->{AID}, WEB_OPTIONS => $web_options });

  print "Location: $SELF_URL?index=$FORM{index}", "\n\n";
  exit;
}


#===========================================================


my @actions = ([$_SA_ONLY, $_ADD, $_LIST, $_PASSWD, $_CHANGE, $_DEL, $_ALL, $_MULTIUSER_OP],  # Users
               [$_LIST, $_ADD, $_DEL, $_ALL],                                 # Payments
               [$_LIST, $_GET, $_DEL, $_ALL],                                 # Fees
               [$_LIST, $_DEL],                                               # reports view
               [$_LIST, $_ADD, $_CHANGE, $_DEL],                              # system magment
               [$_ALL],                                                       # Modules managments
               [$_SEARCH],                                                    # Search
               [$_MONITORING],
               [$_PROFILE],
               );

$LIST_PARAMS{GID}=$admin->{GID} if ($admin->{GID} > 0);

#Global Vars
@action    = ('add', $_ADD);
@bool_vals = ($_NO, $_YES);
@PAYMENT_METHODS = ('Cash', 'Bank', 'Internet Card', 'Credit Card', 'Bonus');

my %menu_items  = ();
my %menu_names  = ();
my $maxnumber   = 0;
my %uf_menus    = (); #User form menu list


fl();
my %USER_SERVICES = ();
#Add modules
foreach my $m (@MODULES) {
	require "Abills/modules/$m/config";
  my %module_fl=();

  my @sordet_module_menu = sort keys %FUNCTIONS_LIST;
  foreach my $line (@sordet_module_menu) {
   
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

    #make user service list
    if ($SUB == 0 && $FUNCTIONS_LIST{$line} == 11) {
      $USER_SERVICES{$maxnumber}="$NAME" ;
     }

    $menu_names{$maxnumber}=$NAME;
    $functions{$maxnumber}=$FUNTION_NAME if ($FUNTION_NAME  ne '');
    $module{$maxnumber}=$m;
  }
}

use Users;
my $users = Users->new($db, $admin, \%conf); 


#Quick index
# Show only function results whithout main windows
if ($FORM{qindex}) {
  $index = $FORM{qindex};

  if(defined($module{$index})) {
    my $lang_file = '';
    foreach my $prefix (@INC) {
      my $realfilename = "$prefix/Abills/modules/$module{$index}/lng_$html->{language}.pl";
      if (-f $realfilename) {
        $lang_file =  $realfilename;
        require $lang_file;
        last;
       }
     }

    if ($lang_file eq '' && -f "Abills/modules/$module{$index}/lng_english.pl" ) {
      require "Abills/modules/$module{$index}/lng_english.pl";
     }

 	 	require "Abills/modules/$module{$index}/webinterface";
   }

  $functions{$index}->();
  exit;
}






print $html->header({ 
	 PATH    => '../',
	 CHARSET => $CHARSET });


my ($menu_text, $navigat_menu) = mk_navigator();
my ($online_users, $online_count) = $admin->online();


my %SEARCH_TYPES = (11 => $_USERS,
                    2  => $_PAYMENTS,
                    3  => $_FEES,
                    13 => $_COMPANY
                   );

if(defined($FORM{index}) && $FORM{index} != 7 && ! defined($FORM{type})) {
	$FORM{type}=$FORM{index};
 }
elsif (! defined $FORM{type}) {
	$FORM{type}=15;
}

my $SEL_TYPE = $html->form_select('type', 
                                { SELECTED   => $FORM{type},
 	                                SEL_HASH   => \%SEARCH_TYPES,
 	                                NO_ID      => 1
 	                                #EX_PARAMS => 'onChange="selectstype()"'
 	                               });


print "
<table width='100%'>
<tr bgcolor='$_COLORS[3]'><td colspan='2'>
<div class='header'>
<form action='$SELF_URL'>
<table width='100%' border='0'>
  <tr><th align='left'>$_DATE: $DATE $TIME Admin: <a href='$SELF_URL?index=53'>$admin->{A_LOGIN}</a> / Online: <abbr title=\"$online_users\"><a href='$SELF_URL?index=50' title='$online_users'>Online: $online_count</a></abbr></th>
  <th align='right'><input type='hidden' name='index' value='7'/><input type='hidden' name='search' value='y'/>
  Search: $SEL_TYPE <input type='text' name=\"LOGIN_EXPR\" value='$FORM{LOGIN_EXPR}'/> 
  (<b><a href='#' onclick=\"window.open('help.cgi?index=$index&amp;FUNCTION=$functions{$index}','help',
    'height=550,width=450,resizable=0,scrollbars=yes,menubar=no, status=yes');\">?</a></b>)</th></tr>
</table>
</form>
</div>
</td></tr>\n";



if(defined($conf{tech_works})) {
  print "<tr><th bgcolor='#FF0000' colspan='2'>$conf{tech_works}</th></tr>";
}

if ($admin->{WEB_OPTIONS}{qm}) {
  print "<tr><td colspan='2' class='noprint'>\n<table  width='100%' border='0'>";
	my @a = split(/,/, $admin->{WEB_OPTIONS}{qm});
  my $i = 0;
	foreach my $line (@a) {
    if (  $i % 6 == 0) {
      print "<tr>\n";
     }

    my ($qm_id, $qm_name)=split(/:/, $line, 2);
    my $color=($qm_id eq $index) ? $_COLORS[0] : $_COLORS[2];
    
    $qm_name = $menu_names{$qm_id} if ($qm_name eq '');
    
    print "  <th bgcolor='$color'>";
    if (defined($menu_args{$qm_id})) {
    	my $args = 'LOGIN_EXPR' if ($menu_args{$qm_id} eq 'UID');
      print $html->button("$qm_name", '', 
         { JAVASCRIPT => "javascript: Q=prompt('$menu_names{$qm_id}',''); if (Q != null) {  Q='". "&$args='+Q;  }else{Q = '';} this.location.href='$SELF_URL?index=$qm_id'+Q;" });
     }
    else {
      print $html->button($qm_name, "index=$qm_id");
     } 
     
    print "  </th>\n";
	  $i++;
	 }
  
  print "</tr></table>\n</td></tr>\n";
}

print "<tr><td valign='top' width='18%' bgcolor='$_COLORS[2]' rowspan='2' class='noprint'>
$menu_text
</td><td bgcolor='$_COLORS[0]' height='50'>$navigat_menu</td></tr>
<tr><td valign='top' align='center'>";


if ($functions{$index}) {
  if(defined($module{$index})) {
    my $lang_file = '';
    foreach my $prefix (@INC) {
      my $realfilename = "$prefix/Abills/modules/$module{$index}/lng_$html->{language}.pl";
      if (-f $realfilename) {
        $lang_file =  $realfilename;
        require $lang_file;
        last;
       }
     }

    if ($lang_file eq '' && -f "Abills/modules/$module{$index}/lng_english.pl" ) {
      require "Abills/modules/$module{$index}/lng_english.pl";
     }

 	 	require "Abills/modules/$module{$index}/webinterface";
   }
  
  if(defined($FORM{UID}) && $FORM{UID} > 0) {
  	my $ui = user_info($FORM{UID});
  	if($ui->{errno}==2) {
  		$html->message('err', $_ERROR, "[$FORM{UID}] $_USER_NOT_EXIST")
  	 }
    elsif ($admin->{GID} > 0 && $ui->{GID} != $admin->{GID}) {
    	$html->message('err', $_ERROR, "[$FORM{UID}] $_USER_NOT_EXIST")
     }
  	else {
  	  $functions{$index}->({ USER => $ui });
  	  #$LIST_PARAMS{LOGIN} = '11111';
  	}
   }
  elsif ($index == 0) {
  	form_start();
   }
  else {
     $functions{$index}->();
   }
}
else {
  $html->message('err', $_ERROR,  "Function not exist ($index / $functions{$index})");	
}


if ($begin_time > 0) {
  my $end_time = gettimeofday;
  my $gen_time = $end_time - $begin_time;
  $conf{version} .= " (Generation time: $gen_time)";
}

print "</td></tr>
<tr><td colspan='2'><hr/> ABillS $conf{version}</td></tr>
</table>\n";
#print ';
$html->test();






























#**********************************************************
#
# check_permissions()
#**********************************************************
sub check_permissions {
  my ($login, $password, $attr)=@_;


  $login =~ s/"/\\"/g;
  $login =~ s/'/\''/g;
  $password =~ s/"/\\"/g;
  $password =~ s/'/\\'/g;

  my %PARAMS = ( LOGIN     => "$login", 
                 PASSWORD  => "$password",
                 SECRETKEY => $conf{secretkey},
                 IP        => $ENV{REMOTE_ADDR} || '0.0.0.0');


  $admin->info(0, { %PARAMS } );

  

  if ($admin->{errno}) {
    return 1;
   }
  elsif($admin->{DISABLE} == 1) {
  	$admin->{errno}=2;
  	$admin->{errstr} = 'DISABLED';
  	return 2;
   }
  
  if ($admin->{WEB_OPTIONS}) {
    my @WO_ARR = split(/;/, $admin->{WEB_OPTIONS}	);
    foreach my $line (@WO_ARR) {
    	my ($k, $v)=split(/=/, $line);
    	$admin->{WEB_OPTIONS}{$k}=$v;
     }
   }
  
  my $p_ref = $admin->get_permissions();
  %permissions = %$p_ref;

  return 0;
}


#**********************************************************
#
#**********************************************************
sub form_start {
my  %new_hash = ();
while((my($findex, $hash)=each(%menu_items))) {
   while(my($parent, $val)=each %$hash) {
     $new_hash{$parent}{$findex}=$val;
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

my $table2 = $html->table({ width       => '100%',
	                          border => 0 });
my $table;
my @rows;

for(my $parent=1; $parent<$#menu_sorted; $parent++) { 
  my $val = $h->{$parent};
  my $level = 0;
  my $prefix = '';
  $table->{rowcolor}=$_COLORS[0];      

  next if (! defined($permissions{($parent-1)}));  

  if ($parent != 0) {
    $table = $html->table({ width       => '200',
                            title_plain => [ $html->button("<b>$val</b>", "index=$parent") ],
                            border      => 1,
                            cols_align  => ['left']
                         });
   }

  if (defined($new_hash{$parent})) {
    $table->{rowcolor}=$_COLORS[1];
    $level++;
    $prefix .= "&nbsp;&nbsp;&nbsp;";

    label:
      my $mi = $new_hash{$parent};
      while(my($k, $val)=each %$mi) {
        $table->addrow("$prefix ". $html->button($val, "index=$k"));
        delete($new_hash{$parent}{$k});
      }
  }

push @rows, $table->td($table->show(), { bgcolor => $_COLORS[1], valign => 'top', align => 'center' });

if ($#rows > 1) {
  $table2->addtd(@rows);
  undef @rows;
}


}

$table2->addtd(@rows);
print $table2->show();
# return 0;


	
}
#**********************************************************
#
#**********************************************************
sub form_companies {
  use Customers;	

  my $customer = Customers->new($db, $admin, \%conf);
  my $company = $customer->company();

if ($FORM{add}) {
  $company->add({ %FORM });
 
  if (! $company->{errno}) {
    $html->message('info', $_ADDED, "$_ADDED");
   }
 }
elsif($FORM{change}) {

  $company->change({ %FORM });

  if (! $company->{errno}) {
    $html->message('info', $_INFO, $_CHANGED. " # $company->{ACCOUNT_NAME}");
    goto INFO;  	 
   }

 }
elsif($FORM{COMPANY_ID}) {
  

  
  INFO:

  $company->info($FORM{COMPANY_ID});
  $LIST_PARAMS{COMPANY_ID}=$FORM{COMPANY_ID};
  $pages_qs .= "&COMPANY_ID=$FORM{COMPANY_ID}";

  func_menu({ 
  	         'ID'   => $company->{COMPANY_ID}, 
  	         $_NAME => $company->{COMPANY_NAME}
  	       }, 
  	{ 
  	 $_INFO     => ":COMPANY_ID=$company->{COMPANY_ID}",
     $_USERS    => "11:COMPANY_ID=$company->{COMPANY_ID}",
     $_PAYMENTS => "2:COMPANY_ID=$company->{COMPANY_ID}",
     $_FEES     => "3:COMPANY_ID=$company->{COMPANY_ID}",
     $_ADD_USER => "24:COMPANY_ID=$FORM{COMPANY_ID}",
     $_BILL     => "19:COMPANY_ID=$FORM{COMPANY_ID}"
  	 });
 

  #Sub functions
  if (! $FORM{subf}) {
    $company->{ACTION}='change';
    $company->{LNG_ACTION}=$_CHANGE;
    $company->{DISABLE} = ($company->{DISABLE} > 0) ? 'checked' : '';
    $html->tpl_show(templates('form_company'), $company);
  }

 }
elsif(defined($FORM{del}) && defined($FORM{is_js_confirmed})  && $permissions{0}{5} ) {
   $company->del( $FORM{del} );
   $html->message('info', $_INFO, "$_DELETED # $FORM{del}");
 }
else {
  my $list = $company->list( { %LIST_PARAMS } );
  my $table = $html->table( { width      => '100%',
                              caption    => $_COMPANIES,
                              border     => 1,
                              title      => [$_NAME, $_DEPOSIT, $_REGISTRATION, $_USERS, $_STATUS, '-', '-'],
                              cols_align => ['left', 'right', 'right', 'right', 'center', 'center'],
                              pages      => $company->{TOTAL},
                              qs         => $pages_qs
                                  } );

  foreach my $line (@$list) {
    $table->addrow($line->[0],  
      $line->[1], 
      $line->[2], 
      $html->button($line->[3], "index=13&COMPANY_ID=$line->[5]"), 
      "$status[$line->[4]]",
      $html->button($_INFO, "index=13&COMPANY_ID=$line->[5]"), 
      (defined($permissions{0}{5})) ? $html->button($_DEL, "index=13&del=$line->[5]", { MESSAGE => "$_DEL $line->[0]?" }) : ''
      );
   }
  print $table->show();

  $table = $html->table( { width      => '100%',
                           cols_align => ['right', 'right'],
                           rows       => [ [ "$_TOTAL:", "<b>$company->{TOTAL}</b>" ] ]
                       } );
  print $table->show();
}

  if ($company->{errno}) {
    $html->message('info', $_ERROR, "[$company->{errno}] $err_strs{$company->{errno}}");
   }

}


#**********************************************************
# Functions menu
#**********************************************************
sub func_menu {
  my ($header, $items, $f_args)=@_; 
 
print "<TABLE width=\"100%\" bgcolor=\"$_COLORS[2]\">\n";

while(my($k, $v)=each %$header) {
  print "<tr><td>$k: </td><td valign=top>$v</td></tr>\n";
}
print "<tr bgcolor=\"$_COLORS[3]\"><td colspan=\"2\">\n";

my $menu;
while(my($name, $v)=each %$items) {
  my ($subf, $ext_url)=split(/:/, $v, 2);
  $menu .= (defined($FORM{subf}) && $FORM{subf} eq $subf) ? "::". $html->button("<b>$name</b>", "index=$index&$ext_url&subf=$subf"): "::". $html->button($name, "index=$index&$ext_url&subf=$subf");
}

print "$menu</td></tr>
</TABLE>\n";


if ($FORM{subf}) {
  if ($functions{$FORM{subf}}) {
 	  if(defined($module{$index})) {
  	 	require "Abills/modules/$module{$index}/webinterface";
     }
    $functions{$FORM{subf}}->($f_args->{f_args});
   }
  else {
  	$html->message('err', $_ERROR, "Function not Defined");
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
  $html->tpl_show(templates('form_company'), $company);
}



#**********************************************************
# user_form()
#**********************************************************
sub user_form {
 my ($user_info, $attr) = @_;

 $index = 15;
 
 if (! defined($user_info->{UID})) {
   my $user = Users->new($db, $admin); 
   $user_info = $user->defaults();

   if ($FORM{COMPANY_ID}) {
     use Customers;	
     my $customers = Customers->new($db);
     my $company = $customers->company->info($FORM{COMPANY_ID});
 	   $user_info->{COMPANY_ID}=$FORM{COMPANY_ID};
     $user_info->{EXDATA} =  "<tr><td>$_COMPANY:</td><td>". $html->button($company->{COMPANY_NAME}, "index=13&COMPANY_ID=$company->{COMPANY_ID}"). "</td></tr>\n";
    }
   
   $user_info->{GID} = sel_groups();
   if ($admin->{GID}) {
   	 $user_info->{GID} .= "<input type='hidden' name='GID' value='$admin->{GID}'>";
    }
   $user_info->{EXDATA} .=  $html->tpl_show(templates('form_user_exdata'), undef, { notprint => 'y' });

   $user_info->{DISABLE} = ($user_info->{DISABLE} > 0) ? ' checked' : '';
   $user_info->{ACTION}='add';
   $user_info->{LNG_ACTION}=$_ADD;
  }
 else {
   $user_info->{EXDATA} = "
            <tr><td colspan='2'><input type='hidden' name='UID' value=\"$FORM{UID}\"/></td></tr>
            <tr><td>$_DEPOSIT:</td><td>$user_info->{DEPOSIT}</td></tr>
            <tr><td>$_COMPANY:</td><td>". $html->button($user_info->{COMPANY_NAME}, "index=13&COMPANY_ID=$user_info->{COMPANY_ID}") ."</td></tr>
            <tr><td>BILL_ID:</td><td>%BILL_ID%</td></tr>\n";

   $user_info->{DISABLE} = ($user_info->{DISABLE} > 0) ? ' checked' : '';
   $user_info->{ACTION}='change';
   $user_info->{LNG_ACTION}=$_CHANGE;
  } 

$html->tpl_show(templates('form_user'), $user_info);

}


#**********************************************************
# form_groups()
#**********************************************************
sub form_groups {

if ($FORM{add}) {
  $users->group_add( { %FORM });
  if (! $users->{errno}) {
    $html->message('info', $_ADDED, "$_ADDED [$users->{GID}]");
   }
}
elsif($FORM{change}){
  $users->group_change($FORM{chg}, { %FORM });
  if (! $users->{errno}) {
    $html->message('info', $_CHANGED, "$_CHANGED $users->{GID}");
   }
}
elsif(defined($FORM{GID})){
  $users->group_info( $FORM{GID} );

  $LIST_PARAMS{GID}=$users->{GID};
  $pages_qs="&GID=$users->{GID}&subf=$FORM{subf}";

  func_menu({ 
  	         'ID'   => $users->{GID}, 
  	         $_NAME =>$users->{G_NAME}
  	       }, 
  	{ 
     $_CHANGE   => ":GID=$users->{GID}",
     $_USERS    => "11:GID=$users->{GID}",
     $_PAYMENTS => "2:GID=$users->{GID}",
     $_FEES     => "3:GID=$users->{GID}",
  	 });
 

  #Sub functions
  if (! $FORM{subf}) {
#    if (! $users->{errno}) {
#      $html->message('info', $_CHANGED, "$_CHANGING $users->{GID}");
#     }
    $users->{ACTION}='change';
    $users->{LNG_ACTION}=$_CHANGE;
    $html->tpl_show(templates('form_groups'), $users);
  }
 
  return 0;
}
elsif(defined($FORM{del}) && defined($FORM{is_js_confirmed}) && $permissions{0}{5}){
  $users->group_del( $FORM{del} );
  if (! $users->{errno}) {
    $html->message('info', $_DELETED, "$_DELETED $users->{GID}");
   }
}


if ($users->{errno}) {
   $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
  }

my $list = $users->groups_list({ %LIST_PARAMS });
my $table = $html->table( { width      => '100%',
                            caption    => "$_GROUPS",
                            border     => 1,
                            title      => [$_ID, $_NAME, $_DESCRIBE, $_USERS, '-', '-'],
                            cols_align => ['right', 'left', 'left', 'right', 'center', 'center'],
                            qs         => $pages_qs,
                            pages      => $users->{TOTAL}
                                  } );

foreach my $line (@$list) {
  my $delete = (defined($permissions{0}{5})) ?  $html->button($_DEL, "index=27$pages_qs&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]]?" }) : ''; 

  $table->addrow("<b>$line->[0]</b>", "$line->[1]", "$line->[2]", 
   $html->button($line->[3], "index=27&GID=$line->[0]&subf=15"), 
   $html->button($_INFO, "index=27&GID=$line->[0]"),
   $delete);
}
print $table->show();


$table = $html->table({ width      => '100%',
                        cols_align => ['right', 'right'],
                        rows       => [ [ "$_TOTAL:", "<b>$users->{TOTAL}</b>" ] ]
                      });
print $table->show();
}



#**********************************************************
# add_groups()
#**********************************************************
sub add_groups {
  my $users;
  $users->{ACTION}='add';
  $users->{LNG_ACTION}=$_ADD;
  $html->tpl_show(templates('form_groups'), $users); 
}

#**********************************************************
# user_info
#**********************************************************
sub user_info {
  my ($UID)=@_;
	my $user_info = $users->info( $UID );
  
  
  $table = $html->table({ width      => '100%',
  	                      rowcolor   => $_COLORS[2],
  	                      border     => 0,
                          cols_align => ['left'],
                          rows       => [ [ "$_USER: ". $html->button("<b>$user_info->{LOGIN}</b>", "index=15&UID=$user_info->{UID}") ] ]
                        });
  print $table->show();
 
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
    $html->message('info', $_ADDED, "$_ADDED");	
   }
  }
 elsif($FORM{change}) {
 	 my $user_pi = $user->pi_change({ %FORM });
   if (! $user_pi->{errno}) {
    $html->message('info', $_CHAGED, "$_CHANGED");	
   }
 }

  if ($user_pi->{errno}) {
    $html->message('err', $_ERROR, "[$user_pi->{errno}] $err_strs{$user_pi->{errno}}");	
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
  
  $index=30;
  $html->tpl_show(templates('form_pi'), $user_pi);
}

#**********************************************************
# form_users()
#**********************************************************
sub form_users {
  my ($attr)=@_;

if(defined($attr->{USER})) {

  my $user_info = $attr->{USER};
  if ($users->{errno}) {
    $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
    return 0;
   }

  print "<table width=\"100%\" border=\"0\" cellspacing=\"1\" cellpadding=\"2\"><tr><td valign=\"top\" align=\"center\">\n";
  
  
  form_passwd({ USER => $user_info}) if (defined($FORM{newpassword}));

  if ($FORM{change}) {
    $user_info->change($user_info->{UID}, { %FORM } );
    if ($user_info->{errno}) {
      $html->message('err', $_ERROR, "[$user_info->{errno}] $err_strs{$user_info->{errno}}");	
      user_form();    
      print "</td></table>\n";
      return 0;	
     }
    else {
      $html->message('info', $_CHANGED, "$_CHANGED $users->{info}");
      
      #External scripts 
      if ($conf{external_userchange}) {
        if (! _external($conf{external_userchange}, { %FORM }) ) {
     	    return 0;
         }
       }
     }
   }
  elsif ($FORM{del_user} && $FORM{is_js_confirmed} && $index == 15 && $permissions{0}{5} ) {
    $user_info->del();
    if ($user_info->{errno}) {
      $html->message('err', $_ERROR, "[$user_info->{errno}] $err_strs{$user_info->{errno}}");	
     }
    else {
      $html->message('info', $_DELETE, "$_DELETED <br>from tables<br>$users->{info}");
     }
    
    $conf{DELETE_USER}=$user_info->{UID};
    foreach my $mod (@MODULES) {
    	print $mod . "<br>\n";
    	require "Abills/modules/$mod/webinterface";
     }
    

    print "</td></tr></table>\n";
    return 0;
   }
  else {

    @action = ('change', $_CHANGE);
    user_form($user_info);
    
    user_pi({ USER => $user_info });

   }




my $payments = (defined($permissions{1})) ? '<li/>'. $html->button($_PAYMENTS, "UID=$user_info->{UID}&index=2") : '';
my $fees = (defined($permissions{2})) ? '<li/>' .$html->button($_FEES, "UID=$user_info->{UID}&index=3") : '';

print "
</td><td bgcolor='$_COLORS[3]' valign='top' width='180'>
<table width='100%' border='0'><tr><td><ul>
      $payments
      $fees
      <li/>". $html->button($_SEND_MAIL, "UID=$user_info->{UID}&index=31").
"</ul>\n</td></tr>
<tr><td> 
  <ul>\n";


#Show services

while(my($k, $v)=each %menu_items) {
	if (defined($menu_items{$k}{20})) {
		print '<li/>'. $html->button($menu_items{$k}{20}, "UID=$user_info->{UID}&index=$k");
	 }
}

#

print  "</ul><ul>\n";
my %userform_menus = (
             22 =>  $_LOG,
             17 =>  $_PASSWD,
             21 =>  $_COMPANY,
             12 =>  $_GROUP,
             18 =>  $_NAS,
             20 =>  $_SERVICES,
             19	=>  $_BILL
             );

while(my($k, $v)=each %uf_menus) {
	$userform_menus{$k}=$v;
}

while(my($k, $v)=each (%userform_menus) ) {
  my $url =  "index=$k&UID=$user_info->{UID}";
  my $a = (defined($FORM{$k})) ? "<b>$v</b>" : $v;
  print "<li/>" . $html->button($a,  "$url");
}

print "<li/>". $html->button($_DEL, "index=15&del_user=y&UID=$user_info->{UID}", { MESSAGE => "$_USER: $user_info->{LOGIN} / $user_info->{UID}" }) if (defined($permissions{0}{5}));

print "</ul></td></tr>
</table>
</td></tr></table>\n";
  return 0;
}
elsif ($FORM{add}) {
  my $user_info = $users->add({ %FORM });  
  
  if ($users->{errno}) {
    $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
    user_form();    
    return 0;	
   }
  else {
    $html->message('info', $_ADDED, "$_ADDED '$user_info->{LOGIN}' / [$user_info->{UID}]");

    if ($conf{external_useradd}) {
       if (! _external($conf{external_useradd}, { %FORM }) ) {
       	  return 0;
        }
     }

    $user_info = $users->info( $user_info->{UID} );
    $html->tpl_show(templates('user_info'), $user_info);

    $LIST_PARAMS{UID}=$user_info->{UID};
    $index=2;
    form_payments({ USER => $user_info });
    return 0;
   }
}
#Multi user operations
elsif ($FORM{MULTIUSER}) {
  my @multiuser_arr = split(/, /, $FORM{IDS});
  my $count = 0;
	my %CHANGE_PARAMS = ();
 	while(my($k, $v)=each %FORM) {
 		if ($k =~ /^MU_(\S+)/) {
      $CHANGE_PARAMS{$1}=$FORM{$1};
	   }
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
  	    my $user_info = $users->info( $uid );
  	    $user_info->del();

        if ($users->{errno}) {
          $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
         }
  		 }
  		else {
  			$users->change($uid, { UID => $uid, %CHANGE_PARAMS } );
  			if ($users->{errno}) {
  			  $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
  			  return 0;
  			 }
  		 }
  	 }
    $html->message('info', $_MULTIUSER_OP, "$_TOTAL: $#multiuser_arr IDS: $FORM{IDS}");
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

 print $html->letters_list({ pages_qs => $pages_qs  }); 

 if ($FORM{letter}) {
   $LIST_PARAMS{FIRST_LETTER} = $FORM{letter};
   $pages_qs .= "&letter=$FORM{letter}";
  } 

my $list = $users->list( { %LIST_PARAMS } );

my @TITLE = ($_LOGIN, $_FIO, $_DEPOSIT, $_CREDIT, $_STATUS, '-', '-');
for(my $i=0; $i<$users->{SEARCH_FIELDS_COUNT}; $i++){
	push @TITLE, '-';
	$TITLE[5+$i] = "$_SEARCH";
}

if ($users->{errno}) {
  $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
  return 0;
 }
elsif ($users->{TOTAL} == 1) {
	$FORM{index} = 15;
	$FORM{UID}=$list->[0]->[5+$users->{SEARCH_FIELDS_COUNT}];
	form_users({  USER => user_info($list->[0]->[5+$users->{SEARCH_FIELDS_COUNT}]) });
	return 0;
}

#User list
my $table = $html->table( { width      => '100%',
                            title      => \@TITLE,
                            cols_align => ['left', 'left', 'right', 'right', 'center', 'center:noprint', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $users->{TOTAL}
                          });

foreach my $line (@$list) {
  my $payments = ($permissions{1}) ? $html->button($_PAYMENTS, "index=2&UID=$line->[5+$users->{SEARCH_FIELDS_COUNT}]") : ''; 
  my $fees     = ($permissions{2}) ? $html->button($_FEES, "index=3&UID=$line->[5+$users->{SEARCH_FIELDS_COUNT}]") : '';

  my @fields_array  = ();
  for(my $i=0; $i<$users->{SEARCH_FIELDS_COUNT}; $i++){
     push @fields_array, $table->td($line->[5+$i]);
   }



my $multiuser = ($permissions{0}{7}) ? $html->form_input('IDS', "$line->[5+$users->{SEARCH_FIELDS_COUNT}]", { TYPE => 'checkbox', }) : '';

$table->addtd(
                  $table->td(
                  $multiuser.$html->button($line->[0], "index=15&UID=$line->[5+$users->{SEARCH_FIELDS_COUNT}]") ), 
                  $table->td($line->[1]), 
                  $table->td( ($line->[2] + $line->[3] < 0) ? "<font color='$_COLORS[6]'>$line->[2]</font>" : $line->[2] ), 
                  $table->td($line->[3]), 
                  $table->td($status[$line->[4]], { bgcolor => $state_colors[$line->[4]] }), 
                  @fields_array, 
                  $table->td($payments),
                  $table->td($fees)
         );

}


my $table2 = $html->table( { width      => '100%',
                             cols_align => ['right', 'right'],
                             rows       => [ [ "$_TOTAL:", "<b>$users->{TOTAL}</b>" ] ]
                          });


if ($permissions{0}{7}) {
  my $table3 = $html->table( { width      => '100%',
  	                       caption    => "$_MULTIUSER_OP",
                           cols_align => ['left', 'left'],
                           rows       => [ [ $html->form_input('MU_GID', "1", { TYPE => 'checkbox', }). $_GROUP,    sel_groups()],
                                           [ $html->form_input('MU_DISABLE', "1", { TYPE => 'checkbox', }). $_DISABLE,  $html->form_input('DISABLE', "1", { TYPE => 'checkbox', }) ],
                                           [ $html->form_input('MU_DEL', "1", { TYPE => 'checkbox', }). $_DEL,      $html->form_input('DEL', "1", { TYPE => 'checkbox', }) ],
                                           [ $html->form_input('MU_ACTIVATE', "1", { TYPE => 'checkbox', }). $_ACTIVATE, $html->form_input('ACTIVATE', "0000-00-00") ], 
                                           [ $html->form_input('MU_EXPIRE', "1", { TYPE => 'checkbox', }). $_EXPIRE,   $html->form_input('EXPIRE', "0000-00-00")   ], 
                                           [ '',         $html->form_input('MULTIUSER', "$_CHANGE", { TYPE => 'submit'})   ], 
                                         
                                         ]
                       });

   print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }).
   	                                   $table2->show({ OUTPUT2RETURN => 1 }).
   	                                   $table3->show({ OUTPUT2RETURN => 1 }),
	                          HIDDEN  => { index => 11,
	                       	          },
                       });



}
else {
  print $table->show() . $table2->show();	
}


}

#**********************************************************
# user_group
#**********************************************************
sub user_group {
  my ($attr) = @_;
  my $user = $attr->{USER};
  $user->{SEL_GROUPS} = sel_groups();
  $html->tpl_show(templates('chg_group'), $user);
}

#**********************************************************
# user_company
#**********************************************************
sub user_company {
 my ($attr) = @_;
 my $user_info = $attr->{USER};
 use Customers;
 my $customer = Customers->new($db);

 $user_info->{SEL_COMPANIES} = $html->form_select('COMPANY_ID', 
                                { 
 	                                SELECTED          => $FORM{COMPANY_ID},
 	                                SEL_MULTI_ARRAY   => $customer->company->list({ PAGE_ROWS => 2000 }),
 	                                MULTI_ARRAY_KEY   => 5,
 	                                MULTI_ARRAY_VALUE => 0,
 	                                SEL_OPTIONS       => { 0 => '-N/S-'}
 	                               });

$html->tpl_show(templates('chg_company'), $user_info);
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
<FORM action="$SELF_URL">
<input type="hidden" name="UID" value="$user->{UID}"/>
<input type="hidden" name="index" value="$index"/>
<table>
<tr><td>$_SERVICES:</td><td>$variant_out</td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=S_DESCRIBE value="%S_DESCRIBE%"/></td></tr>
</table>
<input type=submit name=%ACTION% value='%LNG_ACTION%'/>
</form>
[END]


my $table = $html->table( { width => '100%',
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
 my %EX_HIDDEN_PARAMS = (subf  => "$FORM{subf}",
	                       index => "$index");

if ($attr->{USER}) {
  my $user = $attr->{USER};
  if ($FORM{change}) {
    $user->nas_add(\@allow);
    if (! $user->{errno}) {
      $html->message('info', $_INFO, "$_ALLOW $_NAS: $FORM{ids}");
     }
   }
  elsif($FORM{default}) {
    $user->nas_del();
    if (! $user->{errno}) {
      $html->message('info', $_NAS, "$_CHANGED");
     }
   }

  if ($user->{errno}) {
    $html->message('err', $_ERROR, "[$user->{errno}] $err_strs{$user->{errno}}");	
   }

  my $list = $user->nas_list();
  foreach my $line (@$list) {
     $allow_nas{$line->[0]}='test';
   }
  
  $EX_HIDDEN_PARAMS{UID}=$user->{UID};
 }
elsif($attr->{TP}) {
  my $tarif_plan = $attr->{TP};

  if ($FORM{change}){
    $tarif_plan->nas_add(\@allow);
    if ($tarif_plan->{errno}) {
      $html->message('err', $_ERROR, "[$tarif_plan->{errno}] $err_strs{$tarif_plan->{errno}}");	
     }
    else {
      $html->message('info', $_INFO, "$_ALLOW $_NAS: $FORM{ids}");
     }
   }
  
  my $list = $tarif_plan->nas_list();
  foreach my $nas_id (@$list) {
     $allow_nas{$nas_id->[0]}='y';
   }

  $EX_HIDDEN_PARAMS{TP_ID}=$tarif_plan->{TP_ID};
}
elsif (defined($FORM{TP_ID})) {
  $FORM{chg}=$FORM{TP_ID};
  $FORM{subf}=$index;
  dv_tp();
  return 0;
 }

my $nas = Nas->new($db, \%conf);


my $table = $html->table( { width     => '100%',
                           border     => 1,
                           title      => ["$_ALLOW", "$_NAME", 'NAS-Identifier', "IP", "$_TYPE", "$_AUTH"],
                           cols_align => ['center', 'left', 'left', 'right', 'left', 'left'],
                           qs         => $pages_qs
                           });

my $list = $nas->list();

foreach my $line (@$list) {
  my $checked = (defined($allow_nas{$line->[0]}) || $allow_nas{all}) ? ' checked ' :  '';    
  $table->addrow("<input type=checkbox name=ids value=$line->[0] $checked>", 
    $line->[1], 
    $line->[2],  
    $line->[3],  
    $line->[4], $auth_types[$line->[5]]);
}

print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
	                       HIDDEN  => { %EX_HIDDEN_PARAMS },
	                       SUBMIT  => { change   => "$_CHANGE",
	                       	            default  => $_DEFAULT 
	                       	           } });

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

  $user->{SEL_BILLS} =  "<select name='BILL_ID'>\n";
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
  $html->tpl_show(templates('chg_bill'), $user);
}


#**********************************************************
# form_changes();
#**********************************************************
sub form_changes {
 my ($attr) = @_; 
 my %search_params = ();
 
if ($FORM{del} && $FORM{is_js_confirmed}) {
	$admin->action_del( $FORM{del} );
  if ($admins->{errno}) {
    $html->message('err', $_ERROR, "[$admins->{errno}] $err_strs{$admins->{errno}}");	
   }
  else {
    $html->message('info', $_DELETED, "$_DELETED [$FORM{del}]");
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


%search_params=%FORM;
$search_params{MODULES_SEL} = $html->form_select('MODULE', 
                                { SELECTED      => $FORM{MODULE},
 	                                SEL_ARRAY     => ['', @MODULES],
 	                                OUTPUT2RETURN => 1
 	                               });


form_search({ HIDDEN_FIELDS => $LIST_PARAMS{AID},
	            SEARCH_FORM   => $html->tpl_show(templates('history_search'), \%search_params, { notprint => 'y' })
	           });


my $list = $admin->action_list({ %LIST_PARAMS });
my $table = $html->table( { width      => '100%',
                            border     => 1,
                            title      => ['#', 'UID',  $_DATE,  $_CHANGE,  $_ADMIN,   'IP', "$_MODULES", '-'],
                            cols_align => ['right', 'left', 'right', 'left', 'left', 'right', 'left', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $admin->{TOTAL}
                           });



foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=$index$pages_qs&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]] ?" }); 

  $table->addrow("<b>$line->[0]</b>",
    $html->button($line->[1], "index=15&UID=$line->[7]"), 
    $line->[2], 
    $line->[3], 
    $line->[4], 
    $line->[5], 
    $line->[6], 
    $delete);
}



print $table->show();
$table = $html->table( { width      => '100%',
                         cols_align => ['right', 'right'],
                         rows       => [ [ "$_TOTAL:", "<b>$admin->{TOTAL}</b>" ] ]
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
  my $max_traffic_class_id = 0; #Max taffic class id

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
      $html->message('info', $_INFO, "$_INTERVALS $_ADDED");
     }
   }
  elsif($FORM{change}) {
    $tarif_plan->ti_change( $FORM{TI_ID}, { %FORM } );

    if (! $tarif_plan->{errno}) {
      $html->message('info', $_INFO, "$_INTERVALS $_CHANGED [$tarif_plan->{TI_ID}]");
     }
   }
  elsif(defined($FORM{chg})) {
  	$tarif_plan->ti_info( $FORM{chg} );
    if (! $tarif_plan->{errno}) {
      $html->message('info', $_INFO, "$_INTERVALS $_CHANGE [$FORM{chg}]");
     }

 	 	$tarif_plan->{ACTION}='change';
 	 	$tarif_plan->{LNG_ACTION}=$_CHANGE;
   }
  elsif($FORM{del} && $FORM{is_js_confirmed}) {
    $tarif_plan->ti_del($FORM{del});
    if (! $tarif_plan->{errno}) {
      $html->message('info', $_DELETED, "$_DELETED $FORM{del}");
     }
   }
  else {
 	 	$tarif_plan->ti_defaults();
   }

  my $list = $tarif_plan->ti_list({ %LIST_PARAMS });
  my $table = $html->table( { width      => '100%',
                              caption    => "$_INTERVALS",
                              border     => 1,
                              title      => ['#', $_DAYS, $_BEGIN, $_END, $_HOUR_TARIF, $_TRAFFIC, '-', '-',  '-'],
                              cols_align => ['left', 'left', 'right', 'right', 'right', 'center', 'center', 'center', 'center', 'center'],
                              qs         => $pages_qs,
                           } );

  my $color="AAA000";
  foreach my $line (@$list) {

    my $delete = $html->button($_DEL, "index=$index$pages_qs&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]] ?" }); 
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
                  $table->td($html->button($_TRAFFIC, "index=$index$pages_qs&tt=$line->[0]")),
                  $table->td($html->button($_CHANGE, "index=$index$pages_qs&chg=$line->[0]")),
                  $table->td($delete),
                  $table->td("&nbsp;", { bgcolor => '#'.$color, rowspan => ($line->[5] > 0) ? 2 : 1 })
      );

     if($line->[5] > 0) {
     	 my $TI_ID = $line->[0];
     	 #Traffic tariff IN (1 Mb) Traffic tariff OUT (1 Mb) Prepaid (Mb) Speed (Kbits) Describe NETS 

       my $table2 = $html->table( { width      => '100%',
                                   title_plain => ["#", "$_TRAFFIC_TARIFF In ", "$_TRAFFIC_TARIFF Out ", "$_PREPAID", "$_SPEED IN",  "$_SPEED OUT", "DESCRIBE", "NETS", "-", "-"],
                                   cols_align  => ['center', 'right', 'right', 'right', 'right', 'right', 'left', 'right', 'center', 'center', 'center'],
                                   caption     => "$_BYTE_TARIF"
                                  } );

       my $list_tt = $tarif_plan->tt_list({ TI_ID => $line->[0] });
       foreach my $line (@$list_tt) {
          $max_traffic_class_id=$line->[0] if ($line->[0] > $max_traffic_class_id);
          $table2->addrow($line->[0], 
           $line->[1], 
           $line->[2], 
           $line->[3], 
           $line->[4], 
           $line->[5], 
           $line->[6], 
           convert($line->[7], { text2html => 'yes'  }),
           $html->button($_CHANGE, "index=$index$pages_qs&tt=$TI_ID&chg=$line->[0]"),
           $html->button($_DEL, "index=$index$pages_qs&tt=$TI_ID&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]]?" } ));
        }

       my $table_traf = $table2->show();
  
       $table->addtd($table->td("$table_traf", { bgcolor => $_COLORS[2], colspan => 7}));
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
   $html->message('err', $_ERROR, "[$tarif_plan->{errno}] $err_strs{$tarif_plan->{errno}} $tarif_plan->{errstr}");	
 }


#visualization
#                               title_plain => ["#", "$_TRAFFIC_TARIFF In ", "$_TRAFFIC_TARIFF Out ", "$_PREPAID", "$_SPEED", "DESCRIBE", "NETS"],
#                               cols_align => ['center', 'right', 'right', 'right', 'right', 'right', 'right', 'center', 'center'],


$table = $html->table({ width       => '100%',
	                      title_plain => [$_DAYS, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,14,15,16,17,18, 19, 20, 21, 22, 23],
                        caption     => "$_INTERVALS",
                        rowcolor    => $_COLORS[1]
                        });



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
  	   	   $tdcolor = '#'.$color;
  	 	     $link = $html->button('#', "index=$index&TP_ID=$FORM{TP_ID}&subf=$FORM{subf}&chg=$p");
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


  my %TT_IDS = (0 => "Global",
                1 => "Extended 1",
                2 => "Extended 2" );

  if ($max_traffic_class_id >= 2) {
  	for (my $i=3; $i<$max_traffic_class_id+2; $i++) { 
  	  $TT_IDS{$i}="Extended $i";
  	 }
  }

  $tarif_plan->{SEL_TT_ID} = $html->form_select('TT_ID', 
                                { SELECTED    => $tarif_plan->{TT_ID},
 	                                SEL_HASH   => \%TT_IDS,
 	                               });
  
  if ($conf{DV_EXPPP_NETFILES}) {
     $tarif_plan->{DV_EXPPP_NETFILES}="EXPPP_NETFILES: ". $html->form_input('DV_EXPPP_NETFILES', 'yes', 
                                                       { TYPE          => 'checkbox',
       	                                                 OUTPUT2RETURN => 1,
       	                                                 STATE         => 1
       	                                                }  
       	                                               );
   }
  
  $html->tpl_show(_include('dv_tt', 'Dv'), $tarif_plan);
}
else {

  my $day_id = $FORM{day} || $tarif_plan->{TI_DAY};

  $tarif_plan->{SEL_DAYS} = $html->form_select('TI_DAY', 
                                { SELECTED   => $day_id,
 	                                SEL_ARRAY  => \@DAY_NAMES,
 	                                ARRAY_NUM_ID  => 'y'
 	                               });
  $html->tpl_show(templates('ti'), $tarif_plan);
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
    $html->message('info', $_INFO, "$_ADDED");	
   }
}
elsif($FORM{del}){
  $holidays->holidays_del($FORM{del});

  if (! $holidays->{errno}) {
    $html->message('info', $_INFO, "$_DELETED");	
  }
}

if ($holidays->{errno}) {
    $html->message('err', $_ERROR, "[$holidays->{errno}] $err_strs{$holidays->{errno}}");	
 }


my $list = $holidays->holidays_list( { %LIST_PARAMS });
my $table = $html->table( { caption    => "$_HOLIDAYS",
	                          width      => '640',
                            title      => [$_DAY,  $_DESCRIBE, '-'],
                            cols_align => ['left', 'left', 'center'],
                          } );
my ($delete); 
foreach my $line (@$list) {
	my ($m, $d)=split(/-/, $line->[0]);
	$m--;
  $delete = $html->button($_DEL, "index=75&del=$line->[0]", { MESSAGE => "$_DEL ?" }); 
  $table->addrow("$d $MONTHES[$m]", $line->[1], $delete);
  #$hollidays{$m}{$d}='y';
}

print $table->show();

$table = $html->table( { width      => '640',
                         cols_align => ['right', 'right'],
                         rows       => [ [ "$_TOTAL:", "<b>$holidays->{TOTAL}</b>" ] ]
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

print "<br><TABLE width=\"400\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\">
<tr><TD bgcolor=\"$_COLORS[4]\">
<TABLE width=\"100%\" cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=\"$_COLORS[0]\"><th>". $html->button(' << ', "index=75&month=$p_month&year=$p_year"). "</th><th colspan=5>$MONTHES[$month] $yeayeayeayear</th><th>". $html->button(' >> ', "index=75&month=$n_month&year=$n_year") ."</th></tr>
<tr bgcolor=\"$_COLORS[0]\"><th>$WEEKDAYS[1]</th><th>$WEEKDAYS[2]</th><th>$WEEKDAYS[3]</th>
<th>$WEEKDAYS[4]</th><th>$WEEKDAYS[5]</th>
<th><font color=\"#FF0000\">$WEEKDAYS[6]</font></th><th><font color=#FF0000>$WEEKDAYS[7]</font></th></tr>\n";



my $day = 1;
my $month_days = 31;
while($day < $month_days) {
  print "<tr bgcolor=\"$_COLORS[1]\">";
  for($wday=0; $wday < 7 and $day <= $month_days; $wday++) {
     if ($day == 1 && $gwday != $wday) { 
       print "<td>&nbsp;</td>";
       if ($wday == 7) {
       	 print "$day == 1 && $gwday != $wday";
       	 return 0;
       	}
      }
     else {
       my $bg = '';
       if ($wday > 4) {
       	  $bg = "bgcolor=\"$_COLORS[2]\"";
       	}

       if (defined($holiday{$month}{$day})) {
         print "<th bgcolor=\"$_COLORS[0]\">$day</th>";
        }
       else {
         print "<td align=right $bg>". $html->button($day, "index=75&add=$month-$day"). '</td>';
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
#        $html->message('info', $_INFO, "$_ADMINS: $admin_form->{NAME}<br>$_PASSWD $_CHANGED");
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
      $html->message('info', $_CHANGED, "$_CHANGED ");	
     }
   }
  $admin_form->{ACTION}='change';
  $admin_form->{LNG_ACTION}=$_CHANGE;
 }
elsif ($FORM{add}) {
  $admin_form->add({ %FORM });
  if (! $admin_form->{errno}) {
     $html->message('info', $_INFO, "$_ADDED");	
   }
}
elsif($FORM{del}) {
  $admin_form->del($FORM{del});
  if (! $admin_form->{errno}) {
     $html->message('info', $_DELETE, "$_DELETED");	
   }
}


if ($admin_form->{errno}) {
     $html->message('err', $_ERROR, $err_strs{$admin_form->{errno}});	
 }


$admin_form->{DISABLE} = ($admin_form->{DISABLE} > 0) ? 'checked' : '';
$admin_form->{GROUP_SEL} = sel_groups();

$html->tpl_show(templates('form_admin'), $admin_form);

my $table = $html->table( { width      => '100%',
                            border     => 1,
                            title      => ['ID', $_NAME, $_FIO, $_CREATE, $_STATUS,  $_GROUPS, '-', '-', '-', '-', '-', '-'],
                            cols_align => ['right', 'left', 'left', 'right', 'left', 'center', 'center', 'center', 'center', 'center', 'center'],
                         } );

my $list = $admin_form->list();
foreach my $line (@$list) {
  $table->addrow($line->[0], 
    $line->[1], 
    $line->[2], 
    $line->[3], 
    $status[$line->[4]], 
    $line->[5], 
   $html->button($_PERMISSION, "index=$index&subf=52&AID=$line->[0]"),
   $html->button($_LOG, "index=$index&subf=51&AID=$line->[0]"),
   $html->button($_PASSWD, "index=$index&subf=54&AID=$line->[0]"),
   $html->button($_INFO, "index=$index&AID=$line->[0]"), 
   $html->button($_DEL, "index=$index&del=$line->[0]", { MESSAGE => "$_DEL ?"} ));
}
print $table->show();

$table = $html->table( { width      => '100%',
                         cols_align => ['right', 'right'],
                         rows       => [ [ "$_TOTAL:", "<b>$admin_form->{TOTAL}</b>" ] ]
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
       
       $permits{$section_index}{$action_index}='y' if ($section_index >= 0);
      }
    }
   $admin->set_permissions(\%permits);

   if ($admin->{errno}) {
     $html->message('err', $_ERROR, "$err_strs{$admin->{errno}}");
    }
   else {
     $html->message('info', $_INFO, "$_CHANGED");
    }
  }

 my $p = $admin->get_permissions();
 if ($admin->{errno}) {
    $html->message('err', $_ERROR, "$err_strs{$admin->{errno}}");
    return 0;
  }

 %permits = %$p;
 

my $table = $html->table( { width       => '400',
                            border      => 1,
                            title_plain => ['ID', $_NAME, ''],
                            cols_align  => ['right', 'left', 'center'],
                        } );


while(my($k, $v) = each %menu_items ) {
  if (defined($menu_items{$k}{0}) && $k > 0) {
  	$table->{rowcolor}=$_COLORS[0];
  	$table->addrow("$k:", "<b>$menu_items{$k}{0}</b>", '');
    $k--;
    my $actions_list = $actions[$k];
    my $action_index = 0;
    $table->{rowcolor}=undef;
    foreach my $action (@$actions_list) {

      $table->addrow("$action_index", "$action", 
       $html->form_input($k."_$action_index", 'yes', { TYPE          => 'checkbox',
       	                                               OUTPUT2RETURN => 1,
       	                                               STATE         => (defined($permits{$k}{$action_index})) ? '1' : undef  
       	                                              })  
       	                                              );

      $action_index++;
     }
   }
 }
  
  
print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
	                       HIDDEN  => { index => '50',
                                      AID   => "$FORM{AID}",
                                      subf  => "$FORM{subf}"
                                     },
	                       SUBMIT  => { set   => "$_SET"
	                       	           } });



}




#*******************************************************************
# 
# profile()
#*******************************************************************
sub admin_profile {
 #my ($admin) = @_;

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

print "$FORM{colors} ". $html->{language};


my $REFRESH=$admin->{WEB_OPTIONS}{REFRESH} || 60;
my $ROWS=$admin->{WEB_OPTIONS}{PAGE_ROWS} || $PAGE_ROWS;


my $SEL_LANGUAGE = $html->form_select('language', 
                                { 
 	                                SELECTED  => $html->{language},
 	                                SEL_HASH  => \%LANG 
 	                               });

print << "[END]";
<form action="$SELF_URL" METHOD="POST">
<input type="hidden" name="index" value="$index">
<input type="hidden" name="AWEB_OPTIONS" value="1">
<TABLE width="640" cellspacing="0" cellpadding="0" border="0"><tr><TD bgcolor="$_COLORS[4]">
<TABLE width="100%" cellspacing="1" cellpadding="0" border="0"><tr bgcolor="$_COLORS[1]"><td colspan="2">$_LANGUAGE:</td>
<td>$SEL_LANGUAGE</td></tr>
<tr bgcolor="$_COLORS[1]"><th colspan="3">&nbsp;</th></tr>
<tr bgcolor="$_COLORS[0]"><th colspan="2">$_PARAMS</th><th>$_VALUE</th></tr>

[END]


 for($i=0; $i<=10; $i++) {
   print "<tr bgcolor=\"$_COLORS[1]\"><td width=30% bgcolor=\"$_COLORS[$i]\">$i</td><td>$colors_descr[$i]</td><td><input type=text name=colors value='$_COLORS[$i]'></td></tr>\n";
  } 
 

print "
</table>
<br>
<table width=\"100%\">
<tr><td colspan=\"2\">&nbsp;</td></tr>
<tr><td>$_REFRESH (sec.):</td><td><input type='input' name='REFRESH' value='$REFRESH'></td></tr>
<tr><td>$_ROWS:</td><td><input type='input' name='PAGE_ROWS' value='$PAGE_ROWS'></td></tr>
</table>
</td></tr></table>
<br>
<input type='submit' name='set' value='$_SET'> 
<input type='submit' name='default' value='$_DEFAULT'>
</form><br>\n";
   
my %profiles = ();
$profiles{'Black'} = "#333333, #000000, #444444, #555555, #777777, #FFFFFF, #FF0000, #BBBBBB, #FFFFFF, #EEEEEE, #000000";
$profiles{'Green'} = "#33AA44, #FFFFFF, #eeeeee, #dddddd, #E1E1E1, #FFFFFF, #FF0000, #000088, #0000A0, #000000, #FFFFFF";
$profiles{'Ligth Green'} = "#4BD10C, #FFFFFF, #eeeeee, #dddddd, #E1E1E1, #FFFFFF, #FF0000, #000088, #0000A0, #000000, #FFFFFF";
$profiles{'��'} = "#FCBB43, #FFFFFF, #eeeeee, #dddddd, #E1E1E1, #FFFFFF, #FF0000, #000088, #0000A0, #000000, #FFFFFF";
$profiles{'Cisco'} = "#99CCCC, #FFFFFF, #FFFFFF, #669999, #669999, #FFFFFF, #FF0000, #003399, #003399, #000000, #FFFFFF";

while(my($thema, $colors)=each %profiles ) {
  my $url = "index=53&AWEB_OPTIONS=1&set=set";
  my @c = split(/, /, $colors);
  foreach my $line (@c) {
      $line =~ s/#/%23/ig;
      $url .= "&colors=$line";
    }
  print $html->button("$thema", $url) . ' ::';
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

if($FORM{NAS_ID}) {
  $nas->info( { NAS_ID => $FORM{NAS_ID}	} );
  $pages_qs .= "&NAS_ID=$FORM{NAS_ID}&subf=$FORM{subf}";
  $LIST_PARAMS{NAS_ID} = $FORM{NAS_ID};
  %F_ARGS = ( NAS => $nas );
  
  $nas->{NAME_SEL} = $html->form_main({ CONTENT => $html->form_select('NAS_ID', 
                                         { 
 	                                          SELECTED  => $FORM{NAS_ID},
 	                                          SEL_MULTI_ARRAY   => $nas->list({ %LIST_PARAMS }),
 	                                          MULTI_ARRAY_KEY   => 0,
 	                                          MULTI_ARRAY_VALUE => 1,
 	                                        }),
	                       HIDDEN  => { index => '60',
                                      AID   => "$FORM{AID}",
                                      subf  => "$FORM{subf}"
                                     },
	                       SUBMIT  => { show   => "$_SHOW"
	                       	           } });

  func_menu({ 
  	         'ID' =>   $nas->{NAS_ID}, 
  	         $_NAME => $nas->{NAME_SEL}
  	       }, 
  	{ 
  	 $_INFO          => ":NAS_ID=$nas->{NAS_ID}",
     'IP Pools'      => "61:NAS_ID=$nas->{NAS_ID}",
     $_STATS         => "62:NAS_ID=$nas->{NAS_ID}"
  	 },
  	{
  		f_args => { %F_ARGS }
  	 });

  if ($FORM{subf}) {
  	return 0;
   }
  elsif($FORM{change}) {
    $nas->change({ %FORM });  
    if (! $nas->{errno}) {
       $html->message('info', $_CHANGED, "$_CHANGED $nas->{NAS_ID}");
     }
   }

  $nas->{LNG_ACTION}=$_CHANGE;
  $nas->{ACTION}='change';
 }
elsif ($FORM{add}) {
  $nas->add({	%FORM	});

  if (! $nas->{errno}) {
    $html->message('info', $_INFO, "$_ADDED '$FORM{NAS_IP}'");
   }
 }
elsif ($FORM{del} && $FORM{is_js_confirmed}) {
  $nas->del($FORM{del});
  if (! $nas->{errno}) {
    $html->message('info', $_INFO, "$_DELETED [$FORM{del}]");
   }

}

if ($nas->{errno}) {
  $html->message('err', $_ERROR, "$err_strs{$nas->{errno}}");
 }

# my @nas_types = ('other', 'usr', 'pm25', 'ppp', 'exppp', 'radpppd', 'expppd', 'pppd', 'dslmax', 'mpd', 'gnugk');
 my %nas_descr = (
  'asterisk'  => "Asterisk",
  'usr'       => "USR Netserver 8/16",
  'pm25'      => 'LIVINGSTON portmaster 25',
  'ppp'       => 'FreeBSD ppp demon',
  'exppp'     => 'FreeBSD ppp demon with extended futures',
  'dslmax'    => 'ASCEND DSLMax',
  'expppd'    => 'pppd deamon with extended futures',
  'radpppd'   => 'pppd version 2.3 patch level 5.radius.cbcp',
  'mpd'       => 'MPD with kha0s patch',
  'ipcad'     => 'IP accounting daemon with Cisco-like ip accounting export',
  'lepppd'    => 'Linux PPPD IPv4 zone counters',
  'pppd'      => 'pppd + RADIUS plugin (Linux)',
  'gnugk'     => 'GNU GateKeeper',
  'cisco'     => 'Cisco (Experimental)',
  'patton'    => 'Patton RAS 29xx',
  'cisco_air' => 'Cisco Aironets',
  'bsr1000'   => 'CMTS Motorola BSR 1000',
  'mikrotik'  => 'Mikrotik (http://www.mikrotik.com)',
  'other'     => 'Other nas server'
 );


  if (defined($conf{nas_servers})) {
  	%nas_descr = ( %nas_descr,  %{$conf{nas_servers}} );
   }

  $nas->{SEL_TYPE} = $html->form_select('NAS_TYPE', 
                                { SELECTED   => $nas->{NAS_TYPE},
 	                                SEL_HASH   => \%nas_descr,
 	                                SORT_KEY   => 1 
 	                               });

  $nas->{SEL_AUTH_TYPE} .= $html->form_select('NAS_AUTH_TYPE', 
                                { SELECTED     => $nas->{NAS_AUTH_TYPE},
 	                                SEL_ARRAY    => \@auth_types,
                                  ARRAY_NUM_ID => 'y' 	                                
 	                               });

$nas->{NAS_DISABLE} = ($nas->{NAS_DISABLE} > 0) ? ' checked' : '';
$html->tpl_show(templates('form_nas'), $nas);

my $table = $html->table( { width      => '100%',
                            caption    => "$_NAS",
                            title      => ["ID", "$_NAME", "NAS-Identifier", "IP", "$_TYPE", "$_AUTH", "$_STATUS", '-', '-', '-'],
                            cols_align => ['center', 'left', 'left', 'right', 'left', 'left', 'center', 'center:noprint', 'center:noprint', 'center:noprint'],
                           });

my $list = $nas->list({ %LIST_PARAMS });
foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=60&del=$line->[0]", { MESSAGE => "$_DEL NAS \\'$line->[1]\\'?" }); 
  $table->addrow($line->[0], 
    $line->[1], 
    $line->[2], 
    $line->[3], $line->[4], $auth_types[$line->[5]], 
    $status[$line->[6]],
    $html->button("IP POOLs", "index=61&NAS_ID=$line->[0]"),
    $html->button("$_CHANGE", "index=60&NAS_ID=$line->[0]"),
    $delete);
}
print $table->show();

$table = $html->table( { width      => '100%',
                         cols_align => ['right', 'right'],
                         rows       => [ [ "$_TOTAL:", "<b>$nas->{TOTAL}</b>" ] ]
                     } );
print $table->show();
}

#**********************************************************
# form_ip_pools()
#**********************************************************
sub form_ip_pools {
	my ($attr) = @_;
	my $nas;
  
if ($attr->{NAS}) {
	$nas = $attr->{NAS};
  if ($FORM{add}) {
    $nas->ip_pools_add({
       NAS_IP_SIP   => $FORM{NAS_IP_SIP},
       NAS_IP_COUNT => $FORM{NAS_IP_COUNT}
     });

    if (! $nas->{errno}) {
       $html->message('info', $_INFO, "$_ADDED");
     }
   }
  elsif($FORM{del} && $FORM{is_js_confirmed} ) {
    $nas->ip_pools_del( $FORM{del} );

    if (! $nas->{errno}) {
       $html->message('info', $_INFO, "$_DELETED");
     }
   }
  $pages_qs = "&NAS_ID=$nas->{NAS_ID}";

  $html->tpl_show(templates('form_ip_pools'), $nas);
 }
elsif($FORM{NAS_ID}) {
  $FORM{subf}=$index;
  form_nas();
  return 0;
 }
else {
  $nas = Nas->new($db, \%conf);	
}

if ($nas->{errno}) {
  $html->message('err', $_ERROR, "$err_strs{$nas->{errno}}");
 }



    
my $table = $html->table( { width      => '100%',
                            caption    => "IP POOLs",
                            border     => 1,
                            title      => ["NAS", "$_BEGIN", "$_END", "$_COUNT", '-'],
                            cols_align => ['left', 'right', 'right', 'right', 'center'],
                            qs         => $pages_qs              
                           });


my $list = $nas->ip_pools_list({ %LIST_PARAMS });	
foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=61$pages_qs&del=$line->[6]", { MESSAGE => "$_DEL NAS $line->[4]?" }); 
  $table->addrow($html->button($line->[0], "index=60&NAS_ID=$line->[7]"), 
    $line->[4], 
    $line->[5], 
    $line->[3],  
    $delete);
}
print $table->show();
}

#**********************************************************
# form_nas_stats()
#**********************************************************
sub form_nas_stats {
  my ($attr) = @_;
  my $nas;

if ($attr->{NAS}) {
	$nas = $attr->{NAS};

 }
elsif($FORM{NAS_ID}) {
  $FORM{subf}=$index;
  form_nas();
  return 0;
}
else {
	$nas = Nas->new($db, \%conf);	
}


my $table = $html->table( { width      => '100%',
                                   caption    => "$_STATS",
                                   border     => 1,
                                   title      => ["NAS", "NAS_PORT", "$_SESSIONS", "$_LAST_LOGIN", "$_AVG", "$_MIN", "$_MAX"],
                                   cols_align => ['left', 'right', 'right', 'right', 'right', 'right', 'right'],
                                  } );
my $list = $nas->stats({ %LIST_PARAMS });	

foreach my $line (@$list) {
  $table->addrow($html->button($line->[0], "index=60&NAS_ID=$line->[7]"), 
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
     	 $html->message('err', $_USER, "[$users->{errno}] $err_strs{$users->{errno}}");
     	 return 0;
      }
	   $UID = $list->[0]->[6];
	 }
  else {
	  $UID = $attr->{UID};
   }
}

my $user = $users->info($UID);

my $OP_SID = mk_unique_value(16);

 print $html->form_main({HIDDEN  => { index  => "$index",
                                      subf   => "$index",
                                      sum    => "$sum",
                                      OP_SID => "$OP_SID",
                                      UID    => "$UID",
                                      BILL_ID => $user->{BILL_ID}
                                     },
	                        SUBMIT  => { bm   => "$_BACK_MONEY ?"
	                       	           } });

}




#**********************************************************
# form_passwd($attr)
#**********************************************************
sub form_passwd {
 my ($attr)=@_;
 my $password_form;
 
 
 if (defined($FORM{AID})) {
   $password_form->{HIDDDEN_INPUT} = $html->form_input('AID', "$FORM{AID}", { TYPE => 'hidden',
       	                                OUTPUT2RETURN => 1
       	                               });
 	 $index=50;
 	}
 elsif (defined($attr->{USER})) {
	 $password_form->{HIDDDEN_INPUT} = $html->form_input('UID', "$FORM{UID}", { TYPE => 'hidden',
       	                               OUTPUT2RETURN => 1
       	                               });
	 $index=15;
 }


if ($FORM{newpassword} eq '') {

}
elsif (length($FORM{newpassword}) < $conf{passwd_length}) {
  $html->message('err', $_ERROR,  "$ERR_SHORT_PASSWD");
}
elsif ($FORM{newpassword} eq $FORM{confirm}) {
  $FORM{PASSWORD} = $FORM{newpassword};
}
elsif($FORM{newpassword} ne $FORM{confirm}) {
  $html->message('err', $_ERROR, $err_strs{5});
}

#$password_form->{GEN_PASSWORD}=mk_unique_value(8);
$password_form->{PW_CHARS}="abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ";
$password_form->{PW_LENGTH}=8;
$password_form->{ACTION}='change';
$password_form->{LNG_ACTION}="$_CHANGE";
$html->tpl_show(templates('form_password'), $password_form);

 return 0;
}


#**********************************************************
#
# FIELDS => FIELDS_HASH
#**********************************************************
sub reports {
 my ($attr) = @_;
 
my $EX_PARAMS; 
my ($y, $m, $d);
$type='DATE';

if ($FORM{MONTH}) {
  $LIST_PARAMS{MONTH}=$FORM{MONTH};
	$pages_qs="&MONTH=$LIST_PARAMS{MONTH}";
 }
elsif($FORM{allmonthes}) {
	$type='MONTH';
	$pages_qs="&allmonthes=y";
 }
else {
	($y, $m, $d)=split(/-/, $DATE, 3);
	$LIST_PARAMS{MONTH}="$y-$m";
	$pages_qs="&MONTH=$LIST_PARAMS{MONTH}";
}


if ($LIST_PARAMS{UID}) {
	 $pages_qs.="&UID=$LIST_PARAMS{UID}";
 }
else {
  if ($FORM{GID}) {
	  $LIST_PARAMS{GID}=$FORM{GID};
    $pages_qs="&GID=$FORM{GID}";
   }

  #$user->{GROUPS_SEL} = sel_groups();
  #$html->tpl_show(templates('groups_sel'), $user);
}

my @rows = ();

my $FIELDS='';

if ($attr->{FIELDS}) {
  my %fields_hash = (); 
  if (defined($FORM{FIELDS})) {
  	my @fileds_arr = split(/, /, $FORM{FIELDS});
   	foreach my $line (@fileds_arr) {
   		$fields_hash{$line}=1;
   	 }
   }

  $LIST_PARAMS{FIELDS}=$FORM{FIELDS};
  $pages_qs="&FIELDS=$FORM{FIELDS}";
  
  foreach my $line (sort keys %{ $attr->{FIELDS} }) {
  	my ($id, $k)=split(/:/, $line);
  	$FIELDS .= $html->form_input("FIELDS", $k, { TYPE => 'checkbox', STATE => (defined($fields_hash{$k})) ? 'checked' : undef }). " $attr->{FIELDS}{$line}";
   }
 }  


if ($attr->{PERIOD_FORM}) {
	$table = $html->table( { width    => '100%',
	                         rowcolor => $_COLORS[1],
                           rows     => [["$_FROM: ",   $html->date_fld('from', { MONTHES => \@MONTHES} ),
                                          "$_TO: ",    $html->date_fld('to', { MONTHES => \@MONTHES } ), 
                                          "$_GROUP:",  sel_groups(),
                                          "$_TYPE:",   $html->form_select('TYPE', 
                                                                 { SELECTED     => $FORM{TYPE},
 	                                                                 SEL_HASH     => { DAYS  => $_DAYS, 
 	                                                                                   USER  => $_USERS, 
 	                                                                                   HOURS => $_HOURS,
 	                                                                                   ($attr->{EXT_TYPE}) ? %{ $attr->{EXT_TYPE} } : ''
 	                                                                                   
 	                                                                                    },
 	                                                                 NO_ID        => 1
 	                                                                }) ,
 	                                        ($attr->{XML}) ? 
 	                                        $html->form_input('NO_MENU', 1, { TYPE => 'hidden' }).
 	                                        $html->form_input('xml', 1, { TYPE => 'checkbox' })."XML" : '',

                                          $html->form_input('show', $_SHOW, { TYPE => 'submit' }) ]
                                         ],                                   
                      });
 
  print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }).$FIELDS,
	                         HIDDEN  => { 
	                                    index => "$index"
	                                    }});

  if (defined($FORM{show})) {
    $pages_qs .= "&show=y&fromD=$FORM{fromD}&fromM=$FORM{fromM}&fromY=$FORM{fromY}&toD=$FORM{toD}&toM=$FORM{toM}&toY=$FORM{toY}";
    $FORM{fromM}++;
    $FORM{toM}++;
    $FORM{fromM} = sprintf("%.2d", $FORM{fromM}++);
    $FORM{toM} = sprintf("%.2d", $FORM{toM}++);

    $LIST_PARAMS{TYPE}=$FORM{TYPE};
    $LIST_PARAMS{INTERVAL} = "$FORM{fromY}-$FORM{fromM}-$FORM{fromD}/$FORM{toY}-$FORM{toM}-$FORM{toD}";
   }
	
}






if (defined($FORM{DATE})) {
  ($y, $m, $d)=split(/-/, $FORM{DATE}, 3);	

  $LIST_PARAMS{DATE}="$FORM{DATE}";
  $pages_qs .="&DATE=$LIST_PARAMS{DATE}";

  if (defined($attr->{EX_PARAMS})) {
   	my $EP = $attr->{EX_PARAMS};

	  while(my($k, $v)=each(%$EP)) {
     	if ($FORM{EX_PARAMS} eq $k) {
        $EX_PARAMS .= " <b>$v</b> ";
        $LIST_PARAMS{$k}=1;
        #$pages_qs .="&EX_PARAMS=$k";

     	  if ($k eq 'HOURS') {
    	  	 undef $attr->{SHOW_HOURS};
	       } 
     	 }
     	else {
     	  $EX_PARAMS .= '::'. $html->button($v, "index=$index$pages_qs&EX_PARAMS=$k");
     	 }
	  }
  
  }



  my $days = '';
  for ($i=1; $i<=31; $i++) {
     $days .= ($d == $i) ? " <b>$i </b>" : ' '.$html->button($i, sprintf("index=$index&DATE=%d-%02.f-%02.f&EX_PARAMS=$FORM{EX_PARAMS}%s%s", $y, $m, $i, 
       (defined($FORM{GID})) ? "&GID=$FORM{GID}" : '', 
       (defined($FORM{UID})) ? "&UID=$FORM{UID}" : '' ));
   }
  
  
  @rows = ([ "$_YEAR:",  $y ],
           [ "$_MONTH:", $MONTHES[$m-1] ], 
           [ "$_DAY:",   $days ]);
  
  if ($attr->{SHOW_HOURS}) {
    my(undef, $h)=split(/ /, $FORM{HOUR}, 2);
    my $hours = '';
    for (my $i=0; $i<24; $i++) {
    	$hours .= ($h == $i) ? " <b>$i </b>" : ' '.$html->button($i, sprintf("index=$index&HOUR=%d-%02.f-%02.f+%02.f&EX_PARAMS=$FORM{EX_PARAMS}$pages_qs", $y, $m, $d, $i));
     }

 	  $LIST_PARAMS{HOUR}="$FORM{HOUR}";

  	push @rows, [ "$_HOURS", $hours ];
   }

  if ($attr->{EX_PARAMS}) {
    push @rows, [' ', $EX_PARAMS];
   }  


  
  
  

  $table = $html->table({ width       => '100%',
                           rowcolor   => $_COLORS[1],
                           cols_align => ['right', 'left'],
                           rows       => [ @rows ]
                         });

  print $table->show();

}

}

#**********************************************************
#
#**********************************************************
sub report_fees_month {
	$FORM{allmonthes}='y';
  report_fees();
}

#**********************************************************
#
#**********************************************************
sub report_fees {
  reports({ DATE        => $FORM{DATE}, 
  	        REPORT      => '',
            PERIOD_FORM => 1
  	         });

  $LIST_PARAMS{PAGE_ROWS}=1000;
  use Finance;
  my $fees = Finance->fees($db, $admin, \%conf);


if (defined($FORM{DATE})) {
  $list = $fees->list( { %LIST_PARAMS } );
  $table_fees = $html->table( { width      => '100%',
  	                            caption    => "$_FEES", 
                                title      => ['ID', $_LOGIN, $_DATE, $_SUM, $_DESCRIBE, $_ADMINS, 'IP', $_DEPOSIT],
                                cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right'],
                                qs         => $pages_qs
                               });

  foreach my $line (@$list) {
   $table_fees->addrow("<b>$line->[0]</b>", 
     $html->button($line->[1], "index=15&subf=3&DATE=$line->[0]&UID=$line->[8]"),  
      $line->[2],
      $line->[3], $line->[4],  "$line->[5]", "$line->[6]", "$line->[7]");
    }
 }   
else{ 
  #Fees###################################################
  $table_fees = $html->table({ width      => '100%',
	                             caption    => $_FEES, 
                               title      => ["$_DATE", "$_COUNT", $_SUM],
                               cols_align => ['right', 'right', 'right'],
                               qs         => $pages_qs
                               });


  $list = $fees->reports({ %LIST_PARAMS });
  foreach my $line (@$list) {
    $table_fees->addrow($html->button($line->[0], "index=$index&$type=$line->[0]$pages_qs"), $line->[1], "<b>$line->[2]</b>" );
   }


}

  print $table_fees->show();	
  $table = $html->table( { width      => '100%',
                           cols_align => ['right', 'right', 'right', 'right'],
                           rows       => [ [ "$_TOTAL:", "<b>$fees->{TOTAL}</b>", "$_SUM", "<b>$fees->{SUM}</b>" ] ],
                           rowcolor   => $_COLORS[2]
                          });
  print $table->show();
}




#**********************************************************
#
#**********************************************************
sub report_payments_month {
	$FORM{allmonthes}='y';
  report_payments();
}


#**********************************************************
#
#**********************************************************
sub report_payments {

  my %METHODS_HASH = ();
  
  for(my $i=0; $i<=$#PAYMENT_METHODS; $i++) {
  	$METHODS_HASH{"$i:$i"}="$PAYMENT_METHODS[$i]";
   }
  

  reports({ DATE        => $FORM{DATE}, 
  	        REPORT      => '',
  	        PERIOD_FORM => 1,
  	        FIELDS      => { %METHODS_HASH },
  	        EXT_TYPE    => { PAYMENT_METHOD => $_PAYMENT_METHOD }
         });
  
  if ($FORM{FIELDS}) {
  	$LIST_PARAMS{METHODS}=$FORM{FIELDS};
   }

  $LIST_PARAMS{PAGE_ROWS}=1000;
  use Finance;
  my $payments = Finance->payments($db, $admin, \%conf);
  
if (defined($FORM{DATE})) {
  $list  = $payments->list( { %LIST_PARAMS } );
  $table = $html->table({ width      => '100%',
  	                      caption    => "$_PAYMENTS", 
                          title      => ['ID', $_LOGIN, $_DATE, $_SUM, $_DESCRIBE, $_ADMINS, 'IP', $_DEPOSIT],
                          cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right'],
                          qs         => $pages_qs
                         });

  foreach my $line (@$list) {
   $table->addrow("<b>$line->[0]</b>", 
      $html->button($line->[1], "index=15&subf=3&DATE=$line->[0]&UID=$line->[10]"),  
      $line->[2],
      $line->[3], 
      $line->[4],  
      "$line->[5]", 
      "$line->[6]", 
      "$line->[7]");
    }
 }   
else{ 
  
  
  my @CAPTION = ("$_DATE", "$_COUNT", $_SUM);
  if ($FORM{TYPE} && $FORM{TYPE} eq 'PAYMENT_METHOD') {
  	$CAPTION[0]=$_PAYMENT_METHOD;
  }
  
  $table = $html->table({ width      => '100%',
	                        caption    => $_PAYMENTS, 
                          title      => \@CAPTION,
                          cols_align => ['right', 'right', 'right'],
                          qs         => $pages_qs
                        });


  $list = $payments->reports({ %LIST_PARAMS });

  foreach my $line (@$list) {
    $table->addrow(
    
      ($FORM{TYPE} && $FORM{TYPE} eq 'PAYMENT_METHOD') ? @PAYMENT_METHODS[$line->[0]] : $html->button($line->[0], "index=$index&$type=$line->[0]$pages_qs"), 
      $line->[1], 
     "<b>$line->[2]</b>" );
   }


}

  print $table->show();	

  $table = $html->table( { width      => '100%',
                           cols_align => ['right', 'right', 'right', 'right'],
                           rows       => [ [ "$_TOTAL:", "<b>$payments->{TOTAL}</b>", "$_SUM", "<b>$payments->{SUM}</b>" ] ],
                           rowcolor   => $_COLORS[2]
                               } );
  print $table->show();
}

#**********************************************************
# Main functions
#**********************************************************
sub fl {

	# ID:PARENT:NAME:FUNCTION:SHOW SUBMENU:module:
my @m = (
 "0:0::null:::",
 "1:0:$_CUSTOMERS:null:::",
 "11:1:$_LOGINS:form_users:::",
 "24:11:$_ADD:user_form:::",
 "13:1:$_COMPANY:form_companies:::",
 "14:13:$_ADD:add_company:::",
 "25:13:$_LIST:form_companies:::",
 "15:11:$_INFO:form_users:UID::",
 "22:15:$_LOG:form_changes:UID::",
 "17:15:$_PASSWD:form_passwd:UID::",
 "18:15:$_NAS:form_nas_allow:UID::",
 "19:15:$_BILL:form_bills:UID::",
 "20:15:$_SERVICES:null:UID::",
 "21:15:$_COMPANY:user_company:UID::",
 "101:15:$_PAYMENTS:form_payments:UID::",
 "102:15:$_FEES:form_fees:UID::",

 "12:15:$_GROUP:user_group:UID::",
 "27:1:$_GROUPS:form_groups:::",
 "28:27:$_ADD:add_groups:::",
 "29:27:$_LIST:form_groups:::",
 "30:15:$_USER_INFO:user_pi:UID::",
 "31:15:Send e-mail:form_sendmail:UID::",

 "2:0:$_PAYMENTS:form_payments:::",
 "3:0:$_FEES:form_fees:::",
 "4:0:$_REPORTS:null:::",
 "41:4:$_PAYMENTS:report_payments:::",
 "42:41:$_MONTH:report_payments_month:::",
 "44:4:$_FEES:report_fees:::",
 "45:44:$_MONTH:report_fees_month:::",

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
 "62:60:$_NAS_STATISTIC:form_nas_stats:::",

 "65:5:$_EXCHANGE_RATE:form_exchange_rate:::",
 "75:5:$_HOLIDAYS:form_holidays:::",

 
 "85:5:$_SHEDULE:form_shedule:::",
 "86:5:$_BRUTE_ATACK:form_bruteforce:::",
 "90:5:MISC:null:::",
 "91:90:$_TEMPLATES:form_templates:::",
 "92:90:$_DICTIONARY:form_dictionary:::",
 "93:90:Config:form_config:::",
 "94:90:WEB server:form_webserver_info:::",
 "95:90:$_SQL_BACKUP:form_sql_backup:::",
 "6:0:$_OTHER:null:::",
  
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
  $functions{$ID}=$FUNTION_NAME if ($FUNTION_NAME  ne '');
  $menu_args{$ID}=$ARGS if ($ARGS ne '');
  $maxnumber=$ID if ($maxnumber < $ID);
}

	
}


#**********************************************************
# mk_navigator()
#**********************************************************
sub mk_navigator {

my ($menu_navigator, $menu_text) = $html->menu(\%menu_items, 
                                               \%menu_args, 
                                               \%permissions,
                                              { 
     	                                          FUNCTION_LIST   => \%functions
     	                                         }
                                               );
  
  if ($html->{ERROR}) {
  	$html->message('err',  $_ERROR, "$html->{ERROR}");
  	exit;
  }

return  $menu_text, "/".$menu_navigator;
}







#**********************************************************
# Functions list
#**********************************************************
sub flist {

my  %new_hash = ();
while((my($findex, $hash)=each(%menu_items))) {
   while(my($parent, $val)=each %$hash) {
#     print "$findex $parent $val<br>\n";
     $new_hash{$parent}{$findex}=$val;
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
if (defined($admin->{WEB_OPTIONS}{qm})) {
	my @a = split(/,/, $admin->{WEB_OPTIONS}{qm});
	foreach my $line (@a) {
     my($id, $custom_name)=split(/:/, $line, 2);
     $qm{$id} = ($custom_name ne '') ? $custom_name : '';
	 }
}

my $table = $html->table({ width      => '100%',
                           border     => 1,
                           cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left', 'left', 'center']
                         });


for(my $parent=1; $parent<$#menu_sorted; $parent++) { 
  my $val = $h->{$parent};
  my $level = 0;
  my $prefix = '';
  $table->{rowcolor}=$_COLORS[0];      

  next if (! defined($permissions{($parent-1)}));  

  $table->addrow("$level:", "$parent >> ". $html->button("<b>$val</b>", "index=$parent"). "<<", '') if ($parent != 0);

  if (defined($new_hash{$parent})) {
    $table->{rowcolor}=undef;
    $level++;
    $prefix .= "&nbsp;&nbsp;&nbsp;";
    label:
      my $mi = $new_hash{$parent};

      while(my($k, $val)=each %$mi) {
 
        my $checked = undef;
        if (defined($qm{$k})) { 
        	$checked = 1;  
        	$val = "<b>$val</b>";
         }

        
        $table->addrow("$k ". $html->form_input('qm_item', "$k", { TYPE          => 'checkbox',
       	                                                           OUTPUT2RETURN => 1,
       	                                                           STATE         => $checked  
       	                                           }),  
                     "$prefix ". $html->button($val, "index=$k"), 
                     $html->form_input("qm_name_$k", $qm{$k}, { OUTPUT2RETURN => 1 }) );

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
      $level--;
      
      $prefix = substr($prefix, 0, $level * 6 * 3);
      goto label;
    }
    delete($new_hash{0}{$parent});
   }

# return 0;
}




print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
	                       HIDDEN  => { index        => "$index",
	                       	            AWEB_OPTIONS => 1
                                     },
	                       SUBMIT  => { quick_set => "$_SET"
	                       	           } });



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
 	  $html->message('err', $_ERROR, "$_EXIST");
   }
  elsif ($FORM{add} && $FORM{SUM})	{
    my $er = $payments->exchange_info($FORM{ER});
    $FORM{ER} = $er->{ER_RATE};
    $payments->add($user, { %FORM } );  

    if ($payments->{errno}) {
      $html->message('err', $_ERROR, "[$payments->{errno}] $err_strs{$payments->{errno}}");	
     }
    else {
      $html->message('info', $_PAYMENTS, "$_ADDED $_SUM: $FORM{SUM} $er->{ER_SHORT_NAME}");
      
      if ($conf{external_payments}) {
        if (! _external($conf{external_payments}, { %FORM }) ) {
     	    return 0;
         }
       }
     }
   }
  elsif($FORM{del} && $FORM{is_js_confirmed}) {
  	if (! defined($permissions{1}{2})) {
      $html->message('err', $_ERROR, "[13] $err_strs{13}");
      return 0;		
	   }

    $payments->del($user, $FORM{del});
    if ($payments->{errno}) {
      $html->message('err', $_ERROR, "[$payments->{errno}] $err_strs{$payments->{errno}}");	
     }
    else {
      $html->message('info', $_PAYMENTS, "$_DELETED ID: $FORM{del}");
     }
   }

#exchange rate sel
my $er = $payments->exchange_list();
  $payments->{SEL_ER} = "<select name=ER>\n";
  $payments->{SEL_ER} .= "<option value=''>\n";
foreach my $line (@$er) {
  $payments->{SEL_ER} .= "<option value=$line->[4]";
  $payments->{SEL_ER} .= ">$line->[1] : $line->[2]\n";
}
$payments->{SEL_ER} .= "</select>\n";

#$payments->{SEL_ER} =  $html->form_select('ER', 
#                                { 
# 	                                SELECTED  => '',
# 	                                SEL_MULTI_ARRAY   => $payments->exchange_list(),
# 	                                MULTI_ARRAY_KEY   => 4,
# 	                                MULTI_ARRAY_VALUE => 1,
# 	                                SEL_OPTIONS       => { 0 => '-N/S-'}
# 	                               });



$payments->{SEL_METHOD} =  $html->form_select('METHOD', 
                                { SELECTED      => $day_id,
 	                                SEL_ARRAY     => \@PAYMENT_METHODS,
 	                                ARRAY_NUM_ID  => 'y'
 	                               });



if (defined ($permissions{1}{1})) {
   $payments->{OP_SID} = mk_unique_value(16);
   $html->tpl_show(templates('form_payments'), $payments);
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
my $table = $html->table( { width      => '100%',
                            caption    => "$_PAYMENTS",
                            border     => 1,
                            title      => ['ID', $_LOGIN, $_DATE, $_SUM, $_DESCRIBE, $_ADMINS, 'IP',  $_DEPOSIT, $_PAYMENT_METHOD, 'EXT ID', '-'],
                            cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left', 'left', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $payments->{TOTAL}
                           } );

$pages_qs .= "&subf=2" if (! $FORM{subf});

foreach my $line (@$list) {
  my $delete = ($permissions{1}{2}) ?  $html->button($_DEL, "index=$index&del=$line->[0]&UID=$line->[10]$pages_qs", { MESSAGE => "$_DEL [$line->[0]] ?" }) : ''; 
  $table->addrow("<b>$line->[0]</b>", 
  $html->button($line->[1], "index=15&UID=$line->[10]"), 
  $line->[2], 
  $line->[3], 
  $line->[4],  
  "$line->[5]", 
  "$line->[6]", 
  "$line->[7]", 
  $PAYMENT_METHODS[$line->[8]], 
  "$line->[9]", 
  $delete);
}

print $table->show();

$table = $html->table({ width      => '100%',
                        cols_align => ['right', 'right', 'right', 'right'],
                        rows       => [ [ "$_TOTAL:", "<b>$payments->{TOTAL}</b>", "$_SUM", "<b>$payments->{SUM}</b>" ] ],
                        rowcolor   => $_COLORS[2]
                      });
print $table->show();
}

#*******************************************************************
# form_exchange_rate
#*******************************************************************
sub form_exchange_rate {
 use Finance;
 my $finance = Finance->new($db, $admin);

 $finance->{ACTION}='add';
 $finance->{LNG_ACTION}="$_ADD";

if ($FORM{add}) {
	$finance->exchange_add({ %FORM });
  if ($finance->{errno}) {
    $html->message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    $html->message('info', $_EXCHANGE_RATE, "$_ADDED");
   }
}
elsif($FORM{change}) {
	$finance->exchange_change("$FORM{chg}", { %FORM });
  if ($finance->{errno}) {
    $html->message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    $html->message('info', $_EXCHANGE_RATE, "$_CHANGED");
   }
}
elsif($FORM{chg}) {
	$finance->exchange_info("$FORM{chg}");

  if ($finance->{errno}) {
    $html->message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    $finance->{ACTION}='change';
    $finance->{LNG_ACTION}="$_CHANGE";
    $html->message('info', $_EXCHANGE_RATE, "$_CHANGING");
   }
}
elsif($FORM{del}) {
	$finance->exchange_del("$FORM{del}");
  if ($finance->{errno}) {
    $html->message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    $html->message('info', $_EXCHANGE_RATE, "$_DELETED");
   }

}
	

$html->tpl_show(templates('form_er'), $finance);
my $table = $html->table( { width      => '640',
                            title      => ["$_MONEY", "$_SHORT_NAME", "$_EXCHANGE_RATE (1 unit =)", "$_CHANGED", '-', '-'],
                            cols_align => ['left', 'left', 'right', 'center', 'center'],
                          });

my $list = $finance->exchange_list( {%LIST_PARAMS} );
foreach my $line (@$list) {
  $table->addrow($line->[0], $line->[1], $line->[2], $line->[3], 
     $html->button($_CHANGE, "index=65&chg=$line->[4]"), 
     $html->button($_DEL, "index=65&del=$line->[4]", { MESSAGE => "$_DEL [$line->[0]]?" } ));
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
 my $fees = Finance->fees($db, $admin, \%conf);

if (defined($attr->{USER})) {
  my $user = $attr->{USER};

  if($user->{BILL_ID} < 1) {
    form_bills({ USER => $user });
    return 0;
  }
  
  use Shedule;
  my $shedule = Shedule->new($db, $admin, \%conf); 

  $fees->{UID} = $user->{UID};
  if ($FORM{take} && $FORM{SUM}) {
    # add to shedule
    if ($FORM{ER} && $FORM{ER} ne '') {
      my $er = $fees->exchange_info($FORM{ER});
      $FORM{ER} = $er->{ER_RATE};
      $FORM{SUM} = $FORM{SUM} / $FORM{ER};
    }

    if ($period == 1) {

      $FORM{date_M}++;
      $shedule->add( { DESCRIBE => $FORM{DESCR}, 
      	               D        => $FORM{date_D},
      	               M        => $FORM{date_M},
      	               Y        => $FORM{date_Y},
                       UID      => $user->{UID},
                       TYPE     => 'fees',
                       ACTION   => "$FORM{SUM}:$FORM{DESCRIBE}"
                      } );

      if ($shedule->{errno}) {
        $html->message('err', $_ERROR, "[$shedule->{errno}] $err_strs{$shedule->{errno}}");	
       }
      else {
  	    $html->message('info', $_SHEDULE, "$_ADDED");
       }
     }
    #Add now
    else {
      
      $fees->take($user, $FORM{SUM}, { %FORM } );  
      if ($fees->{errno}) {
        $html->message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");	
       }
      else {
        $html->message('info', $_PAYMENTS, "$_TAKE SUM: $fees->{SUM}");
        
        #External script
        if ($conf{external_fees}) {
          if (! _external($conf{external_fees}, { %FORM }) ) {
       	    return 0;
           }
         }
       }
    }
   }
  elsif ($FORM{del} && $FORM{is_js_confirmed}) {
  	if (! defined($permissions{2}{2})) {
      $html->message('err', $_ERROR, "[13] $err_strs{13}");
      return 0;		
	   }

	  $fees->del($user,  $FORM{del});
    if ($fees->{errno}) {
      $html->message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");
     }
    else {
      $html->message('info', $_DELETED, "$_DELETED [$FORM{del}]");
    }
   }


  $shedule->list({ UID  => $user->{UID},
                   TYPE => 'fees' });
  
  if ($shedule->{TOTAL} > 0) {
  	 $fees->{SHEDULE}=$html->button($_SHEDULE, "index=85&UID=$user->{UID}"); 
   }
  
  $fees->{PERIOD_FORM}=form_period($period);
  if (defined ($permissions{2}{1})) {
    #exchange rate sel
    my $er = $fees->exchange_list();
    $fees->{SEL_ER} = "<select name='ER'>\n";
    $fees->{SEL_ER} .= "<option value=''>\n";
    foreach my $line (@$er) {
      $fees->{SEL_ER} .= "<option value='$line->[4]'";
      $fees->{SEL_ER} .= ">$line->[1] : $line->[2]\n";
    }
    $fees->{SEL_ER} .= "</select>\n";

    $html->tpl_show(templates('form_fees'), $fees);
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
my $table = $html->table( { width      => '100%',
                            caption    => "$_FEES",
                            border     => 1,
                            title      => ['ID', $_LOGIN, $_DATE, $_SUM, $_DESCRIBE, $_ADMINS, 'IP',  $_DEPOSIT, '-'],
                            cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $fees->{TOTAL}
                                  } );


$pages_qs .= "&subf=2" if (! $FORM{subf});
foreach my $line (@$list) {
  my $delete = ($permissions{2}{2}) ?  $html->button($_DEL, "index=$index&del=$line->[0]&UID=$line->[8]$pages_qs", 
   { MESSAGE => "$_DEL ID: $line->[0]?" }) : ''; 

  $table->addrow("<b>$line->[0]</b>", $html->button($line->[1], "index=15&UID=$line->[8]"), $line->[2], 
   $line->[3], $line->[4],  "$line->[5]", "$line->[6]", "$line->[7]", $delete);
}

print $table->show();

$table = $html->table( { width      => '100%',
                         cols_align => ['right', 'right', 'right', 'right'],
                         rows       => [ [ "$_TOTAL:", "<b>$fees->{TOTAL}</b>", "$_SUM:", "<b>$fees->{SUM}</b>" ] ],
                         rowcolor   => $_COLORS[2]
                                  } );
print $table->show();


}

#*******************************************************************
sub form_sendmail {
 my %MAIL_PRIORITY = (2 => 'High', 
                      3 => 'Normal', 
                      4 => 'Low');



 my $user = Users->new($db, $admin); 
 $user->info($FORM{UID});
 $user->pi();
 

 $user->{EMAIL} = (defined($user->{EMAIL}) && $user->{EMAIL} ne '') ? $user->{EMAIL} : $user->{LOGIN} .'@'. $conf{USERS_MAIL_DOMAIN};
 $user->{FROM} = $FORM{FROM} || $conf{ADMIN_MAIL};

 if ($FORM{sent}) {
   
   sendmail("$user->{FROM}", "$user->{EMAIL}", "$FORM{SUBJECT}", "$FORM{TEXT}", "$conf{MAIL_CHARSET}", "$FORM{PRIORITY} ($MAIL_PRIORITY{$FORM{PRIORITY}})");
   my $table = $html->table({ width    => '100%',
                              rows     => [ [ "$_USER:",    "$user->{LOGIN}" ],
                                            [ "E-Mail:",    "$user->{EMAIL}" ],
                                            [ "$_SUBJECT:", "$FORM{SUBJECT}" ],
                                            [ "$_FROM:",    "$user->{FROM}"  ],
                                            [ "PRIORITY:",  "$FORM{PRIORITY} (". $MAIL_PRIORITY{$FORM{PRIORITY}} .")"]    
                                           ],
                              rowcolor => $_COLORS[1]
                              });

   $html->message('info', $_SENDED, $table->show());
   return 0;
  }


 $user->{EXTRA} = "<tr><td>$_TO:</td><td bgcolor='$_COLORS[2]'>$user->{EMAIL}</td></tr>\n";
 $user->{PRIORITY_SEL}=$html->form_select('PRIORITY', 
                                { SELECTED  => $FORM{PRIORITY},
 	                                SEL_HASH  => \%MAIL_PRIORITY
 	                               });

 $html->tpl_show(templates('mail_form'), $user); 
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
	  $SEARCH_DATA{HIDDEN_FIELDS}.=$html->form_input("$k", "$v", { TYPE          => 'hidden',
       	                                                         OUTPUT2RETURN => 1
      	                                                        });
	 }
}


if (defined($attr->{SIMPLE})) {

	my $SEARCH_FIELDS = $attr->{SIMPLE};
	while(my($k, $v)=each( %$SEARCH_FIELDS )) {
	  $SEARCH_DATA{SEARCH_FORM}.="<tr><td>$k:</td><td><input type=text name=\"$v\" value=\"%". $v ."%\"></td></tr>\n";
	 }

  $html->tpl_show(templates('form_search_simple'), \%SEARCH_DATA);
 }
elsif ($attr->{TPL}) {
	#defined();
 }
else {


my $SEL_METHOD =  $html->form_select('METHOD', 
                                { SELECTED      => $day_id,
 	                                SEL_ARRAY     => \@PAYMENT_METHODS,
 	                                ARRAY_NUM_ID  => 'y'
 	                               });


my $group_sel = sel_groups();
my %search_form = ( 
2 => "
<!-- PAYMENTS -->
<tr><td colspan=\"2\"><hr/></td></tr>
<tr><td>$_OPERATOR:</td><td><input type='text' name='A_LOGIN' value='%A_LOGIN%'/></td></tr>
<tr><td>$_DESCRIBE (*):</td><td><input type='text' name='DESCRIBE' value='%DESCRIBE%'/></td></tr>
<tr><td>$_SUM (&lt;):</td><td><input type='text' name='SUM' value='%SUM%'/></td></tr>
<tr><td>$_PAYMENT_METHOD:</td><td>$SEL_METHOD</td></tr>
<tr><td>ID:</td><td><input type='text' name='ID' value='%ID%'/></td></tr>
<tr><td>EXT ID:</td><td><input type='text' name='EXT_ID' value='%EXT_ID%'/></td></tr>
\n",

3 => "
<!-- FEES -->
<tr><td colspan='2'><hr/></td></tr>
<tr><td>$_OPERATOR (*):</td><td><input type=text name=A_LOGIN value='%A_LOGIN%'/></td></tr>
<tr><td>$_DESCRIBE (*):</td><td><input type=text name=DESCRIBE value='%DESCRIBE%'/></td></tr>
<tr><td>$_SUM (<,>):</td><td><input type=text name=SUM value='%SUM%'/></td></tr>\n",

11 => $html->tpl_show(templates('form_search_users'), { %info, %FORM, GROUPS_SEL => $group_sel }, { notprint => 1 })
 


);


$SEARCH_DATA{SEARCH_FORM}=(defined($attr->{SEARCH_FORM})) ? $attr->{SEARCH_FORM} : $search_form{$FORM{type}};
$SEARCH_DATA{FROM_DATE} = $html->date_fld('FROM_', { MONTHES => \@MONTHES });
$SEARCH_DATA{TO_DATE} = $html->date_fld('TO_', { MONTHES => \@MONTHES} );
$SEARCH_DATA{SEL_TYPE}="<tr><td>WHERE:</td><td>$SEL_TYPE</td></tr>\n" if ($index == 7);

$html->tpl_show(templates('form_search'), \%SEARCH_DATA);

}

if ($FORM{search}) {
	$LIST_PARAMS{LOGIN_EXPR}=$FORM{LOGIN_EXPR};
  $pages_qs = "&search=y";
  $pages_qs .= "&type=$FORM{type}" if ($pages_qs !~ /&type=/);

	if(defined($FORM{FROM_D}) && defined($FORM{TO_D})) {
	  $FORM{FROM_DATE}="$FORM{FROM_Y}-". sprintf("%.2d", ($FORM{FROM_M}+1)). "-$FORM{FROM_D}";
	  $FORM{TO_DATE}="$FORM{TO_Y}-". sprintf("%.2d", ($FORM{TO_M}+1)) ."-$FORM{TO_D}";
   }	 
	
	while(my($k, $v)=each %FORM) {
		if ($k =~ /([A-Z0-9]+)/ && $v ne '' && $k ne '__BUFFER') {
		  #print "$k, $v<br>";
		  $LIST_PARAMS{$k}=$v;
	    $pages_qs .= "&$k=$v";
		 }
	 }



  if ($FORM{type} ne $index) {
  	#print "$index = $FORM{type}";
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
  $shedule->del({ ID => $FORM{del} });
  if ($shedule->{errno}) {
    $html->message('err', $_ERROR, "[$shedule->{errno}] $err_strs{$shedule->{errno}}");
   }
  else {
    $html->message('info', $_DELETED, "$_DELETED [$FORM{del}]");
   }
}


my $list = $shedule->list( { %LIST_PARAMS } );
my $table = $html->table( { width      => '100%',
                            border     => 1,
                            title      => ["$_HOURS", "$_DAY", "$_MONTH", "$_YEAR", "$_COUNT", "$_USER", "$_TYPE", "$_VALUE", "$_MODULES", "$_ADMINS", "$_CREATED", "-"],
                            cols_align => ['right', 'right', 'right', 'right', 'right', 'left', 'right', 'right', 'right', 'left', 'right', 'center'],
                            qs         => $pages_qs,
                            pages      => $shedule->{TOTAL}
                          });

foreach my $line (@$list) {
  my $delete = ($permissions{4}{3}) ?  $html->button($_DEL, "index=$index&del=$line->[13]", { MESSAGE =>  "$_DEL [$line->[13]]?" }) : '-'; 
  $table->addrow("<b>$line->[0]</b>", $line->[1], $line->[2], 
    $line->[3],  $line->[4],  
    $html->button($line->[5], "index=15&UID=$line->[12]"), 
    "$line->[6]", 
    "$line->[7]", 
    "$line->[8]", 
    "$line->[9]", 
    "$line->[10]", $delete);
}

print $table->show();

$table = $html->table({ width      => '100%',
                        cols_align => ['right', 'right', 'right', 'right'],
                        rows       => [ [ "$_TOTAL:", "<b>$shedule->{TOTAL}</b>" ] ]
                       });
print $table->show();





}




#**********************************************************
# Create templates
# form_templates()
#**********************************************************
sub form_templates {
  
  
  my $sys_templates = '../../Abills/modules';
  my $template = '';
  my %info = ();


  my %main_templates = ('user_warning' => USER_WARNING,
                        'invoce'       => INVOCE,
                        'admin_report' => ADMIN_REPORT,
                        'account'      => ACCOUNT,
                        'user_info'    => USER_INFO);


$info{ACTION_LNG}=$_CREATE;

if ($FORM{create}) {
   
   my ($module, $file)=split(/:/, $FORM{create}, 2);
   $info{TPL_NAME} = "$module"._."$file";
  
 
   if (-f  "$sys_templates/$module/templates/$file" ) {
	  open(FILE, "$sys_templates/$module/templates/$file") || $html->message('err', $_ERROR, "Can't open file '$sys_templates/$module/templates/$file' $!\n");;
  	  while(<FILE>) {
	    	$info{TEMPLATE} .= $_;
	    }	 
	  close(FILE);
   }

   

   
 }
elsif ($FORM{change}) {
  my $FORM2  = ();
  my @pairs = split(/&/, $FORM{__BUFFER});
  $info{ACTION_LNG}=$_CHANGE;
  
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


  $info{TEMPLATE} = $FORM2{template};
  $info{TPL_NAME} = $FORM{tpl_name};
  
	open(FILE, ">$conf{TPL_DIR}/$FORM{tpl_name}") || $html->message('err', $_ERROR, "Can't open file '$conf{TPL_DIR}/$FORM{tpl_name}' $!\n");
	  print FILE "$info{TEMPLATE}";
	close(FILE);

	$html->message('info', $_INFO, "$_CHANGED");
}
elsif($FORM{tpl_name}) {
  if (-f  "$conf{TPL_DIR}/$FORM{tpl_name}" ) {
	  open(FILE, "$conf{TPL_DIR}/$FORM{tpl_name}") || $html->message('err', $_ERROR, "Can't open file '$conf{TPL_DIR}/$FORM{tpl_name}' $!\n");;
  	  while(<FILE>) {
	    	 $template .= $_;
	    }	 
	  close(FILE);
   }

  $html->message('info', $_CHAMGE, "$_CHANGE: $templates{$FORM{tpl_name}}");
}


print << "[END]";

<form action='$SELF_URL' METHOD='POST'>
<input type="hidden" name="index" value='$index'>
<input type="hidden" name="tpl_name" value='$info{TPL_NAME}'>
<table>
<tr bgcolor="$_COLORS[0]"><th>$_TEMPLATES</th></tr>
<tr bgcolor="$_COLORS[0]"><td>$info{TPL_NAME}</td></tr>
<tr><td>
   <textarea cols="100" rows="30" name="template">$info{TEMPLATE}</textarea>
</td></tr>
<tr><td>$conf{TPL_DIR}</td></tr>
</table>
<input type="submit" name="change" value='$info{ACTION_LNG}'>
</form>
[END]



my $table = $html->table( { width       => '600',
                            title_plain => ["FILE", "$_SIZE", "-", "-"],
                            cols_align  => ['left', 'left', 'center']
                         } );


foreach my $module (@MODULES) {
	$table->{rowcolor}=$_COLORS[0];
	$table->{extra}="colspan='4' class='small'";
	
	$table->addrow("$module ($sys_templates/$module/templates)");
	if (-d "$sys_templates/$module/templates" ) {
    opendir DIR, "$sys_templates/$module/templates" or die "Can't open dir '$sys_templates/$module/templates' $!\n";
      my @contents = grep  !/^\.\.?$/  , readdir DIR;
    closedir DIR;
    $table->{rowcolor}=undef;
    $table->{extra}=undef;

    foreach my $file (@contents) {
      next if (-d "$sys_templates/$module/templates/".$file);

      my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$sys_templates/$module/templates/".$file);

      $table->addrow("$file", $size, 
         (-f "$conf{TPL_DIR}/$module_$file") ? $html->button($_CHANGE, "index=$index&tpl_name=$module_$file") : $html->button($_CREATE, "index=$index&create=$module:$file"),
         (-f "$conf{TPL_DIR}/$module_$file") ? $html->button($_DEL, "index=$index&delete=$module_$file") : '');
     }

   }
}

#while(my($k, $v) = each %templates) {
#  $table->addrow("<b>$k</b>", "$v", $html->button($_CHANGE, "index=$index&tpl_name=$k"));
#}

print $table->show();





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
#
# form_dictionary();
#*******************************************************************
sub form_dictionary {
	
	my $sub_dict = $FORM{SUB_DICT} || '';

 ($sub_dict, undef) = split(/\./, $sub_dict, 2);
  if ($FORM{change}) {
  	my $out = '';
  	my $i=0;
  	while(my($k, $v)=each %FORM) {
  		 if ($k =~ /$sub_dict/ && $k ne '__BUFFER') {
  		    my ($pre, $key)=split(/_/, $k, 2);

 		      $key =~ s/\%40/\@/;

          if ($key =~ /@/) {
   		    	$v =~ s/\\'/'/g;
   		    	$v =~ s/\\"/"/g;
   		    	$out .= "$key=$v;\n"; 
  		     }
  		    else {
  		      $key =~ s/\%24/\$/;
  		    	$out .= "$key=\"$v\";\n"; 
  		     }

  		    #print '$_'."$key=\"$v\";<br>\n";
  		    $i++;
  		  }
  		  
  	 }

    open(FILE, ">../../language/$sub_dict.pl" )  ;
      print FILE "$out";
	  close(FILE);

  	$html->message('info', $_CHANGED, "$_CHANGED '$FORM{SUB_DICT}'");
   }


	my $table = $html->table({ width       => '600',
                             title_plain => ["$_NAME", "-"],
                             cols_align  => ['left', 'center']
                            });

#show dictionaries
 opendir DIR, "../../language/" or die "Can't open dir '../../language/' $!\n";
   my @contents = grep  !/^\.\.?$/  , readdir DIR;
 closedir DIR;

 if ($#contents > 0) {
   foreach my $file (@contents) {
    if (-f "../../language/". $file) {
        if ($sub_dict. ".pl" eq $file) {
          $table->{rowcolor}=$_COLORS[0];      
         }
        else {
    	    undef($table->{rowcolor});
         }
        $table->addrow("$file", $html->button($_CHANGE, "index=$index&SUB_DICT=$file"));
      }
    }
  }
  
  print $table->show();




  #Open main dictionary	
  my %main_dictionary = ();

	open(FILE, "<../../language/english.pl") || print "Can't open file '../../language/english.pl' $!\n";
	  while(<FILE>) {
	  	 my($name, $value)=split(/=/, $_, 2);
       $name =~ s/ //ig;
       if ($_ =~ /^@/){
       	 $main_dictionary{"$name"}=$value;
        }
       elsif ($_ !~ /^#|^\n/){
         $main_dictionary{"$name"}=clearquotes($value);
        }
	   }
	close(FILE);




    my %sub_dictionary = ();
  if ($sub_dict ne '') {
    #Open main dictionary	
	  open(FILE, "<../../language/". $sub_dict . ".pl" ) || print "Can't open file '../../language/$sub_dict.pl' $!\n";
  	  while(<FILE>) {
	    	 my($name, $value)=split(/=/, $_, 2);
         $name =~ s/ //ig;
	    	 if ($_ =~ /^@/){
       	   $sub_dictionary{"$name"}=$value;
          }
	    	 elsif ($_ !~ /^#|^\n/) {
           $sub_dictionary{"$name"}=clearquotes($value) 
          }
	     }
	  close(FILE);
   }



	$table = $html->table( { width       => '600',
                           title_plain => ["$_NAME", "$_VALUE", "-"],
                           cols_align  => ['left', 'left', 'center']
                        } );

  foreach my $k (sort keys %main_dictionary) {
  	 my $v = $main_dictionary{$k};
  	 my $v2 = (defined($sub_dictionary{"$k"})) ? $sub_dictionary{"$k"} : '--';
     
     $table->addrow(
        $html->form_input('NAME', "$k"), 
        $html->form_input("$k", "$v"), 
        $html->form_input($sub_dict ."_". $k, "$v2")); 
   }

   $table->addrow("$_TOTAL", "$i", ''); 




print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
	                       HIDDEN  => { index    => "$index",
                                      SUB_DICT => "$sub_dict"
                                     },
	                       SUBMIT  => { change   => "$_CHANGE"
	                       	           } });

}

#*******************************************************************
# form_webserver_info()
#*******************************************************************
sub form_webserver_info {

	my $table = $html->table( {
		                         caption     => 'WEB server info',
		                         width       => '600',
                             title_plain => ["$_NAME", "$_VALUE", "-"],
                             cols_align  => ['left', 'left', 'center']
                                  } );

 foreach my $k (sort keys %ENV) {
    $table->addrow($k, $ENV{$k}, '');
  }
	print $table->show();
}

#*******************************************************************
# form config
#*******************************************************************
sub form_config {
	

	my $table = $html->table( {caption     => 'config',
		                         width       => '600',
                             title_plain => ["$_NAME", "$_VALUE", "-"],
                             cols_align  => ['left', 'left', 'center']
                                  } );
  my $i = 0;
  foreach my $k (sort keys %conf) {
     if ($k eq 'dbpasswd') {
      	$conf{$k}='*******';
      }
     $table->addrow($k, $conf{$k}, '');
     $i++;
   }
	print $table->show();
}



#*******************************************************************
# For clearing quotes
# clearquotes( $text )
#*******************************************************************
sub clearquotes {
 my $text = shift;
 if ($text ne '""') {
   $text =~ s/\"|'|;//g;
  }
 else {
 	 $text = '';
  }
 return "$text";
}


#*******************************************************************
# sel_groups();
#*******************************************************************
sub sel_groups {
  my $GROUPS_SEL = '';

  if ($admin->{GID} > 0) {
  	$users->group_info($admin->{GID});
  	$GROUPS_SEL = "$admin->{GID}:$users->{G_NAME}";
   }
  else {
    $GROUPS_SEL = $html->form_select('GID', 
                                { 
 	                                SELECTED          => $FORM{GID},
 	                                SEL_MULTI_ARRAY   => $users->groups_list(),
 	                                MULTI_ARRAY_KEY   => 0,
 	                                MULTI_ARRAY_VALUE => 1,
 	                                SEL_OPTIONS       => { 0 => '-N/S-'}
 	                               });
   }

  return $GROUPS_SEL;	
}


#*******************************************************************
# Make SQL backup
#*******************************************************************
sub form_sql_backup {


if ($FORM{mk_backup}) {
   print "$MYSQLDUMP --host=$conf{dbhost} --user=\"$conf{dbuser}\" --password=\"****\" $conf{dbname} | $GZIP > $BACKUP_DIR/abills-$DATE.sql.gz<br>";
   my $res = `$MYSQLDUMP --host=$conf{dbhost} --user="$conf{dbuser}" --password="$conf{dbpasswd}" $conf{dbname} | $GZIP > $conf{BACKUP_DIR}/abills-$DATE.sql.gz`;
   $html->message('info', $_INFO, "Backup created: $res ($conf{BACKUP_DIR}/abills-$DATE.sql.gz)");
 }
elsif($FORM{del}) {
  my $status = unlink("$conf{BACKUP_DIR}/$FORM{del}");
  $html->message('info', $_INFO, "$_DELETED : $conf{BACKUP_DIR}/$FORM{del} [$status]");
}




  my $table = $html->table( { width      => '600',
                              caption    => "$_SQL_BACKUP",
                              border     => 1,
                              title      => ["$_NAME", $_DATE, $_SIZE, '-'],
                              cols_align => ['left', 'right', 'right', 'center']
                               } );


  opendir DIR, $conf{BACKUP_DIR} or $html->message('err', $_ERROR, "Can't open dir '$conf{BACKUP_DIR}' $!\n");
    my @contents = grep  !/^\.\.?$/  , readdir DIR;
  closedir DIR;

  use POSIX qw(strftime);
  foreach my $filename (@contents) {
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$conf{BACKUP_DIR}/$filename");
    my $date = strftime "%Y-%m-%d %H:%M:%S", localtime($mtime);
    $table->addrow($filename,  $date, $size, $html->button($_DEL, "index=$index&del=$filename", { MESSAGE => "$_DEL $filename?" })
    );
   }

 print  $table->show();
 print  $html->button($_CREATE, "index=$index&mk_backup=y");
	
}


#******************************************************************
#
#*******************************************************************
sub weblog {
	my ($action, $value) = @_;

  open(FILE, ">>$conf{WEB_LOGFILE}") || die "Can't open file '$conf{WEB_LOGFILE}' $!\n";
    print FILE "$DATE $TIME $admin->{A_LOGIN} $admin->{SESSION_IP} $action:$value\n";
  close(FILE);
	
}




#**********************************************************
#
#**********************************************************
sub form_bruteforce {
	
	
if(defined($FORM{del}) && defined($FORM{is_js_confirmed})  && $permissions{0}{5} ) {
   $users->bruteforce_del({ LOGIN => $FORM{del} });
   $html->message('info', $_INFO, "$_DELETED # $FORM{del}");
 }
	
  my $list = $users->bruteforce_list( { %LIST_PARAMS, %FORM } );
  my $table = $html->table( { width      => '100%',
                              caption    => "$_BRUTE_ATACK",
                              border     => 1,
                              title      => [$_LOGIN, $_PASSWD, $_DATE, $_COUNT, 'IP', '-', '-'],
                              cols_align => ['left', 'left', 'right', 'right', 'center', 'center'],
                              pages      => $users->{TOTAL},
                              qs         => $pages_qs
                           } );

  foreach my $line (@$list) {
    $table->addrow($line->[0],  
      $line->[1], 
      $line->[2], 
      $line->[3], 
      $line->[4], 
      $html->button($_INFO, "index=$index&LOGIN=$line->[0]"), 
      (defined($permissions{0}{5})) ? $html->button($_DEL, "index=$index&del=$line->[0]", { MESSAGE => "$_DEL $line->[0]?" }) : ''
      );
   }
  print $table->show();

  $table = $html->table( { width      => '100%',
                           cols_align => ['right', 'right'],
                           rows       => [ [ "$_TOTAL:", "<b>$users->{TOTAL}</b>" ] ]
                        } );
  print $table->show();

}



#**********************************************************
# Make external operations
#**********************************************************
sub _external {
	my ($file, $attr) = @_;
  
  my $arguments = '';
  while(my ($k, $v) = each %$attr) {
  	if ($k ne '__BUFFER' && $k =~ /[A-Z0-9_]/) {
  		$arguments .= " $k=\"$v\"";
  	 }
   }

  my $result = `$file $arguments`;
  my ($num, $message)=split(/:/, $result, 2);
  if ($num == 1) {
   	$html->message('info', "_EXTERNAL $_ADDED", "$message");
   	return 1;
   }
  else {
 	  $html->message('err', "_EXTERNAL $_ERROR", "[$num] $message");
    return 0;
   }
	
}
