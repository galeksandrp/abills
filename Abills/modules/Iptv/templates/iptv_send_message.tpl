<form action=$SELF_URL METHOD=post>
<input type=hidden name=index value='$index'>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=send_message value='1'>
<table class=form>
<tr><th class=form_title>$_SEND $_MESSAGE</th></tr>
<tr><th><textarea cols=60 rows=10 name=MESSAGE>%MESSAGE%</textarea></th></tr>
<tr><th class=even><input type=submit name=send value='$_SEND'></th></tr>
</table>
</form>
