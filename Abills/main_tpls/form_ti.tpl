<div class='noprint'>
<form action='$SELF_URL'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='%TP_ID%'>
<input type=hidden name='TI_ID' value='%TI_ID%'>
 <TABLE width=400 cellspacing=1 cellpadding=0 border=0>
 <TR><TD>$_DAY:</TD><TD>%SEL_DAYS%</TD></TR>
 <TR><TD>$_BEGIN:</TD><TD><input type=text name=TI_BEGIN value='%TI_BEGIN%'></TD></TR>
 <TR><TD>$_END:</TD><TD><input type=text name=TI_END value='%TI_END%'></TD></TR>
 <TR><TD>$_HOUR_TARIF (0.00<!--  / 0% -->):</TD><TD><input type=text name=TI_TARIF value='%TI_TARIF%'></TD></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>
