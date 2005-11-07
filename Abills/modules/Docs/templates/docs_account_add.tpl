<form action=$SELF_URL method=post>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=$FORM{UID}>
<input type=hidden name=ACCT_ID value='%ACCT_ID%'>
<Table>
<tr><td>$_TO_USER:</td><td>$login</td></tr>
<tr><td>N:</td><td><input type=text name=ACCT_ID value='%ACCT_ID%'></td></tr>
<tr><td>$_DATE:</td><td><input type=text name=DATE value='%DATE%'></td></tr>
<tr><td>$_CUSTOMER:</td><td><input type=text name=CUSTOMER value='%CUSTOMER%'></td></tr>
<tr><td>$_PHONE:</td><td><input type=text name=PHONE value=%PHONE%></td></tr>
<tr><td>$_ORDER:</td><td>%ORDER_SEL%</td></tr>
<tr><td>$_SUM:</td><td><input type=text name=SUM value='%SUM%'></td></tr>
</table>
<!-- <input type=submit name=pre value='$_PRE'>  -->
<input type=submit name=create value='$_CREATE'>
</form>
