<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{chg}'>
<TABLE>
<tr><td>$_NAME:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>$_COMMENTS:</td><td><input type='text' name='COMMENTS' value='%COMMENTS%'></td></tr>
</TABLE>
<input type='submit' name='%ACTION%' value='%ACTION_LNG%'>
</form>