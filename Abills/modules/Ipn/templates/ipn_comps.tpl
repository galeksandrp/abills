<form action='$SELF_URL'>
<input type=hidden name=index value=$index> 
<input type=hidden name=ID value='$FORM{chg}'> 
<table>
<tr><td>$_NAME:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>IP:</td><td><input type='text' name='IP' value='%IP%'></td></tr>
<tr><td>MAC:</td><td><input type='text' name='CID' value='%CID%'></td></tr>
</table>

<input type='submit' name='%ACTION%' value='%ACTION_LNG%'>
</form>