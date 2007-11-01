package Dv_Sessions;
# Stats functions
#



use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");

my $db;
my $admin;
my $CONF;

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  
  if ($CONF->{DELETE_USER}) {
    $self->del($CONF->{DELETE_USER}, '', '', '', { DELETE_USER => $CONF->{DELETE_USER} });
   }
  
  return $self;
}


#**********************************************************
# del
#**********************************************************
sub del {
  my $self = shift;
  my ($uid, $session_id, $nas_id, $session_start, $attr) = @_;

  if ($attr->{DELETE_USER}) {
    $self->query($db, "DELETE FROM dv_log WHERE uid='$attr->{DELETE_USER}';", 'do');
  }
  else {
    $self->query($db, "DELETE FROM dv_log 
     WHERE uid='$uid' and start='$session_start' and nas_id='$nas_id' and acct_session_id='$session_id';", 'do');
   }

  return $self;
}

#**********************************************************
# online()
#********************************************************** 
sub online_update {
	my $self = shift;
	my ($attr) = @_;


  my @SET_RULES = ();
  
  push @SET_RULES, 'lupdated=UNIX_TIMESTAMP()' if (defined($attr->{STATUS}) && $attr->{STATUS} == 5);
  
  if (defined($attr->{in})) {
   	push @SET_RULES, "acct_input_octets='$attr->{in}'";
   }

  if (defined($attr->{out})) {
  	push @SET_RULES, "acct_output_octets='$attr->{out}'";
   }


  if (defined($attr->{STATUS})) {
  	push @SET_RULES, "status='$attr->{STATUS}'";
   }


 
  my $SET = ($#SET_RULES > -1) ? join(', ', @SET_RULES)  : '';

  $self->query($db, "UPDATE dv_calls SET $SET
   WHERE 
    user_name='$attr->{USER_NAME}'
    and acct_session_id='$attr->{ACCT_SESSION_ID}'; ", 'do');

  return $self;
}

#**********************************************************
# online()
#********************************************************** 
sub online {
	my $self = shift;
	my ($attr) = @_;


  my @FIELDS_ALL = (
   'c.user_name',
   'pi.fio',
   'c.nas_port_id',
   'c.framed_ip_address',
   'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started))',

   'c.acct_input_octets', 'c.acct_output_octets', 'c.ex_input_octets', 'c.ex_output_octets',
 
   'c.CID',                           
   'c.acct_session_id',
   'dv.tp_id',
   'c.CONNECT_INFO',
   'dv.speed',   
   'c.sum',
   'c.status',

   'pi.phone',
   'INET_NTOA(c.framed_ip_address)',
   'u.uid',
   'INET_NTOA(c.nas_ip_address)',
   'if(company.name IS NULL, b.deposit, cb.deposit)',
   'u.credit',
   'if(date_format(c.started, "%Y-%m-%d")=curdate(), date_format(c.started, "%H:%i:%s"), c.started)',
   'c.nas_id',
   'UNIX_TIMESTAMP()-c.lupdated',
   'c.acct_session_time',
   'c.lupdated - UNIX_TIMESTAMP(c.started)'
   );


  my @RES_FIELDS = (0, 1, 2, 3, 4, 5, 6, 7, 8);
 
  if ($attr->{FIELDS}) {
  	@RES_FIELDS = @{ $attr->{FIELDS} };
   }
  
  my $fields = '';
  my $port_id=0;
  for(my $i=0; $i<=$#RES_FIELDS; $i++) {
  	$port_id=$i if ($RES_FIELDS[$i] == 2);
    $fields .= "$FIELDS_ALL[$RES_FIELDS[$i]], ";
   }


 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 my @WHERE_RULES = ();
 
 if (defined($attr->{ZAPED})) {
 	 push @WHERE_RULES, "c.status=2";
  }
 elsif ($attr->{ALL}) {

  }
 else {
   push @WHERE_RULES, "(c.status=1 or c.status>=3)";
  } 
 
 if (defined($attr->{USER_NAME})) {
 	 push @WHERE_RULES, "c.user_name='$attr->{USER_NAME}'";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }


 if (defined($attr->{FRAMED_IP_ADDRESS})) {
 	 push @WHERE_RULES, "framed_ip_address=INET_ATON('$attr->{FRAMED_IP_ADDRESS}')";
  }

 if (defined($attr->{NAS_ID})) {
 	 push @WHERE_RULES, "nas_id='$attr->{NAS_ID}'";
  }
 
 if ($attr->{FILTER}) {
 	 push @WHERE_RULES, "$FIELDS_ALL[$attr->{FILTER_FIELD}]='$attr->{FILTER}'";
  }
 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT  $fields
 
   pi.phone,
   INET_NTOA(c.framed_ip_address),
   u.uid,
   INET_NTOA(c.nas_ip_address),
   if(company.name IS NULL, b.deposit, cb.deposit),
   u.credit,
   if(date_format(c.started, '%Y-%m-%d')=curdate(), date_format(c.started, '%H:%i:%s'), c.started),
   UNIX_TIMESTAMP()-c.lupdated,
   c.status,
   c.nas_id,
   c.user_name,
   c.nas_port_id,
   c.acct_session_id,
   c.CID,
   dv.tp_id
   
 FROM dv_calls c
 LEFT JOIN users u     ON (u.id=user_name)
 LEFT JOIN dv_main dv  ON (dv.uid=u.uid)
 LEFT JOIN users_pi pi ON (pi.uid=u.uid)

 LEFT JOIN bills b ON (u.bill_id=b.id)
 LEFT JOIN companies company ON (u.company_id=company.id)
 LEFT JOIN bills cb ON (company.bill_id=cb.id)
 
 $WHERE
 ORDER BY $SORT $DESC;");

 my %dub_logins = ();
 my %dub_ports  = ();
 my %nas_sorted = ();


 if ($self->{TOTAL} < 1) {
 	 $self->{dub_ports} =\%dub_ports;
   $self->{dub_logins}=\%dub_logins;
   $self->{nas_sorted}=\%nas_sorted;

 	 return $self->{list};
  }


 my $list = $self->{list};
 
 my $nas_id_field = $#RES_FIELDS+10;
 
 foreach my $line (@$list) {

    
 	  $dub_logins{$line->[0]}++;
 	  $dub_ports{$line->[$nas_id_field]}{$line->[$port_id]}++;
    
    my @fields = ();
    for(my $i=0; $i<=$#RES_FIELDS+15; $i++) {
       push @fields, $line->[$i];
     }

    push( @{ $nas_sorted{"$line->[$nas_id_field]"} }, [ @fields ]);

  }
 
 


 $self->{dub_ports} =\%dub_ports;
 $self->{dub_logins}=\%dub_logins;
 $self->{nas_sorted}=\%nas_sorted;

 return $self->{list};	
}



#**********************************************************
# online_del()
#********************************************************** 
sub online_del {
	my $self = shift;
	my ($attr) = @_;

  if ($attr->{SESSIONS_LIST}) {
  	my $session_list = join("', '", @{$attr->{SESSIONS_LIST}});
  	$WHERE = "acct_session_id in ( '$session_list' )";
   }
  else {
    my $NAS_ID  = (defined($attr->{NAS_ID})) ? $attr->{NAS_ID} : '';
    my $NAS_PORT        = (defined($attr->{NAS_PORT})) ? $attr->{NAS_PORT} : '';
    my $ACCT_SESSION_ID = (defined($attr->{ACCT_SESSION_ID})) ? $attr->{ACCT_SESSION_ID} : '';
    $WHERE = "nas_id='$NAS_ID'
            and nas_port_id='$NAS_PORT' 
            and acct_session_id='$ACCT_SESSION_ID'";
   }

  $self->query($db, "DELETE FROM dv_calls WHERE $WHERE;", 'do');

  return $self;
}


#**********************************************************
# Add online session to log
# online2log()
#
#********************************************************** 
sub online2log {
	my $self = shift;
	my ($attr) = @_;

  $self->query($db, "SELECT c.user_name, ", 'do');
}


#**********************************************************
# Add online session to log
# online2log()
#********************************************************** 
sub online_info {
	my $self = shift;
	my ($attr) = @_;

   undef @WHERE_RULES; 

   if($attr->{NAS_ID}) {
   	  push @WHERE_RULES, "nas_id='$attr->{NAS_ID}'";
    }
   elsif (defined($attr->{NAS_IP_ADDRESS})) {
      push @WHERE_RULES, "nas_ip_address=INET_ATON('$attr->{NAS_IP_ADDRESS}')";
    }
   
   if (defined($attr->{NAS_PORT})) {
     push @WHERE_RULES, "nas_port_id='$attr->{NAS_PORT}'";
    }
   
   if (defined($attr->{ACCT_SESSION_ID})) {
     push @WHERE_RULES, "acct_session_id='$attr->{ACCT_SESSION_ID}'";
    }
 
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
  $self->query($db, "SELECT user_name, UNIX_TIMESTAMP(started), acct_session_time, 
   acct_input_octets,
   acct_output_octets,
   ex_input_octets,
   ex_output_octets,
   connect_term_reason,
   INET_NTOA(framed_ip_address),
   lupdated,
   nas_port_id,
   INET_NTOA(nas_ip_address),
      CID,
      CONNECT_INFO,
      acct_session_id,
      nas_id,
      started
      FROM dv_calls 
   $WHERE 
   ");


  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{USER_NAME}, 
   $self->{SESSION_START}, 
   $self->{ACCT_SESSION_TIME}, 
   $self->{ACCT_INPUT_OCTETS}, 
   $self->{ACCT_OUTPUT_OCTETS}, 
   $self->{ACCT_EX_INPUT_OCTETS}, 
   $self->{ACCT_EX_OUTPUT_OCTETS}, 
   $self->{CONNECT_TERM_REASON}, 
   $self->{FRAMED_IP_ADDRESS}, 
   $self->{LAST_UPDATE}, 
   $self->{NAS_PORT}, 
   $self->{NAS_IP_ADDRESS}, 
   $self->{CALLING_STATION_ID},
   $self->{CONNECT_INFO},
   $self->{ACCT_SESSION_ID},
   $self->{NAS_ID},
   $self->{ACCT_SESSION_STARTED}
    )= @{ $self->{list}->[0] };


  return $self;
}




#**********************************************************
# Session zap
#**********************************************************
sub zap {
  my $self=shift;
  my ($nas_id, $nas_port_id, $acct_session_id, $attr)=@_;
  
  if (! defined($attr->{ALL})) {
    $WHERE = "WHERE nas_id='$nas_id' and nas_port_id='$nas_port_id' and acct_session_id='$acct_session_id'";
   }

  $self->query($db, "UPDATE dv_calls SET status='2' $WHERE;", 'do');
  return $self;
}

#**********************************************************
# Session detail
#**********************************************************
sub session_detail {
 my $self = shift;	
 my ($attr) = @_;
 



 $WHERE = " and l.uid='$attr->{UID}'" if ($attr->{UID});
 

 $self->query($db, "SELECT 
  l.start,
  l.start + INTERVAL l.duration SECOND,
  l.duration,
  l.tp_id,
  tp.name,

  l.sent,
  l.recv,
  l.sent2,
  l.recv2,

  INET_NTOA(l.ip),
  l.CID,
  l.nas_id,
  n.name,
  n.ip,
  l.port_id,
  
  l.minp,
  l.kb,
  l.sum,

  l.bill_id,
  u.id,
  
  l.uid,
  l.acct_session_id,
  l.terminate_cause
 FROM (dv_log l, users u)
 LEFT JOIN tarif_plans tp ON (l.tp_id=tp.id) 
 LEFT JOIN nas n ON (l.nas_id=n.id) 
 WHERE l.uid=u.uid 
 $WHERE
 and acct_session_id='$attr->{SESSION_ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{START}, 
   $self->{STOP}, 
   $self->{DURATION}, 
   $self->{TP_ID}, 
   $self->{TP_NAME}, 
   $self->{SENT}, 
   $self->{RECV}, 
   $self->{SENT2},   #?
   $self->{RECV2},   #?
   $self->{IP}, 
   $self->{CID}, 
   $self->{NAS_ID}, 
   $self->{NAS_NAME},
   $self->{NAS_IP},
   $self->{NAS_PORT}, 

   $self->{TIME_TARIFF},
   $self->{TRAF_TARIFF},
   $self->{SUM}, 

   $self->{BILL_ID}, 
   $self->{LOGIN}, 

   $self->{UID}, 
   $self->{SESSION_ID},
   $self->{ACCT_TERMINATE_CAUSE}
    )= @$ar;


 return $self;
}

#**********************************************************
# detail_list()
#**********************************************************
sub detail_list {
	my $self = shift;
	my ($attr) = @_;

	
my $lupdate;
	
my $WHERE = ($attr->{SESSION_ID}) ? "and acct_session_id='$attr->{SESSION_ID}'" : '';	
my $GROUP;

if ($attr->{PERIOD} eq 'days') {
  $lupdate = "DATE_FORMAT(FROM_UNIXTIME(last_update), '%Y-%m-%d')";	
  $GROUP = $lupdate;
  $WHERE = '';
}
elsif($attr->{PERIOD} eq 'hours') {
  $lupdate = "DATE_FORMAT(FROM_UNIXTIME(last_update), '%Y-%m-%d %H')";	
  $GROUP = $lupdate;
  $WHERE = '';
}
elsif($attr->{PERIOD} eq 'sessions') {
	$WHERE = '';
  $lupdate = "FROM_UNIXTIME(last_update)";
  $GROUP='acct_session_id';
}
else {
  $lupdate = "FROM_UNIXTIME(last_update)";
  $GROUP = $lupdate;
}


 
 $self->query($db, "SELECT $lupdate, acct_session_id, nas_id, 
   sum(sent1), sum(recv1), sum(sent2), sum(recv2) 
  FROM s_detail 
  WHERE id='$attr->{LOGIN}' $WHERE
  GROUP BY $GROUP 
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;" );

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(DISTINCT $lupdate)
      FROM s_detail 
     WHERE id='$attr->{LOGIN}' $WHERE ;");
    
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }
	
	
return $list;
}


#**********************************************************
# Periods totals
# periods_totals($self, $attr);
#**********************************************************
sub periods_totals {
 my $self = shift;
 my ($attr) = @_;
 my $WHERE = '';
 
 if($attr->{UID})  {
   $WHERE .= ($WHERE ne '') ?  " and uid='$attr->{UID}' " : "WHERE uid='$attr->{UID}' ";
  }

 $self->query($db, "SELECT  
   sum(if(date_format(start, '%Y-%m-%d')=curdate(), sent, 0)), 
   sum(if(date_format(start, '%Y-%m-%d')=curdate(), recv, 0)), 
   SEC_TO_TIME(sum(if(date_format(start, '%Y-%m-%d')=curdate(), duration, 0))), 

   sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, sent, 0)),
   sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, recv, 0)),
   SEC_TO_TIME(sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, duration, 0))),

   sum(if((YEAR(curdate())=YEAR(start)) and (WEEK(curdate()) = WEEK(start)), sent, 0)),
   sum(if((YEAR(curdate())=YEAR(start)) and  WEEK(curdate()) = WEEK(start), recv, 0)),
   SEC_TO_TIME(sum(if((YEAR(curdate())=YEAR(start)) and WEEK(curdate()) = WEEK(start), duration, 0))),

   sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), sent, 0)), 
   sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), recv, 0)), 
   SEC_TO_TIME(sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), duration, 0))),
  
   sum(sent), sum(recv), SEC_TO_TIME(sum(duration))
   FROM dv_log $WHERE;");

  ($self->{sent_0}, 
      $self->{recv_0}, 
      $self->{duration_0}, 
      $self->{sent_1}, 
      $self->{recv_1}, 
      $self->{duration_1},
      $self->{sent_2}, 
      $self->{recv_2}, 
      $self->{duration_2}, 
      $self->{sent_3}, 
      $self->{recv_3}, 
      $self->{duration_3}, 
      $self->{sent_4}, 
      $self->{recv_4}, 
      $self->{duration_4}) =  @{ $self->{list}->[0] };
  
  for(my $i=0; $i<5; $i++) {
    $self->{'sum_'. $i } = $self->{'sent_' . $i } + $self->{'recv_' . $i};
  }

  return $self;	
}


#**********************************************************
#
#**********************************************************
sub prepaid_rest {
  my $self = shift;	
  my ($attr) = @_;
	
	$CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};
	
	#Get User TP and intervals
  $self->query($db, "select tt.id, i.begin, i.end, 
    if(u.activate<>'0000-00-00', u.activate, DATE_FORMAT(curdate(), '%Y-%m-01')), 
     tt.prepaid, 
    u.id, 
    tp.octets_direction, 
    u.uid, 
    dv.tp_id, 
    tp.name,
    tp.traffic_transfer_period
  from (users u,
        dv_main dv,
        tarif_plans tp,
        intervals i,
        trafic_tarifs tt)
WHERE
     u.uid=dv.uid
 and dv.tp_id=tp.id
 and tp.id=i.tp_id
 and i.id=tt.interval_id
 and u.uid='$attr->{UID}'
 ORDER BY 1
 ");

 if($self->{TOTAL} < 1) {
 	  return 1;
  }


 my %rest = (0 => 
             1 => );
 
 foreach my $line (@{ $self->{list} } ) {
   $rest{$line->[0]} = $line->[4];
  }

 
 $self->{INFO_LIST}=$self->{list};
 my $login = $self->{INFO_LIST}->[0]->[5];
 my $traffic_transfert = $self->{INFO_LIST}->[0]->[10];

 return 1 if ($attr->{INFO_ONLY});
 
 my $octets_direction = "sent + recv";
 my $octets_direction2 = "sent2 + recv2";
 my $octets_online_direction = "acct_input_octets + acct_output_octets";
 my $octets_online_direction2 = "ex_input_octets + ex_output_octets";
 
 if ($self->{INFO_LIST}->[0]->[6] == 1) {
   $octets_direction = "recv";
   $octets_direction2 = "recv2";
   $octets_online_direction = "acct_input_octets";
   $octets_online_direction2 = "ex_input_octets";
  }
 elsif ($self->{INFO_LIST}->[0]->[6] == 2) {
   $octets_direction  = "sent";
   $octets_direction2 = "sent2";
   $octets_online_direction = "acct_output_octets";
   $octets_online_direction2 = "ex_output_octets";
  }

 #Traffic transfert
 if ($traffic_transfert > 0) {
 	 #Get using traffic
   $self->query($db, "select  
     if($rest{0} > sum($octets_direction) / $CONF->{MB_SIZE}, $rest{0} - sum($octets_direction) / $CONF->{MB_SIZE}, 0),
     if($rest{0} > sum($octets_direction) / $CONF->{MB_SIZE}, $rest{1} - sum($octets_direction2) / $CONF->{MB_SIZE}, 0)
   FROM dv_log
   WHERE uid='$attr->{UID}'  and tp_id='$self->{INFO_LIST}->[0]->[8]' and
    (
     DATE_FORMAT(start, '%Y-%m-%d')>='$self->{INFO_LIST}->[0]->[3]' - INTERVAL $traffic_transfert MONTH 
     and DATE_FORMAT(start, '%Y-%m-%d')<='$self->{INFO_LIST}->[0]->[3]'
      ) 
   GROUP BY uid
   ;");


  if ($self->{TOTAL} > 0) {

    my ($in,
        $out
       ) =  @{ $self->{list}->[0] };
    $rest{0} += $in;
    $rest{1} += $out;

    $self->{INFO_LIST}->[0]->[4] += $in;
    $self->{INFO_LIST}->[0]->[4] += $out;
   }
 }

 
 #Check sessions
 #Get using traffic
 $self->query($db, "select  
  $rest{0} - sum($octets_direction) / $CONF->{MB_SIZE},
  $rest{1} - sum($octets_direction2) / $CONF->{MB_SIZE}
 FROM dv_log
 WHERE uid='$attr->{UID}' and DATE_FORMAT(start, '%Y-%m-%d')>='$self->{INFO_LIST}->[0]->[3]'
 GROUP BY uid
 ;");

 if ($self->{TOTAL} > 0) {
   ($rest{0}, 
    $rest{1} 
    ) =  @{ $self->{list}->[0] };
  }


 #Check online
 $self->query($db, "select 
  $rest{0} - sum($octets_online_direction) / $CONF->{MB_SIZE},
  $rest{1} - sum($octets_online_direction2) / $CONF->{MB_SIZE}
 FROM dv_calls
 WHERE user_name='$login' 
 GROUP BY user_name ;");

 if ($self->{TOTAL} > 0) {
   ($rest{0}, 
    $rest{1} 
    ) =  @{ $self->{list}->[0] };
  }
 
 $self->{REST}=\%rest;
  
 return 1;
}

#**********************************************************
# List
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 @WHERE_RULES = (); 
 
  %{$self->{SESSIONS_FIELDS}} = (LOGIN           => 'u.id', 
                                 START           => 'l.start', 
                                 DURATION        => 'SEC_TO_TIME(l.duration)', 
                                 TP              => 'l.tp_id',
                                 SENT            => 'l.sent', 
                                 RECV            => 'l.recv', 
                                 CID             => 'l.CID', 
                                 NAS_ID          => 'l.nas_id', 
                                 IP_INT          => 'l.ip', 
                                 SUM             => 'l.sum', 
                                 IP              => 'INET_NTOA(l.ip)', 
                                 ACCT_SESSION_ID => 'l.acct_session_id', 
                                 UID             => 'l.uid', 
                                 START_UNIX_TIME => 'UNIX_TIMESTAMP(l.start)',
                                 DURATION_SEC    => 'l.duration',
                                 SEND            => 'l.sent2', 
                                 RECV            => 'l.recv2');
 
#UID
 if ($attr->{UID}) {
    push @WHERE_RULES, "l.uid='$attr->{UID}'";
  }
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
  }


 if ($attr->{LIST_UIDS}) {
   push @WHERE_RULES, "l.uid IN ($attr->{LIST_UIDS})";
  }


#IP
 if ($attr->{IP}) {
   push @WHERE_RULES, "l.ip=INET_ATON('$attr->{IP}')";
  }

#NAS ID
 if ($attr->{NAS_ID}) {
   push @WHERE_RULES, "l.nas_id='$attr->{NAS_ID}'";
  }

#NAS ID
 if ($attr->{CID}) {
   if($attr->{CID}) {
     $attr->{CID} =~ s/\*/\%/ig;
     push @WHERE_RULES, "l.cid LIKE '$attr->{CID}'";
    }
   else {
     push @WHERE_RULES, "l.cid='$attr->{CID}'";
    }
  }

#NAS PORT
 if ($attr->{NAS_PORT}) {
   push @WHERE_RULES, "l.port_id='$attr->{NAS_PORT}'";
  }

#TARIF_PLAN
 if ($attr->{TARIF_PLAN}) {
   push @WHERE_RULES, "l.tp_id='$attr->{TARIF_PLAN}'";
  }

#Session ID
if ($attr->{ACCT_SESSION_ID}) {
   push @WHERE_RULES, "l.acct_session_id='$attr->{ACCT_SESSION_ID}'";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }


if ($attr->{TERMINATE_CAUSE}) {
	push @WHERE_RULES, "l.terminate_cause='$attr->{TERMINATE_CAUSE}'";
 }

if ($attr->{FROM_DATE}) {
   push @WHERE_RULES, "(date_format(l.start, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(l.start, '%Y-%m-%d')<='$attr->{TO_DATE}')";
 }

if ($attr->{DATE}) {
   push @WHERE_RULES, "date_format(l.start, '%Y-%m-%d')>='$attr->{DATE}'";
 }

if ($attr->{MONTH}) {
   push @WHERE_RULES, "date_format(l.start, '%Y-%m')>='$attr->{MONTH}'";
 }


#Interval from date to date
if ($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(start, '%Y-%m-%d')>='$from' and date_format(start, '%Y-%m-%d')<='$to'";
  }
#Period
elsif (defined($attr->{PERIOD}) ) {
   my $period = int($attr->{PERIOD});   
   if ($period == 4) { $WHERE .= ''; }
   else {
     $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
     if($period == 0)    {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(start) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(start) and (WEEK(curdate()) = WEEK(start)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}' "; }
     else {$WHERE .= "date_format(start, '%Y-%m-%d')=curdate() "; }
    }
 }
elsif($attr->{DATE}) {
	 push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}'";
}
#else {
#	 push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()";
#}
#From To


 push @WHERE_RULES, "u.uid=l.uid";
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';


 $self->query($db, "SELECT u.id, l.start, SEC_TO_TIME(l.duration), l.tp_id,
  l.sent, l.recv, l.CID, l.nas_id, l.ip, l.sum, INET_NTOA(l.ip), 
  l.acct_session_id, 
  l.uid, 
  UNIX_TIMESTAMP(l.start),
  l.duration,
  l.sent2, l.recv2
  FROM (dv_log l, users u)
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");


 my $list = $self->{list};



 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(l.uid), SEC_TO_TIME(sum(l.duration)), sum(l.sent), sum(l.recv), 
      sum(l.sent2), sum(l.recv2), 
      sum(sum)  
      FROM (dv_log l, users u)
     $WHERE;");

    ($self->{TOTAL},
     $self->{DURATION},
     $self->{TRAFFIC_IN},
     $self->{TRAFFIC_OUT},
     $self->{TRAFFIC2_IN},
     $self->{TRAFFIC2_OUT},
     $self->{SUM}) = @{ $self->{list}->[0] };
  }

#  $self->{list}=$list;

return $list;
}


#**********************************************************
# session calculation
# min max average
#**********************************************************
sub calculation {
	my ($self) = shift;
	my ($attr) = @_;

  @WHERE_RULES = ();
#Login
  if ($attr->{UID}) {
  	push @WHERE_RULES, "l.uid='$attr->{UID}'";
   }

if($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(start, '%Y-%m-%d')>='$from' and date_format(start, '%Y-%m-%d')<='$to'";
 }
#Period
elsif (defined($attr->{PERIOD}) ) {
   my $period = int($attr->{PERIOD});   
   if ($period == 4) {  

   	}
   else {
     if($period == 0)    {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(start) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(start) and (WEEK(curdate()) = WEEK(start)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}' "; }
    }
 }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';


  $self->query($db, "SELECT 
  SEC_TO_TIME(min(l.duration)), SEC_TO_TIME(max(l.duration)), SEC_TO_TIME(avg(l.duration)), SEC_TO_TIME(sum(l.duration)),
  min(l.sent), max(l.sent), avg(l.sent), sum(l.sent),
  min(l.recv), max(l.recv), avg(l.recv), sum(l.recv),
  min(l.recv+l.sent), max(l.recv+l.sent), avg(l.recv+l.sent), sum(l.recv+l.sent)
  FROM dv_log l $WHERE");

  ($self->{min_dur}, 
   $self->{max_dur}, 
   $self->{avg_dur}, 
   $self->{total_dur}, 

   $self->{min_sent}, 
   $self->{max_sent}, 
   $self->{avg_sent},
   $self->{total_sent},
   
   $self->{min_recv}, 
   $self->{max_recv}, 
   $self->{avg_recv}, 
   $self->{total_recv}, 

   $self->{min_sum}, 
   $self->{max_sum}, 
   $self->{avg_sum},
  $self->{total_sum}) =  @{ $self->{list}->[0] };

	return $self;
}


#**********************************************************
# Use
#**********************************************************
sub reports {
	my ($self) = shift;
	my ($attr) = @_;


 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 undef @WHERE_RULES;
 my $date = '';


 my @FIELDS_ARR = ('DATE', 
                   'USERS', 
                   'SESSIONS', 
                   'TRAFFIC_RECV', 
                   'TRAFFIC_SENT',
                   'TRAFFIC_SUM', 
                   'TRAFFIC_2_SUM', 
                   'DURATION', 
                   'SUM'
                   );

 $self->{REPORT_FIELDS} = {DATE            => '',  	
                           USERS           => 'u.id',
                           SESSIONS        => 'count(l.uid)',
                           TRAFFIC_SUM     => 'sum(l.sent + l.recv)',
                           TRAFFIC_2_SUM   => 'sum(l.sent2 + l.recv2)',
                           DURATION        => 'sec_to_time(sum(l.duration))',
                           SUM             => 'sum(l.sum)',
                           TRAFFIC_RECV    => 'sum(l.recv)',
                           TRAFFIC_SENT    => 'sum(l.sent)'
                          };
 

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }
 
 
 if(defined($attr->{DATE})) {
   push @WHERE_RULES, " date_format(l.start, '%Y-%m-%d')='$attr->{DATE}'";
  }
 elsif ($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(l.start, '%Y-%m-%d')>='$from' and date_format(l.start, '%Y-%m-%d')<='$to'";
   if ($attr->{TYPE} eq 'HOURS') {
     $date = "date_format(l.start, '%H')";
    }
   elsif ($attr->{TYPE} eq 'DAYS') {
     $date = "date_format(l.start, '%Y-%m-%d')";
    }
   else {
     $date = "u.id";   	
    }  
  }
 elsif (defined($attr->{MONTH})) {
 	 push @WHERE_RULES, "date_format(l.start, '%Y-%m')='$attr->{MONTH}'";
   $date = "date_format(l.start, '%Y-%m-%d')";
  } 
 else {
 	 $date = "date_format(l.start, '%Y-%m')";
  }



 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';


$self->{REPORT_FIELDS}{DATE}=$date;
my $fields = "$date, count(DISTINCT l.uid), 
      count(l.uid),
      sum(l.sent + l.recv), 
      sum(l.sent2 + l.recv2),
      sec_to_time(sum(l.duration)), 
      sum(l.sum)";

if ($attr->{FIELDS}) {
	my @fields_array = split(/, /, $attr->{FIELDS});
	my @show_fields = ();
  my %get_fields_hash = ();


  foreach my $line (@fields_array) {
  	$get_fields_hash{$line}=1;
   }
  
  foreach my $k (@FIELDS_ARR) {
    push @show_fields, $self->{REPORT_FIELDS}{$k} if ($get_fields_hash{$k});
  }

  $fields = join(', ', @show_fields)
}
 
 
 
 if(defined($attr->{DATE})) {
   if (defined($attr->{HOURS})) {
   	$self->query($db, "select date_format(l.start, '%Y-%m-%d %H')start, '%Y-%m-%d %H')start, '%Y-%m-%d %H'), count(DISTINCT l.uid), count(l.uid), 
    sum(l.sent + l.recv), sum(l.sent2 + l.recv2), sec_to_time(sum(l.duration)), sum(l.sum), l.uid
      FROM dv_log l
      LEFT JOIN users u ON (u.uid=l.uid)
      $WHERE 
      GROUP BY 1 
      ORDER BY $SORT $DESC");
    }
   else {
   	$self->query($db, "select date_format(l.start, '%Y-%m-%d'), if(u.id is NULL, CONCAT('> ', l.uid, ' <'), u.id), count(l.uid), 
    sum(l.sent + l.recv), sum(l.sent2 + l.recv2), sec_to_time(sum(l.duration)), sum(l.sum), l.uid
      FROM dv_log l
      LEFT JOIN users u ON (u.uid=l.uid)
      $WHERE 
      GROUP BY l.uid 
      ORDER BY $SORT $DESC");
   #$WHERE = "WHERE date_format(l.start, '%Y-%m-%d')='$attr->{DATE}'"; 
    }
  }
 else {
  $self->query($db, "select $fields,
      l.uid
       FROM dv_log l
       LEFT JOIN users u ON (u.uid=l.uid)
       $WHERE    
       GROUP BY 1 
       ORDER BY $SORT $DESC;");
  }

  my $list = $self->{list}; 

  $self->{USERS}    = 0; 
  $self->{SESSIONS} = 0; 
  $self->{TRAFFIC}  = 0; 
  $self->{TRAFFIC_2}= 0; 
  $self->{DURATION} = 0; 
  $self->{SUM}      = 0;

  return $list if ($self->{TOTAL} < 1);

  $self->query($db, "select count(DISTINCT l.uid), 
      count(l.uid),
      sum(l.sent),
      sum(l.recv), 
      sum(l.sent2),
      sum(l.recv2),
      sec_to_time(sum(l.duration)), 
      sum(l.sum)
       FROM dv_log l
       LEFT JOIN users u ON (u.uid=l.uid)
       $WHERE;");

 
  ($self->{USERS}, 
   $self->{SESSIONS}, 
   $self->{TRAFFIC_OUT}, 
   $self->{TRAFFIC_IN},
   $self->{TRAFFIC_2_OUT}, 
   $self->{TRAFFIC_2_IN}, 
   $self->{DURATION}, 
   $self->{SUM}) = @{ $self->{list}->[0] };

   $self->{TRAFFIC} = $self->{TRAFFIC_OUT} + $self->{TRAFFIC_IN};
   $self->{TRAFFIC_2} = $self->{TRAFFIC_2_OUT} + $self->{TRAFFIC_2_IN};

	return $list;
}



#**********************************************************
# List
#**********************************************************
sub list_log_intervals {
 my $self = shift;
 my ($attr) = @_;

 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 undef @WHERE_RULES; 
 
 
#UID
 if ($attr->{ACCT_SESSION_ID}) {
    push @WHERE_RULES, "l.acct_session_id='$attr->{ACCT_SESSION_ID}'";
  }

 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';




 $self->query($db, "SELECT interval_id,
                           traffic_type,
                           sent,
                           recv,
                           duration,
                           sum
  FROM dv_log_intervals l
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");


 my $list = $self->{list};

 return $list;
}

#**********************************************************
# Rotete logs
#**********************************************************
sub log_rotate {
	my $self = shift;
	my ($attr)=@_;
	
  $self->query($db, "DELETE from s_detail
            WHERE
  last_update < UNIX_TIMESTAMP()- $attr->{PERIOD} * 24 * 60 * 60;", 'do');
	

  $self->query($db, "DELETE LOW_PRIORITY dv_log_intervals from dv_log, dv_log_intervals
WHERE
  dv_log.acct_session_id=dv_log_intervals.acct_session_id
  and dv_log.start < curdate() - INTERVAL $attr->{PERIOD} DAY;", 'do');

	
	
	return $self;
}

1
