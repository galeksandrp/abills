<form action='$SELF_URL' method='post' name=pay_to>
<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='SUM' value='%SUM%'>
<table cellspacing='0' cellpadding='3' width=450>
<tr bgcolor=$_COLORS[2]><th colspan=2 class=form_title>$_PAY_TO</th></tr>
<tr bgcolor=$_COLORS[2]><td>$_TARIF_PLAN:</td><th  align='left' valign='middle'>[%TP_ID%] %TP_NAME%</th></tr>
<tr><td>$_DATE:</td><td>%DATE%</td></tr>
<tr><td>$_SUM:</td><td>%SUM%</td></tr>
<tr><td>$_DAYS:</td><td>%DAYS%</td></tr>
</table>
<input type=submit name='pay_to' value='%ACTION_LNG%' class='noprint'>
</form>
