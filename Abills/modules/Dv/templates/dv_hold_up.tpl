<div id=form_holdup>
<form action=$SELF_URL METHOD=GET name=holdup>
<input type=hidden name=index value=$index>
<input type=hidden name=sid value=$sid>
<input type=hidden name=UID value=$FORM{UID}>

<TABLE width=500 cellspacing=0 cellpadding=0 border=0>
<TR><TD bgcolor=#E1E1E1>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<TR><TD bgcolor=#FFFFFF>

<table width=100%>
<tr><th colspan=2 class=table_title align=right>$_HOLD_UP</th></tr>
<tr><td>$_FROM:</td><td>%DATE_FROM%</td></tr>
<tr><td>$_TO:</td><td>%DATE_TO%</td></tr>
<tr><th colspan=2><input type=submit value='$_HOLD_UP' name='add'></th></tr>
</table>

</td></tr></table>
</td></tr></table>


</form>

</div>