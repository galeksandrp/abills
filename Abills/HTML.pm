package Abills::HTML;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION %h2
   @_COLORS
   %FORM
   %LIST_PARAMS
   %COOKIES
   %functions
   $index
   $pages_qs
   $domain
   $web_path
   $secure
   $SORT
   $DESC
   $PG
   $PAGE_ROWS
   $OP
   $SELF_URL
   $SESSION_IP
   @MONTHES
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw(
   &message
   @_COLORS
   %err_strs
   %FORM
   %LIST_PARAMS
   %COOKIES
   %functions
   $index
   $pages_qs
   $domain
   $web_path
   $secure
   $SORT
   $DESC
   $PG
   $PAGE_ROWS
   $OP
   $SELF_URL
   $SESSION_IP
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();

my $bg;
my $debug;
my %log_levels;
my $IMG_PATH;
my $row_number = 0;
#Hash of url params


#**********************************************************
# Create Object
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;
  
  $IMG_PATH = (defined($attr->{IMG_PATH})) ? $attr->{IMG_PATH} : '../img/';

  my $self = { };
  bless($self, $class);

  %FORM = form_parse();
  %COOKIES = getCookies();
  $SORT = $FORM{sort} || 1;
  $DESC = ($FORM{desc}) ? 'DESC' : '';
  $PG = $FORM{pg} || 0;
  $OP = $FORM{op} || '';
  $PAGE_ROWS = $FORM{PAGE_ROWS} || 25;
  $domain = $ENV{SERVER_NAME};
  $web_path = '';
  $secure = '';
  my $prot = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http' ;
  $SELF_URL = (defined($ENV{HTTP_HOST})) ? "$prot://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}" : '';
  $SESSION_IP = $ENV{REMOTE_ADDR} || '0.0.0.0';
  
  @_COLORS = ('#FDE302',  # 0 TH
            '#FFFFFF',  # 1 TD.1
            '#eeeeee',  # 2 TD.2
            '#dddddd',  # 3 TH.sum, TD.sum
            '#E1E1E1',  # 4 border
            '#FFFFFF',  # 5
            '#FFFFFF',  # 6
            '#000088',  # 7 vlink
            '#0000A0',  # 8 Link
            '#000000',  # 9 Text
            '#FFFFFF',  #10 background
           ); #border
  
  %LIST_PARAMS = ( SORT => $SORT,
	       DESC => $DESC,
	       PG => $PG,
	       PAGE_ROWS => $PAGE_ROWS,
	      );

  %functions = ();
  
  $pages_qs = '';
  $index = $FORM{index} || 0;  
  
  
  if (defined($COOKIES{language}) && $COOKIES{language} ne '') {
    $self->{language}=$COOKIES{language};
   }
  else {
    $self->{language} = 'english';
   }

  return $self;
}




#*******************************************************************
# Parse inputs from query
# form_parse()
#*******************************************************************
sub form_parse {
  my $self = shift;
  my $buffer = '';
  my $value='';
  my %FORM = ();
  
  return %FORM if (! defined($ENV{'REQUEST_METHOD'}));

if ($ENV{'REQUEST_METHOD'} eq "GET") {
   $buffer= $ENV{'QUERY_STRING'};
 }
elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
   read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
 }

my @pairs = split(/&/, $buffer);
$FORM{__BUFFER}=$buffer;

foreach my $pair (@pairs) {
   my ($side, $value) = split(/=/, $pair);
   $value =~ tr/+/ /;
   $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
   $value =~ s/<!--(.|\n)*-->//g;
   $value =~ s/<([^>]|\n)*>//g;
   if (defined($FORM{$side})) {
     $FORM{$side} .= ", $value";
    }
   else {
     $FORM{$side} = $value;
    }
 }

  return %FORM;
}





sub dirname {
    my($x) = @_;
    #print STDERR "dirname('$x') = ";
    if ( $x !~ s@[/\\][^/\\]+$@@ ) {
     	$x = '.';
    }
    #print STDERR "'$x'\n";
    $x;
}


#*******************************************************************
#Set cookies
# setCookie($name, $value, $expiration, $path, $domain, $secure);
#*******************************************************************
sub setCookie {
	# end a set-cookie header with the word secure and the cookie will only
	# be sent through secure connections
	my $self = shift;
	my($name, $value, $expiration, $path, $domain, $secure) = @_;
	
	#$path = dirname($ENV{SCRIPT_NAME}) if ($path eq '');


	print "Set-Cookie: ";
	print $name, "=$value; expires=\"", $expiration,
		"\"; path=$path; domain=", $domain, "; ", $secure, "\n";
}



#********************************************************************
# get cookie values and return hash of it
#
# getCookies()
#********************************************************************
sub getCookies {
  my $self = shift;
	# cookies are seperated by a semicolon and a space, this will split
	# them and return a hash of cookies
	my(%cookies);

  if (defined($ENV{'HTTP_COOKIE'})) {
 	  my(@rawCookies) = split (/; /, $ENV{'HTTP_COOKIE'});
	  foreach(@rawCookies){
	     my ($key, $val) = split (/=/,$_);
	     $cookies{$key} = $val;
	  } 
   }

	return %cookies; 
}



#*******************************************************************
# menu($type, $main_para,_name, $ex_params, \%menu_hash_ref);
#
# $type
#   0 - horizontal  
#   1 - vertical
# $ex_params - extended params
# $mp_name - Menu parameter name
# $params - hash of menu items
# menu($type, $mp_name, $ex_params, $menu, $sub_menu, $attr);
#*******************************************************************
sub menu {
 my $self = shift;
 my ($type, $mp_name, $ex_params, $menu, $sub_menu, $attr)=@_;
 my @menu_captions = sort keys %$menu;

 $self->{menu} = "<table width=100%>\n";

if ($type == 1) {

  foreach my $line (@menu_captions) {
    my($n, $file, $k)=split(/:/, $line);
    my $link = ($file eq '') ? "$SELF_URL" : "$file";
    $link .= '?'; 
    $link .= "$mp_name=$k&" if ($k ne '');


#    if ((defined($FORM{$mp_name}) && $FORM{$mp_name} eq $k) && $file eq '') {
     if ((defined($FORM{root_index}) && $FORM{root_index} eq $k) && $file eq '') {
      $self->{menu} .= "<tr><td bgcolor=$_COLORS[3]><a href='$link$ex_params'><b>". $menu->{"$line"} ."</b></a></td></tr>\n";
      while(my($k, $v)=each %$sub_menu) {
      	 $self->{menu} .= "<tr><td bgcolor=$_COLORS[1]>&nbsp;&nbsp;&nbsp;<a href='$SELF_URL?index=$k'>$v</a></td></tr>\n";
       }
     }
    else {
      $self->{menu} .= "<tr><td><a href='$link'>". $menu->{"$line"} ."</a></td></tr>\n";
     }
   }
}
else {
  $self->{menu} .= "<tr bgcolor=$_COLORS[0]>\n";
  
  foreach my $line (@menu_captions) {
    my($n, $file, $k)=split(/:/, $line);
    my $link = ($file eq '') ? "$SELF_URL" : "$file";
    $link .= '?'; 
    $link .= "$mp_name=$k&" if ($k ne '');

    $self->{menu} .= "<th";
    if ($FORM{$mp_name} eq $k && $file eq '') {
      $self->{menu} .= " bgcolor=$_COLORS[3]><a href='$link$ex_params'>". $menu->{"$line"} ."</a></th>";
     }
    else {
      $self->{menu} .= "><a href='$link'>". $menu->{"$line"} ."</a></th>\n";
     }

 }
  $self->{menu} .= "</tr>\n"; 
}

 $self->{menu} .= "</table>\n";


 return $self->{menu};
}



#*******************************************************************
# heder off main page
# header()
#*******************************************************************
sub header {
 my $self = shift;
 my($attr)=@_;
 my $admin_name=$ENV{REMOTE_USER};
 my $admin_ip=$ENV{REMOTE_ADDR};
 $self->{header} = "Content-Type: text/html\n\n";
# my @_C;
 if ($COOKIES{colors} ne '') {
   @_COLORS = split(/, /, $COOKIES{colors});
#    @_C = split(/, /, $COOKIES{colors});
  }

  my $JAVASCRIPT = ($attr->{PATH}) ? "$attr->{PATH}functions.js" : "functions.js";

#print "Content-Type: text/html\n\n";
# foreach my $line (@_C) {
# 	 print "$line <br>\n";
#  }
  
 my $css = css();


my $CHARSET=(defined($attr->{CHARSET})) ? $attr->{CHARSET} : 'windows-1251';

$self->{header} .= qq{<!doctype html public "-//W3C//DTD HTML 3.2 Final//EN">
<html>
<head>
 <META HTTP-EQUIV="Cache-Control" content="no-cache">
 <META HTTP-EQUIV="Pragma" CONTENT="no-cache">
 <meta http-equiv="Content-Type" content="text/html; charset=$CHARSET">
 <meta name="Author" content="~AsmodeuS~">
};

$self->{header} .= $css;
$self->{header} .= 
"<script src=\"$JAVASCRIPT\" type=\"text/javascript\" language=\"javascript\"></script>\n".
q{ 
<title>~AsmodeuS~ Billing System</title>
</head>} .
"<body style='margin: 0' bgcolor=$_COLORS[10] text=$_COLORS[9] link=$_COLORS[8]  vlink=$_COLORS[7]>\n";

 return $self->{header};
}

#********************************************************************
#
# css()
#********************************************************************
sub css { 

my $css = "
<style type=\"text/css\">

body {
  background-color: $_COLORS[10];
  color: $_COLORS[9];
  font-family: Arial, Tahoma, Verdana, Helvetica, sans-serif;
  font-size: 14px;
  /* this attribute sets the basis for all the other scrollbar colors (Internet Explorer 5.5+ only) */
}

th.small {
  color: $_COLORS[9];
  font-size: 10px;
  height: 10;
}

td.small {
  color: $_COLORS[9];
  height: 1;
}

th, li {
  color: $_COLORS[9];
  height: 24;
  font-family: Arial, Tahoma, Verdana, Helvetica, sans-serif;
  font-size: 12px;
}

td {
  color: $_COLORS[9];
  font-family: Arial, Tahoma, Verdana, Helvetica, sans-serif;
  height: 20;
  font-size: 14px;
}

form {
  font-family: Tahoma,Verdana,Arial,Helvetica,sans-serif;
  font-size: 12px;
}

.button {
  font-family:  Arial, Tahoma,Verdana, Helvetica, sans-serif;
  background-color: #003366;
  color: #fcdc43;
  font-size: 12px;
  font-weight: bold;
}

input, textarea {
	font-family : Verdana, Arial, sans-serif;
	font-size : 12px;
	color : $_COLORS[9];
	border-color : #9F9F9F;
	border : 1px solid #9F9F9F;
	background : $_COLORS[2];
}

select {
	font-family : Verdana, Arial, sans-serif;
	font-size : 12px;
	color : $_COLORS[9];
	border-color : #C0C0C0;
	border : 1px solid #C0C0C0;
	background : $_COLORS[2];
}

TABLE.border {
  border-color : #99CCFF;
  border-style : solid;
  border-width : 1px;
}
</style>";

 return $css;
}


#**********************************************************
# table
#**********************************************************
sub table {
 my $class = shift;
 my($attr)=@_;
 my $self = { };

 bless($self, $class);

 
 my $width = (defined($attr->{width})) ? "width=$attr->{width}" : '';
 my $border = (defined($attr->{border})) ? "border=$attr->{border}" : '';

 if (defined($attr->{rowcolor})) {
     $self->{rowcolor} = $attr->{rowcolor};
   }  


 if (defined($attr->{rows})) {
    my $rows = $attr->{rows};
    foreach my $line (@$rows) {
      $self->addrow(@$line);
     }
  }

 if (defined($attr->{caption})) {
 	 $self->{table} = "<b>$attr->{caption}</b><br>". $self->{table}; 
  }


 $self->{table} = "<TABLE $width cellspacing=0 cellpadding=0 border=0>";
 
 if (defined($attr->{caption})) {
   $self->{table} .= "<TR><TD bgcolor=$_COLORS[1] align=right><b>$attr->{caption}</b></td></tr>\n";
  }

 $self->{table} .= "<TR><TD bgcolor=$_COLORS[4]>
               <TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n";


 if (defined($attr->{title})) {
 	 $self->{table} .= $self->table_title($SORT, $DESC, $PG, $OP, $attr->{title}, $attr->{qs});
  }
 elsif(defined($attr->{title_plain})) {
   $self->{table} .= $self->table_title_plain($attr->{title_plain});
  }

 if (defined($attr->{cols_align})) {
   $self->{table} .= "<COLGROUP>";
   my $cols_align = $attr->{cols_align};
   foreach my $line (@$cols_align) {
     $self->{table} .= "<COL align=$line>\n";
     <COL align=right>
    }
   $self->{table} .= "</COLGROUP>\n";
  }
 
 if (defined($attr->{pages})) {
 	   my $op;
 	   if($FORM{index}) {
 	   	 $op = "index=$FORM{index}";
 	    }
 	   else {
 	   	 $op = "op=$OP";
 	    }
 	   my %ATTR = ();
 	   if (defined($attr->{recs_on_page})) {
 	   	 $ATTR{recs_on_page}=$attr->{recs_on_page};
 	     }
 	   $self->{pages} =  $self->pages($attr->{pages}, "$op$attr->{qs}", { %ATTR });
	 } 
 return $self;
}

#*******************************************************************
# addrows()
#*******************************************************************
sub addrow {
  my $self = shift;
  my (@row) = @_;


  if (defined($self->{rowcolor})) {
    $bg = $self->{rowcolor};
   }  
  else {
  	$bg = ($bg eq $_COLORS[1]) ? $_COLORS[2] : $_COLORS[1];
   }
  
  my $extra=(defined($self->{extra})) ? $self->{extra} : '';

  $row_number++;
  
  $self->{rows} .= "<tr bgcolor=$bg  onmouseover=\"setPointer(this, $row_number, 'over', '$bg', '$_COLORS[3]', '$_COLORS[0]');\" onmouseout=\"setPointer(this, $row_number, 'out', '$bg', '$_COLORS[3]', '$_COLORS[0]');\" onmousedown=\"setPointer(this, $row_number, 'click', '$bg', '$_COLORS[3]', '$_COLORS[0]');\">";
  foreach my $val (@row) {
     $self->{rows} .= "<td bgcolor=$bg $extra>$val</td>";
   }
  $self->{rows} .= "</tr>\n";
  return $self->{rows};
}

#*******************************************************************
# addrows()
#*******************************************************************
sub addtd {
  my $self = shift;
  my (@row) = @_;

  if (defined($self->{rowcolor})) {
    $bg = $self->{rowcolor};
   }  
  else {
  	$bg = ($bg eq $_COLORS[1]) ? $_COLORS[2] : $_COLORS[1];
   }
  
  my $extra=(defined($self->{extra})) ? $self->{extra} : '';


  $self->{rows} .= "<tr bgcolor=$bg>";
  foreach my $val (@row) {
     $self->{rows} .= "$val";
   }

  $self->{rows} .= "</tr>\n";
  return $self->{rows};
}


#*******************************************************************
# Extendet add rows
# td()
#
#*******************************************************************
sub td {
  my $self = shift;
  my ($value, $attr) = @_;
  my $extra='';
  
  while(my($k, $v)=each %$attr ) {
    $extra.=" $k=$v";
   }

  my $td = "<td $extra>$value</td>";

  return $td;
}


#*******************************************************************
# title_plain($caption)
# $caption - ref to caption array
#*******************************************************************
sub table_title_plain {
  my $self = shift;
  my ($caption)=@_;
  $self->{table_title} = "<tr bgcolor=$_COLORS[0]>";
	
  foreach my $line (@$caption) {
    $self->{table_title} .= "<th class=table_title>$line</th>";
   }
	
  $self->{table_title} .= "</tr>\n";
  return $self->{table_title};
}

#*******************************************************************
# Show table column  titles with wort derectives
# Arguments 
# table_title($sort, $desc, $pg, $get_op, $caption, $qs);
# $sort - sort column
# $desc - DESC / ASC
# $pg - page id
# $caption - array off caption
#*******************************************************************
sub table_title  {
  my $self = shift;
  my ($sort, $desc, $pg, $get_op, $caption, $qs)=@_;
  my ($op);
  my $img='';

#  print "$sort, $desc, $pg, $op, $caption, $qs";

  $self->{table_title} = "<tr bgcolor=$_COLORS[0]>";
  my $i=1;
  foreach my $line (@$caption) {
     $self->{table_title} .= "<th  class=table_title>$line ";
     if ($line ne '-') {
         if ($sort != $i) {
             $img = 'sort_none.png';
           }
         elsif ($desc eq 'DESC') {
             $img = 'down_pointer.png';
             $desc='';
           }
         elsif($sort > 0) {
             $img = 'up_pointer.png';
             $desc='DESC';
           }
         
         if ($FORM{index}) {
         	  $op="index=$FORM{index}";
         	}
         else {
         	  $op="op=$get_op";
          }

         $self->{table_title} .= $self->button("<img src='$IMG_PATH/$img' width=12 height=10 border=0 alt='Sort' title=sort>", "$op$qs&pg=$pg&sort=$i&desc=$desc");
       }
     else {
         $self->{table_title} .= "$line";
       }

     $self->{table_title} .= "</th>\n";
     $i++;
   }
 $self->{table_title} .= "</tr>\n";

 return $self->{table_title};
}



#**********************************************************
# show
#**********************************************************
sub show  {
  my $self = shift;	
  $self->{show} .= $self->{table};
  $self->{show} .= $self->{rows}; 
  $self->{show} .= "</table></td></tr></table>\n";

  if (defined($self->{pages})) {
 	   $self->{show} =  '<br>'.$self->{pages} . $self->{show} . $self->{pages} .'<br>';
 	 } 

  return $self->{show};
}

#**********************************************************
#
# del_button($op, $del, $message, $attr)
#**********************************************************
sub button {
  my $self = shift;
  my ($name, $params, $attr)=@_;
  my $ex_prams = (defined($attr->{ex_params})) ? $attr->{ex_params} : '';
  my $ex_attr = '';
  
  $params = "$SELF_URL?$params";
  $params = $attr->{JAVASCRIPT} if (defined($attr->{JAVASCRIPT}));
  $params =~ s/ /%20/g;
  $params =~ s/&/&amp;/g;
  

 
  
  $ex_attr=" TITLE='$attr->{TITLE}'" if (defined($attr->{TITLE}));
  my $message = (defined($attr->{MESSAGE})) ? "onclick=\"return confirmLink(this, '$attr->{MESSAGE}')\"" : '';


  my $button = "<A href=\"$params\" $ex_attr $message>$name</a>";

  return $button;
}

#*******************************************************************
# Show message box
# message($self, $type, $caption, $message)
# $type - info, err
#*******************************************************************
sub message {
 my $type = shift; #info; err
 my $caption = shift;
 my $message = shift;	
 my $head = '';
 
 if ($type eq 'err') {
   $head = "<tr><th bgcolor='#FF0000'>$caption</th></tr>\n";
  }
 elsif ($type eq 'info') {
   $head = "<tr><th bgcolor='$_COLORS[0]'>$caption</th></tr>\n";
  }  
 
print << "[END]";
<br>
<table width=400 border=0 cellpadding="0" cellspacing="0">
<tr><td bgcolor=$_COLORS[9]>
<table width=100% border=0 cellpadding="2" cellspacing="1">
<tr><td bgcolor=$_COLORS[1]>

<table width=100%>
$head
<tr><td bgcolor=$_COLORS[1]>$message</td></tr>
</table>

</td></tr>
</table>
</td></tr>
</table>
<br>
[END]
}


#*******************************************************************
# Make pages and count total records
# pages($count, $argument)
#*******************************************************************
sub pages {
 my $self = shift;
 my ($count, $argument, $attr) = @_;

 if (defined($attr->{recs_on_page})) {
 	 $PAGE_ROWS = $attr->{recs_on_page};
  }

 my $begin=0;   


 $self->{pages} = '';
 $begin = ($PG - $PAGE_ROWS * 3 < 0) ? 0 : $PG - $PAGE_ROWS * 3;

for(my $i=$begin; ($i<=$count && $i < $PG + $PAGE_ROWS * 10); $i+=$PAGE_ROWS) {
   $self->{pages} .= ($i == $PG) ? "<b>$i</b>:: " : $self->button($i, "$argument&pg=$i"). ':: ';
}
 
 return $self->{pages};
}



#*******************************************************************
# Make data field
# date_fld($base_name)
#*******************************************************************
sub date_fld  {
 my $self = shift;
 my ($base_name, $attr) = @_;
 
 my $MONTHES = $attr->{MONTHES};

 my($sec,$min,$hour,$mday,$mon,$curyear,$wday,$yday,$isdst) = localtime(time);

 my $day = $FORM{$base_name.'D'} || 1;
 my $month = $FORM{$base_name.'M'} || $mon;
 my $year = $FORM{$base_name.'Y'} || $curyear + 1900;



# print "$base_name -";
my $result  = "<SELECT name=". $base_name ."D>";
for (my $i=1; $i<=31; $i++) {
   $result .= sprintf("<option value=%.2d", $i);
   $result .= ' selected' if($day == $i ) ;
   $result .= ">$i\n";
 }	
$result .= '</select>';


$result  .= "<SELECT name=". $base_name ."M>";

my $i=0;
foreach my $line (@$MONTHES) {
   $result .= sprintf("<option value=%.2d", $i);
   $result .= ' selected' if($month == $i ) ;
   
   $result .= ">$line\n";
   $i++
}

$result .= '</select>';

$result  .= "<SELECT name=". $base_name ."Y>";
for ($i=2001; $i<=$curyear + 1900; $i++) {
   $result .= "<option value=$i";
   $result .= ' selected' if($year eq $i ) ;
   $result .= ">$i\n";
 }	
$result .= '</select>';

return $result ;
}

#**********************************************************
# log_print()
#**********************************************************
sub log_print {
 my $self = shift;
 my ($level, $text) = @_;	

 if($debug < $log_levels{$level}) {
     return 0;	
  }

print << "[END]";
<table width=640 border=0 cellpadding="0" cellspacing="0">
<tr><td bgcolor=#00000>
<table width=100% border=0 cellpadding="2" cellspacing="1">
<tr><td bgcolor=FFFFFF>

<table width=100%>
<tr bgcolor=$_COLORS[3]><th>
$level
</th></tr>
<tr><td>
$text
</td></tr>
</table>

</td></tr>
</table>
</td></tr>
</table>
[END]
}

#**********************************************************
# show tamplate
# tpl_show
# 
# template
# variables_ref
# atrr [EX_VARIABLES]
#**********************************************************
sub tpl_show {
  my $self = shift;
  my ($tpl, $variables_ref, $attr) = @_;	
  
#  my $i=0;
#  while(my($k, $v)=each %$variables_ref) {
#  	print "$k $v";
#   }
#  return 0;
  
  while($tpl =~ /\%(\w+)\%/g) {
#    print "-$1-<br>\n";
    my $var = $1;
    if (defined($variables_ref->{$var})) {
    	$tpl =~ s/\%$var\%/$variables_ref->{$var}/g;
    }
    else {
      $tpl =~ s/\%$var\%//g;
    }
  }


  if ($attr->{notprint}) {
  	return $tpl;
   }
	else { 
	 print $tpl;
	}
}

#**********************************************************
# test function
#  %FORM     - Form
#  %COOKIES  - Cookies
#  %ENV      - Enviropment
# 
#**********************************************************
sub test {

 my $output = '';

#print "<table border=1>
#<tr><td colspan=2>FORM</td></tr>
#<tr><td>index</td><td>$index</td></td></tr>
#<tr><td>root_index</td><td>root_index</td></td></tr>\n";	
  while(my($k, $v)=each %FORM) {
  	$output .= "$k | $v\n" if ($k ne '__BUFFER');
    #print "<tr><td>$k</td><td>$v</td></tr>\n";	
   }
#print "</table>\n";
 $output .= "\n";
#print "<br><table border=1>
#<tr><td colspan=2>COOKIES</td></tr>
#<tr><td>index</td><td>$index</td></td></tr>\n";	
  while(my($k, $v)=each %COOKIES) {
    $output .= "$k | $v\n";
    #print "<tr><td>$k</td><td>$v</td></tr>\n";	
   }
#print "</table>\n";


#print "<br><table border=1>\n";
#  while(my($k, $v)=each %ENV) {
#    print "<tr><td>$k</td><td>$v</td></tr>\n";	
#   }
#print "</table>\n";

#print "<br><table border=1>\n";
#  while(my($k, $v)=each %conf) {
#    print "<tr><td>$k</td><td>$v</td></tr>\n";	
#   }
#print "</table>\n";
#

print "<a href='#' title='$output'><font color=$_COLORS[1]>Debug</font></a>\n";

}


#**********************************************************
# letters_list();
#**********************************************************
sub letters_list {
 my ($self, $attr) = @_;
 
 my $pages_qs = $attr->{pages_qs} if (defined($attr->{pages_qs}));

  
my $letters = "<a href='$SELF_URL?index=$index'>All</a> ::";
for (my $i=97; $i<123; $i++) {
  my $l = chr($i);
  if ($FORM{letter} eq $l) {
     $letters .= "<b>$l </b>";
   }
  else {
     #$pages_qs = '';
     $letters .= "<a href='$SELF_URL?index=$index&letter=$l$pages_qs'>$l</a> ";
   }
 }

 return $letters;
}

1