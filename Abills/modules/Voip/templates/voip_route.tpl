<form action=$SELF_URL method=post>
<input type=hidden name=index value=$index>
<input type=hidden name=chg value='%ROUTE_ID%'>
<table width=420 cellspacing=0 cellpadding=3>
<tr><td>ID:</td><td><input type=text name=ROUTE_ID value='%ROUTE_ID%'></td></tr>
<tr><td>$_PREFIX:</td><td><input type=text name=ROUTE_PREFIX value='%ROUTE_PREFIX%'></td></tr>
<tr><td>$_NAME:</td><td><input type=text name=ROUTE_NAME value='%ROUTE_NAME%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
