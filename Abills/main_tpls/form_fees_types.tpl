<div class='noprint'>
<form action='$SELF_URL' name=user>
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=index value='$index'>
<input type=hidden name=subf value='$FORM{subf}'>
<TABLE border=0>
<TR><TH colspan=3 class='form_title'>$_FEES $_TYPES</TH></TR>
<TR><TD colspan=2>ID:</TD><TD><input type='text' name='ID' value='%ID%'></TD></TR>
<TR><TD colspan=2>$_NAME:</TD><TD><input type='text' name='NAME' value='%NAME%'></TD></TR>
<TR><TD colspan=2>$_SUM:</TD><TD><input type='text' name='SUM' value='%SUM%'></TD></TR>
<TR><TD rowspan=2>$_DESCRIBE:</TD><TD>$_USER:</TD><TD><input type=text name=DESCRIBE value='%DESCRIBE%' size=40></TD></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>
