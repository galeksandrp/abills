<form action=$SELF_URL method=post>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='$FORM{UID}'>
<table width=420 cellspacing=0 cellpadding=3>
<tr><td>$_NUMBER:</td><td><input type=text name=NUMBER value='%NUMBER%'></td></tr>
<tr><td>$_TARIF_PLAN:</td><td valign=center>[%TP_ID%]<b> %TP_NAME%</b></td></tr>
<tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=SIMULTANEONSLY value='%SIMULTANEOUSLY%'></td></tr>
<tr><td>IP:</td><td><input type=text name=IP value='%IP%'></td></tr>
<tr><td>CID:</td><td><input type=text name=CID value='%CID%'>
<tr><td>$_ALLOW_ANSWER:</td><td><input type=checkbox name=ALLOW_ANSWER value='1' %ALLOW_ANSWER%></td></tr>
<tr><td>$_ALLOW_CALLS:</td><td><input type=checkbox name=ALLOW_CALLS value='1' %ALLOW_CALLS%></td></tr>

<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
