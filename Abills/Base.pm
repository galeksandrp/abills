package Abills::Base;


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
 %int
 %variants
 %conf
);

use Exporter;

$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw( &radius_log
  &null
  &convert
  &parse_arguments
  &session_spliter
  &int2ip
  &ip2int
  &int2byte
  &sec2time
  &int2ml
  &show_log
  &mk_unique_value
  &decode_base64
  &check_time
  &get_radius_params
  &test_radius_returns
  &ping
  &sendmail
  %variants
  %int
 );

@EXPORT_OK = ();
%EXPORT_TAGS = ();

#**********************************************************
# Null function
#
#**********************************************************
sub null {
  return 0;	
}


#**********************************************************
# Converter
#   Attributes
#     text2html - convert text to HTML
#
#
# convert
#**********************************************************
sub convert {
	my ($text, $attr)=@_;
	
	if(defined($attr->{text2html})) {
		 $text =~ s/\n/<br>/gi;
   }
	elsif(defined($attr->{win2koi})) {
		 $text = wintokoi($text);
	 }
	
	return $text;
}


# $version = '0.01';
# ��������� ���������������� ����������, ����� wintokoi(<����������>)

sub wintokoi {
    my $pvdcoderwin=shift;
    $pvdcoderwin=~ tr/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/\xE1\xE2\xF7\xE7\xE4\xE5\xF6\xFA\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFE\xFB\xFD\xFF\xF9\xF8\xFC\xE0\xF1\xC1\xC2\xD7\xC7\xC4\xC5\xD6\xDA\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDE\xDB\xDD\xDF\xD9\xD8\xDC\xC0\xD1/;
return $pvdcoderwin;
}

sub koitowin {
    my $pvdcoderwin=shift;
    $pvdcoderwin=~ tr/\xE1\xE2\xF7\xE7\xE4\xE5\xF6\xFA\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFE\xFB\xFD\xFF\xF9\xF8\xFC\xE0\xF1\xC1\xC2\xD7\xC7\xC4\xC5\xD6\xDA\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDE\xDB\xDD\xDF\xD9\xD8\xDC\xC0\xD1/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/;
return $pvdcoderwin;
}

# ��������� ���������������� ����������, ����� wintoiso(<����������>)
sub wintoiso {
    my $pvdcoderiso=shift;
    $pvdcoderiso=~ tr/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/;
return $pvdcoderiso;
}

sub isotowin {
    my $pvdcoderiso=shift;
    $pvdcoderiso=~ tr/\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/;
return $pvdcoderiso;
}

# ��������� ���������������� ����������, ����� wintodos(<����������>)
sub wintodos {
    my $pvdcoderdos=shift;
    $pvdcoderdos=~ tr/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/;
return $pvdcoderdos;
}

sub dostowin {
    my $pvdcoderdos=shift;
    $pvdcoderdos=~ tr/\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/;
return $pvdcoderdos;
}


#*******************************************************************
# Parse comand line arguments
# parse_arguments(@$argv)
#*******************************************************************
sub parse_arguments {
    my ($argv) = @_;
    
    my %args = ();

    foreach my $line (@$argv) {
    	if($line =~ /=/) {
    	   my($k, $v)=split(/=/, $line, 2);
    	   $args{"$k"}=$v;
    	 }
    	else {
    		$args{"$line"}='y';
    	 }
     }
  return \%args;
}

#********************************************************************
# sendmail($from, $to, $subject, $message, $charset, $priority)
# MAil Priorities:
#
#
#
#
#********************************************************************
sub sendmail {
  my ($from, $to, $subject, $message, $charset, $priority, $attr) = @_;
  my $SENDMAIL = (defined($attr->{SENDMAIL_PATH})) ? $attr->{SENDMAIL_PATH} : '/usr/sbin/sendmail';
  
  if ($attr->{TEST}) {
    print "To: $to\n";
    print "From: $from\n";
    print "Content-Type: text/plain; charset=$charset\n";
    print "X-Priority: $priority\n" if ($priority ne '');
    print "Subject: $subject \n\n";
    print "$message";
    return 0;
   }
  
  open(MAIL, "| $SENDMAIL -t $to") || die "Can't open file '$SENDMAIL' $!\n";
    print MAIL "To: $to\n";
    print MAIL "From: $from\n";
    print MAIL "Content-Type: text/plain; charset=$charset\n";
    print MAIL "X-Priority: $priority\n" if ($priority ne '');
    print MAIL "Subject: $subject \n\n";
    print MAIL "$message";
  close(MAIL);

  return 0;
}
#*******************************************************************
# show log
# show_log($uid, $type, $attr)
#  Attributes
#   PAGE_ROWS
#   PG
#   DATE
#   LOG_TYPE
#*******************************************************************
sub show_log {
  my ($login, $logfile, $attr) = @_;

  my $output = ''; 
  my @err_recs = ();
  my %types = ();

  my $PAGE_ROWS = (defined($attr->{PAGE_ROWS}))? $attr->{PAGE_ROWS} : 100;
  my $PG = (defined($attr->{PG}))? $attr->{PG} : 1;

  open(FILE, "$logfile") || die "Can't open log file '$logfile' $!\n";
   while(<FILE>) {

      my ($date, $time, $log_type, $action, $user, $message)=split(/ /, $_, 6);

      if (defined($attr->{LOG_TYPE}) && $log_type ne $attr->{LOG_TYPE}) {
      	#print "0";
      	next;
       }

      if (defined($attr->{DATE}) && $date ne $attr->{DATE}) {
      	#print "0";
      	next;
       }
      
      
      
      $user =~ s/\[|\]//g;
      if ($login ne "") {
      	if($login eq $user) {
     	    push @err_recs, $_;
     	    $types{$log_type}++;
         }
       }
      else {
     	  push @err_recs, $_;
     	  $types{$log_type}++;
       }
     }
 close(FILE);

 my $total  = 0;
 $total = $#err_recs;
 my @list;

 return (\@list, \%types, $total) if ($total < 1);

  
# my $output;
 my $i = 0;
 for ($i = $total; $i>=$total - $PAGE_ROWS && $i >= 0; $i--) {
    push @list, "$err_recs[$i]";
#    $output .= "$i / $err_recs[$i]<br>";
   }
 
# print "$output";
 $total++;
 return (\@list, \%types, $total);
} 


#*******************************************************************
# Make unique value
# mk_unique_value($size)
#*******************************************************************
sub mk_unique_value {
   my ($passsize) = @_;
   my $symbols = "qwertyupasdfghjikzxcvbnmQWERTYUPASDFGHJKLZXCVBNM23456789";

   my $value = '';
   my $random = '';
   my $i=0;
   
   my $size = length($symbols);
   srand();
   for ($i=0;$i<$passsize;$i++) {
     $random = int(rand($size));
     $value .= substr($symbols,$random,1);
    }
  return $value; 
}




#*******************************************************************
# Convert integer value to ip
# int2ip($i);
#*******************************************************************
sub int2ip {
my $i = shift;
my (@d);
$d[0]=int($i/256/256/256);
$d[1]=int(($i-$d[0]*256*256*256)/256/256);
$d[2]=int(($i-$d[0]*256*256*256-$d[1]*256*256)/256);
$d[3]=int($i-$d[0]*256*256*256-$d[1]*256*256-$d[2]*256);
 return "$d[0].$d[1].$d[2].$d[3]";
}


#*******************************************************************
# Convert ip to int
# ip2int($ip);
#*******************************************************************
sub ip2int($){
  my $ip = shift;
  return unpack("N", pack("C4", split( /\./, $ip)));
}



#********************************************************************
# Second to date
# sec2time()
# return $sec,$minute,$hour,$day
#********************************************************************
sub sec2time {
   my ($value, $attr) = @_;
   my($a,$b,$c,$d);

    $a=int($value % 60);
    $b=int(($value % 3600) / 60);
    $c=int(($value % (24*3600)) / 3600);
    $d=int($value / (24 * 3600));

 if($attr->{str}) {
   return "+$d $c:$b:$a";
  }
 else {
    return($a,$b,$c,$d);
  }
}

#********************************************************************
# Convert Integer to byte definision
# int2byte($val, $attr)
# $KBYTE_SIZE - SIze of kilobyte (Standart 1024)
#********************************************************************
sub int2byte {
 my ($val, $attr) = @_;
 
 my $KBYTE_SIZE = 1024;
 $KBYTE_SIZE = int($attr->{KBYTE_SIZE}) if (defined($attr->{KBYTE_SIZE}));
 my $MEGABYTE = $KBYTE_SIZE * $KBYTE_SIZE;
 my $GIGABYTE = $KBYTE_SIZE * $KBYTE_SIZE * $KBYTE_SIZE;


 if($val > $GIGABYTE)      { $val = sprintf("%.2f GB", $val / $GIGABYTE);   }  # 1024 * 1024 * 1024
 elsif($val > $MEGABYTE)   { $val = sprintf("%.2f MB", $val / $MEGABYTE);   }  # 1024 * 1024
 elsif($val > $KBYTE_SIZE) { $val = sprintf("%.2f Kb", $val / $KBYTE_SIZE); }
 else { $val .= " Bt"; }

 return $val;
}


#********************************************************************
# integet to money in litteral format
# int2ml($array);
#********************************************************************
sub int2ml {
 my $array = shift;
 my $ret = '';

 my @ones = ('������', '������', '������', '������', '��������');
 my @twos = ('�����', '������', '�������', '�������', '���������');
 my @fifth = ('�������', '�����', '�������', '�������', '���������');

 my @one = ('', '����', '���', '���', '������', '�\'���', '�����', '��', '���', '���\'���');
 my @onest = ('', '����', '��');
 my @ten = ('', '', '��������', '��������', '�����', '�\'�������', '���������', '�������', '��������', '���\'������');
 my @tens = ('������', '����������', '����������', '����������', '������������', '�\'���������', '�����������', '���������', '����������', '���\'���������');
 my @hundred = ('', '���', '����', '������', '���������', '�\'�����', '�������', '�����', '������', '���\'�����');

 $array =~ tr/0-9,.//cd;
 my $tmp = $array;
 my $count = ($tmp =~ tr/.,//);

#print $array,"\n";
if ($count > 1) {
  $ret .= "i2s.pl: bad integer format\n";
  return 1;
}

my $second = "00";
my ($first, $i, @first, $j);

if (!$count) {
  $first = $array;
} else {
  $first = $second = $array;
  $first =~ s/(.*)(\..*)/$1/;
  $second =~ s/(.*)(\.)(\d\d)(.*)/$3/;
}

$count = int ((length $first) / 3);
my $first_length = length $first;

for ($i = 1; $i <= $count; $i++) {
  $tmp = $first;
  $tmp =~ s/(.*)(\d\d\d$)/$2/;
  $first =~ s/(.*)(\d\d\d$)/$1/;
  $first[$i] = $tmp;
}

if ($count < 4 && $count * 3 < $first_length) {
  $first[$i] = $first;
  $first_length = $i;
} else {
  $first_length = $i - 1;
}

for ($i = $first_length; $i >=1; $i--) {
  $tmp = 0;
  for ($j = length ($first[$i]); $j >= 1; $j--) {
    if ($j == 3) {
      $tmp = $first[$i];
      $tmp =~ s/(^\d)(\d)(\d$)/$1/;
      $ret .= $hundred[$tmp];
      if ($tmp > 0) {
        $ret .= " ";
      }
    }
    if ($j == 2) {
      $tmp = $first[$i];
      $tmp =~ s/(.*)(\d)(\d$)/$2/;
      if ($tmp != 1) {  
        $ret .= $ten[$tmp];
        if ($tmp > 0) {
          $ret .= " ";
        }
      }
    }
    if ($j == 1) {
      if ($tmp != 1) {
        $tmp = $first[$i];
        $tmp =~ s/(.*)(\d$)/$2/;
        if ((($i == 1) || ($i == 2)) && ($tmp == 1 || $tmp == 2)) {
          $ret .= $onest[$tmp];
          if ($tmp > 0) {
            $ret .= " ";
          }
        } else {
            $ret .= $one[$tmp];
            if ($tmp > 0) {
              $ret .= " ";
            }
        }
      } else {
        $tmp = $first[$i];
        $tmp =~ s/(.*)(\d$)/$2/;
        $ret .= $tens[$tmp];
        if ($tmp > 0) {
          $ret .= " ";
        }
        $tmp = 5;
      }
    }
    
  }

  if ($tmp == 1) {
    $ret .= $ones[$i - 1] . " ";
  }
  elsif ($tmp > 1 && $tmp < 5) {
    $ret .= $twos[$i - 1] . " ";
  }
  elsif ($tmp > 4) {
    $ret .= $fifth[$i - 1] . " ";
  }
  else {
    $ret .= $fifth[0] . " ";
  }
}

if ($second ne '') {
 $ret .= "$second ���.\n";
} else {
 $ret .= "\n";
}
 
 return $ret;
}


##get recs from radwtmp
#
#=commnent
#struct radutmp {
#        char login[RUT_NAMESIZE];       /* Loginname (maybe modified) */
#        char orig_login[RUT_NAMESIZE];  /* Original loginname */
#        int  nas_port;                  /* Port on the terminal server */
#        char session_id[RUT_IDSIZE];    /* Radius session ID */
#                                        /* (last RUT_IDSIZE bytes at least)*/
#        unsigned int nas_address;       /* IP of portmaster. */
#        unsigned int framed_address;    /* SLIP/PPP address or login-host. */
#        int proto;                      /* Protocol. */
#        time_t time;                    /* Time the entry was last updated. */
#        time_t delay;                   /* Delay time of request */
#        int type;                       /* Type of entry (login/logout) */
#        char porttype;         /* Porttype (I=ISDN A=Async T=Async-ISDN) */
#        char res1,res2,res3;            /* Fills up to one int */
#        time_t duration;
#        char caller_id[RUT_PNSIZE];      /* calling station ID */
#        unsigned int realm_address;
#        char reserved[10];
#};
#=cut
#	
#my $packstring = "a32a32La16NNiIIiaaaaIa24La12";
#my $reclength = length(pack($packstring));
#open(D,"<$RADWTMP") or die "Couldn't open '$RADWTMP', $!";
#
#my %wtmp_info;
#while(sysread(D,my $rec,$reclength)) {
# my ($login, $orig_login, $nas_port, $session_id, $nas_address, $framed_address, $proto, $time, $delay, $type, 
#  $porttype, $res1, $res2, $res3, $duration, $caller_id, $realm_address, $reserved) = unpack($packstring,$rec);
# # 0 - logout; 1 - login
# if ($type == 1) {
#   $wtmp_info{"$session_id"}{login}=$login;
#   $wtmp_info{"$session_id"}{orig_login}=$orig_login;
#   $wtmp_info{"$session_id"}{nas_port}=$nas_port;
#   $wtmp_info{"$session_id"}{nas_address}=$nas_address;
#   $wtmp_info{"$session_id"}{framed_address}=$framed_address;
#   $wtmp_info{"$session_id"}{proto}=$proto;
#   $wtmp_info{"$session_id"}{time}=$time;
#   $wtmp_info{"$session_id"}{delay}=$delay;
#   $wtmp_info{"$session_id"}{type}=$type;
#   $wtmp_info{"$session_id"}{porttype}=$porttype;
#   $wtmp_info{"$session_id"}{res1}=$res1;
#   $wtmp_info{"$session_id"}{res2}=$res2;
#   $wtmp_info{"$session_id"}{res3}=$res3;
#   $wtmp_info{"$session_id"}{duration}=time-$time;
#   $wtmp_info{"$session_id"}{caller_id}=$caller_id;
#   $wtmp_info{"$session_id"}{realm_address}=$realm_address;
#   $wtmp_info{"$session_id"}{reserved}=$reserved;
#  }
# elsif ($type == 0) {
#  undef($wtmp_info{"$session_id"});
#=comment
#   $wtmp_info{$session_id}{login}=$login;
#   $wtmp_info{$session_id}{orig_login}=$orig_login;
#   $wtmp_info{$session_id}{nas_port}=$nas_port;
#   $wtmp_info{$session_id}{nas_address}=$nas_address;
#   $wtmp_info{$session_id}{framed_address}=$framed_address;
#   $wtmp_info{$session_id}{proto}=$proto;
#   $wtmp_info{$session_id}{time}=$time;
#   $wtmp_info{$session_id}{delay}=$delay;
#   $wtmp_info{$session_id}{type}=$type;
#   $wtmp_info{$session_id}{porttype}=$porttype;
#   $wtmp_info{$session_id}{res1}=$res1;
#   $wtmp_info{$session_id}{res2}=$res2;
#   $wtmp_info{$session_id}{res3}=$res3;
#   $wtmp_info{$session_id}{duration}=$duration;
#   $wtmp_info{$session_id}{caller_id}=$caller_id;
#   $wtmp_info{$session_id}{realm_address}=$realm_address;
#   $wtmp_info{$session_id}{reserved}=$reserved;
#=cut
#  }
#}
#
#close(D) or die "Couldn't close wtmp, $!";
# return %wtmp_info;
#}

#Get pppacct information
sub ppp_acct {
 my $ifc = shift;
 my $ppphost = shift;
 my $pppport = shift;
 $ifc =~ m/(\d+)/;
 
 print "$ifc - $1\n";
 my %res = ();
 $res{ifc}=$ifc;
 
 #print "pppctl -p 'c)ntro1' $ppphost:$pppport ! echo UPTIME OCTETSIN OCTETSOUT";
 my $result = `pppctl -p 'c)ntro1' $ppphost:$pppport ! echo USER UPTIME OCTETSIN OCTETSOUT`;
 
 ($res{name}, $res{uptime}, $res{in}, $res{out})=split(/ /, $result);
 return %res;
}


#**********************************************************
# decode_base64()
#**********************************************************
sub decode_base64 {
    local($^W) = 0; # unpack("u",...) gives bogus warning in 5.00[123]
    my $str = shift;
    my $res = "";

    $str =~ tr|A-Za-z0-9+=/||cd;            # remove non-base64 chars
    $str =~ s/=+$//;                        # remove padding
    $str =~ tr|A-Za-z0-9+/| -_|;            # convert to uuencoded format
    while ($str =~ /(.{1,60})/gs) {
        my $len = chr(32 + length($1)*3/4); # compute length byte
        $res .= unpack("u", $len . $1 );    # uudecode
    }

    return $res;
}


#*******************************************************************
# time check function
# check_time()
#*******************************************************************
sub check_time {
# return 0 if ($conf{time_check} == 0);

 my $begin_time = 0;
# BEGIN {
 #my $begin_time = 0;
 #Check the Time::HiRes module (available from CPAN)
   eval { require Time::HiRes; };
   if (! $@) {
     Time::HiRes->import(qw(gettimeofday));
     $begin_time = gettimeofday();
    }
#  }
 return $begin_time;
}


#*******************************************************************
# Get Argument params or Environment parameters  
# 
# FreeRadius enviropment parameters
#  CLIENT_IP_ADDRESS - 127.0.0.1
#  NAS_IP_ADDRESS - 127.0.0.1
#  USER_PASSWORD - xxxxxxxxx
#  SERVICE_TYPE - VPN
#  NAS_PORT_TYPE - Virtual
#  FRAMED_PROTOCOL - PPP
#  USER_NAME - andy
#  NAS_IDENTIFIER - media.intranet
#*******************************************************************
sub get_radius_params {
 my %RAD=();
 if ($#ARGV > 1) {
    foreach my $pair (@ARGV) {
        my ($side, $value) = split(/=/, $pair);
        $RAD{"$side"} = clearquotes("$value");
     }
  }
 else {
    while(my($k, $v)=each(%ENV)) {
      $RAD{$k}=clearquotes("$v");
     }
  }
 
 return \%RAD;
}


#*******************************************************************
# For clearing quotes
# clearquotes( $text )
#*******************************************************************
sub clearquotes {
 my $text = shift;
 $text =~ s/"//g;
 return "$text";
}

#*******************************************************************
# Get testing information
# test_radius_returns()
#*******************************************************************
sub test_radius_returns {
 my ($RAD)=@_;

 my $test = " ==ARGV\n";
 
 foreach my $line (@ARGV) {
    $test .= "  $line\n";
  }

 $test .= "\n\n ==ENV\n";
 while(my($k, $v)=each(%ENV)){
   $test .= "  $k - $v\n";
  }

 $test .= "\n\n ==RAD\n";
 my @sorted_rad = sort keys %$RAD; 

  foreach my $line (@sorted_rad) {
    $test .= "  $line - $RAD->{$line}\n";
  }

# log_print('LOG_DEBUG', "$test");
}

1;
