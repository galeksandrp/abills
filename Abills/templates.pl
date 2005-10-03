
#**********************************************************
# templates
#**********************************************************
sub _include {
  my ($tpl, $module) = @_;
  my $result = '';
  
  if (defined($module)) {
    $tpl	= "modules/$module/templates/$tpl";
   }

  foreach $prefix (@INC) {
     my $realfilename = "$prefix/Abills/$tpl.tpl";
     if (-f $realfilename) {
        open(FILE, "$realfilename") || die "Can't open file '$realfilename' $!";
        while(<FILE>) {
  	      $tpl_content .= eval "\"$_\"";
         }
        close(FILE);
        last;
      }
  }
  return $tpl_content;
}


#**********************************************************
# templates
#**********************************************************
sub templates {
  my ($tpl_name) = @_;

if ($tpl_name eq 'form_pi') {
return qq{
<form action=$SELF_URL method=post>
<input type=hidden name=index value=30>
<input type=hidden name=UID value="%UID%">
<table width=420 cellspacing=0 cellpadding=3>
<tr><td>$_FIO:*</td><td><input type=text name=FIO value="%FIO%"></td></tr>
<tr><td>$_PHONE:</td><td><input type=text name=PHONE value="%PHONE%"></td></tr>
<tr><td>$_ADDRESS_STREET:</td><td><input type=text name=ADDRESS_STREET value="%ADDRESS_STREET%"></td></tr>
<tr><td>$_ADDRESS_BUILD:</td><td><input type=text name=ADDRESS_BUILD value="%ADDRESS_BUILD%"></td></tr>
<tr><td>$_ADDRESS_FLAT:</td><td><input type=text name=ADDRESS_FLAT value="%ADDRESS_FLAT%"></td></tr>
<tr><td>E-mail:</td><td><input type=text name=EMAIL value="%EMAIL%"></td></tr>
<tr><td>$_CONTRACT_ID:</td><td><input type=text name=CONTRACT_ID value="%CONTRACT_ID%"></td></tr>
<tr><th colspan=2>:$_COMMENTS:</th></tr>
<tr><th colspan=2><textarea name=COMMENTS rows=5 cols=45>%COMMENTS%</textarea></th></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
};

 }
elsif ($tpl_name eq 'form_user') {
return qq{
<form action=$SELF_URL method=post METHOD=POST>
<input type=hidden name=index value=11>
<input type=hidden name=COMPANY_ID value='%COMPANY_ID%'>
<input type=hidden name=UID value="%UID%">
<table width=420 cellspacing=0 cellpadding=3>
%EXDATA%
<tr><td>BILL_ID:<td>%BILL_ID%</td></tr>
<tr><td colspan=2>&nbsp;</td></tr>

<tr><td>$_CREDIT:</td><td><input type=text name=CREDIT value='%CREDIT%'></td></tr>
<tr><td>$_GROUPS:</td><td>%GID%:%G_NAME%</td></tr>
<tr><td>$_ACTIVATE:</td><td><input type=text name=ACTIVATE value='%ACTIVATE%'></td></tr>
<tr><td>$_EXPIRE:</td><td><input type=text name=EXPIRE value='%EXPIRE%'></td></tr>
<tr><td>$_REDUCTION (%):</td><td><input type=text name=REDUCTION value='%REDUCTION%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
};

 }
elsif ($tpl_name eq 'client_info') {
return qq{
<p>
<TABLE width=600 cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=#E1E1E1>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=#EEEEEE><td><b>$_LOGIN:</b></td><td>%LOGIN%</td></tr>
<tr bgcolor=#FFFFFF><td><b>$_FIO:</b></td><td>%FIO%</td></tr>
<tr bgcolor=#FFFFFF><td><b>$_PHONE:</b></td><td>%PHONE%</td></tr>
<tr bgcolor=#FFFFFF><td><b>$_ADDRESS:</b></td><td>%ADDRESS%</td></tr>
<tr bgcolor=#FFFFFF><td><b>E-mail:</b></td><td>%EMAIL%</td></tr>
<tr bgcolor=#DDDDDD><td colspan=2>&nbsp</td></tr>
<tr bgcolor=#FFFFFF><td><b>$_TARIF_PLAN:</b></td><td>%TARIF_PLAN% : %TARIF_PLAN_NAME%</td></tr>
<tr bgcolor=#FFFFFF><td><b>$_DEPOSIT:</b></td><td>%DEPOSIT%</td></tr>
<tr bgcolor=#FFFFFF><td><b>$_CREDIT:</b></td><td>%CREDIT%</td></tr>
<tr bgcolor=#FFFFFF><td><b>$_REDUCTION:</b></td><td>%REDUCTION% %</td></tr>
<tr bgcolor=#FFFFFF><td><b>$_SIMULTANEOUSLY:</b></td><td>%SIMULTANEONSLY%</td></tr>
<tr bgcolor=#DDDDDD><td colspan=2>&nbsp</td></tr>
<tr bgcolor=#FFFFFF><td><b>$_ACTIVATE:</b></td><td>%ACTIVATE%</td></tr>
<tr bgcolor=#FFFFFF><td><b>$_EXPIRE:</b></td><td>%EXPIRE%</td></tr>
<tr bgcolor=#FFFFFF><td><b>IP:</b></td><td>%IP%</td></tr>
<tr bgcolor=#FFFFFF><td><b>$_SPEED (Kb)</b></td><td>%SPEED%</td></tr>
<tr bgcolor=#FFFFFF><td><b>CID:</b></td><td>%CID%</td></tr>
</table>
</td></tr></table>
</p>
};
 }
elsif($tpl_name eq 'session_detail') {
 return qq{
<TABLE width=600 cellspacing=0 cellpadding=0 border=0>
 <TR><TD bgcolor=#E1E1E1>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=#FFFFFF><td>$_SESSION_ID:</td><td>%SESSION_ID%</td></tr>
<tr bgcolor=#FFFFFF><td>$_BEGIN:</td><td align=right>%START%</td></tr>
<tr bgcolor=#FFFFFF><td>$_END:</td><td align=right>%STOP%</td></tr>
<tr bgcolor=#FFFFFF><td>$_DURATION</td><td align=right>%DURATION%</td></tr>
<tr bgcolor=#FFFFFF><td>$_TARIF_PLAN</td><td>[%TP_ID%] %TP_NAME%</td></tr>
<tr bgcolor=#FFFFFF><td>$_SENT:</td><td align=right>%_SENT% (%SENT%)</td></tr>
<tr bgcolor=#FFFFFF><td>$_RECV:</td><td  align=right>%_RECV% (%RECV%)</td></tr>
<tr bgcolor=#FFFFFF><td>$_SENT 2:</td><td align=right>%_SENT2% (%SENT2%)</td></tr>
<tr bgcolor=#FFFFFF><td>$_RECV 2:</td><td align=right>%_RECV2% (%RECV2%)</td></tr>
<tr bgcolor=#FFFFFF><td>IP:</td><td align=right>%IP%</td></tr>
<tr bgcolor=#FFFFFF><td>CID:</td><td align=right>%CID%</td></tr>
<tr bgcolor=$_COLORS[0]><th colspan=2>$_NAS</th></tr>
<tr bgcolor=#FFFFFF><td>ID:</td><td>%NAS_ID%</td></tr>
<tr bgcolor=#FFFFFF><td>NAME</td><td>%NAS_NAME%</td></tr>
<tr bgcolor=#FFFFFF><td>IP:</td><td>%NAS_IP%</td></tr>
<tr bgcolor=#FFFFFF><td>PORT:</td><td>%NAS_PORT%</td></tr>
<tr bgcolor=#FFFFFF><td colspan=2>&nbsp;</td></tr>
<tr bgcolor=#FFFFFF><td>$_TIME_TARIF:</td><td>%TIME_TARIFF%</td></tr>
<tr bgcolor=#FFFFFF><td>$_TRAF_TARIF:</td><td>%TRAF_TARIFF%</td></tr>
<tr bgcolor=#FFFFFF><td>$_SUM:</td><td>%SUM%</td></tr>

<tr bgcolor=#FFFFFF><td>$_COMPANY_ID:</td><td>%COMPANY_ID%</td></tr>

</td></tr></table>
</table>
};

}
elsif ($tpl_name eq 'user_info') {
return qq{
<table width=100%>
<tr><td>$_LOGIN:</td><td>%LOGIN%</td></tr>
<tr><td>UID:</td><td>%UID%</td></tr>
<tr><td>$_FIO:</td><td>%FIO%</td></tr>
<tr><td>$_PHONE:</td><td>%PHONE%</td></tr>
<tr><td>$_ADDRESS:</td><td>%ADDRESS%</td></tr>
<tr><td>E-mail:</td><td>%EMAIL%</td></tr>
<tr><td>$_TARIF_PLAN:</td><td>%TARIF_PLAN%</td></tr>
<tr><td>$_CREDIT:</td><td>%CREDIT%</td></tr>
<tr><td>$_REDUCTION</td><td>%REDUICTION% %</td></tr>
<tr><td>$_SIMULTANEOUSLY:</td><td>%SIMULTANEONSLY%</td></tr>
<tr><td>$_ACTIVATE:</td><td>%ACTIVATE%</td></tr>
<tr><td>$_EXPIRE:</td><td>%EXPIRE%</td></tr>
<tr><td>IP:</td><td>%IP%</td></tr>
<tr><td>NETMASK:</td><td>%NETMASK%</td></tr>
<tr><td>$_SPEED (Kb)</td><td>%SPEED%</td></tr>
<tr><td>$_FILTERS</td><td>%FILTER_ID%</td></tr>
<tr><td>CID:</td><td>%CID%</td></tr>
<tr><th colspan=2>:$_COMMENTS:</th></tr>
<tr><th colspan=2>%COMMENTS%</th></tr>
</table>};
 }
elsif ($tpl_name eq 'form_payments') {
return qq{
<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=subf value=$FORM{subf}>
<input type=hidden name=OP_SID value=%OP_SID%>
<input type=hidden name=UID value=%UID%>
<table>
<tr><td>$_SUM:</td><td><input type=text name=SUM></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=DESCRIBE></td></tr>
<tr><td>$_EXCHANGE_RATE:</td><td>%SEL_ER%</td></tr>
<tr><td colspan=2><hr size=1></td></tr>
<tr><td>$_PAYMENT_METHOD:</td><td>%SEL_METHOD%</td></tr>
<tr><td>ID:</td><td><input type=text name=EXT_ID value='%EXT_ID%'></td></tr>
</table>
<input type=submit name=add value='$_ADD'>
</form>
};
 }
elsif ($tpl_name eq 'form_fees') {
return qq{
<form action=$SELF_URL>
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=index value='$index'>
<input type=hidden name=subf value='$FORM{subf}'>
<table>
<tr><td>$_SUM:</td><td><input type=text name=SUM></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=DESCR></td></tr>
%PERIOD_FORM%
</table>
<input type=submit name=take value='$_TAKE'>
</form>
}

}
elsif ($tpl_name eq 'tp') {
return qq{
<form action=$SELF_URL METHOD=POST>
<input type=hidden name=index value=70>
<input type=hidden name=chg value='%TP_ID%'>
<table border=0>
  <tr><th>#</th><td><input type=text name=TP_ID value='%TP_ID%'></td></tr>
  <tr><td>$_NAME:</td><td><input type=text name=NAME value='%NAME%'></td></tr>
  <tr><td>$_UPLIMIT:</td><td><input type=text name=ALERT value='%ALERT%'></td></tr>

<!--
  <tr><td>$_BEGIN:</td><td><input type=text name=BEGIN value='%BEGIN%'></td></tr>
  <tr><td>$_END:</td><td><input type=text name=END value='%END%'></td></tr>
-->

  <tr><td>$_DAY_FEE:</td><td><input type=text name=DAY_FEE value='%DAY_FEE%'></td></tr>
  <tr><td>$_MONTH_FEE:</td><td><input type=text name=MONTH_FEE value='%MONTH_FEE%'></td></tr>
  <tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=SIMULTANEOUSLY value='%SIMULTANEOUSLY%'></td></tr>
  <tr><td>$_HOUR_TARIF (1 Hour):</td><td><input type=text name=TIME_TARIF value='%TIME_TARIF%'></td></tr>
  <tr><th colspan=2 bgcolor=$_COLORS[0]>$_TIME_LIMIT (sec)</th></tr> 
  <tr><td>$_DAY</td><td><input type=text name=DAY_TIME_LIMIT value='%DAY_TIME_LIMIT%'></td></tr> 
  <tr><td>$_WEEK</td><td><input type=text name=WEEK_TIME_LIMIT value='%WEEK_TIME_LIMIT%'></td></tr>
  <tr><td>$_MONTH</td><td><input type=text name=MONTH_TIME_LIMIT value='%MONTH_TIME_LIMIT%'></td></tr>
  <tr><th colspan=2 bgcolor=$_COLORS[0]>$_TRAF_LIMIT (Mb)</th></tr>
  <tr><td>$_DAY</td><td><input type=text name=DAY_TRAF_LIMIT value='%DAY_TRAF_LIMIT%'></td></tr>
  <tr><td>$_WEEK</td><td><input type=text name=WEEK_TRAF_LIMIT value='%WEEK_TRAF_LIMIT%'></td></tr>
  <tr><td>$_MONTH</td><td><input type=text name=MONTH_TRAF_LIMIT value='%MONTH_TRAF_LIMIT%'></td></tr>
  <tr><td>$_OCTETS_DIRECTION</td><td>%SEL_OCTETS_DIRECTION%</td></tr>
  <tr><th colspan=2 bgcolor=$_COLORS[0]>$_OTHER</th></tr>
  <tr><td>$_ACTIVATE:</td><td><input type=text name=ACTIV_PRICE value='%ACTIV_PRICE%'></td></tr>
  <tr><td>$_CHANGE:</td><td><input type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'></td></tr>
  <tr><td>$_CREDIT_TRESSHOLD:</td><td><input type=text name=CREDIT_TRESSHOLD value='%CREDIT_TRESSHOLD%'></td></tr>
  <tr><td>$_MAX_SESSION_DURATION (sec.):</td><td><input type=text name=MAX_SESSION_DURATION value='%MAX_SESSION_DURATION%'></td></tr>
  <tr><td>$_FILTERS:</td><td><input type=text name=FILTER_ID value='%FILTER_ID%'></td></tr>
  <tr><td>$_AGE ($_DAYS):</td><td><input type=text name=AGE value='%AGE%'></td></tr>
  <tr><td>$_PAYMENT_TYPE:</td><td>%PAYMENT_TYPE_SEL%</td></tr>
  <tr><td>$_MIN_SESSION_COST:</td><td><input type=text name=MIN_SESSION_COST value='%MIN_SESSION_COST%'></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
};
 }
#elsif($tpl_name eq 'tt') {
#
#return qq{ <form action=$SELF_URL method=POST>
#<input type=hidden name=index value='70'>
#<input type=hidden name=subf value='73'>
#<input type=hidden name=TP_ID value='%TP_ID%'>
#<input type=hidden name=tt value='%TI_ID%'>
#
#<table BORDER=0 CELLSPACING=1 CELLPADDING=0>
#<tr bgcolor=$_COLORS[1]><th colspan=7 align=right>$_TRAFIC_TARIFS</th></tr>
#<tr bgcolor=$_COLORS[0]><th>#</th><th>$_BYTE_TARIF IN (1 Mb)</th><th>$_BYTE_TARIF OUT (1 Mb)</th><th>$_PREPAID (Mb)</th><th>$_SPEED (Kbits)</th><th>$_DESCRIBE</th><th>NETS</th></tr>
#<tr><td bgcolor=$_COLORS[0]>0</td>
#<td valign=top><input type=text name='TT_PRICE_IN_0' value='%TT_PRICE_IN_0%'></td>
#<td valign=top><input type=text name='TT_PRICE_OUT_0' value='%TT_PRICE_OUT_0%'></td>
#<td valign=top><input type=text size=12 name='TT_PREPAID_0' value='%TT_PREPAID_0%'></td>
#<td valign=top><input type=text size=12 name='TT_SPEED_0' value='%TT_SPEED_0%'></td>
#<td valign=top><input type=text name='TT_DESCRIBE_0' value='%TT_DESCRIBE_0%'></td>
#<td><textarea cols=20 rows=4 name='TT_NETS_0'>%TT_NETS_0%</textarea></td></tr>
#
#<tr><td bgcolor=$_COLORS[0]>1</td>
#<td valign=top><input type=text name='TT_PRICE_IN_1' value='%TT_PRICE_IN_1%'></td>
#<td valign=top><input type=text name='TT_PRICE_OUT_1' value='%TT_PRICE_OUT_1%'></td>
#<td valign=top><input type=text size=12 name='TT_PREPAID_1' value='%TT_PREPAID_1%'></td>
#<td valign=top><input type=text size=12 name='TT_SPEED_1' value='%TT_SPEED_1%'></td>
#<td valign=top><input type=text name='TT_DESCRIBE_1' value='%TT_DESCRIBE_1%'></td>
#<td><textarea cols=20 rows=4 name='TT_NETS_1'>%TT_NETS_1%</textarea></td></tr>
#
#<tr><td bgcolor=$_COLORS[0]>2</td>
#<td valign=top>&nbsp;</td>
#<td valign=top>&nbsp;</td>
#<td valign=top>&nbsp;</td>
#<td valign=top><input type=text size=12 name='TT_SPEED_2' value='%TT_SPEED_2%'></td>
#<td valign=top><input type=text name='TT_DESCRIBE_2' value='%TT_DESCRIBE_2%'></td>
#<td><textarea cols=20 rows=4 name='TT_NETS_2'>%TT_NETS_2%</textarea></td></tr>
#
#</table>
#<input type=submit name='change' value='$_CHANGE'>
#</form>\n};
# }
elsif($tpl_name eq 'tt') {

return qq{ <form action=$SELF_URL method=POST>
<input type=hidden name=index value='70'>
<input type=hidden name=subf value='73'>
<input type=hidden name=TP_ID value='%TP_ID%'>
<input type=hidden name=tt value='%TI_ID%'>
<table BORDER=0 CELLSPACING=1 CELLPADDING=0>
<tr bgcolor=$_COLORS[1]><th colspan=7 align=right>$_TRAFIC_TARIFS</th></tr>
<tr><td>ID</td><td bgcolor=$_COLORS[0]>0</td></tr>
<tr><td>$_BYTE_TARIF IN (1 Mb)</td><td><input type=text name='TT_PRICE_IN' value='%TT_PRICE_IN%'></td></tr>
<tr><td>$_BYTE_TARIF OUT (1 Mb)</td><td><input type=text name='TT_PRICE_OUT' value='%TT_PRICE_OUT%'></td></tr>
<tr><td>$_PREPAID (Mb)</td><td><input type=text size=12 name='TT_PREPAID' value='%TT_PREPAID%'></td></tr>
<tr><td>$_SPEED (Kbits)</td><td><input type=text size=12 name='TT_SPEED' value='%TT_SPEED%'></td></tr>
<tr><td>$_DESCRIBE</td><td><input type=text name='TT_DESCRIBE' value='%TT_DESCRIBE%'></td></tr>
<tr><th colspan=2>NETS</th></tr>
<tr><td colspan=2><textarea cols=20 rows=4 name='TT_NETS'>%TT_NETS_0%</textarea></th></tr>
</table>
<input type=submit name='change' value='$_CHANGE'>
</form>
};
 }

elsif ($tpl_name eq 'ti') {
return qq{<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=TP_ID value='%TP_ID%'>
<input type=hidden name=TI_ID value='%TI_ID%'>
 <TABLE width=400 cellspacing=1 cellpadding=0 border=0>
 <tr><td>$_DAY:</td><td><select name=TI_DAY>%SEL_DAYS%</select></td></tr>
 <tr><td>$_BEGIN:</td><td><input type=text name=TI_BEGIN value='%TI_BEGIN%'></td></tr>
 <tr><td>$_END:</td><td><input type=text name=TI_END value='%TI_END%'></td></tr>
 <tr><td>$_HOUR_TARIF<br>(0.00 / 0%):</td><td><input type=text name=TI_TARIF value='%TI_TARIF%'></td></tr>
</table>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</form>
};
 }
elsif ($tpl_name eq 'form_admin') {
return qq{<form action=$SELF_URL>
<input type=hidden name=index value=50>
<input type=hidden name=AID value='%AID%'>
<table>
<tr><td>ID:</td><td><input type=text name=A_LOGIN value="%A_LOGIN%"></td></tr>
<tr><td>$_FIO:</td><td><input type=text name=A_FIO value="%A_FIO%"></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><td>$_PHONE:</td><td><input type=text name=A_PHONE value='%A_PHONE%'></td></tr>
<!-- <tr><td>$_GROUPS:</td><td><input type=text name=name value="$name"></td></tr> -->
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
};
}
elsif ($tpl_name eq 'form_nas') {
return qq{
<form action=$SELF_URL METHOD=post>
<input type=hidden name=index value=60>
<input type=hidden name=nid value=%NID%>
<table>
<tr><td>ID</td><td>%NID%</td></tr>
<tr><td>IP</td><td><input type=text name=NAS_IP value='%NAS_IP%'></td></tr>
<tr><td>$_NAME:</td><td><input type=text name=NAS_NAME value="%NAS_NAME%"></td></tr>
<tr><td>Radius NAS-Identifier:</td><td><input type=text name=NAS_INDENTIFIER value="%NAS_INDENTIFIER%"></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=NAS_DESCRIBE value="%NAS_DESCRIBE%"></td></tr>
<tr><td>$_TYPE:</td><td><select name=NAS_TYPE>%SEL_TYPE%</select></td></tr>
<tr><td>$_AUTH:</td><td><select name=NAS_AUTH_TYPE>%SEL_AUTH_TYPE%</select></td></tr>
<tr><td>Alive:</td><td><input type=text name=NAS_ALIVE value='%NAS_ALIVE%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=NAS_DISABLE value=1 %NAS_DISABLE%></td></tr>
<tr><th colspan=2>:$_MANAGE:</th></tr>
<tr><td>IP:PORT:</td><td><input type=text name=NAS_MNG_IP_PORT value="%NAS_MNG_IP_PORT%"></td></tr>
<tr><td>$_USER:</td><td><input type=text name=NAS_MNG_USER value="%NAS_MNG_USER%"></td></tr>
<tr><td>$_PASSWD:</td><td><input type=password name=NAS_MNG_PASSWORD value=""></td></tr>
<tr><th colspan=2>RADIUS $_PARAMS (,)</th></tr>
<tr><th colspan=2><textarea cols=50 rows=4 name=NAS_RAD_PAIRS>%NAS_RAD_PAIRS%</textarea></th></tr>
</table>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</form>
};

}
elsif ($tpl_name eq 'form_company') {
return qq{	
<form action=$SELF_URL METHOD=POST>
<input type=hidden name=index value='13'>
<input type=hidden name=COMPANY_ID value='%COMPANY_ID%'>
<Table>
<tr><td>$_NAME:</td><td><input type=text name=COMPANY_NAME value="%COMPANY_NAME%"></td></tr>
<tr bgcolor=$_BG1><td>$_BILL:</td><td>%BILL_ID%</td></tr>
<tr bgcolor=$_BG1><td>$_DEPOSIT:</td><td>%DEPOSIT%</td></tr>
<tr bgcolor=$_BG1><td>$_CREDIT:</td><td><input type=text name=CREDIT value='%CREDIT%'></td></tr>
<tr bgcolor=$_BG1><td>$_TAX_NUMBER:</td><td><input type=text name=TAX_NUMBER value='%TAX_NUMBER%' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_ACCOUNT:</td><td><input type=text name=BANK_ACCOUNT value='%BANK_ACCOUNT%' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_BANK_NAME:</td><td><input type=text name=BANK_NAME value='%BANK_NAME%' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_COR_BANK_ACCOUNT:</td><td><input type=text name=COR_BANK_ACCOUNT value='%COR_BANK_ACCOUNT%' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_BANK_BIC:</td><td><input type=text name=BANK_BIC value='%BANK_BIC%' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
}
}
elsif ($tpl_name eq 'chg_company') {
return qq{
<form action=$SELF_URL>
<input type=hidden name=index value=11>
<input type=hidden name=UID value=%UID%>
<input type=hidden name=user_f value=chg_company>
<Table>
<tr><td>$_COMPANY:</td><td>%COMPANY_NAME%</td></tr>
<tr><td>$_TO:</td><td>%SEL_COMPANIES%</td></tr>
</table>
<input type=submit name=change value=$_CHANGE>
</form>
}
}
elsif ($tpl_name eq 'chg_group') {
return qq{
<form action=$SELF_URL>
<input type=hidden name=index value=11>
<input type=hidden name=UID value=%UID%>
<input type=hidden name=user_f value=chg_group>
<Table>
<tr><td>$_GROUP:</td><td>%GID%:%G_NAME%</td></tr>
<tr><td>$_TO:</td><td>%SEL_GROUPS%</td></tr>
</table>
<input type=submit name=change value=$_CHANGE>
</form>
}
}
elsif ($tpl_name eq 'form_search') {
return qq{
<form action=$SELF_URL>
<input type=hidden name=index value=7>
<table>
<tr><td>$_NAME:</td><td><input type=text name=LOGIN_EXPR value='%LOGIN_EXPR%'></td></tr>
<tr><td>WHERE:</td><td>%SEL_TYPE%</td></tr>
<tr><td>$_PERIOD:</td><td>
<table width=100%>
<tr><td>$_FROM: </td><td>%FROM_DATE%</td></tr>
<tr><td>$_TO:</td><td>%TO_DATE%</td></tr>
</table>
</td></tr>
%SEARCH_FORM%
</table>
<input type=submit name=search value=$_SEARCH>
</form>
};
	
}
elsif ($tpl_name eq 'form_ip_pools') {
return qq{
<form action=$SELF_URL METHOD=post>
<input type=hidden name=index value=61>
<input type=hidden name=nid value=%NID%>
<table>
<tr><td>FIRST IP:</td><td><input type=text name=NAS_IP_SIP value='%NAS_IP_SIP%'></td></tr>
<tr><td>COUNT:</td><td><input type=text name=NAS_IP_COUNT value='%NAS_IP_COUNT%'></td></tr>
</table>
<input type=submit name=add value="$_ADD">
</form>
};
}
elsif ($tpl_name eq 'form_groups') {
return qq{
<form action=$SELF_URL METHOD=post>
<input type=hidden name=index value=27>
<input type=hidden name=chg value=%GID%>
<table>
<tr><td>GID:</td><td><input type=text name=GID value='%GID%'></td></tr>
<tr><td>$_NAME:</td><td><input type=text name=G_NAME value='%G_NAME%'></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=G_DESCRIBE value='%G_DESCRIBE%'></td></tr>
</table>
<input type=submit name=%ACTION% value="%LNG_ACTION%">
</form>
};
}
elsif ($tpl_name eq 'chg_bill') {
return qq{
<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=%UID%>
<input type=hidden name=COMPANY_ID value=$FORM{COMPANY_ID}>
<Table width=300>
<tr><td>$_BILL:</td><td>%BILL_ID%:%LOGIN%</td></tr>
<tr><td>$_CREATE:</td><td><input type=checkbox name=create value=1></td></tr>
<tr><td>$_TO:</td><td>%SEL_BILLS%</td></tr>
</table>
%CREATE_BTN%
<input type=submit name=change value=$_CHANGE>
</form>
}
}
elsif($tpl_name eq 'users_warning_messages') {
return qq{
Шановний користувач %LOGIN%.

Ви працюєте за тарифним планом # [%TP_ID%] %TP_NAME%.
На Вашому рахунку на даний час залишилось %DEPOSIT% у.о.
Якщо Ваш рахунок стане меншим за допустиму межу входу: %CREDIT%
(Кредит %CREDIT% у.о.)
Ваш доступ тимчасово буде заблоковано.
};
}
elsif($tpl_name eq 'admin_report_day') {

return qq{
Daily Admin Report /%DATE%/

$_PAYMENTS
=========================================================
%PAYMENTS%

$_FEES
=========================================================
%FEES%

$_SHEDULE
=========================================================
%SHEDULE%

USERS_WARNING_MESSAGES
=========================================================
%USERS_WARNINGS%

$_CLOSED
=========================================================
%CLOSED%

$_USED
=========================================================
%SESSIONS%


};

}
elsif($tpl_name eq 'admin_report_month') {

return qq{
Daily Admin Report /%DATE%/

$_PAYMENTS
=========================================================
%PAYMENTS%


$_FEES
=========================================================
%FEES%


USERS_WARNING_MESSAGES
=========================================================
%USERS_WARNINGS%


$_CLOSED
=========================================================
%CLOSED%


$_USED
=========================================================
%SESSIONS%


};

}


return 'No such template [$tpl_name]';

}


1
