
<form action=$SELF_URL METHOD=POST>
<input type=hidden name='index' value='$index'>
<input type=hidden name='MAIL_TRANSPORT_ID' value='%MAIL_TRANSPORT_ID%'>
<table>
<tr><td>$_ADDRESS:</td><td><input type=text name=DOMAIN value='%DOMAIN%'></td></tr>
<tr><td>GOTO (virtual: maildrop: local: relay:):</td><td><input type=text name=TRANSPORT value='%TRANSPORT%'></td></tr>
<!-- <tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr> -->
<tr><th colspan=2>$_COMMENTS:</th></tr>
<tr><th colspan=2><textarea name=COMMENTS cols=40 rows=5>%COMMENTS%</textarea></th></tr>
</table>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</form>